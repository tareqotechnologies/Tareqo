import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/sale_local_data_source_impl.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';

Sale _sale(String id, {String storeId = 'st1'}) => Sale(
  id: id,
  storeId: storeId,
  number: 1,
  dateTime: DateTime(2026, 8, 16, 9),
  items: const [],
  totalAmountCents: 2500,
  paymentMethod: PaymentMethod.cash,
);

void main() {
  group('SaleLocalDataSourceImpl (memória — web/fallback)', () {
    test('add + getAll devolve apenas as vendas DA LOJA pedida', () async {
      final ds = SaleLocalDataSourceImpl();
      await ds.add(_sale('s1', storeId: 'st1'));
      await ds.add(_sale('s2', storeId: 'st2'));

      final st1 = await ds.getAll(storeId: 'st1');
      final st2 = await ds.getAll(storeId: 'st2');

      expect(st1.map((s) => s.id), ['s1']);
      expect(st2.map((s) => s.id), ['s2']);
    });

    test('getById respeita o escopo por loja (outra loja não vê)', () async {
      final ds = SaleLocalDataSourceImpl();
      await ds.add(_sale('s1', storeId: 'st1'));

      expect(await ds.getById('s1', storeId: 'st1'), isNotNull);
      // Escopo por loja: id certo, loja errada → invisível (isolamento).
      expect(await ds.getById('s1', storeId: 'st2'), isNull);
      expect(await ds.getById('inexistente', storeId: 'st1'), isNull);
    });

    test('markCancelled marca cancelada com o instante da anulação', () async {
      final ds = SaleLocalDataSourceImpl();
      await ds.add(_sale('s1'));

      await ds.markCancelled('s1', storeId: 'st1');

      final sale = await ds.getById('s1', storeId: 'st1');
      expect(sale!.status, SaleStatus.cancelled);
      expect(sale.cancelledAt, isNotNull);
    });

    test('markCancelled de venda DE OUTRA LOJA lança StateError', () async {
      final ds = SaleLocalDataSourceImpl();
      await ds.add(_sale('s1', storeId: 'st1'));

      // Isolamento: anular com storeId errado falha em vez de vazar.
      await expectLater(
        ds.markCancelled('s1', storeId: 'st2'),
        throwsA(isA<StateError>()),
      );
      // A venda da loja certa continua intacta (não cancelada).
      final sale = await ds.getById('s1', storeId: 'st1');
      expect(sale!.status, isNot(SaleStatus.cancelled));
    });

    test(
      'registerLotConsumption + getLotConsumption devolvem a fotografia FIFO',
      () async {
        final ds = SaleLocalDataSourceImpl();
        await ds.add(_sale('s1'));

        await ds.registerLotConsumption('s1', 'st1', const [
          LotConsumption(lotId: 'l1', productId: 'p1', quantity: 5000),
          LotConsumption(lotId: 'l2', productId: 'p1', quantity: 2500),
        ]);

        final consumption = await ds.getLotConsumption('s1', storeId: 'st1');
        expect(consumption, hasLength(2));
        expect(consumption.first.lotId, 'l1');
        expect(consumption.first.quantity, 5000);
      },
    );

    test('getLotConsumption de venda sem consumo devolve vazio', () async {
      final ds = SaleLocalDataSourceImpl();
      expect(
        await ds.getLotConsumption('s-inexistente', storeId: 'st1'),
        isEmpty,
      );
    });

    test('seed guarda as vendas informadas na construção', () async {
      final ds = SaleLocalDataSourceImpl(seed: [_sale('s1')]);
      expect(await ds.getAll(storeId: 'st1'), hasLength(1));
    });
  });
}
