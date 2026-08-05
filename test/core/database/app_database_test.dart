import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:dumbhanengue/core/database/app_database_io.dart';
import 'package:dumbhanengue/data/datasources/local/product_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/domain/entities/product.dart';

void main() {
  late Directory tempDirectory;
  late String dbPath;

  setUp(() async {
    AppDatabase.configureLoader();
    tempDirectory = await Directory.systemTemp.createTemp('dumbhanengue_test');
    dbPath = '${tempDirectory.path}${Platform.pathSeparator}test.db';
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('abre arquivo, cria schema e semeia dados demo (produção)', () {
    final db = sqlite3.open(dbPath);
    AppDatabase.initialize(db);

    // Seed da demonstração presente após a primeira inicialização
    // (Fase 2: 7 produtos e 4 vendas — 2 produtos e 1 venda extra da
    // Loja Shopping para demonstrar o escopo por loja).
    expect(db.select('SELECT COUNT(*) AS c FROM products').first['c'], 7);
    expect(db.select('SELECT COUNT(*) AS c FROM sales').first['c'], 4);
    expect(db.select('SELECT COUNT(*) AS c FROM sale_items').first['c'], 5);
    expect(
      db.select('SELECT COUNT(*) AS c FROM financial_transactions').first['c'],
      10,
    );
    expect(db.select('SELECT COUNT(*) AS c FROM debts').first['c'], 5);
    expect(db.select('SELECT COUNT(*) AS c FROM customers').first['c'], 4);
    expect(db.select('SELECT COUNT(*) AS c FROM purchases').first['c'], 2);

    db.dispose();
  });

  test('dados persistem entre aberturas e seed não duplica', () async {
    // Primeira abertura: cria + semeia.
    final first = sqlite3.open(dbPath);
    AppDatabase.initialize(first);
    first.dispose();

    // Segunda abertura: o seed NÃO deve duplicar os dados.
    final second = sqlite3.open(dbPath);
    AppDatabase.initialize(second);

    expect(second.select('SELECT COUNT(*) AS c FROM products').first['c'], 7);

    // Round-trip real via datasource sobre o arquivo.
    final dataSource = ProductSqliteDataSourceImpl(second);
    await dataSource.add(
      const Product(
        id: 'novo',
        name: 'Produto novo',
        purchasePrice: 2.0,
        salePrice: 4.0,
        stockQuantity: 3,
      ),
    );
    expect(
      (await dataSource.getById('novo', storeId: 'st1'))?.stockQuantity,
      3,
    );

    second.dispose();

    // Terceira abertura: o produto adicionado continua lá.
    final third = sqlite3.open(dbPath);
    expect(
      (await ProductSqliteDataSourceImpl(third).getById('novo', storeId: 'st1'))
          ?.name,
      'Produto novo',
    );
    third.dispose();
  });

  test('migra banco existente sem as colunas is_paid e paid_at', () {
    final db = sqlite3.open(dbPath);

    // Simula um banco criado ANTES das colunas de baixa do fiado.
    db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        person_name TEXT NOT NULL,
        amount REAL NOT NULL,
        due_date INTEGER NOT NULL,
        is_customer_debt INTEGER NOT NULL
      );
    ''');
    db.execute(
      "INSERT INTO debts "
      "(id, person_name, amount, due_date, is_customer_debt) "
      "VALUES ('d1', 'João', 25.0, 100, 1)",
    );

    AppDatabase.createSchema(db);

    // `is_paid` adicionada com DEFAULT 0 → dívida existente fica pendente,
    // sem perda de dados; `paid_at` adicionada como NULL (sem data de baixa).
    final columns = db.select('PRAGMA table_info(debts)').map((r) => r['name']);
    expect(columns, contains('is_paid'));
    expect(columns, contains('paid_at'));
    expect(
      db.select('SELECT is_paid FROM debts WHERE id = ?', [
        'd1',
      ]).first['is_paid'],
      0,
    );
    expect(
      db.select('SELECT paid_at FROM debts WHERE id = ?', [
        'd1',
      ]).first['paid_at'],
      isNull,
    );

    db.dispose();
  });

  test('transação faz rollback em caso de erro', () {
    final db = sqlite3.open(dbPath);
    AppDatabase.createSchema(db);

    expect(
      () => AppDatabase.runInTransaction(db, () {
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
    expect(db.select('SELECT COUNT(*) AS c FROM products').first['c'], 0);

    db.dispose();
  });
}
