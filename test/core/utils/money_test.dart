import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/utils/money.dart';

void main() {
  group('Money.fromReais', () {
    test('converte reais em centavos inteiros (arredondando)', () {
      expect(Money.fromReais(9.9), 990);
      expect(Money.fromReais(0.1 + 0.2), 30);
      expect(Money.fromReais(29.7), 2970);
      expect(Money.fromReais(0), 0);
      expect(Money.fromReais(1.234), 123); // 1.234 → 123 centavos
      expect(Money.fromReais(13.9), 1390);
    });
  });

  group('Money.parse', () {
    test('aceita vírgula (pt) e ponto (en) como separador decimal', () {
      expect(Money.parse('13,90'), 1390);
      expect(Money.parse('13.90'), 1390);
      expect(Money.parse('9,9'), 990);
    });

    test('aceita separador de milhares', () {
      expect(Money.parse('1.234,56'), 123456);
      expect(Money.parse('1,234.56'), 123456);
    });
    test('entradas vazias/inválidas retornam 0', () {
      expect(Money.parse(''), 0);
      expect(Money.parse(' '), 0);
      expect(Money.parse('abc'), 0);
    });

    test('sem separador = reais inteiros (documenta a ambiguidade A2)', () {
      // "1390" digitado sem separador é lido como 1.390,00 (e não 13,90):
      // o comportamento é intencional e a UI mitiga com o MoneyLivePreview
      // (auditoria A2) — este teste trava o contrato para não regredir.
      expect(Money.parse('1390'), 139000);
      expect(Money.parse('13,90'), 1390);
      expect(Money.parse('13.90'), 1390);
      expect(Money.parse('0'), 0);
    });
  });

  group('Money.toReais', () {
    test('converte centavos de volta para reais (exibição/plotagem)', () {
      expect(Money.toReais(990), 9.9);
      expect(Money.toReais(30), 0.3);
      expect(Money.toReais(0), 0.0);
    });
  });
}
