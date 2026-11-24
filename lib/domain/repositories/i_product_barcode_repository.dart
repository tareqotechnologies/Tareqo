import '../entities/product_barcode.dart';

/// Contrato de persistência dos códigos de barras/embalagens por produto.
///
/// A tabela é ADITIVA: `products.barcode` continua a ser o código principal
/// legado e o fallback de compatibilidade.
abstract interface class IProductBarcodeRepository {
  /// Todos os códigos da loja [storeId].
  Future<List<ProductBarcode>> getAll({required String storeId});

  /// Códigos do produto [productId] na loja [storeId].
  Future<List<ProductBarcode>> getForProduct(
    String productId, {
    required String storeId,
  });

  Future<void> add(ProductBarcode barcode);

  Future<void> update(ProductBarcode barcode);

  Future<void> delete(String id, {required String storeId});
}
