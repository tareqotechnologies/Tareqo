import '../../domain/entities/sale.dart';
import '../../domain/repositories/i_sale_repository.dart';
import '../datasources/local/sale_local_data_source.dart';

/// Implementação concreta de [ISaleRepository] sobre um
/// [SaleLocalDataSource] — hoje em memória; a SQLite trocaria apenas o
/// datasource injetado, sem tocar no domínio.
final class SaleRepositoryImpl implements ISaleRepository {
  const SaleRepositoryImpl(this._dataSource);

  final SaleLocalDataSource _dataSource;

  @override
  Future<void> registerSale(Sale sale) => _dataSource.add(sale);

  @override
  Future<List<Sale>> getAll({required String storeId}) =>
      _dataSource.getAll(storeId: storeId);
}
