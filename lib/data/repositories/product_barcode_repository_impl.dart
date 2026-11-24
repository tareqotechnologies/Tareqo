import '../../domain/entities/product_barcode.dart';
import '../../domain/repositories/i_product_barcode_repository.dart';
import '../datasources/local/product_barcode_local_data_source.dart';

/// Implementação de [IProductBarcodeRepository] sobre o datasource ativo
/// (SQLite, memória ou Supabase).
final class ProductBarcodeRepositoryImpl implements IProductBarcodeRepository {
  const ProductBarcodeRepositoryImpl(this._dataSource);

  final ProductBarcodeLocalDataSource _dataSource;

  @override
  Future<List<ProductBarcode>> getAll({required String storeId}) =>
      _dataSource.getAll(storeId: storeId);

  @override
  Future<List<ProductBarcode>> getForProduct(
    String productId, {
    required String storeId,
  }) => _dataSource.getForProduct(productId, storeId: storeId);

  @override
  Future<void> add(ProductBarcode barcode) => _dataSource.add(barcode);

  @override
  Future<void> update(ProductBarcode barcode) => _dataSource.update(barcode);

  @override
  Future<void> delete(String id, {required String storeId}) =>
      _dataSource.delete(id, storeId: storeId);
}
