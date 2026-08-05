import '../entities/product.dart';
import '../repositories/i_product_repository.dart';  /// Caso de uso: obter todos os produtos cadastrados da loja [storeId].
  ///
  /// Orquestra o contrato [IProductRepository] sem conhecer a
  /// implementação concreta (Dio, SQLite, etc.). Pode ser chamado como
  /// `GetProductsUseCase(repository)(storeId: storeId)`.
  class GetProductsUseCase {
    const GetProductsUseCase(this._repository);

    final IProductRepository _repository;

    Future<List<Product>> call({required String storeId}) =>
        _repository.getAll(storeId: storeId);
  }
