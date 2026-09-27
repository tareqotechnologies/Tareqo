import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/product.dart';

/// Fase 1 — papel do tipo do produto em cada fluxo:
/// - COMPRAS repõe matéria-prima, revenda e embalagem;
/// - PDV vende revenda, produzido e composto.
///
/// Matéria-prima/embalagem são consumidas internamente (nunca vendidas);
/// produzido/composto nascem da produção interna (nunca comprados).
void main() {
  group('ProductType — papel nos fluxos', () {
    test('isPurchasable: só matéria-prima, revenda e embalagem', () {
      expect(ProductType.rawMaterial.isPurchasable, isTrue);
      expect(ProductType.resale.isPurchasable, isTrue);
      expect(ProductType.packaging.isPurchasable, isTrue);
      expect(ProductType.manufactured.isPurchasable, isFalse);
      expect(ProductType.composite.isPurchasable, isFalse);
    });

    test('isSellable: só revenda, produzido e composto', () {
      expect(ProductType.resale.isSellable, isTrue);
      expect(ProductType.manufactured.isSellable, isTrue);
      expect(ProductType.composite.isSellable, isTrue);
      expect(ProductType.rawMaterial.isSellable, isFalse);
      expect(ProductType.packaging.isSellable, isFalse);
    });

    test('todo tipo tem um papel e revenda é o único comprado E vendido', () {
      for (final type in ProductType.values) {
        expect(
          type.isPurchasable || type.isSellable,
          isTrue,
          reason: '${type.name} precisa ter um papel definido',
        );
      }
      final both = ProductType.values
          .where((type) => type.isPurchasable && type.isSellable)
          .toList();
      expect(both, [ProductType.resale]);
    });
  });
}
