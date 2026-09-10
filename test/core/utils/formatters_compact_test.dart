import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/utils/formatters.dart';

void main() {
  tearDown(() {
    Formatters.applySettings(currencyCode: 'BRL', language: 'pt');
  });

  group('Formatters.compact (cards de métrica)', () {
    test('abaixo de 1000: número inteiro simples (pt)', () {
      expect(Formatters.compact(890), '890');
      expect(Formatters.compact(0), '0');
      expect(Formatters.compact(999), '999');
    });

    test('milhar: sufixo k com uma casa decimal (pt)', () {
      expect(Formatters.compact(12400), '12,4k');
      expect(Formatters.compact(1000), '1,0k');
    });

    test('milhão: sufixo M (pt)', () {
      expect(Formatters.compact(1250000), '1,3M');
      expect(Formatters.compact(1000000), '1,0M');
    });

    test('en usa ponto decimal', () {
      Formatters.applySettings(currencyCode: 'USD', language: 'en');
      expect(Formatters.compact(12400), '12.4k');
      expect(Formatters.compact(1250000), '1.3M');
    });

    test('valores negativos usam o módulo para escolher o sufixo', () {
      // -1250000 → abs ≥ 1M → M com o sinal preservado.
      expect(Formatters.compact(-1250000), '-1,3M');
      expect(Formatters.compact(-12400), '-12,4k');
    });
  });

  group('Formatters.signedAmount (feed de atividade)', () {
    test('positivo tem sinal + e duas casas (pt)', () {
      expect(Formatters.signedAmount(50000), '+500,00');
    });

    test('negativo tem sinal - e módulo', () {
      expect(Formatters.signedAmount(-89000), '-890,00');
    });

    test('zero é tratado como positivo (+)', () {
      expect(Formatters.signedAmount(0), '+0,00');
    });
  });

  group('Formatters.amountWithCode (cards da Home)', () {
    test('pt: valor + código da moeda ativa', () {
      Formatters.applySettings(currencyCode: 'MZN', language: 'pt');
      expect(Formatters.amountWithCode(1234.56), '1.234,56 MZN');
    });

    test('en: separadores norte-americanos', () {
      Formatters.applySettings(currencyCode: 'MZN', language: 'en');
      expect(Formatters.amountWithCode(1234.56), '1,234.56 MZN');
    });
  });
}
