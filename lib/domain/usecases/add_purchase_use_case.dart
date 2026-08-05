import '../../core/i18n/transaction_descriptions.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ids.dart';
import '../entities/financial_transaction.dart';
import '../entities/purchase.dart';
import '../repositories/i_financial_transaction_repository.dart';
import '../repositories/i_purchase_processor.dart';
import '../repositories/i_purchase_repository.dart';
import '../repositories/i_unit_of_work.dart';
import 'update_product_stock_use_case.dart';

/// Exceção de domínio: compra inválida (sem itens ou total divergente).
final class InvalidPurchaseException implements Exception {
  const InvalidPurchaseException(this.message);

  final String message;

  @override
  String toString() => 'InvalidPurchaseException: $message';
}

/// Caso de uso: processar uma compra (registrar + aumentar estoque + caixa).
///
/// Orquestra [IPurchaseRepository], [UpdateProductStockUseCase],
/// [IFinancialTransactionRepository] e [IUnitOfWork] — depende apenas de
/// abstrações, nunca de implementações concretas.
///
/// Quando [processor] é fornecido (Supabase), a compra inteira é delegada
/// a ele — o servidor executa tudo em UMA transação (RPC `process_purchase`).
/// Sem processor (SQLite/memória), usa o caminho composto com o
/// [IUnitOfWork]. Em ambos os casos a validação de negócio roda aqui.
class ProcessPurchaseUseCase {
  const ProcessPurchaseUseCase(
    this._purchaseRepository,
    this._updateStockUseCase,
    this._transactionRepository,
    this._unitOfWork, {
    this.processor,
  });

  final IPurchaseRepository _purchaseRepository;
  final UpdateProductStockUseCase _updateStockUseCase;
  final IFinancialTransactionRepository _transactionRepository;
  final IUnitOfWork _unitOfWork;

  /// Processador atômico opcional (Supabase via RPC).
  final IPurchaseAtomicProcessor? processor;

  /// Registra [purchase], aumenta o estoque dos itens e lança a **saída** no
  /// caixa — tudo em uma única transação ([IUnitOfWork]): ou as três coisas
  /// são gravadas, ou nenhuma (rollback completo em qualquer falha).
  ///
  /// Ordem dentro da transação:
  /// 1. **Validação da compra** — itens não vazios e total consistente
  ///    (`totalAmount == Σ(quantidade × preço unitário)`);
  /// 2. **Registro** da compra (compra + itens);
  /// 3. **Entrada no estoque** de cada item (`increase` — o produto deve
  ///    existir; lança [ProductNotFoundException]);
  /// 4. **Saída no caixa** — compra vira um movimento de saída
  ///    [TransactionStatus.paid] na categoria "Compras".
  Future<void> call(Purchase purchase) async {
    _validate(purchase);

    // Caminho atômico (Supabase): o servidor garante a transação inteira.
    final atomicProcessor = processor;
    if (atomicProcessor != null) {
      await atomicProcessor.process(purchase);
      return;
    }

    await _unitOfWork.run(() async {
      // 2. Registra a compra.
      await _purchaseRepository.add(purchase);

      // 3. Aumenta o estoque de cada item comprado (na loja da compra).
      for (final item in purchase.items) {
        await _updateStockUseCase.increase(
          item.productId,
          item.quantity,
          storeId: purchase.storeId,
        );
      }

      // 4. Saída no caixa (despesa de mercadoria).
      await _transactionRepository.add(
        FinancialTransaction(
          id: AppIds.newId('t'),
          // A saída no caixa pertence à MESMA loja da compra.
          storeId: purchase.storeId,
          description: TransactionDescriptions.purchase(
            language: Formatters.currentLanguage,
            supplierName: purchase.supplierName,
          ),
          amount: purchase.totalAmount,
          type: TransactionType.expense,
          category: TransactionDescriptions.purchaseCategory(
            Formatters.currentLanguage,
          ),
          date: purchase.dateTime,
          status: TransactionStatus.paid,
        ),
      );
    });
  }

  /// Valida a integridade da compra antes de qualquer persistência.
  void _validate(Purchase purchase) {
    if (purchase.items.isEmpty) {
      throw const InvalidPurchaseException(
        'A compra deve conter ao menos um item.',
      );
    }

    final itemsTotal = purchase.items.fold<double>(
      0,
      (sum, item) => sum + item.quantity * item.unitPrice,
    );
    // Comparação em CENTAVOS (mesma técnica do ProcessSaleUseCase).
    final itemsCents = (itemsTotal * 100).round();
    final totalCents = (purchase.totalAmount * 100).round();
    if (itemsCents != totalCents) {
      throw InvalidPurchaseException(
        'O total da compra (${purchase.totalAmount}) não corresponde aos '
        'itens ($itemsTotal).',
      );
    }
  }
}
