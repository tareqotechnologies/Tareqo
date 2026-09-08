import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_lot_consumption.dart';
import '../../domain/repositories/i_sale_repository.dart';
import '../datasources/local/sale_local_data_source.dart';

/// Implementação concreta de [ISaleRepository] sobre um
/// [SaleLocalDataSource] — memória, SQLite ou Supabase: o datasource
/// injetado troca sem tocar no domínio.
final class SaleRepositoryImpl implements ISaleRepository {
  const SaleRepositoryImpl(this._dataSource);

  final SaleLocalDataSource _dataSource;

  @override
  Future<void> registerSale(Sale sale) => _dataSource.add(sale);

  @override
  Future<List<Sale>> getAll({required String storeId}) =>
      _dataSource.getAll(storeId: storeId);

  @override
  Future<Sale?> getById(String id, {required String storeId}) =>
      _dataSource.getById(id, storeId: storeId);

  @override
  Future<void> markCancelled(String id, {required String storeId}) =>
      _dataSource.markCancelled(id, storeId: storeId);

  @override
  Future<List<LotConsumption>> getLotConsumption(
    String saleId, {
    required String storeId,
  }) => _dataSource.getLotConsumption(saleId, storeId: storeId);

  @override
  Future<void> registerLotConsumption(
    String saleId,
    String storeId,
    List<LotConsumption> consumption,
  ) => _dataSource.registerLotConsumption(saleId, storeId, consumption);
}
