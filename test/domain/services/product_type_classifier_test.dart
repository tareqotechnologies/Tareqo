import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/services/product_type_classifier.dart';

/// Backfill one-off do `products.type` (Fase 1): o classificador sugere o
/// tipo pelo NOME, a tabela é ORDENADA (primeira regra que casa vence) e o
/// casamento ignora acento/maiúsculas e exige TOKEN inteiro.
///
/// A última seção cobre o plano de backfill: por padrão só reclassifica quem
/// ainda está em `resale` (o default legado) e nunca toca tipos já definidos.
void main() {
  const classifier = ProductTypeClassifier();

  ProductType classify(String name) => classifier.classify(name).type;

  group('ProductTypeClassifier — regras por palavra-chave', () {
    test('matéria-prima', () {
      expect(classify('Farinha de Trigo'), ProductType.rawMaterial);
      expect(classify('Açúcar Cristal'), ProductType.rawMaterial);
      expect(classify('Leite Integral'), ProductType.rawMaterial);
      expect(classify('Carne Picada'), ProductType.rawMaterial);
      expect(classify('Ovos'), ProductType.rawMaterial);
    });

    test('embalagem', () {
      expect(classify('Copo Descartável 200ml'), ProductType.packaging);
      expect(classify('Guardanapos'), ProductType.packaging);
      expect(classify('Caixa de Papelão'), ProductType.packaging);
    });

    test('produzido', () {
      expect(classify('Pão Francês'), ProductType.manufactured);
      expect(classify('Croissant de Manteiga'), ProductType.manufactured);
      expect(classify('Bolo de Chocolate'), ProductType.manufactured);
      expect(classify('Empada de Frango'), ProductType.manufactured);
    });

    test('composto', () {
      expect(classify('Hambúrguer Clássico'), ProductType.composite);
      expect(classify('Sanduíche de Presunto'), ProductType.composite);
      expect(classify('Prato Feito'), ProductType.composite);
    });

    test('revenda', () {
      expect(classify('Água Mineral 500ml'), ProductType.resale);
      expect(classify('Refrigerante Lata'), ProductType.resale);
      expect(classify('Sumo de Laranja'), ProductType.resale);
    });

    test('sem regra casada cai no default revenda (ex.: Coca-Cola)', () {
      final suggestion = classifier.classify('Coca-Cola 350ml');
      expect(suggestion.type, ProductType.resale);
      expect(suggestion.reason, 'default');
    });
  });

  group('ProductTypeClassifier — normalização e fronteiras', () {
    test('ignora maiúsculas e acentos', () {
      expect(classify('AÇÚCAR MASCAVO'), ProductType.rawMaterial);
      expect(classify('PÃO DE QUEIJO'), ProductType.manufactured);
      expect(classify('Açaí'), ProductType.rawMaterial);
    });

    test('casa TOKEN inteiro — "sal" não casa "salada"/"salgadinho"', () {
      expect(classify('Salada de Frutas'), ProductType.resale);
      expect(classify('Salgadinho'), ProductType.resale);
      // "salgado" É uma regra de produzido, mas "salgadinho" não é token igual.
      expect(classify('Sal'), ProductType.rawMaterial);
    });

    test('casa FRASES delimitadas (multi-palavra)', () {
      expect(classify('Cachorro Quente'), ProductType.composite);
      expect(classify('Pão de Queijo'), ProductType.manufactured);
      expect(classify('Batata Frita Congelada'), ProductType.resale);
    });

    test('a primeira regra da tabela vence (precedência)', () {
      // produzido antes de matéria-prima: o pastel não vira "carne".
      expect(classify('Pastel de Carne'), ProductType.manufactured);
      // revenda antes de matéria-prima: o sumo não vira "laranja".
      expect(classify('Sumo de Laranja'), ProductType.resale);
      // composto antes de embalagem: "prato feito" não vira "prato".
      expect(classify('Prato Feito'), ProductType.composite);
    });

    test('a razão registra a palavra-chave que casou', () {
      expect(classifier.classify('Farinha de Trigo').reason, 'farinha');
      expect(classifier.classify('Pão Francês').reason, 'pao');
    });

    test('tabela padrão é ordenada e sem palavras-chave vazias', () {
      expect(ProductTypeClassifier.defaultRules, isNotEmpty);
      for (final rule in ProductTypeClassifier.defaultRules) {
        expect(rule.keywords, isNotEmpty);
        for (final keyword in rule.keywords) {
          expect(keyword, keyword.toLowerCase());
          expect(keyword, isNot(''));
        }
      }
    });
  });

  group('planProductTypeBackfill', () {
    final candidates = <ProductTypeCandidate>[
      const ProductTypeCandidate(
        id: '1',
        name: 'Farinha de Trigo',
        currentType: ProductType.resale,
      ),
      const ProductTypeCandidate(
        id: '2',
        name: 'Pão Francês',
        currentType: ProductType.rawMaterial,
      ),
      const ProductTypeCandidate(
        id: '3',
        name: 'Coca-Cola 350ml',
        currentType: ProductType.resale,
      ),
    ];

    test('só propõe quem ainda está em revenda (default legado)', () {
      final plan = planProductTypeBackfill(candidates);
      expect(plan, hasLength(1));
      final entry = plan.single;
      expect(entry.id, '1');
      expect(entry.name, 'Farinha de Trigo');
      expect(entry.from, ProductType.resale);
      expect(entry.to, ProductType.rawMaterial);
      expect(entry.reason, 'farinha');
      expect(entry.changes, isTrue);
    });

    test('não toca tipos já definidos nem quem permanece revenda', () {
      final plan = planProductTypeBackfill(candidates);
      final ids = plan.map((e) => e.id).toList();
      expect(ids, isNot(contains('2')));
      expect(ids, isNot(contains('3')));
    });

    test('include-classified reaplica as regras a todos', () {
      final plan = planProductTypeBackfill(candidates, onlyResale: false);
      expect(plan, hasLength(2));
      expect(plan.map((e) => e.id).toSet(), {'1', '2'});
      expect(plan.firstWhere((e) => e.id == '2').to, ProductType.manufactured);
    });
  });
}
