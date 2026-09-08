import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/data/datasources/local/stock_lot_sqlite_data_source_impl.dart';
import 'package:tareqo/domain/entities/stock_lot.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
  late Database db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  StockLot buildLot(
    String id, {
    required int current,
    DateTime? expiry,
    DateTime? entry,
    String storeId = 'st1',
    int cost = 500,
  }) => StockLot(
    id: id,
    storeId: storeId,
    productId: 'p1',
    entryDate: entry ?? DateTime(2026, 1, 1),
    expiryDate: expiry,
    initialQuantity: current,
    currentQuantity: current,
    costPriceCents: cost,
  );

  test('add persiste e getActiveByProduct devolve o lote fiel', () async {
    final dataSource = StockLotSqliteDataSourceImpl(db);
    final expiry = DateTime(2026, 12, 31);
    await dataSource.add(buildLot('l1', current: 1750, expiry: expiry));

    final lots = await dataSource.getActiveByProduct('p1', storeId: 'st1');

    expect(lots, hasLength(1));
    expect(lots.single.id, 'l1');
    expect(lots.single.currentQuantity, 1750);
    expect(lots.single.initialQuantity, 1750);
    expect(lots.single.expiryDate, expiry);
    expect(lots.single.costPriceCents, 500);
  });

  test(
    'ordena FIFO: validade mais próxima primeiro, sem validade no fim',
    () async {
      final dataSource = StockLotSqliteDataSourceImpl(db);
      // Ordem de inserção propositalmente bagunçada.
      await dataSource.add(
        buildLot('l-sem-2', current: 100, entry: DateTime(2026, 5, 1)),
      );
      await dataSource.add(
        buildLot('l-jun', current: 100, expiry: DateTime(2026, 6, 1)),
      );
      await dataSource.add(
        buildLot('l-mar', current: 100, expiry: DateTime(2026, 3, 1)),
      );
      await dataSource.add(
        buildLot('l-sem-1', current: 100, entry: DateTime(2026, 1, 1)),
      );

      final lots = await dataSource.getActiveByProduct('p1', storeId: 'st1');

      expect(lots.map((lot) => lot.id), [
        'l-mar', // vence primeiro
        'l-jun',
        'l-sem-1', // sem validade, entrada mais antiga primeiro
        'l-sem-2',
      ]);
    },
  );

  test('desempate por data de entrada e id entre lotes sem validade', () async {
    final dataSource = StockLotSqliteDataSourceImpl(db);
    await dataSource.add(
      buildLot('l-antigo', current: 100, entry: DateTime(2026, 1, 1)),
    );
    await dataSource.add(
      buildLot('l-novo', current: 100, entry: DateTime(2026, 6, 1)),
    );

    final lots = await dataSource.getActiveByProduct('p1', storeId: 'st1');

    expect(lots.map((lot) => lot.id), ['l-antigo', 'l-novo']);
  });

  test('getActiveByProduct filtra por loja e ignora lotes zerados', () async {
    final dataSource = StockLotSqliteDataSourceImpl(db);
    await dataSource.add(buildLot('l1', current: 500, storeId: 'st1'));
    await dataSource.add(buildLot('l2', current: 0, storeId: 'st1'));
    await dataSource.add(buildLot('l3', current: 500, storeId: 'st2'));

    final lots = await dataSource.getActiveByProduct('p1', storeId: 'st1');

    expect(lots.map((lot) => lot.id), ['l1']);
  });

  test(
    'updateQuantity define a quantidade atual (escopado pela loja)',
    () async {
      final dataSource = StockLotSqliteDataSourceImpl(db);
      await dataSource.add(buildLot('l1', current: 1000));

      await dataSource.updateQuantity('l1', 400, storeId: 'st1');

      final lots = await dataSource.getActiveByProduct('p1', storeId: 'st1');
      expect(lots.single.currentQuantity, 400);
    },
  );

  test(
    'updateQuantity lança StateError para lote inexistente ou de outra loja',
    () async {
      final dataSource = StockLotSqliteDataSourceImpl(db);
      await dataSource.add(buildLot('l1', current: 1000, storeId: 'st1'));

      expect(
        () => dataSource.updateQuantity('fantasma', 1, storeId: 'st1'),
        throwsStateError,
      );
      expect(
        () => dataSource.updateQuantity('l1', 1, storeId: 'st2'),
        throwsStateError,
      );
    },
  );

  test(
    'getByStore retorna todos os lotes ativos da loja em ordem FIFO',
    () async {
      final dataSource = StockLotSqliteDataSourceImpl(db);
      await dataSource.add(
        buildLot('l1', current: 100, expiry: DateTime(2026, 6, 1)),
      );
      await dataSource.add(
        buildLot('l2', current: 200, expiry: DateTime(2026, 3, 1)),
      );
      await dataSource.add(buildLot('l3', current: 300, storeId: 'st2'));

      final lots = await dataSource.getByStore(storeId: 'st1');

      expect(lots.map((lot) => lot.id), ['l2', 'l1']);
    },
  );

  test(
    'CHECK do banco rejeita quantidade negativa (salvaguarda final)',
    () async {
      expect(
        () => db.execute(
          'INSERT INTO stock_lots '
          '(id, store_id, product_id, entry_date, expiry_date, '
          ' initial_quantity, current_quantity, cost_price) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          ['x', 'st1', 'p1', 0, null, 100, -5, 0],
        ),
        throwsA(isA<SqliteException>()),
      );
    },
  );
}
