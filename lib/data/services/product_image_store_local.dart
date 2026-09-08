import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/i_product_image_store.dart';

/// Implementação LOCAL (modo SQLite): grava a foto como arquivo JPEG no
/// diretório de documentos do app (`product_images/<productId>.jpg`) e
/// devolve o **caminho absoluto** — persistido em `products.image_path` e
/// exibido via [ProductImage] (Image.file). O banco SQLite guarda apenas a
/// string de referência (banco leve, sem blob).
final class ProductImageStoreLocal implements IProductImageStore {
  const ProductImageStoreLocal();

  /// Nome de arquivo seguro a partir do id (ids do app são alfanuméricos,
  /// mas a sanitização protege contra qualquer entrada).
  static String _safeFileName(String productId) =>
      productId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  static Future<Directory> _imagesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'product_images'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  @override
  Future<String> saveImage({
    required String productId,
    required String storeId,
    required Uint8List bytes,
  }) async {
    final dir = await _imagesDir();
    final file = File(p.join(dir.path, '${_safeFileName(productId)}.jpg'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<void> deleteImage(String path) async {
    if (path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
