import '../../core/i18n/transaction_descriptions.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ids.dart';
import '../entities/financial_transaction.dart';
import '../entities/sale.dart';
import '../repositories/i_financial_transaction_repository.dart';
import '../repositories/i_sale_processor.dart';
import '../repositories/i_sale_repository.dart';
import '../repositories/i_unit_of_work.dart';
import 'fifo_stock_use_case.dart';

/// Exceção de domínio: a venda a anular não existe na loja (ou pertence a
/// outra loja). O usuário vê a mensagem amigável na UI.
final class SaleNotFoundException implements Exception {
  const SaleNotFoundException();

  @override
  String toString() => 'SaleNotFoundException: venda não encontrada na loja.';
}

/// Caso de uso: anular uma venda (estorno de estoque + caixa + status).
///
/// Orquestra [ISaleRepository], [FifoStockUseCase] e
/// [IFinancialTransactionRepository] dentro de um [IUnitOfWork] —
/// depende apenas de abstrações, nunca de implementações concretas.
///
/// O que a anulação faz (tudo em UMA transação):
/// 1. **Lê a venda** e garante que existe e ainda está ativa
/// ([SaleStatus.active]) — anular duas vezes é um no-op;
/// 2. **Devolve o estoque aos lotes EXATOS** que foram consumidos na
/// venda ([LotConsumption] gravado no registro da venda) — validade e
/// custo de cada lote são preservados;
/// 3. **Marca a venda como [SaleStatus.cancelled]** com o momento da
/// anulação (trilha de auditoria — a venda permanece no histórico);
/// 4. **Estorna o caixa**: cria um movimento de SAÍDA no valor da venda
/// (categoria Vendas, status pago) que compensa a entrada original.
///
/// A venda anulada continua no histórico com selo "Anulada", mas sai dos
/// relatórios, KPIs e do resumo do dia (filtros por status nos agregados
/// client-side e nas RPCs do servidor).
///
/// Quando [processor] é fornecido (Supabase), toda a anulação é delegada
/// à RPC `cancel_sale` — o servidor executa o estorno em UMA transação,
/// com a guarda gerencial `is_manager_of_store` (apenas dono/gerente).
/// Sem processor (SQLite/memória), usa o caminho composto abaixo.
class CancelSaleUseCase {
  const CancelSaleUseCase(
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

  /// Processador atômico opcional (Supabase via RPC `cancel_sale`).
  final ISaleCancellationProcessor? processor;

  /// Anula a venda [saleId] da loja [storeId].
  ///
  /// Lança [SaleNotFoundException] se a venda não existir na loja. A
  /// anulação de uma venda já anulada é um no-op (idempotência).
  Future<void> call(String saleId, {required String storeId}) async {
    final atomicProcessor = processor;
    if (atomicProcessor != null) {
      await atomicProcessor.cancel(saleId, storeId: storeId);
      return;
    }

    await _unitOfWork.run(() async {
      // 1. Lê a venda (dentro da transação — o valor a estornar é o do
      // banco, não o da UI) e garante que ainda está ativa.
      final sale = await _saleRepository.getById(saleId, storeId: storeId);
      if (sale == null) {
        throw const SaleNotFoundException();
      }
      if (sale.status == SaleStatus.cancelled) return;

      // 2. Devolve o estoque aos lotes exatos consumidos pela venda.
      final consumption = await _saleRepository.getLotConsumption(
        saleId,
        storeId: storeId,
      );
      for (final consumed in consumption) {
        await _fifoStock.restoreLot(
          consumed.lotId,
          consumed.productId,
          consumed.quantity,
          storeId: storeId,
        );
      }

      // 3. Marca a venda como anulada (permanece no histórico).
      await _saleRepository.markCancelled(saleId, storeId: storeId);

      // 4. Estorno no caixa: saída no valor da venda, categoria de vendas
      // — o par (entrada original + estorno) fecha o caixa em zero.
      await _transactionRepository.add(
        FinancialTransaction(
          id: AppIds.newId('t'),
          storeId: storeId,
          description: TransactionDescriptions.saleReversal(
            language: Formatters.currentLanguage,
            paymentMethod: sale.paymentMethod,
          ),
          amountCents: sale.totalAmountCents,
          type: TransactionType.expense,
          category: TransactionDescriptions.saleCategory(
            Formatters.currentLanguage,
          ),
          date: DateTime.now(),
          status: TransactionStatus.paid,
        ),
      );
    });
  }
}
