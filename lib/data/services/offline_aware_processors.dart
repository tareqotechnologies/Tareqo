import '../../domain/entities/debt.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/i_debt_processor.dart';
import '../../domain/repositories/i_purchase_processor.dart';
import '../../domain/repositories/i_sale_processor.dart';
import 'offline_sync_service.dart';

/// Wrappers OFFLINE-AWARE dos processadores atômicos do modo SaaS.
///
/// Cada wrapper tenta a RPC normal; em falha de REDE o [OfflineSyncService]
/// enfileira o comando original (payload JSON) e lança
/// [OfflineEnqueuedException] — a UI avisa \"salvo offline\" e o replay
/// acontece automaticamente. Erros de NEGÓCIO propagam sem enfileirar.
///
/// Tipos de op registrados (replay idempotente nas RPCs):
/// `process_sale` · `process_purchase` · `register_debt` ·
/// `settle_debt` · `cancel_sale`
final class OfflineAwareSaleProcessor implements ISaleAtomicProcessor {
 const OfflineAwareSaleProcessor(this._inner, this._sync);

 final ISaleAtomicProcessor _inner;
 final OfflineSyncService _sync;

 @override
 Future<void> process(Sale sale) => _sync.run(
 opType: 'process_sale',
 payload: {'sale': sale.toJson()},
 rpc: () => _inner.process(sale),
 );
}

final class OfflineAwarePurchaseProcessor implements IPurchaseAtomicProcessor {
 const OfflineAwarePurchaseProcessor(this._inner, this._sync);

 final IPurchaseAtomicProcessor _inner;
 final OfflineSyncService _sync;

 @override
 Future<void> process(Purchase purchase) => _sync.run(
 opType: 'process_purchase',
 payload: {'purchase': purchase.toJson()},
 rpc: () => _inner.process(purchase),
 );
}

final class OfflineAwareDebtProcessor implements IDebtAtomicProcessor {
 const OfflineAwareDebtProcessor(this._inner, this._sync);

 final IDebtAtomicProcessor _inner;
 final OfflineSyncService _sync;

 @override
 Future<void> register(Debt debt) => _sync.run(
 opType: 'register_debt',
 payload: {'debt': debt.toJson()},
 rpc: () => _inner.register(debt),
 );

 @override
 Future<void> settle(String debtId, {required String storeId}) => _sync.run(
 opType: 'settle_debt',
 payload: {'debtId': debtId, 'storeId': storeId},
 rpc: () => _inner.settle(debtId, storeId: storeId),
 );
}

final class OfflineAwareSaleCancellationProcessor
 implements ISaleCancellationProcessor {
 const OfflineAwareSaleCancellationProcessor(this._inner, this._sync);

 final ISaleCancellationProcessor _inner;
 final OfflineSyncService _sync;

 @override
 Future<void> cancel(String saleId, {required String storeId}) => _sync.run(
 opType: 'cancel_sale',
 payload: {'saleId': saleId, 'storeId': storeId},
 rpc: () => _inner.cancel(saleId, storeId: storeId),
 );
}
