import '../../../domain/entities/product_barcode.dart';

/// Contrato de persistência dos códigos de barras/embalagens.
///
/// Implementado em memória (web/testes), SQLite e Supabase (RLS por loja).
abstract interface class ProductBarcodeLocalDataSource {
  Future<List<ProductBarcode>> getAll({required String storeId});

  Future<List<ProductBarcode>> getForProduct(
    String productId, {
    required String storeId,
  });

  Future<void> add(ProductBarcode barcode);

  Future<void> update(ProductBarcode barcode);

  Future<void> delete(String id, {required String storeId});
}
