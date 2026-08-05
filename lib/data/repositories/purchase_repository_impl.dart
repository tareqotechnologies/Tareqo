import '../../domain/entities/purchase.dart';
import '../../domain/repositories/i_purchase_repository.dart';
import '../datasources/local/purchase_local_data_source.dart';

/// Implementação de [IPurchaseRepository] sobre um [PurchaseLocalDataSource].
///
/// O repositório **não sabe** se os dados vêm da memória, do SQLite ou do
/// Supabase: apenas delega para o datasource injetado.
final class PurchaseRepositoryImpl implements IPurchaseRepository {
  const PurchaseRepositoryImpl(this._localDataSource);

  final PurchaseLocalDataSource _localDataSource;

  @override
  Future<List<Purchase>> getAll({required String storeId}) =>
      _localDataSource.getAll(storeId: storeId);

  @override
  Future<void> add(Purchase purchase) => _localDataSource.add(purchase);
}
