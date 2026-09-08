import '../entities/store.dart';
import '../repositories/i_store_repository.dart';

/// Caso de uso: listar as lojas de um tenant.
class GetStoresUseCase {
  const GetStoresUseCase(this._repository);

  final IStoreRepository _repository;

  Future<List<Store>> call(String tenantId) =>
      _repository.getByTenant(tenantId);
}
