import '../../domain/entities/sale.dart';
import '../../domain/repositories/i_sale_processor.dart';
import '../datasources/remote/supabase_sale_data_source.dart';

/// [ISaleAtomicProcessor] sobre o Supabase: delega à RPC `process_sale`,
/// que executa venda + itens + estoque + caixa em uma única transação no
/// banco (ver `supabase/schema.sql`).
final class SupabaseSaleProcessor implements ISaleAtomicProcessor {
  const SupabaseSaleProcessor(this._dataSource);

  final SaleSupabaseDataSourceImpl _dataSource;

  @override
  Future<void> process(Sale sale) => _dataSource.processSale(sale);
}
