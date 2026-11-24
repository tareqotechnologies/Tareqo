import 'package:sqlite3/sqlite3.dart';

import '../../../domain/entities/product_barcode.dart';
import 'product_barcode_local_data_source.dart';

/// Implementação SQLite do [ProductBarcodeLocalDataSource].
///
/// O stock NÃO é tocado aqui: esta tabela é apenas o catálogo de códigos e
/// fatores. A baixa continua a acontecer na venda, em milésimos.
final class ProductBarcodeSqliteDataSourceImpl
    implements ProductBarcodeLocalDataSource {
  const ProductBarcodeSqliteDataSourceImpl(this._db);

  final Database _db;

  static const _columns =
      'id, store_id, product_id, barcode, qty_factor, description, is_active';

  @override
  Future<List<ProductBarcode>> getAll({required String storeId}) async {
    final rows = _db.select(
      'SELECT $_columns FROM product_barcodes WHERE store_id = ? '
      'ORDER BY product_id, barcode COLLATE NOCASE',
      [storeId],
    );
    return [for (final row in rows) _map(row)];
  }

  @override
  Future<List<ProductBarcode>> getForProduct(
    String productId, {
    required String storeId,
  }) async {
    final rows = _db.select(
      'SELECT $_columns FROM product_barcodes '
      'WHERE product_id = ? AND store_id = ? '
      'ORDER BY barcode COLLATE NOCASE',
      [productId, storeId],
    );
    return [for (final row in rows) _map(row)];
  }

  @override
  Future<void> add(ProductBarcode barcode) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _db.execute(
      'INSERT INTO product_barcodes '
      '($_columns, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        barcode.id,
        barcode.storeId,
        barcode.productId,
        barcode.barcode,
        barcode.qtyFactor,
        barcode.description,
        barcode.isActive ? 1 : 0,
        now,
        now,
      ],
    );
  }

  @override
  Future<void> update(ProductBarcode barcode) async {
    _db.execute(
      'UPDATE product_barcodes SET barcode = ?, qty_factor = ?, '
      'description = ?, is_active = ?, updated_at = ? '
      'WHERE id = ? AND store_id = ?',
      [
        barcode.barcode,
        barcode.qtyFactor,
        barcode.description,
        barcode.isActive ? 1 : 0,
        DateTime.now().millisecondsSinceEpoch,
        barcode.id,
        barcode.storeId,
      ],
    );
    if (_db.updatedRows == 0) {
      throw StateError('Código ${barcode.id} não encontrado para atualização.');
    }
  }

  @override
  Future<void> delete(String id, {required String storeId}) async {
    _db.execute('DELETE FROM product_barcodes WHERE id = ? AND store_id = ?', [
      id,
      storeId,
    ]);
  }

  ProductBarcode _map(Row row) => ProductBarcode(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    productId: row['product_id'] as String,
    barcode: row['barcode'] as String,
    qtyFactor: (row['qty_factor'] as num).toInt(),
    description: (row['description'] as String?) ?? '',
    isActive: (row['is_active'] as int? ?? 1) == 1,
  );
}
