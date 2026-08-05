import '../../../domain/entities/product.dart';

/// Contrato de armazenamento local de produtos (camada de dados).
///
/// Declara apenas *o que* a persistência precisa fazer — não *como*.
/// Implementações possíveis: memória (atual), SQLite, Hive, drift...
/// O repositório depende desta abstração, e não de uma implementação,
/// por isso trocar a persistência **não altera o repositório**.
abstract interface class ProductLocalDataSource {
  /// Retorna todos os produtos da loja [storeId] armazenados localmente.
  Future<List<Product>> getAll({required String storeId});

  /// Retorna o produto com o [id] informado da loja [storeId], ou `null`
  /// se não existir lá (o id é global; a leitura é escopada pela loja).
  Future<Product?> getById(String id, {required String storeId});

  /// Adiciona um produto ao armazenamento local.
  Future<void> add(Product product);

  /// Define a quantidade em estoque do produto [id] da loja [storeId]
  /// (valor absoluto) — escopado pela loja.
  Future<void> updateStock(
    String id,
    int newQuantity, {
    required String storeId,
  });
}
