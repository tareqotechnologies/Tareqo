import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/utils/quantity.dart';

void main() {
  group('Quantity (W11 — milésimos de unidade)', () {
    test('parse aceita separador vírgula (pt) e ponto (en)', () {
      expect(Quantity.parse('1,75'), 1750);
      expect(Quantity.parse('1.75', language: 'en'), 1750);
      expect(Quantity.parse('1'), 1000);
      expect(Quantity.parse('0,5'), 500);
      expect(Quantity.parse(' 2,5 '), 2500);
    });

    test('parse segue a MESMA convenção de locale do format (round-trip)', () {
      // pt: '.' é MILHAR e ',' é decimal — espelho exato do NumberFormat.
      // Antes da correção, "1.250" era lido como 1,25 (corrompia estoque).
      expect(Quantity.parse('1.250'), 1250 * 1000);
      expect(Quantity.parse('1,25'), 1250);
      // en: ',' é milhar e '.' é decimal.
      expect(Quantity.parse('1,250', language: 'en'), 1250 * 1000);
      // Round-trips reais do PDV/estoque (pt) — mesmo recorte do dialog
      // (o dialog faz split(' ').first para descartar o rótulo):
      expect(
        Quantity.parse(Quantity.format(1250000).split(' ').first),
        1250000,
      );
      expect(
        Quantity.parse(Quantity.format(1250, unitLabel: 'kg').split(' ').first),
        1250,
      );
      expect(Quantity.parse(Quantity.format(25000).split(' ').first), 25000);
    });

    test('parse devolve 0 para entradas vazias ou inválidas', () {
      expect(Quantity.parse(''), 0);
      expect(Quantity.parse('abc'), 0);
      expect(Quantity.parse(' '), 0);
    });

    test('fromUnits e toUnits são inversos (sem perda em 3 casas)', () {
      expect(Quantity.fromUnits(1.75), 1750);
      expect(Quantity.fromUnits(1), 1000);
      expect(Quantity.toUnits(1750), closeTo(1.75, 0.0000001));
      expect(Quantity.toUnits(1000), 1);
    });

    test('lineTotal usa divisão inteira exata (qtd × preço ~/ 1000)', () {
      // 1,75 kg × 80,00/kg = 140,00.
      expect(Quantity.lineTotal(1750, 8000), 14000);
      // 2 unidades × 2,00 = 4,00.
      expect(Quantity.lineTotal(2000, 200), 400);
      // Sem fração: 1 × 9,90 = 9,90.
      expect(Quantity.lineTotal(1000, 990), 990);
    });

    test('format exibe inteiros sem fração e frações com até 3 casas', () {
      expect(Quantity.format(2000), '2');
      expect(Quantity.format(1750, language: 'pt'), '1,75');
      expect(Quantity.format(1750, language: 'en'), '1.75');
      expect(Quantity.format(1750, unitLabel: 'kg'), '1,75 kg');
      expect(Quantity.format(2000, unitLabel: 'un'), '2'); // 'un' não é exibido
      expect(Quantity.format(0), '0');
    });
  });
}
