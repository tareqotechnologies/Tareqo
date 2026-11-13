import 'package:sqlite3/sqlite3.dart';

import '../../../domain/entities/product.dart';
import 'product_local_data_source.dart';

/// Converte o nome persistido do [ProductType] de volta ao enum.
///
/// Default [ProductType.resale] para `null` (linha criada antes da coluna
/// `type`) ou valor desconhecido (banco escrito por versão mais nova do
/// app) — a leitura de produtos legados NUNCA quebra por valor inesperado.
ProductType _productTypeFromName(String? name) => ProductType.values.firstWhere(
  (type) => type.name == name,
  orElse: () => ProductType.resale,
);

/// Implementação SQLite do [ProductLocalDataSource].
///
/// Mantém **as mesmas assinaturas** do contrato, então a troca de
/// persistência acontece apenas no ServiceLocator. Usa SQL parametrizado
/// (prepared statements) — nunca concatenação de strings.
final class ProductSqliteDataSourceImpl implements ProductLocalDataSource {
  const ProductSqliteDataSourceImpl(this._db);

  final Database _db;

  static const _columns =
      'id, store_id, name, description, image_path, purchase_price, '
      'sale_price, stock_quantity, barcode, code, category, venda_por_fracao, '
      'unit_label, is_active, type';

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
      'INSERT INTO products ($_columns) VALUES '
      '(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        product.id,
        product.storeId,
        product.name,
        product.description,
        product.imagePath.isEmpty ? null : product.imagePath,
        product.purchasePriceCents,
        product.salePriceCents,
        product.stockQuantity,
        product.barcode.isEmpty ? null : product.barcode,
        product.code.isEmpty ? null : product.code,
        product.category.isEmpty ? null : product.category,
        product.vendaPorFracao ? 1 : 0,
        product.unitLabel,
        product.isActive ? 1 : 0,
        product.type.name,
      ],
    );
  }

  @override
  Future<void> update(Product product) async {
    // Atualiza apenas os campos EDITÁVEIS do catálogo — o stock_quantity
    // NÃO entra no UPDATE (a mutação de estoque passa pelo
    // FifoStockUseCase, que mantém a invariante `stock = Σ lotes`).
    // Escopo por loja: o WHERE com store_id impede mutar produto de outra
    // loja (mesmo sabendo o id).
    _db.execute(
      'UPDATE products SET name = ?, description = ?, image_path = ?, '
      'purchase_price = ?, sale_price = ?, barcode = ?, code = ?, '
      'category = ?, venda_por_fracao = ?, unit_label = ?, is_active = ?, '
      'type = ? WHERE id = ? AND store_id = ?',
      [
        product.name,
        product.description,
        product.imagePath.isEmpty ? null : product.imagePath,
        product.purchasePriceCents,
        product.salePriceCents,
        product.barcode.isEmpty ? null : product.barcode,
        product.code.isEmpty ? null : product.code,
        product.category.isEmpty ? null : product.category,
        product.vendaPorFracao ? 1 : 0,
        product.unitLabel,
        product.isActive ? 1 : 0,
        product.type.name,
        product.id,
        product.storeId,
      ],
    );
    if (_db.updatedRows == 0) {
      throw StateError(
        'Produto ${product.id} não encontrado para atualização.',
      );
    }
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
      throw StateError(
        'Produto $id não encontrado para atualização de estoque.',
      );
    }
  }

  Product _map(Row row) => Product(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    name: row['name'] as String,
    description: row['description'] as String,
    imagePath: (row['image_path'] as String?) ?? '',
    purchasePriceCents: (row['purchase_price'] as num).toInt(),
    salePriceCents: (row['sale_price'] as num).toInt(),
    stockQuantity: row['stock_quantity'] as int,
    barcode: (row['barcode'] as String?) ?? '',
    code: (row['code'] as String?) ?? '',
    category: (row['category'] as String?) ?? '',
    vendaPorFracao: (row['venda_por_fracao'] as int) == 1,
    unitLabel: (row['unit_label'] as String?) ?? 'un',
    // Default true: bancos criados antes do campo (sem a coluna ou com
    // NULL) preservam produtos existentes como ATIVOS.
    isActive: (row['is_active'] as int? ?? 1) == 1,
    // Fase 1: default resale — produtos criados antes da coluna `type`
    // (ou com valor desconhecido) permanecem de revenda, como sempre
    // foram. Nunca lança por valor legado inesperado.
    type: _productTypeFromName(row['type'] as String?),
  );
}
