import '../../domain/entities/product.dart';

/// Preserva o rótulo, removendo espaços redundantes do agrupamento.
String normalizeProductCategory(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Categorias usadas no catálogo da loja, distintas e ordenadas sem caixa.
List<String> productCategoriesOf(Iterable<Product>? products) {
  final labels = <String, String>{};
  for (final product in products ?? const <Product>[]) {
    final label = normalizeProductCategory(product.category);
    if (label.isNotEmpty) labels.putIfAbsent(label.toLowerCase(), () => label);
  }
  return labels.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}

/// null = todas; vazio = sem categoria. Não confunde rótulos reais com
/// valores reservados, mesmo que o usuário crie uma categoria chamada Todas.
bool matchesProductCategory(Product product, String? selected) =>
    selected == null ||
    normalizeProductCategory(product.category).toLowerCase() ==
        normalizeProductCategory(selected).toLowerCase();

/// Ao guardar, reutiliza o rótulo já existente para evitar duplicados visuais.
String canonicalProductCategory(String value, Iterable<Product>? products) {
  final label = normalizeProductCategory(value);
  for (final existing in productCategoriesOf(products)) {
    if (existing.toLowerCase() == label.toLowerCase()) return existing;
  }
  return label;
}
