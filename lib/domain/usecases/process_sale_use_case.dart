import '../../core/i18n/transaction_descriptions.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/quantity.dart';
import '../entities/financial_transaction.dart';
import '../entities/sale.dart';
import '../entities/sale_lot_consumption.dart';
import '../repositories/i_financial_transaction_repository.dart';
import '../repositories/i_sale_processor.dart';
import '../repositories/i_sale_repository.dart';
import '../repositories/i_unit_of_work.dart';
import 'fifo_stock_use_case.dart';

/// Exceção de domínio: venda inválida (sem itens ou total divergente).
final class InvalidSaleException implements Exception {
  const InvalidSaleException(this.message);

  final String message;

  @override
  String toString() => 'InvalidSaleException: $message';
}

/// Caso de uso: processar uma venda (registrar + baixar estoque + caixa).
///
/// Orquestra [ISaleRepository], [FifoStockUseCase],
/// [IFinancialTransactionRepository] e [IUnitOfWork] — depende apenas de
/// abstrações, nunca de implementações concretas.
///
/// Quando [processor] é fornecido (Supabase), a venda inteira é delegada a
/// ele — o servidor executa tudo em UMA transação (RPC `process_sale`, que
/// também baixa os lotes em FIFO). Sem processor (SQLite/memória), usa o
/// caminho composto com o [IUnitOfWork]. Em ambos os casos a validação de
/// negócio roda aqui.
class ProcessSaleUseCase {
  const ProcessSaleUseCase(
    this._saleRepository,
    this._fifoStock,
    this._transactionRepository,
    this._unitOfWork, {
    this.processor,
  });

  final ISaleRepository _saleRepository;
  final FifoStockUseCase _fifoStock;
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
  /// 2. **Pré-validação** de TODOS os itens (sem mutação): produto ATIVO
  ///    (desativado não vende — espelha a guarda do `lock_products_or_raise`)
  ///    e estoque suficiente (soma dos lotes ativos via
  ///    [FifoStockUseCase.ensureSufficientStock]);
  /// 3. **Registro** da venda;
  /// 4. **Baixa** do estoque de cada item em FIFO por lotes
  ///    ([FifoStockUseCase.decrease] — validade mais próxima primeiro);
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
      // 2. Pré-validação (dentro da transação): produto ATIVO (espelha a
      // guarda do lock_products_or_raise — desativado não vende) e
      // estoque suficiente.
      for (final item in sale.items) {
        await _fifoStock.requireActive(
          item.productId,
          storeId: sale.storeId,
        );
        await _fifoStock.ensureSufficientStock(
          item.productId,
          item.quantity,
          // O estoque é baixado na MESMA loja da venda.
          storeId: sale.storeId,
        );
      }

      // 3. Registra a venda.
      await _saleRepository.registerSale(sale);

      // 4. Baixa o estoque de cada item vendido em FIFO (na loja da venda).
      //    A baixa devolve QUAIS lotes foram consumidos — registrados na
      //    MESMA transação para a anulação devolver o estoque aos lotes
      //    exatos depois.
      final consumption = <LotConsumption>[];
      for (final item in sale.items) {
        consumption.addAll(
          await _fifoStock.decrease(
            item.productId,
            item.quantity,
            storeId: sale.storeId,
          ),
        );
      }
      if (consumption.isNotEmpty) {
        await _saleRepository.registerLotConsumption(
          sale.id,
          sale.storeId,
          consumption,
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
          amountCents: sale.totalAmountCents,
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

    // Soma em CENTAVOS inteiros (W4 + W11): cada item é
    // `qtd(milésimos) × preço_unitário ~/ 1000` — divisão inteira exata,
    // mesmo contrato das RPCs do servidor.
    final itemsTotalCents = sale.items.fold<int>(
      0,
      (sum, item) =>
          sum + Quantity.lineTotal(item.quantity, item.unitPriceCents),
    );
    if (itemsTotalCents != sale.totalAmountCents) {
      throw InvalidSaleException(
        'O total da venda (${sale.totalAmountCents}) não corresponde aos '
        'itens ($itemsTotalCents).',
      );
    }
  }
}
