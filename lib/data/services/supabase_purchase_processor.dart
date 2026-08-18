import '../../domain/entities/purchase.dart';
import '../../domain/repositories/i_purchase_processor.dart';
import '../datasources/remote/supabase_purchase_data_source.dart';

/// [IPurchaseAtomicProcessor] sobre o Supabase: delega à RPC
/// `process_purchase`, que executa compra + itens + estoque + caixa em uma
/// única transação no banco (ver `supabase/schema.sql`).
final class SupabasePurchaseProcessor implements IPurchaseAtomicProcessor {
 const SupabasePurchaseProcessor(this._dataSource);

 final PurchaseSupabaseDataSourceImpl _dataSource;

 @override
 Future<void> process(Purchase purchase) => _dataSource.processPurchase(purchase);
}
