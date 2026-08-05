import '../../../domain/entities/store.dart';
import 'store_local_data_source.dart';

/// Implementação em memória do [StoreLocalDataSource].
final class StoreLocalDataSourceImpl implements StoreLocalDataSource {
  StoreLocalDataSourceImpl({List<Store> seed = const []}) : _stores = [...seed];

  final List<Store> _stores;

  @override
  Future<List<Store>> getByTenant(String tenantId) async => List.unmodifiable(
        _stores.where((store) => store.tenantId == tenantId),
      );

  @override
  Future<void> add(Store store) async {
    _stores.add(store);
  }
}
