import '../../domain/entities/store.dart';
import '../../domain/repositories/i_store_repository.dart';
import '../datasources/local/store_local_data_source.dart';

/// Implementação de [IStoreRepository] sobre um [StoreLocalDataSource].
final class StoreRepositoryImpl implements IStoreRepository {
 const StoreRepositoryImpl(this._localDataSource);

 final StoreLocalDataSource _localDataSource;

 @override
 Future<List<Store>> getByTenant(String tenantId) =>
 _localDataSource.getByTenant(tenantId);

 @override
 Future<void> add(Store store) => _localDataSource.add(store);
}
