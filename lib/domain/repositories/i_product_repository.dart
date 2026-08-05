import '../entities/product.dart';

/// Contrato de persistência de produtos (camada de domínio).
///
/// Declara apenas *o que* o sistema precisa — **não** *como* é feito.
/// A implementação concreta (ex.: `ProductRepositoryImpl` usando Dio,
/// SQLite, etc.) vive na camada `data` e implementa este contrato.
abstract interface class IProductRepository {
  /// Retorna todos os produtos cadastrados da loja [storeId] — cada loja
  /// tem seu próprio estoque (Fase 2 do multi-tenancy).
  Future<List<Product>> getAll({required String storeId});

  /// Retorna o produto com o [id] informado **na loja [storeId]**, ou
  /// `null` se não existir lá. O id é global, mas a leitura é sempre
  /// escopada pela loja (Fase 2 do multi-tenancy) — um produto de outra
  /// loja não é visível.
  Future<Product?> getById(String id, {required String storeId});

  /// Adiciona um novo produto ao repositório.
  Future<void> add(Product product);

  /// Define a quantidade em estoque do produto [id] da loja [storeId]
  /// (valor absoluto).
  ///
  /// A validação de não negatividade é responsabilidade da camada de
  /// domínio (use cases) — o repositório apenas persiste o valor. A
  /// atualização é escopada pela loja: um id de outra loja não é
  /// alcançável.
  Future<void> updateStock(
    String id,
    int newQuantity, {
    required String storeId,
  });
}
