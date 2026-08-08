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
    tempDirectory = await Directory.systemTemp.createTemp('dumbhanengue_test');
    dbPath = '${tempDirectory.path}${Platform.pathSeparator}test.db';
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('abre arquivo e cria schema vazio (sem dados de demonstração)', () {
    final db = sqlite3.open(dbPath);
    AppDatabase.initialize(db);

    // O app não semeia NADA: o banco nasce com o schema criado e vazio —
    // só registra dados REAIS criados pelo usuário.
    for (final table in [
      'products',
      'sales',
      'sale_items',
      'financial_transactions',
      'debts',
      'customers',
      'purchases',
      'purchase_items',
    ]) {
      expect(
        db.select('SELECT COUNT(*) AS c FROM $table').first['c'],
        0,
        reason: 'tabela $table deveria nascer vazia',
      );
    }

    db.close();
  });

  test('dados reais persistem entre aberturas (sem seed)', () async {
    // Primeira abertura: cria o schema vazio.
    final first = sqlite3.open(dbPath);
    AppDatabase.initialize(first);
    first.close();

    // Segunda abertura: continua VAZIO (nada é semeado).
    final second = sqlite3.open(dbPath);
    AppDatabase.initialize(second);
    expect(second.select('SELECT COUNT(*) AS c FROM products').first['c'], 0);

    // Round-trip real via datasource sobre o arquivo.
    final dataSource = ProductSqliteDataSourceImpl(second);
    await dataSource.add(
      const Product(
        id: 'novo',
        name: 'Produto novo',
        purchasePriceCents: 200,
        salePriceCents: 400,
        stockQuantity: 3,
      ),
    );
    expect(
      (await dataSource.getById('novo', storeId: 'st1'))?.stockQuantity,
      3,
    );

    second.close();

    // Terceira abertura: o produto adicionado continua lá (persistência
    // real) e nenhum dado de demonstração apareceu.
    final third = sqlite3.open(dbPath);
    expect(
      (await ProductSqliteDataSourceImpl(third).getById('novo', storeId: 'st1'))
          ?.name,
      'Produto novo',
    );
    expect(third.select('SELECT COUNT(*) AS c FROM products').first['c'], 1);
    third.close();
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

    db.close();
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

    db.close();
  });

  test('migra vendas antigas com forma de pagamento pix para mPesa', () {
    final db = sqlite3.open(dbPath);

    // Simula um banco criado antes da troca Pix → M-Pesa/E-Mola: o enum é
    // persistido pelo NOME, então uma venda 'pix' quebraria a leitura
    // (PaymentMethod.values.byName('pix') lança) sem a migração.
    db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL DEFAULT 'st1',
        sale_number INTEGER NOT NULL DEFAULT 0,
        total_amount INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        date_time INTEGER NOT NULL
      );
    ''');
    db.execute(
      "INSERT INTO sales (id, total_amount, payment_method, date_time) "
      "VALUES ('s1', 400, 'pix', 100)",
    );

    AppDatabase.createSchema(db);

    // A venda foi reescrita para 'mPesa' (escolha do produto: M-Pesa é a
    // operadora dominante) — a leitura via values.byName volta a funcionar.
    expect(
      db.select("SELECT payment_method FROM sales WHERE id = 's1'")
          .first['payment_method'],
      'mPesa',
    );

    db.close();
  });

  test('adiciona forma de pagamento em compras antigas (backfill cash)', () {
    final db = sqlite3.open(dbPath);

    // Simula um banco criado antes da coluna `payment_method` (compras
    // antigas não registravam o método do fornecedor).
    db.execute('''
      CREATE TABLE purchases (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL DEFAULT 'st1',
        purchase_number INTEGER NOT NULL DEFAULT 0,
        supplier_name TEXT NOT NULL,
        total_amount INTEGER NOT NULL,
        date_time INTEGER NOT NULL
      );
    ''');
    db.execute(
      "INSERT INTO purchases "
      "(id, supplier_name, total_amount, date_time) "
      "VALUES ('pc1', 'Fornecedor', 2000, 100)",
    );

    AppDatabase.createSchema(db);

    // A coluna foi adicionada e a compra existente virou 'cash' (compra à
    // vista) — a leitura via PaymentMethod.values.byName não quebra.
    final columns = db.select('PRAGMA table_info(purchases)').map((r) => r['name']);
    expect(columns, contains('payment_method'));
    expect(
      db.select("SELECT payment_method FROM purchases WHERE id = 'pc1'")
          .first['payment_method'],
      'cash',
    );

    db.close();
  });
}
