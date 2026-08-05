import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/core/utils/money.dart';

void main() {
  group('Money.round2', () {
    test('arredonda para 2 casas', () {
      expect(Money.round2(2.5), 2.5);
      expect(Money.round2(1.004), 1.0);
      expect(Money.round2(0.1 + 0.2), 0.3);
    });

    test('round2 é consistente com centavos (idempotente)', () {
      // round2(x) deve ser fixo: re-arredondar não muda nada — é o
      // contrato que o Postgres NUMERIC(12,2) também garante.
      final sample = [0.1, 0.2, 0.3, 9.9, 29.7, 1.004, 2.5, 123.456];
      for (final value in sample) {
        expect(Money.round2(Money.round2(value)), Money.round2(value));
        // E sempre cai em centavos exatos (2 casas).
        expect((Money.round2(value) * 100).round() / 100,
            Money.round2(value));
      }
    });

    test('não cria artefatos de double', () {
      // 2 × 9.9 + 9.9 = 29.700000000000003 → 29.7 exato.
      expect(Money.round2(2 * 9.9 + 9.9), 29.7);
      expect(Money.round2(0.30000000000000004), 0.3);
    });
  });

  group('Money.sum', () {
    test('soma exata em centavos', () {
      expect(Money.sum([0.1, 0.2, 0.3]), 0.6);
      expect(Money.sum([9.9, 9.9, 9.9]), 29.7);
      expect(Money.sum([1.005, 1.005]), 2.0); // 1.005 → 1.0 (binário)
    });

    test('soma vazia é zero', () {
      expect(Money.sum(const <num>[]), 0.0);
    });

    test('aceita ints e doubles', () {
      expect(Money.sum([1, 2.5, 3]), 6.5);
    });
  });

  group('Money.cents', () {
    test('converte para centavos inteiros', () {
      expect(Money.cents(9.9), 990);
      expect(Money.cents(0.1 + 0.2), 30);
      expect(Money.cents(29.7), 2970);
      expect(Money.cents(0), 0);
    });
  });

  group('Money.times', () {
    test('multiplicação exata qty × preço unitário', () {
      expect(Money.times(2, 9.9), 19.8);
      expect(Money.times(3, 0.1), 0.3);
      expect(Money.times(10, 1.234), 12.3); // 1.234 → 123 centavos
    });
  });
}
