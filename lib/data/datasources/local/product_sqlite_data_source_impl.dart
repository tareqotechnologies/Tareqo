import 'package:sqlite3/sqlite3.dart';

import '../../../domain/entities/product.dart';
import 'product_local_data_source.dart';

/// Implementação SQLite do [ProductLocalDataSource].
///
/// Mantém **as mesmas assinaturas** do contrato, então a troca de
/// persistência acontece apenas no ServiceLocator. Usa SQL parametrizado
/// (prepared statements) — nunca concatenação de strings.
final class ProductSqliteDataSourceImpl implements ProductLocalDataSource {
  const ProductSqliteDataSourceImpl(this._db);

  final Database _db;

  static const _columns =
      'id, store_id, name, description, purchase_price, sale_price, '
      'stock_quantity';

  @override
  Future<List<Product>> getAll({required String storeId}) async {
    final rows = _db.select(
      'SELECT $_columns FROM products WHERE store_id = ? '
      'ORDER BY name COLLATE NOCASE',
      [storeId],
    );
    return [for (final row in rows) _map(row)];
  }

  @override
  Future<Product?> getById(String id, {required String storeId}) async {
    final rows = _db.select(
      'SELECT $_columns FROM products WHERE id = ? AND store_id = ?',
      [id, storeId],
    );
    if (rows.isEmpty) return null;
    return _map(rows.first);
  }

  @override
  Future<void> add(Product product) async {
    _db.execute(
      'INSERT INTO products ($_columns) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        product.id,
        product.storeId,
        product.name,
        product.description,
        product.purchasePriceCents,
        product.salePriceCents,
        product.stockQuantity,
      ],
    );
  }

  @override
  Future<void> updateStock(
    String id,
    int newQuantity, {
    required String storeId,
  }) async {
    // Escopo por loja: o WHERE com store_id impede mutar produto de outra
    // loja (mesmo sabendo o id).
    _db.execute(
      'UPDATE products SET stock_quantity = ? WHERE id = ? AND store_id = ?',
      [newQuantity, id, storeId],
    );
    if (_db.updatedRows == 0) {
      throw StateError('Produto $id não encontrado para atualização de estoque.');
    }
  }

  Product _map(Row row) => Product(
        id: row['id'] as String,
        storeId: row['store_id'] as String,
        name: row['name'] as String,
        description: row['description'] as String,
        purchasePriceCents: (row['purchase_price'] as num).toInt(),
        salePriceCents: (row['sale_price'] as num).toInt(),
        stockQuantity: row['stock_quantity'] as int,
      );
}
