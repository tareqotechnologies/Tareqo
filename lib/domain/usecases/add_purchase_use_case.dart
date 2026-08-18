import '../../core/i18n/transaction_descriptions.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/quantity.dart';
import '../entities/financial_transaction.dart';
import '../entities/purchase.dart';
import '../repositories/i_financial_transaction_repository.dart';
import '../repositories/i_purchase_processor.dart';
import '../repositories/i_purchase_repository.dart';
import '../repositories/i_unit_of_work.dart';
import 'fifo_stock_use_case.dart';

/// Exceção de domínio: compra inválida (sem itens ou total divergente).
final class InvalidPurchaseException implements Exception {
 const InvalidPurchaseException(this.message);

 final String message;

 @override
 String toString() => 'InvalidPurchaseException: $message';
}

/// Caso de uso: processar uma compra (registrar + aumentar estoque + caixa).
///
/// Orquestra [IPurchaseRepository], [FifoStockUseCase],
/// [IFinancialTransactionRepository] e [IUnitOfWork] — depende apenas de
/// abstrações, nunca de implementações concretas.
///
/// Quando [processor] é fornecido (Supabase), a compra inteira é delegada
/// a ele — o servidor executa tudo em UMA transação (RPC `process_purchase`,
/// que também cria os lotes FIFO). Sem processor (SQLite/memória), usa o
/// caminho composto com o [IUnitOfWork]. Em ambos os casos a validação de
/// negócio roda aqui.
class ProcessPurchaseUseCase {
 const ProcessPurchaseUseCase(
 this._purchaseRepository,
 this._fifoStock,
 this._transactionRepository,
 this._unitOfWork, {
 this.processor,
 });

 final IPurchaseRepository _purchaseRepository;
 final FifoStockUseCase _fifoStock;
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
 /// (`totalAmount == Σ(quantidade × preço unitário)`);
 /// 2. **Validação dos produtos** de TODOS os itens (existem e estão
 /// ATIVOS — produto desativado não pode ser reposto; espelha o
 /// `lock_products_or_raise` do servidor, que valida ANTES de mutar);
 /// 3. **Registro** da compra (compra + itens);
 /// 4. **Entrada no estoque** de cada item ([FifoStockUseCase.increase] —
 /// cria o LOTE FIFO do item, com validade opcional e custo de
 /// aquisição; o produto deve existir; lança
 /// [ProductNotFoundException]);
 /// 5. **Saída no caixa** — compra vira um movimento de saída
 /// [TransactionStatus.paid] na categoria "Compras".
 Future<void> call(Purchase purchase) async {
 _validate(purchase);

 // Caminho atômico (Supabase): o servidor garante a transação inteira.
 final atomicProcessor = processor;
 if (atomicProcessor != null) {
 await atomicProcessor.process(purchase);
 return;
 }

 await _unitOfWork.run(() async {
 // 2. Valida TODOS os produtos ANTES de mutar (espelha o
 // lock_products_or_raise do servidor): existem e estão ATIVOS —
 // produto desativado não pode ser reposto.
 for (final item in purchase.items) {
 await _fifoStock.requireActive(
 item.productId,
 storeId: purchase.storeId,
 );
 }

 // 3. Registra a compra.
 await _purchaseRepository.add(purchase);

 // 4. Cria o lote FIFO de cada item comprado (na loja da compra) e
 // aumenta o total do produto.
 for (final item in purchase.items) {
 await _fifoStock.increase(
 item.productId,
 item.quantity,
 storeId: purchase.storeId,
 expiryDate: item.expiryDate,
 entryDate: purchase.dateTime,
 costPriceCents: item.unitPriceCents,
 );
 }

 // 5. Saída no caixa (despesa de mercadoria).
 await _transactionRepository.add(
 FinancialTransaction(
 id: AppIds.newId('t'),
 // A saída no caixa pertence à MESMA loja da compra.
 storeId: purchase.storeId,
 description: TransactionDescriptions.purchase(
 language: Formatters.currentLanguage,
 supplierName: purchase.supplierName,
 ),
 amountCents: purchase.totalAmountCents,
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

 // Soma em CENTAVOS inteiros (W4 + W11): cada item é
 // `qtd(milésimos) × preço_unitário ~/ 1000` — divisão inteira exata
 // (mesma técnica do ProcessSaleUseCase).
 final itemsTotalCents = purchase.items.fold<int>(
 0,
 (sum, item) =>
 sum + Quantity.lineTotal(item.quantity, item.unitPriceCents),
 );
 if (itemsTotalCents != purchase.totalAmountCents) {
 throw InvalidPurchaseException(
 'O total da compra (${purchase.totalAmountCents}) não corresponde '
 'aos itens ($itemsTotalCents).',
 );
 }
 }
}
