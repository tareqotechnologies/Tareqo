import 'dart:typed_data';

/// Contrato de armazenamento de IMAGENS de produto (arquivos/objetos).
///
/// Separado de [IProductRepository] de propósito: a foto é um ARQUIVO
/// (blob no Supabase Storage / arquivo no disco do aparelho), não uma
/// linha da tabela `products` — manter a separação evita contaminar o
/// contrato de produtos com I/O de arquivos e preserva os fakes de teste
/// existentes.
///
/// [saveImage] recebe os bytes já comprimidos (JPEG) e devolve a
/// referência persistida — URL pública do Supabase Storage (modo SaaS) ou
/// caminho absoluto do arquivo local (modo SQLite). Essa referência é
/// gravada em [Product.imagePath] e lida pela UI para exibir a foto.
abstract interface class IProductImageStore {
  /// Persiste a imagem [bytes] do produto [productId] da loja [storeId] e
  /// devolve a referência (URL/caminho). Substitui a imagem anterior do
  /// produto (mesmo caminho de objeto/arquivo).
  Future<String> saveImage({
    required String productId,
    required String storeId,
    required Uint8List bytes,
  });

  /// Remove a imagem referenciada por [path] (URL ou caminho local).
  /// No-op quando [path] é vazio ou o arquivo/objeto não existe
  /// (best-effort — remover uma imagem já ausente não é erro).
  Future<void> deleteImage(String path);
}
