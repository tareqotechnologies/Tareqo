import '../../domain/entities/production_order.dart';
import '../../domain/repositories/i_production_processor.dart';
import '../datasources/remote/supabase_production_data_source.dart';

/// [IProductionProcessor] sobre o Supabase: delega à RPC
/// `process_production`, que executa a baixa FIFO dos componentes + o lote do
/// produto acabado + a ordem em uma única transação no banco (ver
/// `supabase/schema.sql`).
final class SupabaseProductionProcessor implements IProductionProcessor {
  const SupabaseProductionProcessor(this._dataSource);

  final ProductionSupabaseDataSourceImpl _dataSource;

  @override
  Future<void> process(ProductionOrder order) =>
      _dataSource.processProduction(order);
}
