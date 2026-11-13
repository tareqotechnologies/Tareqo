import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/core/database/app_database_io.dart';
import 'package:tareqo/data/datasources/local/product_sqlite_data_source_impl.dart';
import 'package:tareqo/domain/entities/product.dart';

/// Categorização do produto — migração v10 (coluna `products.category`):
/// - banco novo nasce com a coluna (nullable, sem default);
/// - banco legado (v9) recebe a coluna sem perder dados;
/// - leitura de NULL devolve categoria vazia (nunca lança);
/// - idempotente: reabrir não duplica a coluna.
void main() {
  late Directory tempDirectory;
  late String dbPath;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('tareqo_cat');
    dbPath = '${tempDirectory.path}${Platform.pathSeparator}test.db';
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  group('migração v10 — products.category', () {
    test('banco novo cria a coluna nullable', () {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);

      AppDatabase.initialize(db);

      final columns = db
          .select('PRAGMA table_info(products)')
          .map((r) => r['name'] as String)
          .toSet();
      expect(columns, contains('category'));
      expect(
        db.select('PRAGMA user_version').first['user_version'],
        AppDatabase.currentSchemaVersion,
      );

      // Sem categoria o INSERT grava NULL (opcional por natureza).
      db.execute(
        "INSERT INTO products (id, name, purchase_price, sale_price) "
        "VALUES ('p1', 'Pão', 500, 800)",
      );
      expect(
        db
            .select("SELECT category FROM products WHERE id = 'p1'")
            .first['category'],
        isNull,
      );
    });

    test('banco legado v9 recebe a coluna e mantém os produtos', () {
      final db = sqlite3.open(dbPath);
      addTearDown(db.close);

      // Simula um banco da era v9: schema completo SEM a coluna category.
      AppDatabase.initialize(db);
      db.execute('PRAGMA user_version = 9');
      db.execute('ALTER TABLE products DROP COLUMN category');

      // Produto existente ANTES da migração v10.
      db.execute(
        "INSERT INTO products (id, store_id, name, description, "
        "purchase_price, sale_price, stock_quantity, code, "
        "venda_por_fracao, unit_label, is_active, image_path, type) "
        "VALUES ('legado', 'st1', 'Caderno', '', 100, 200, 5000, NULL, 0, "
        "'un', 1, NULL, 'resale')",
      );

      // when — reabrir: roda APENAS a v10.
      AppDatabase.initialize(db);

      // then — coluna adicionada, produto preservado e sem categoria.
      expect(
        db
            .select("SELECT category FROM products WHERE id = 'legado'")
            .first['category'],
        isNull,
      );
      expect(
        db.select('PRAGMA user_version').first['user_version'],
        AppDatabase.currentSchemaVersion,
      );

      // Idempotência: re-inicializar não duplica a coluna nem quebra.
      AppDatabase.initialize(db);
      final names = db
          .select('PRAGMA table_info(products)')
          .map((r) => r['name'] as String)
          .toList();
      expect(names.where((name) => name == 'category'), hasLength(1));
    });

    test('categoria faz round-trip pelo datasource SQLite', () async {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);
      AppDatabase.initialize(db);

      final dataSource = ProductSqliteDataSourceImpl(db);
      await dataSource.add(
        const Product(
          id: 'p1',
          name: 'Sumo de laranja',
          purchasePriceCents: 300,
          salePriceCents: 500,
          category: 'Bebidas',
        ),
      );

      expect(
        (await dataSource.getById('p1', storeId: 'st1'))?.category,
        'Bebidas',
      );
    });
  });
}
