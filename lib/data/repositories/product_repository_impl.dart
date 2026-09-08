import '../../domain/entities/product.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../datasources/local/product_local_data_source.dart';

/// Implementação de [IProductRepository] baseada em
/// [ProductLocalDataSource].
///
/// O repositório **não sabe** se os dados vêm da memória, do SQLite ou
/// de uma API: apenas delega para o datasource. Para trocar a
/// persistência, cria-se uma nova implementação de
/// [ProductLocalDataSource] e altera-se **um único registro** no
/// ServiceLocator — domain, casos de uso e UI permanecem intactos.
final class ProductRepositoryImpl implements IProductRepository {
  const ProductRepositoryImpl(this._localDataSource);

  final ProductLocalDataSource _localDataSource;

  @override
  Future<List<Product>> getAll({required String storeId}) =>
      _localDataSource.getAll(storeId: storeId);

  @override
  Future<Product?> getById(String id, {required String storeId}) =>
      _localDataSource.getById(id, storeId: storeId);

  @override
  Future<void> add(Product product) => _localDataSource.add(product);

  @override
  Future<void> update(Product product) => _localDataSource.update(product);

  @override
  Future<void> updateStock(
    String id,
    int newQuantity, {
    required String storeId,
  }) => _localDataSource.updateStock(id, newQuantity, storeId: storeId);
}
