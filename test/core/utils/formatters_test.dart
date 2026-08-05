import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/core/utils/formatters.dart';

void main() {
  tearDown(() {
    // Volta ao padrão para não vazar estado entre testes.
    Formatters.applySettings(currencyCode: 'BRL', language: 'pt');
  });

  group('currency', () {
    test('padrão: BRL + pt (sem configuração)', () {
      expect(Formatters.currentCurrencyCode, 'BRL');
      expect(Formatters.currentLanguage, 'pt');
      expect(Formatters.currency(1234.56), 'R\$ 1.234,56');
    });

    test('USD + en usa separador de milhar norte-americano', () {
      Formatters.applySettings(currencyCode: 'USD', language: 'en');
      expect(Formatters.currency(1234.56), 'US\$ 1,234.56');
    });

    test('EUR mantém vírgula decimal em pt', () {
      Formatters.applySettings(currencyCode: 'EUR', language: 'pt');
      expect(Formatters.currency(1234.5), '€ 1.234,50');
    });

    test('MZN (metical) tem símbolo próprio', () {
      Formatters.applySettings(currencyCode: 'MZN', language: 'en');
      expect(Formatters.currency(5000), 'MTn 5,000.00');
    });
  });

  group('day (idioma ativo)', () {
    test('hoje segue o idioma pt', () {
      expect(Formatters.day(DateTime.now()), 'Hoje');
    });

    test('hoje segue o idioma en', () {
      Formatters.applySettings(currencyCode: 'USD', language: 'en');
      expect(Formatters.day(DateTime.now()), 'Today');
    });
  });
}
