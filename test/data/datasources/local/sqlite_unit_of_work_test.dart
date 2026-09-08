import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/core/database/app_database_io.dart';
import 'package:tareqo/data/datasources/local/sqlite_unit_of_work.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
  late Database db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  int productCount() =>
      db.select('SELECT COUNT(*) AS c FROM products').first['c'] as int;

  test('grava todas as operações no COMMIT (tudo ou nada)', () async {
    final uow = SqliteUnitOfWork(db);

    await uow.run(() async {
      db.execute(
        'INSERT INTO products '
        '(id, name, description, purchase_price, sale_price, '
        'stock_quantity) VALUES (?, ?, ?, ?, ?, ?)',
        ['a', 'A', '', 1.0, 2.0, 1],
      );
      db.execute(
        'INSERT INTO products '
        '(id, name, description, purchase_price, sale_price, '
        'stock_quantity) VALUES (?, ?, ?, ?, ?, ?)',
        ['b', 'B', '', 1.0, 2.0, 1],
      );
    });

    expect(productCount(), 2);
  });

  test(
    'falha em qualquer operação faz ROLLBACK de todas as anteriores',
    () async {
      final uow = SqliteUnitOfWork(db);

      await expectLater(
        uow.run(() async {
          db.execute(
            'INSERT INTO products '
            '(id, name, description, purchase_price, sale_price, '
            'stock_quantity) VALUES (?, ?, ?, ?, ?, ?)',
            ['a', 'A', '', 1.0, 2.0, 1],
          );
          // Força falha: nome nulo viola NOT NULL.
          db.execute(
            'INSERT INTO products '
            '(id, name, description, purchase_price, sale_price, '
            'stock_quantity) VALUES (?, ?, ?, ?, ?, ?)',
            ['b', null, '', 1.0, 2.0, 1],
          );
        }),
        throwsA(isA<SqliteException>()),
      );

      // O primeiro INSERT também foi desfeito pelo rollback.
      expect(productCount(), 0);
    },
  );

  test(
    'runInTransaction aninhado junta-se à transação externa (reentrância)',
    () async {
      final uow = SqliteUnitOfWork(db);

      await expectLater(
        uow.run(() async {
          // Simula SaleSqliteDataSourceImpl.add: usa AppDatabase.runInTransaction
          // por dentro — deve JUNTAR-SE à transação externa, não aninhar.
          AppDatabase.runInTransaction(db, () {
            db.execute(
              'INSERT INTO sales '
              '(id, total_amount, payment_method, date_time) '
              "VALUES ('s1', 4.0, 'mPesa', 100)",
            );
            db.execute(
              'INSERT INTO sale_items '
              '(sale_id, product_id, product_name, quantity, unit_price) '
              "VALUES ('s1', 'p1', 'Caneta', 2, 2.0)",
            );
          });
          // Falha APÓS o aninhado → o rollback externo desfaz também a venda.
          db.execute(
            'INSERT INTO products '
            '(id, name, description, purchase_price, sale_price, '
            'stock_quantity) VALUES (?, ?, ?, ?, ?, ?)',
            ['c', null, '', 1.0, 2.0, 1],
          );
        }),
        throwsA(isA<SqliteException>()),
      );

      // Nada foi gravado: a venda aninhada foi desfeita junto com o resto.
      expect(productCount(), 0);
      expect(db.select('SELECT COUNT(*) AS c FROM sales').first['c'], 0);
      expect(db.select('SELECT COUNT(*) AS c FROM sale_items').first['c'], 0);
    },
  );

  test('execuções concorrentes são serializadas na fila (FIFO)', () async {
    final uow = SqliteUnitOfWork(db);

    await Future.wait([
      uow.run(() async {
        db.execute(
          'INSERT INTO products '
          '(id, name, description, purchase_price, sale_price, '
          'stock_quantity) VALUES (?, ?, ?, ?, ?, ?)',
          ['a', 'A', '', 1.0, 2.0, 1],
        );
      }),
      uow.run(() async {
        db.execute(
          'INSERT INTO products '
          '(id, name, description, purchase_price, sale_price, '
          'stock_quantity) VALUES (?, ?, ?, ?, ?, ?)',
          ['b', 'B', '', 1.0, 2.0, 1],
        );
      }),
    ]);

    // Sem a fila, o segundo BEGIN falharia (transação aninhada).
    expect(productCount(), 2);
  });

  test('contador de profundidade volta a zero após falha (nova transação '
      'funciona)', () async {
    final uow = SqliteUnitOfWork(db);

    // Uma execução que falha e faz rollback.
    await expectLater(
      uow.run(() async {
        db.execute(
          'INSERT INTO products '
          '(id, name, description, purchase_price, sale_price, '
          'stock_quantity) VALUES (?, ?, ?, ?, ?, ?)',
          ['a', null, '', 1.0, 2.0, 1],
        );
      }),
      throwsA(isA<SqliteException>()),
    );

    // A conexão continua limpa: a próxima transação funciona normalmente
    // (guard contra vazamento de profundidade).
    await uow.run(() async {
      db.execute(
        'INSERT INTO products '
        '(id, name, description, purchase_price, sale_price, '
        'stock_quantity) VALUES (?, ?, ?, ?, ?, ?)',
        ['b', 'B', '', 1.0, 2.0, 1],
      );
    });

    expect(productCount(), 1);
  });
}
