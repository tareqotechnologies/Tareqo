import 'package:flutter_test/flutter_test.dart';
import 'package:tareqo/core/utils/product_categories.dart';
import 'package:tareqo/domain/entities/product.dart';

Product product(String category) => Product(
  id: category,
  name: 'Produto',
  purchasePriceCents: 100,
  salePriceCents: 200,
  category: category,
);

void main() {
  test('categorias distintas, ordenadas, sem espaços redundantes', () {
    expect(
      productCategoriesOf([
        product(' Padaria '),
        product('bebidas'),
        product('BEBIDAS'),
        product(''),
        product('  '),
        product('Material   de limpeza'),
        product('material de limpeza'),
      ]),
      ['bebidas', 'Material de limpeza', 'Padaria'],
    );
    expect(productCategoriesOf(null), isEmpty);
  });

  test('todas e sem categoria são seleções distintas', () {
    expect(matchesProductCategory(product('Bebidas'), null), isTrue);
    expect(matchesProductCategory(product(''), null), isTrue);
    expect(matchesProductCategory(product('   '), ''), isTrue);
    expect(matchesProductCategory(product('Bebidas'), ''), isFalse);
    expect(matchesProductCategory(product(' BEBIDAS '), 'bebidas'), isTrue);
    expect(
      matchesProductCategory(
        product('Material   de limpeza'),
        'material de limpeza',
      ),
      isTrue,
    );
    expect(matchesProductCategory(product('Todas'), 'Todas'), isTrue);
    expect(matchesProductCategory(product('Bebidas'), 'Todas'), isFalse);
  });

  test('cadastro reutiliza rótulos existentes ou normaliza categoria nova', () {
    expect(
      canonicalProductCategory(' bebidas ', [product('Bebidas')]),
      'Bebidas',
    );
    expect(
      canonicalProductCategory('Material   de limpeza', []),
      'Material de limpeza',
    );
    expect(canonicalProductCategory('  ', [product('Bebidas')]), '');
  });
}
