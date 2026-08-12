import '../../domain/repositories/i_stock_adjustment_processor.dart';
import '../datasources/remote/supabase_product_data_source.dart';

/// [IStockAdjustmentProcessor] sobre o Supabase: delega à RPC
/// `adjust_product_stock`, que define a quantidade absoluta do produto
/// criando/consumindo LOTES FIFO em uma única transação no banco (ver
/// `supabase/schema.sql` — guarda gerencial `is_manager_of_store`).
final class SupabaseStockAdjustmentProcessor
    implements IStockAdjustmentProcessor {
  const SupabaseStockAdjustmentProcessor(this._dataSource);

  final ProductSupabaseDataSourceImpl _dataSource;

  @override
  Future<void> adjustStock(
    String productId,
    int newQuantity, {
    required String storeId,
  }) =>
      _dataSource.adjustStock(productId, newQuantity, storeId: storeId);
}
