import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/utils/scale_barcode.dart';

void main() {
  group('ScaleBarcode.tryParse', () {
    test('parseia o formato 20PPPPPWWWWW (12 dígitos)', () {
      final data = ScaleBarcode.tryParse('200000120000');
      expect(data, isNotNull);
      expect(data!.productCode, '00001');
      expect(data.totalValueCents, 20000); // 200,00 da moeda local
    });

    test('extrai código do produto e valor total em centavos', () {
      final data = ScaleBarcode.tryParse('201234501750');
      expect(data!.productCode, '12345');
      expect(data.totalValueCents, 1750); // 17,50
    });

    test('tolera sujeira de leitura (espaços e caracteres de controle)', () {
      final data = ScaleBarcode.tryParse('\r\n 200000120000 \n');
      expect(data, isNotNull);
      expect(data!.productCode, '00001');
      expect(data.totalValueCents, 20000);
    });

    test(
      'retorna null para código que NÃO começa com 20 ou fora do formato',
      () {
        expect(ScaleBarcode.tryParse('20000120000'), isNull); // 11 dígitos
        expect(ScaleBarcode.tryParse('1234501750'), isNull); // 10 dígitos
        expect(
          ScaleBarcode.tryParse('200012000'),
          isNull,
        ); // dígitos insuficientes
        expect(ScaleBarcode.tryParse(''), isNull);
      },
    );

    test('retorna null para EAN-13 comum (fluxo normal por código)', () {
      expect(ScaleBarcode.tryParse('5901234123457'), isNull);
    });
  });

  group('ScaleBarcode.lookupKey', () {
    test('remove zeros à esquerda de códigos numéricos (PLU 5 dígitos)', () {
      expect(ScaleBarcode.lookupKey('00123'), '123');
      expect(ScaleBarcode.lookupKey('123'), '123');
      expect(ScaleBarcode.lookupKey('00001'), '1');
      expect(ScaleBarcode.lookupKey(' 007 '), '7');
    });

    test('códigos não-numéricos e vazios ficam sem alteração', () {
      expect(ScaleBarcode.lookupKey('ABC-1'), 'ABC-1');
      expect(ScaleBarcode.lookupKey(''), '');
    });

    test('normaliza PLU da balança e do cadastro para a MESMA chave', () {
      // Balança imprime 5 dígitos; cadastro aceita como digitado.
      expect(ScaleBarcode.lookupKey('00123'), ScaleBarcode.lookupKey('123'));
      expect(ScaleBarcode.lookupKey('00001'), ScaleBarcode.lookupKey('1'));
    });
  });

  group('ScaleBarcode.weightMilliUnits', () {
    test('deriva a fração de peso do valor total ÷ preço unitário', () {
      // 20000 centavos (200,00) ÷ 8000 centavos/kg = 2,5 kg = 2500 milésimos.
      final data = const ScaleBarcodeData(
        productCode: '00001',
        totalValueCents: 20000,
      );
      expect(ScaleBarcode.weightMilliUnits(data, 8000), 2500);
    });

    test('divisão inteira (chão) nunca cobra a mais', () {
      // 1750 centavos ÷ 8000 centavos/kg → 0,21875 → 218 milésimos (0,218 kg).
      final data = const ScaleBarcodeData(
        productCode: '00001',
        totalValueCents: 1750,
      );
      expect(ScaleBarcode.weightMilliUnits(data, 8000), 218);
      // O produto real cobrado (218 × 8000 / 1000 = 1744) ≤ 1750.
      expect(218 * 8000 ~/ 1000, lessThanOrEqualTo(1750));
    });

    test('retorna 0 para preço unitário inválido (≤ 0)', () {
      final data = const ScaleBarcodeData(
        productCode: '00001',
        totalValueCents: 1750,
      );
      expect(ScaleBarcode.weightMilliUnits(data, 0), 0);
      expect(ScaleBarcode.weightMilliUnits(data, -100), 0);
    });
  });
}
