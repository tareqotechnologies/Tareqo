import '../../../domain/entities/product_barcode.dart';
import '../local/product_barcode_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação Supabase do [ProductBarcodeLocalDataSource].
///
/// A tabela `product_barcodes` tem RLS por loja/tenant; o `user_id` é
/// gravado explicitamente e reforçado pelo trigger do schema.
final class ProductBarcodeSupabaseDataSourceImpl
    implements ProductBarcodeLocalDataSource {
  const ProductBarcodeSupabaseDataSourceImpl();

  static const _table = 'product_barcodes';
  static const _columns =
      'id, store_id, product_id, barcode, qty_factor, description, is_active';

  @override
  Future<List<ProductBarcode>> getAll({required String storeId}) async {
    final rows = await fetchAllKeyset(
      supabaseClient.from(_table).select(_columns).eq('store_id', storeId),
    );
    final mapped = [for (final row in rows) _map(row)]
      ..sort((a, b) {
        final byProduct = a.productId.compareTo(b.productId);
        return byProduct != 0
            ? byProduct
            : a.barcode.toLowerCase().compareTo(b.barcode.toLowerCase());
      });
    return List.unmodifiable(mapped);
  }

  @override
  Future<List<ProductBarcode>> getForProduct(
    String productId, {
    required String storeId,
  }) async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('product_id', productId)
        .eq('store_id', storeId)
        .order('barcode', ascending: true);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<void> add(ProductBarcode barcode) async {
    await supabaseClient.from(_table).insert({
      'id': barcode.id,
      'user_id': requireCurrentUserId(),
      'store_id': barcode.storeId,
      'product_id': barcode.productId,
      'barcode': barcode.barcode,
      'qty_factor': barcode.qtyFactor,
      'description': barcode.description,
      'is_active': barcode.isActive,
    });
  }

  @override
  Future<void> update(ProductBarcode barcode) async {
    final rows = await supabaseClient
        .from(_table)
        .update({
          'barcode': barcode.barcode,
          'qty_factor': barcode.qtyFactor,
          'description': barcode.description,
          'is_active': barcode.isActive,
        })
        .eq('id', barcode.id)
        .eq('store_id', barcode.storeId)
        .select('id');
    if (rows.isEmpty) {
      throw StateError('Código ${barcode.id} não encontrado para atualização.');
    }
  }

  @override
  Future<void> delete(String id, {required String storeId}) async {
    await supabaseClient
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('store_id', storeId);
  }

  ProductBarcode _map(Map<String, dynamic> row) => ProductBarcode(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    productId: row['product_id'] as String,
    barcode: row['barcode'] as String,
    qtyFactor: (row['qty_factor'] as num).toInt(),
    description: (row['description'] as String?) ?? '',
    isActive: row['is_active'] as bool? ?? true,
  );
}
