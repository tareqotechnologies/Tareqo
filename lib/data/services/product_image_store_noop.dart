import 'dart:typed_data';

import '../../domain/repositories/i_product_image_store.dart';

/// Implementação NO-OP (modo memória — web/testes): não há disco nem
/// Storage, então a foto é descartada e [saveImage] devolve referência
/// vazia (`Product.imagePath = ''` → a UI mostra o ícone padrão).
/// Registrada apenas quando o app roda sem SQLite e sem Supabase.
final class ProductImageStoreNoop implements IProductImageStore {
  const ProductImageStoreNoop();

  @override
  Future<String> saveImage({
    required String productId,
    required String storeId,
    required Uint8List bytes,
  }) async => '';

  @override
  Future<void> deleteImage(String path) async {}
}
