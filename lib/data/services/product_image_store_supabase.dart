import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../domain/repositories/i_product_image_store.dart';
import '../datasources/remote/supabase_datasource_helpers.dart'
    show supabaseClient, requireCurrentUserId;

/// Bucket PÚBLICO do Supabase Storage que guarda as fotos de produto.
/// Criado no schema (`supabase/schema.sql`) com políticas de leitura
/// pública e escrita autenticada — a URL pública é o que fica gravado em
/// `products.image_path`.
const String kProductImagesBucket = 'product-images';

/// Implementação REMOTA (modo SaaS): sobe a foto para o Supabase Storage
/// no caminho `<storeId>/<productId>.jpg` (UPSERT — substituir a foto não
/// cria objeto órfão) e devolve a **URL pública** via CDN.
///
/// Atenção: O PRIMEIRO segmento do caminho É o store_id, de propósito: a política
/// de escrita do bucket valida `is_my_store((storage.foldername(name))[1])`
/// — um prefixo `products/...` faria a guarda comparar 'products' e negar o
/// upload (403 RLS). Ver secção 27 do upgrade.sql / storage do schema.sql.
final class ProductImageStoreSupabase implements IProductImageStore {
  const ProductImageStoreSupabase();

  @override
  Future<String> saveImage({
    required String productId,
    required String storeId,
    required Uint8List bytes,
  }) async {
    requireCurrentUserId();
    // Primeiro segmento = store_id (obrigatório — ver doc da classe).
    final path = '$storeId/$productId.jpg';
    await supabaseClient.storage
        .from(kProductImagesBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    return supabaseClient.storage.from(kProductImagesBucket).getPublicUrl(path);
  }

  @override
  Future<void> deleteImage(String path) async {
    if (path.isEmpty) return;
    final objectPath = _objectPathFromUrl(path);
    if (objectPath == null) return;
    try {
      await supabaseClient.storage.from(kProductImagesBucket).remove([
        objectPath,
      ]);
    } catch (_) {
      // Best-effort: remover um objeto já ausente não é erro.
    }
  }

  /// Extrai o object path da URL pública (ou aceita o path direto).
  static String? _objectPathFromUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    final path = uri.path;
    final marker = '/$kProductImagesBucket/';
    final index = path.indexOf(marker);
    if (index == -1) return null;
    final objectPath = path.substring(index + marker.length);
    return objectPath.isEmpty ? null : objectPath;
  }
}
