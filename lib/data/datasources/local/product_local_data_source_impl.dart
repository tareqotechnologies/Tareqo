import '../../../domain/entities/product.dart';
import 'product_local_data_source.dart';

/// Implementação em memória do [ProductLocalDataSource].
///
/// Simula o banco de dados com uma `List<Product>` em memória, permitindo
/// desenvolver toda a lógica do ERP (domain → data → presentation) antes
/// de decidir a persistência definitiva.
///
/// Para migrar para SQLite, basta criar uma classe
/// `ProductSqliteDataSourceImpl` que implemente [ProductLocalDataSource]
/// (mesmas assinaturas) e trocá-la no ServiceLocator.
final class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  /// Lista simulando as linhas da tabela de produtos.
  ///
  /// Inicia vazia por padrão (testes dependem disso) — sem dados de
  /// demonstração; o ServiceLocator injeta apenas dados reais.
  ProductLocalDataSourceImpl({List<Product> seed = const []})
      : _products = [...seed];

  final List<Product> _products;

  @override
  Future<List<Product>> getAll({required String storeId}) async {
    // Filtra pela loja ativa e mantém a mesma ordenação do SQLite (por
    // nome, case-insensitive) para listagem idêntica em web e nativo.
    final filtered = _products.where((p) => p.storeId == storeId);
    final sorted = [...filtered]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List.unmodifiable(sorted);
  }

  @override
  Future<Product?> getById(String id, {required String storeId}) async {
    for (final product in _products) {
      // Escopo por loja: um id de outra loja não é visível aqui.
      if (product.id == id && product.storeId == storeId) return product;
    }
    return null;
  }

  @override
  Future<void> add(Product product) async {
    _products.add(product);
  }

  @override
  Future<void> updateStock(
    String id,
    int newQuantity, {
    required String storeId,
  }) async {
    // Escopo por loja: só o produto da loja informada é mutável.
    final index = _products.indexWhere(
      (product) => product.id == id && product.storeId == storeId,
    );
    if (index == -1) {
      throw StateError('Produto $id não encontrado para atualização de estoque.');
    }
    // Product é imutável: substitui por uma nova instância com o estoque novo.
    _products[index] = _products[index].copyWith(stockQuantity: newQuantity);
  }
}
