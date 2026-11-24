import '../../../domain/entities/product_barcode.dart';
import 'product_barcode_local_data_source.dart';

/// Implementação em memória (web/testes) do [ProductBarcodeLocalDataSource].
final class ProductBarcodeLocalDataSourceImpl
    implements ProductBarcodeLocalDataSource {
  ProductBarcodeLocalDataSourceImpl({List<ProductBarcode> seed = const []})
    : _items = [...seed];

  final List<ProductBarcode> _items;

  @override
  Future<List<ProductBarcode>> getAll({required String storeId}) async {
    final rows = _items.where((item) => item.storeId == storeId).toList()
      ..sort((a, b) {
        final byProduct = a.productId.compareTo(b.productId);
        return byProduct != 0
            ? byProduct
            : a.barcode.toLowerCase().compareTo(b.barcode.toLowerCase());
      });
    return List.unmodifiable(rows);
  }

  @override
  Future<List<ProductBarcode>> getForProduct(
    String productId, {
    required String storeId,
  }) async {
    final rows =
        _items
            .where(
              (item) => item.productId == productId && item.storeId == storeId,
            )
            .toList()
          ..sort(
            (a, b) =>
                a.barcode.toLowerCase().compareTo(b.barcode.toLowerCase()),
          );
    return List.unmodifiable(rows);
  }

  @override
  Future<void> add(ProductBarcode barcode) async {
    _ensureUnique(barcode);
    _items.add(barcode);
  }

  @override
  Future<void> update(ProductBarcode barcode) async {
    _ensureUnique(barcode, ignoreId: barcode.id);
    final index = _items.indexWhere(
      (item) => item.id == barcode.id && item.storeId == barcode.storeId,
    );
    if (index == -1) {
      throw StateError('Código ${barcode.id} não encontrado para atualização.');
    }
    _items[index] = barcode;
  }

  @override
  Future<void> delete(String id, {required String storeId}) async {
    _items.removeWhere((item) => item.id == id && item.storeId == storeId);
  }

  void _ensureUnique(ProductBarcode barcode, {String? ignoreId}) {
    final key = barcode.normalizedCode;
    final duplicate = _items.any(
      (item) =>
          item.storeId == barcode.storeId &&
          item.id != ignoreId &&
          item.normalizedCode == key,
    );
    if (duplicate) {
      throw StateError('Código de barras já existe nesta loja.');
    }
  }
}
