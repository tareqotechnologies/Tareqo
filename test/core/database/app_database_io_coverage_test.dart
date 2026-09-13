import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/core/database/app_database_io.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/data/datasources/local/cash_closing_local_data_source.dart';
import 'package:tareqo/data/datasources/local/custom_invoice_local_data_source.dart';
import 'package:tareqo/data/datasources/local/customer_local_data_source.dart';
import 'package:tareqo/data/datasources/local/debt_local_data_source.dart';
import 'package:tareqo/data/datasources/local/employee_management_local_data_source.dart';
import 'package:tareqo/data/datasources/local/financial_transaction_local_data_source.dart';
import 'package:tareqo/data/datasources/local/pending_op_queue.dart';
import 'package:tareqo/data/datasources/local/product_local_data_source.dart';
import 'package:tareqo/data/datasources/local/purchase_local_data_source.dart';
import 'package:tareqo/data/datasources/local/quotation_local_data_source.dart';
import 'package:tareqo/data/datasources/local/sale_local_data_source.dart';
import 'package:tareqo/data/datasources/local/stock_lot_local_data_source.dart';
import 'package:tareqo/domain/repositories/i_unit_of_work.dart';

/// Fake do [PathProviderPlatform] — documentos em temp real (mesmo padrão
/// dos testes de share/exporters): o `openAppDatabase` grava `tareqo.db`
/// em `<docs>/tareqo.db`.
class _FakePathProvider extends PathProviderPlatform {
  late Directory docsDir;

  @override
  Future<String?> getApplicationDocumentsPath() async => docsDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  final fakePP = _FakePathProvider();
  final originalPP = PathProviderPlatform.instance;

  setUpAll(() async {
    // UM diretório para a suíte inteira: o AppDatabase mantém a conexão
    // em um static (o arquivo fica aberto no Windows — não pode apagar
    // entre testes).
    tempDirectory = await Directory.systemTemp.createTemp('tareqo_io');
    fakePP.docsDir = tempDirectory;
    PathProviderPlatform.instance = fakePP;
  });

  tearDownAll(() {
    PathProviderPlatform.instance = originalPP;
    // Best-effort: a conexão estática permanece aberta e o Windows pode
    // segurar o lock — a limpeza do SO cuida do temp residual.
    try {
      tempDirectory.deleteSync(recursive: true);
    } on FileSystemException {
      // Ignorado deliberadamente.
    }
  });

  group('AppDatabase sem banco aberto', () {
    // Este grupo roda ANTES de qualquer openAppDatabase — o static
    // `_database` é global ao processo e nunca volta a null.
    test('registerDatasources falha rápido (assert) sem banco em debug', () {
      // given — GetIt limpo, sem openAppDatabase.
      final getIt = GetIt.asNewInstance();
      addTearDown(getIt.reset);

      // when / then — o guard de contrato dispara em modo debug
      // (release: assert removido e o guard `db == null` é no-op).
      expect(
        () => AppDatabase.registerDatasources(getIt),
        throwsA(isA<AssertionError>()),
      );
    });

    test('registerOfflineQueue sem banco é no-op silencioso (sem lançar)', () {
      // given — a fila usa guard simples, sem assert.
      final getIt = GetIt.asNewInstance();
      addTearDown(getIt.reset);

      // when / then — guard `db == null` desvia sem registrar.
      AppDatabase.registerOfflineQueue(getIt);
      expect(getIt.isRegistered<IPendingOpQueue>(), isFalse);
    });
  });

  group('AppDatabase.openAppDatabase', () {
    test('deve abrir tareqo.db nos documentos e ativar o SQLite', () async {
      // when
      final ok = await AppDatabase.openAppDatabase();

      // then — persistência real: arquivo existe.
      expect(ok, isTrue);
      expect(
        File(
          '${tempDirectory.path}${Platform.pathSeparator}tareqo.db',
        ).existsSync(),
        isTrue,
      );
    });

    test('deve deixar o banco pronto para registrar os datasources', () async {
      // given — ordem do bootstrap: open antes de register.
      final getIt = GetIt.asNewInstance();
      addTearDown(getIt.reset);

      // when
      await AppDatabase.openAppDatabase();
      AppDatabase.registerDatasources(getIt);

      // then — o contrato do bootstrap: os 10 datasources de negócio +
      // a unidade de trabalho ficam resolvíveis.
      expect(getIt.isRegistered<IUnitOfWork>(), isTrue);
      expect(getIt.isRegistered<ProductLocalDataSource>(), isTrue);
      expect(getIt.isRegistered<SaleLocalDataSource>(), isTrue);
      expect(getIt.isRegistered<FinancialTransactionLocalDataSource>(), isTrue);
      expect(getIt.isRegistered<DebtLocalDataSource>(), isTrue);
      expect(getIt.isRegistered<CustomerLocalDataSource>(), isTrue);
      expect(getIt.isRegistered<PurchaseLocalDataSource>(), isTrue);
      expect(getIt.isRegistered<StockLotLocalDataSource>(), isTrue);
      expect(getIt.isRegistered<CashClosingLocalDataSource>(), isTrue);
      expect(getIt.isRegistered<CustomInvoiceLocalDataSource>(), isTrue);
      expect(getIt.isRegistered<QuotationLocalDataSource>(), isTrue);
      expect(getIt.isRegistered<EmployeeManagementLocalDataSource>(), isTrue);
    });

    test('deve resolver datasources que falam com o MESMO banco', () async {
      // given
      final getIt = GetIt.asNewInstance();
      addTearDown(getIt.reset);
      await AppDatabase.openAppDatabase();
      AppDatabase.registerDatasources(getIt);

      // when — grava via o datasource registrado e lê direto do arquivo.
      final products = getIt<ProductLocalDataSource>();
      await products.add(
        const Product(
          id: 'p1',
          storeId: 'st1',
          name: 'Arroz',
          purchasePriceCents: 500,
          salePriceCents: 900,
          stockQuantity: 1000,
        ),
      );

      // then — a gravação foi no tareqo.db persistido (não em memória).
      final db = sqlite3.open(
        '${tempDirectory.path}${Platform.pathSeparator}tareqo.db',
      );
      final row = db.select("SELECT name FROM products WHERE id = 'p1'");
      expect(row, hasLength(1));
      expect(row.first['name'], 'Arroz');
      db.close();
    });

    test('registerOfflineQueue deve registrar a fila no MESMO banco', () async {
      // given
      final getIt = GetIt.asNewInstance();
      addTearDown(getIt.reset);
      await AppDatabase.openAppDatabase();

      // when
      AppDatabase.registerOfflineQueue(getIt);

      // then
      expect(getIt.isRegistered<IPendingOpQueue>(), isTrue);
    });
  });

  group('transações re-entrantes', () {
    test('begin aninhado não abre segunda transação (SQLite rejeitaria)', () {
      // given
      final db = sqlite3.openInMemory();
      addTearDown(db.close);
      db.execute('CREATE TABLE t (v INTEGER);');

      // when — begin externo + begin aninhado.
      AppDatabase.beginTransaction(db);
      AppDatabase.beginTransaction(db); // apenas incrementa profundidade.
      db.execute('INSERT INTO t VALUES (1);');

      // then — o commit ANINHADO não emite COMMIT; só o externo.
      AppDatabase.commitTransaction(db); // aninhado: só decrementa.
      AppDatabase.commitTransaction(db); // externo: COMMIT real.
      // Dado gravado: nenhuma exceção de "transaction within a transaction".
      expect(db.select('SELECT COUNT(*) AS c FROM t').first['c'], 1);
    });

    test(
      'rollback aninhado encerra a transação real (sharp edge documentado)',
      () {
        // given — o rollback aninhado decrementa e, ao chegar a profundidade
        // zero, emite ROLLBACK de verdade na conexão compartilhada.
        final db = sqlite3.openInMemory();
        addTearDown(db.close);
        db.execute('CREATE TABLE t (v INTEGER);');

        // when — externo abre e grava; o rollback "aninhado" fecha TUDO.
        AppDatabase.beginTransaction(db);
        db.execute('INSERT INTO t VALUES (1);');
        AppDatabase.rollbackTransaction(
          db,
        ); // profundidade 1 → 0: ROLLBACK real.

        // then — o trabalho foi desfeito e não há transação ativa (o
        // commit seguinte falharia rápido com o assert de contrato).
        expect(db.select('SELECT COUNT(*) AS c FROM t').first['c'], 0);
        expect(
          () => AppDatabase.commitTransaction(db),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test('runInTransaction aninhado se junta à transação externa', () {
      // given — o IUnitOfWork real envolve chamadas que por si usam
      // runInTransaction; aninhamento deve funcionar sem exceção.
      final db = sqlite3.openInMemory();
      addTearDown(db.close);
      db.execute('CREATE TABLE t (v INTEGER);');

      // when
      AppDatabase.runInTransaction(db, () {
        AppDatabase.runInTransaction(db, () {
          db.execute('INSERT INTO t VALUES (7);');
        });
      });

      // then — commit único do externo persistiu o insert do interno.
      expect(db.select('SELECT COUNT(*) AS c FROM t').first['c'], 1);
    });

    test(
      'runInTransaction externo faz rollback de TUDO em erro do interno',
      () {
        // given
        final db = sqlite3.openInMemory();
        addTearDown(db.close);
        db.execute('CREATE TABLE t (v INTEGER);');

        // when — o interno grava e depois o externo falha.
        expect(
          () => AppDatabase.runInTransaction(db, () {
            AppDatabase.runInTransaction(db, () {
              db.execute('INSERT INTO t VALUES (1);');
            });
            throw StateError('falha no externo');
          }),
          throwsStateError,
        );

        // then — nada persistiu (rollback do externo pegou o insert do
        // interno que se juntou à MESMA transação).
        expect(db.select('SELECT COUNT(*) AS c FROM t').first['c'], 0);
      },
    );
  });

  group('migração W4 (dinheiro REAL → centavos INTEGER)', () {
    test('deve multiplicar valores legados por 100 e carimbar a versão', () {
      // given — banco legado: schema antigo com dinheiro como REAL e sem
      // versionamento (user_version = 0).
      final db = sqlite3.openInMemory();
      addTearDown(db.close);
      db.execute('''
        CREATE TABLE products (
          id TEXT PRIMARY KEY,
          purchase_price REAL NOT NULL,
          sale_price REAL NOT NULL,
          stock_quantity INTEGER NOT NULL DEFAULT 0
        );
      ''');
      db.execute("INSERT INTO products VALUES ('p1', 12.5, 20.0, 1);");
      db.execute("INSERT INTO products VALUES ('p2', 0.99, 1.5, 1);");

      // when
      AppDatabase.initialize(db);

      // then — valores viraram centavos inteiros (12.5 → 1250).
      final rows = db.select(
        'SELECT id, purchase_price, sale_price FROM products ORDER BY id',
      );
      expect((rows.first['purchase_price'] as num).toInt(), 1250);
      expect((rows.first['sale_price'] as num).toInt(), 2000);
      expect((rows.last['purchase_price'] as num).toInt(), 99);
      expect((rows.last['sale_price'] as num).toInt(), 150);
      // Versão carimbada: migração não reexecuta (idempotência).
      expect(
        db.select('PRAGMA user_version').first['user_version'],
        AppDatabase.currentSchemaVersion,
      );
    });

    test('deve preservar colunas de não-dinheiro (estoque intacto)', () {
      // given — schema legado REAL (purchase_price NOT NULL, como o
      // schema antigo) com estoque em unidades.
      final db = sqlite3.openInMemory();
      addTearDown(db.close);
      db.execute('''
        CREATE TABLE products (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          purchase_price REAL NOT NULL,
          sale_price REAL NOT NULL,
          stock_quantity INTEGER NOT NULL DEFAULT 0
        );
      ''');
      db.execute("INSERT INTO products VALUES ('p1', 'Arroz', 10.0, 15.0, 3);");

      // when
      AppDatabase.initialize(db);

      // then — dinheiro ×100 (W4) e estoque convertido de unidades para
      // MILÉSIMOS (W11 — banco legado sem a coluna `code` passa pela
      // conversão completa; 3 unidades → 3000 milésimos) + lote inicial
      // FIFO criado com custo = preço de compra já migrado.
      // (Coluna REAL preserva afinidade: o driver devolve num/double.)
      final row = db.select(
        "SELECT purchase_price, sale_price, stock_quantity FROM products",
      );
      expect((row.first['purchase_price'] as num).toInt(), 1000);
      expect((row.first['sale_price'] as num).toInt(), 1500);
      expect(row.first['stock_quantity'], 3000);
      final lot = db.select(
        "SELECT current_quantity, cost_price FROM stock_lots "
        "WHERE product_id = 'p1'",
      );
      expect(lot, hasLength(1));
      expect(lot.first['current_quantity'], 3000);
      expect((lot.first['cost_price'] as num).toInt(), 1000); // em centavos.
    });

    test('banco já migrado (INTEGER) não é multiplicado de novo', () {
      // given — banco novo: initialize cria o schema INTEGER completo.
      final db = sqlite3.openInMemory();
      addTearDown(db.close);
      AppDatabase.initialize(db);
      db.execute(
        "INSERT INTO products (id, name, purchase_price, sale_price, "
        "stock_quantity) VALUES ('p1', 'Arroz', 500, 900, 1000)",
      );

      // Reabrir/reinicializar um banco já versionado é fast path.
      final versionBefore = db
          .select('PRAGMA user_version')
          .first['user_version'];
      AppDatabase.initialize(db);

      // when / then — preço continua 500 centavos (não virou 50000).
      final row = db.select(
        "SELECT purchase_price FROM products WHERE id = 'p1'",
      );
      expect(row.first['purchase_price'], 500);
      expect(
        db.select('PRAGMA user_version').first['user_version'],
        versionBefore,
      );
    });
  });
}
