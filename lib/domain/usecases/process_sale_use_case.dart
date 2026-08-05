import '../../core/i18n/transaction_descriptions.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ids.dart';
import '../entities/financial_transaction.dart';
import '../entities/sale.dart';
import '../repositories/i_financial_transaction_repository.dart';
import '../repositories/i_sale_processor.dart';
import '../repositories/i_sale_repository.dart';
import '../repositories/i_unit_of_work.dart';
import 'update_product_stock_use_case.dart';

/// Exceção de domínio: venda inválida (sem itens ou total divergente).
final class InvalidSaleException implements Exception {
  const InvalidSaleException(this.message);

  final String message;

  @override
  String toString() => 'InvalidSaleException: $message';
}

/// Caso de uso: processar uma venda (registrar + baixar estoque + caixa).
///
/// Orquestra [ISaleRepository], [UpdateProductStockUseCase],
/// [IFinancialTransactionRepository] e [IUnitOfWork] — depende apenas de
/// abstrações, nunca de implementações concretas.
///
/// Quando [processor] é fornecido (Supabase), a venda inteira é delegada a
/// ele — o servidor executa tudo em UMA transação (RPC `process_sale`).
/// Sem processor (SQLite/memória), usa o caminho composto com o
/// [IUnitOfWork]. Em ambos os casos a validação de negócio roda aqui.
class ProcessSaleUseCase {
  const ProcessSaleUseCase(
    this._saleRepository,
    this._updateStockUseCase,
    this._transactionRepository,
    this._unitOfWork, {
    this.processor,
  });

  final ISaleRepository _saleRepository;
  final UpdateProductStockUseCase _updateStockUseCase;
  final IFinancialTransactionRepository _transactionRepository;
  final IUnitOfWork _unitOfWork;

  /// Processador atômico opcional (Supabase via RPC).
  final ISaleAtomicProcessor? processor;

  /// Registra [sale], baixa o estoque e registra a entrada no caixa —
  /// **tudo em uma única transação** ([IUnitOfWork]): ou as três coisas
  /// são gravadas, ou nenhuma (rollback completo em qualquer falha).
  ///
  /// Ordem dentro da transação:
  /// 1. **Validação da venda** — itens não vazios e total consistente
  ///    (`totalAmount == Σ(quantidade × preço unitário)`);
  /// 2. **Pré-validação de estoque** de TODOS os itens (sem mutação);
  /// 3. **Registro** da venda;
  /// 4. **Baixa** do estoque de cada item (o [UpdateProductStockUseCase]
  ///    revalida internamente como defesa contra chamadas diretas);
  /// 5. **Entrada no caixa** — venda vira um movimento de entrada
  ///    [TransactionStatus.paid] na categoria "Vendas".
  ///
  /// No SQLite o `BEGIN IMMEDIATE` adquire a trava de escrita **antes** da
  /// pré-validação, fechando a janela TOCTOU entre a leitura do estoque e
  /// a gravação (duas vendas concorrentes não podem passar da validação e
  /// baixar o mesmo estoque). Em memória (web) o unit of work é um no-op —
  /// a execução já é sequencial, mas **sem garantia de atomicidade** em uma
  /// falha parcial (escritas em memória praticamente não falham).
  Future<void> call(Sale sale) async {
    _validate(sale);

    // Caminho atômico (Supabase): o servidor garante a transação inteira.
    final atomicProcessor = processor;
    if (atomicProcessor != null) {
      await atomicProcessor.process(sale);
      return;
    }

    await _unitOfWork.run(() async {
      // 2. Pré-validação de estoque (dentro da transação).
      for (final item in sale.items) {
        await _updateStockUseCase.ensureSufficientStock(
          item.productId,
          item.quantity,
          // O estoque é baixado na MESMA loja da venda.
          storeId: sale.storeId,
        );
      }

      // 3. Registra a venda.
      await _saleRepository.registerSale(sale);

      // 4. Baixa o estoque de cada item vendido (na loja da venda).
      for (final item in sale.items) {
        await _updateStockUseCase.decrease(
          item.productId,
          item.quantity,
          storeId: sale.storeId,
        );
      }

      // 5. Entrada no caixa (a entidade Sale e a FinancialTransaction são
      //    separadas por design — ver README).
      await _transactionRepository.add(
        FinancialTransaction(
          id: AppIds.newId('t'),
          // A entrada no caixa pertence à MESMA loja da venda.
          storeId: sale.storeId,
          description: TransactionDescriptions.sale(
            language: Formatters.currentLanguage,
            paymentMethod: sale.paymentMethod,
          ),
          amount: sale.totalAmount,
          type: TransactionType.income,
          category:
              TransactionDescriptions.saleCategory(Formatters.currentLanguage),
          date: sale.dateTime,
          status: TransactionStatus.paid,
        ),
      );
    });
  }

  /// Valida a integridade da venda antes de qualquer persistência.
  void _validate(Sale sale) {
    if (sale.items.isEmpty) {
      throw const InvalidSaleException(
        'A venda deve conter ao menos um item.',
      );
    }

    final itemsTotal = sale.items.fold<double>(
      0,
      (sum, item) => sum + item.quantity * item.unitPrice,
    );
    // Comparação em CENTAVOS: tolerância absoluta em double pode gerar
    // falso positivo em totais grandes (ex.: 2 × 9.9 + 9.9 acumula
    // 29.700000000000003).
    final itemsCents = (itemsTotal * 100).round();
    final totalCents = (sale.totalAmount * 100).round();
    if (itemsCents != totalCents) {
      throw InvalidSaleException(
        'O total da venda (${sale.totalAmount}) não corresponde aos itens '
        '($itemsTotal).',
      );
    }
  }
}
