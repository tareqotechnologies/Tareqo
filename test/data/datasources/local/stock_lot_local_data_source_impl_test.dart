import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/stock_lot_local_data_source_impl.dart';
import 'package:tareqo/domain/entities/stock_lot.dart';

StockLot _lot(
  String id, {
  int current = 100,
  DateTime? expiry,
  DateTime? entry,
  String storeId = 'st1',
  String productId = 'p1',
}) => StockLot(
  id: id,
  storeId: storeId,
  productId: productId,
  entryDate: entry ?? DateTime(2026, 1, 1),
  expiryDate: expiry,
  initialQuantity: current,
  currentQuantity: current,
  costPriceCents: 500,
);

void main() {
  group('StockLotLocalDataSourceImpl (memória — web/fallback)', () {
    test('add + getActiveByProduct filtra por produto e loja', () async {
      final ds = StockLotLocalDataSourceImpl();
      await ds.add(_lot('l1'));
      await ds.add(_lot('l2', productId: 'p2'));
      await ds.add(_lot('l3', storeId: 'st2'));

      final lots = await ds.getActiveByProduct('p1', storeId: 'st1');

      expect(lots.map((l) => l.id), ['l1']);
    });

    test(
      'getActiveByProduct ignora lotes ESGOTADOS (currentQuantity 0)',
      () async {
        final ds = StockLotLocalDataSourceImpl();
        await ds.add(_lot('l1', current: 0));
        await ds.add(_lot('l2', current: 50));

        final lots = await ds.getActiveByProduct('p1', storeId: 'st1');

        expect(lots.map((l) => l.id), ['l2']);
      },
    );

    test(
      'getActiveByProduct devolve lista VAZIA para produto inexistente',
      () async {
        final ds = StockLotLocalDataSourceImpl();
        expect(
          await ds.getActiveByProduct('fantasma', storeId: 'st1'),
          isEmpty,
        );
      },
    );

    test(
      'ordena FIFO: validade mais próxima primeiro, sem validade no fim',
      () async {
        final ds = StockLotLocalDataSourceImpl();
        // Ordem de inserção propositalmente bagunçada — igual ao teste SQLite.
        await ds.add(_lot('l-sem-2', entry: DateTime(2026, 5, 1)));
        await ds.add(_lot('l-jun', expiry: DateTime(2026, 6, 1)));
        await ds.add(_lot('l-mar', expiry: DateTime(2026, 3, 1)));
        await ds.add(_lot('l-sem-1', entry: DateTime(2026, 1, 1)));

        final lots = await ds.getActiveByProduct('p1', storeId: 'st1');

        expect(lots.map((l) => l.id), [
          'l-mar', // vence primeiro
          'l-jun',
          'l-sem-1', // sem validade, entrada mais antiga primeiro
          'l-sem-2',
        ]);
      },
    );

    test('desempate FIFO por entrada e id (mesma validade)', () async {
      final ds = StockLotLocalDataSourceImpl();
      await ds.add(
        _lot('l-b', entry: DateTime(2026, 2, 1), expiry: DateTime(2026, 6, 1)),
      );
      await ds.add(
        _lot('l-a', entry: DateTime(2026, 1, 1), expiry: DateTime(2026, 6, 1)),
      );

      final lots = await ds.getActiveByProduct('p1', storeId: 'st1');

      expect(lots.map((l) => l.id), ['l-a', 'l-b']);
    });

    test('getByStore devolve os lotes ativos da loja em FIFO', () async {
      final ds = StockLotLocalDataSourceImpl();
      await ds.add(_lot('l1', expiry: DateTime(2026, 9, 1)));
      await ds.add(_lot('l2', expiry: DateTime(2026, 8, 1)));
      await ds.add(_lot('l3', storeId: 'st2'));

      final lots = await ds.getByStore(storeId: 'st1');

      expect(lots.map((l) => l.id), ['l2', 'l1']);
    });

    test(
      'updateQuantity grava a quantidade absoluta (escopo por loja)',
      () async {
        final ds = StockLotLocalDataSourceImpl();
        await ds.add(_lot('l1', current: 100));

        await ds.updateQuantity('l1', 40, storeId: 'st1');

        final lot = await ds.getActiveByProduct('p1', storeId: 'st1');
        expect(lot.single.currentQuantity, 40);
      },
    );

    test('updateQuantity de lote DE OUTRA LOJA lança StateError', () async {
      final ds = StockLotLocalDataSourceImpl();
      await ds.add(_lot('l1', current: 100));

      // Isolamento: mesmo id, loja errada → não mutável.
      await expectLater(
        ds.updateQuantity('l1', 0, storeId: 'st2'),
        throwsA(isA<StateError>()),
      );
      final lot = await ds.getActiveByProduct('p1', storeId: 'st1');
      expect(lot.single.currentQuantity, 100);
    });

    test('increaseQuantity soma ao atual (estorno de anulação)', () async {
      final ds = StockLotLocalDataSourceImpl();
      await ds.add(_lot('l1', current: 40));

      await ds.increaseQuantity('l1', 60, storeId: 'st1');

      final lot = await ds.getActiveByProduct('p1', storeId: 'st1');
      expect(lot.single.currentQuantity, 100);
    });

    test('increaseQuantity de lote inexistente lança StateError', () async {
      final ds = StockLotLocalDataSourceImpl();
      await expectLater(
        ds.increaseQuantity('fantasma', 1, storeId: 'st1'),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'updateQuantity aceita ZERO (esgotar o lote) e ele sai do ativo',
      () async {
        final ds = StockLotLocalDataSourceImpl();
        await ds.add(_lot('l1', current: 10));

        await ds.updateQuantity('l1', 0, storeId: 'st1');

        // Zero = esgotado: não é mais "ativo" para venda (FIFO o pula).
        expect(await ds.getActiveByProduct('p1', storeId: 'st1'), isEmpty);
      },
    );
  });
}
