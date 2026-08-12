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

  /// Atualiza os campos EDITÁVEIS do catálogo de [product] (nome,
  /// descrição, preços, código/PLU, venda por fração e status ativo).
  ///
  /// ⚠️ O estoque NÃO é alterado aqui: a mutação de quantidade passa
  /// exclusivamente pelo [FifoStockUseCase] (que mantém a invariante
  /// `product.stock = Σ lotes`). Chamar `update` com um `stockQuantity`
  /// diferente é um no-op para o estoque — o valor persistido continua
  /// sendo o da última operação de estoque.
  ///
  /// A atualização é escopada pela loja ([Product.storeId]): um produto de
  /// outra loja não é alcançável. Lança [StateError] se o produto não
  /// existir na loja.
  Future<void> update(Product product);

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
