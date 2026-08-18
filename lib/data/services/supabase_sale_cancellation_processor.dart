import '../../domain/repositories/i_sale_processor.dart';
import '../datasources/remote/supabase_sale_data_source.dart';

/// [ISaleCancellationProcessor] sobre o Supabase: delega à RPC
/// `cancel_sale`, que estorna o estoque aos lotes exatos + cria o estorno
/// de caixa + marca a venda como `cancelled` em uma única transação no
/// banco (ver `supabase/schema.sql`), com a guarda gerencial
/// `is_manager_of_store` (apenas dono/gerente podem anular).
final class SupabaseSaleCancellationProcessor
 implements ISaleCancellationProcessor {
 const SupabaseSaleCancellationProcessor(this._dataSource);

 final SaleSupabaseDataSourceImpl _dataSource;

 @override
 Future<void> cancel(String saleId, {required String storeId}) =>
 _dataSource.cancelSale(saleId, storeId: storeId);
}
