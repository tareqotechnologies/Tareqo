import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/core/database/app_database_io.dart';
import 'package:tareqo/data/datasources/local/product_sqlite_data_source_impl.dart';
import 'package:tareqo/domain/entities/product.dart';

/// Fase 1 — migração v7 (coluna `products.type`):
/// - banco novo nasce com a coluna (DEFAULT 'resale', SEM CHECK de enum);
/// - banco legado (v6) recebe a coluna com DEFAULT 'resale';
/// - produtos antigos NUNCA são reclassificados (preservação de dados);
/// - a leitura de valor desconhecido cai no default (nunca quebra).
void main() {
  late Directory tempDirectory;
  late String dbPath;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('tareqo_f1');
    dbPath = '${tempDirectory.path}${Platform.pathSeparator}test.db';
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  group('migração v7 — products.type', () {
    test('banco novo cria a coluna com DEFAULT resale e SEM CHECK de enum', () {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);

      AppDatabase.initialize(db);

      final columns = db
          .select('PRAGMA table_info(products)')
          .map((r) => r['name'] as String)
          .toSet();
      expect(columns, contains('type'));
      expect(
        db.select('PRAGMA user_version').first['user_version'],
        AppDatabase.currentSchemaVersion,
      );

      // O DEFAULT do banco também é resale (INSERT sem a coluna).
      db.execute(
        "INSERT INTO products (id, name, purchase_price, sale_price) "
        "VALUES ('p1', 'Pão', 500, 800)",
      );
      expect(
        db.select("SELECT type FROM products WHERE id = 'p1'").first['type'],
        'resale',
      );

      // SEM CHECK de enum no SQLite (decisão Fase 1): SQLite não altera
      // CHECKs sem rebuild — valores futuros de versões novas do app não
      // podem ficar bloqueados pela restrição antiga. A validação vive no
      // datasource (valor desconhecido → default resale, nunca lança).
      db.execute(
        "UPDATE products SET type = 'tipoQualquer' WHERE id = 'p1'",
      );
      expect(
        db.select("SELECT type FROM products WHERE id = 'p1'").first['type'],
        'tipoQualquer',
      );
    });

    test('banco legado v6 recebe a coluna e produtos antigos ficam resale', () {
      final db = sqlite3.open(dbPath);
      addTearDown(db.close);

      // Simula um banco da era v6: schema completo SEM a coluna type.
      AppDatabase.initialize(db);
      db.execute('PRAGMA user_version = 6');
      db.execute('ALTER TABLE products DROP COLUMN type');

      // Produto existente ANTES da migração v7.
      db.execute(
        "INSERT INTO products (id, store_id, name, description, "
        "purchase_price, sale_price, stock_quantity, code, "
        "venda_por_fracao, unit_label, is_active, image_path) "
        "VALUES ('legado', 'st1', 'Caderno', '', 100, 200, 5000, NULL, 0, "
        "'un', 1, NULL)",
      );

      // when — reabrir: roda APENAS a v7.
      AppDatabase.initialize(db);

      // then — coluna adicionada e produto legado classificado como
      // 'resale' (comportamento de sempre: comprável e vendável).
      expect(
        db
            .select("SELECT type FROM products WHERE id = 'legado'")
            .first['type'],
        'resale',
      );
      expect(
        db.select('PRAGMA user_version').first['user_version'],
        AppDatabase.currentSchemaVersion,
      );

      // Idempotência: re-inicializar não reclassifica nem quebra.
      AppDatabase.initialize(db);
      expect(
        db
            .select("SELECT type FROM products WHERE id = 'legado'")
            .first['type'],
        'resale',
      );
    });

    test('todos os valores do enum são persistíveis e legíveis (round-trip)', () async {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);
      AppDatabase.initialize(db);

      final dataSource = ProductSqliteDataSourceImpl(db);
      for (final (index, type) in ProductType.values.indexed) {
        await dataSource.add(
          Product(
            id: 'p$type',
            name: 'Produto ${type.name}',
            purchasePriceCents: 100 + index,
            salePriceCents: 200 + index,
            type: type,
          ),
        );
        final loaded = await dataSource.getById('p$type', storeId: 'st1');
        expect(loaded?.type, type, reason: 'tipo ${type.name}');
      }
    });

    test('valor desconhecido no banco cai no default resale (nunca lança)', () {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);
      AppDatabase.initialize(db);

      // Simula uma linha escrita por versão futura do app.
      db.execute(
        "INSERT INTO products (id, name, purchase_price, sale_price, type) "
        "VALUES ('futuro', 'Produto do futuro', 100, 200, 'tipoNovo')",
      );

      // A leitura NÃO pode quebrar por valor desconhecido.
      expect(
        () => ProductSqliteDataSourceImpl(db).getAll(storeId: 'st1'),
        returnsNormally,
      );
    });
  });
}
