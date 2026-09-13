import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tareqo/core/database/app_database_io.dart';
import 'package:tareqo/data/datasources/local/cash_closing_local_data_source.dart';
import 'package:tareqo/data/datasources/local/custom_invoice_local_data_source.dart';
import 'package:tareqo/data/datasources/local/customer_local_data_source.dart';
import 'package:tareqo/data/datasources/local/debt_local_data_source.dart';
import 'package:tareqo/data/datasources/local/employee_management_local_data_source.dart';
import 'package:tareqo/data/datasources/local/financial_transaction_local_data_source.dart';
import 'package:tareqo/data/datasources/local/pending_op_queue.dart';
import 'package:tareqo/data/datasources/local/pending_op_queue_sqlite_impl.dart';
import 'package:tareqo/data/datasources/local/product_local_data_source.dart';
import 'package:tareqo/data/datasources/local/product_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/sale_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/financial_transaction_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/debt_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/customer_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/purchase_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/stock_lot_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/cash_closing_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/custom_invoice_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/quotation_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/employee_management_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/sqlite_unit_of_work.dart';
import 'package:tareqo/data/datasources/local/purchase_local_data_source.dart';
import 'package:tareqo/data/datasources/local/quotation_local_data_source.dart';
import 'package:tareqo/data/datasources/local/sale_local_data_source.dart';
import 'package:tareqo/data/datasources/local/stock_lot_local_data_source.dart';
import 'package:tareqo/domain/repositories/i_unit_of_work.dart';

/// Fake do [PathProviderPlatform] para o teste que abre o banco real.
class _FakePathProvider extends PathProviderPlatform {
  late Directory docsDir;

  @override
  Future<String?> getApplicationDocumentsPath() async => docsDir.path;
}

/// Banco legado do PIOR CASO: pré-versionamento, sem numeração, sem
/// status de anulação, sem forma de pagamento, sem validade — a v1
/// precisa preencher tudo sem perder dados.
void _createLegacyTables(Database db) {
  db.execute('''
    CREATE TABLE products (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      purchase_price REAL NOT NULL,
      sale_price REAL NOT NULL,
      stock_quantity INTEGER NOT NULL DEFAULT 0
    );
  ''');
  db.execute('''
    CREATE TABLE sales (
      id TEXT PRIMARY KEY,
      total_amount REAL NOT NULL,
      payment_method TEXT NOT NULL,
      date_time INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE sale_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id TEXT NOT NULL,
      product_id TEXT NOT NULL,
      product_name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      unit_price REAL NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE financial_transactions (
      id TEXT PRIMARY KEY,
      description TEXT NOT NULL,
      amount REAL NOT NULL,
      type TEXT NOT NULL,
      category TEXT NOT NULL,
      date INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE debts (
      id TEXT PRIMARY KEY,
      person_name TEXT NOT NULL,
      amount REAL NOT NULL,
      due_date INTEGER NOT NULL,
      is_customer_debt INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE customers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      phone TEXT NOT NULL DEFAULT '',
      email TEXT NOT NULL DEFAULT ''
    );
  ''');
  db.execute('''
    CREATE TABLE purchases (
      id TEXT PRIMARY KEY,
      supplier_name TEXT NOT NULL,
      total_amount REAL NOT NULL,
      date_time INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE purchase_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      purchase_id TEXT NOT NULL,
      product_id TEXT NOT NULL,
      product_name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      unit_price REAL NOT NULL
    );
  ''');

  // Dados legados: 3 vendas, 2 compras, 2 dívidas em ordem aleatória
  // (a re-numeração deve seguir a DATA, não a ordem de inserção).
  db.execute('''
    INSERT INTO products VALUES ('p1', 'Arroz', 10.0, 15.0, 5);
  ''');
  db.execute('''
    INSERT INTO sales VALUES ('s2', 20.0, 'pix', 2000);
  ''');
  db.execute('''
    INSERT INTO sales VALUES ('s1', 10.0, 'cash', 1000);
  ''');
  db.execute('''
    INSERT INTO sales VALUES ('s3', 30.0, 'cash', 3000);
  ''');
  db.execute('''
    INSERT INTO purchases VALUES ('pc2', 'Fornecedor B', 200.0, 2000);
  ''');
  db.execute('''
    INSERT INTO purchases VALUES ('pc1', 'Fornecedor A', 100.0, 1000);
  ''');
  db.execute('''
    INSERT INTO debts VALUES ('d2', 'Maria', 50.0, 2000, 1);
  ''');
  db.execute('''
    INSERT INTO debts VALUES ('d1', 'João', 30.0, 1000, 1);
  ''');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Diretório de documentos para o teste que abre o banco real (a conexão
  // fica no static global — um temp por suíte, best-effort no fim).
  late Directory suiteTemp;
  final fakePP = _FakePathProvider();
  final originalPP = PathProviderPlatform.instance;

  setUpAll(() async {
    suiteTemp = await Directory.systemTemp.createTemp('tareqo_legacy');
    fakePP.docsDir = suiteTemp;
    PathProviderPlatform.instance = fakePP;
  });

  tearDownAll(() {
    PathProviderPlatform.instance = originalPP;
    try {
      suiteTemp.deleteSync(recursive: true);
    } on FileSystemException {
      // Conexão estática ainda aberta — o SO cuida do temp residual.
    }
  });

  group('migração do pior caso legado (backfills da v1)', () {
    test('deve re-numerar por data, adicionar colunas e interpretar pix', () {
      // given — banco da era pré-versionamento com dados reais.
      final db = sqlite3.openInMemory();
      addTearDown(db.close);
      _createLegacyTables(db);

      // when
      AppDatabase.initialize(db);

      // then — numeração de VENDAS por data dentro da loja (s1=1, s2=2,
      // s3=3) e pix legado reinterpretado como mPesa (troca de produto).
      final sales = db
          .select('SELECT id, sale_number, payment_method FROM sales')
          .map(
            (r) => (
              r['id'] as String,
              r['sale_number'] as int,
              r['payment_method'] as String,
            ),
          )
          .toList();
      final s1 = sales.firstWhere((s) => s.$1 == 's1');
      final s2 = sales.firstWhere((s) => s.$1 == 's2');
      final s3 = sales.firstWhere((s) => s.$1 == 's3');
      expect(s1.$2, 1);
      expect(s2.$2, 2);
      expect(s3.$2, 3);
      expect(s2.$3, 'mPesa'); // pix → mPesa (carteiras de Moçambique).
      // Colunas de anulação nascem com todas as vendas ativas.
      final statuses = db
          .select('SELECT status FROM sales')
          .map((r) => r['status'] as String)
          .toSet();
      expect(statuses, {'active'});

      // then — numeração de COMPRAS por data (pc1=1, pc2=2) e forma de
      // pagamento backfillada como cash (compras antigas = à vista).
      final purchases = db
          .select('SELECT id, purchase_number, payment_method FROM purchases')
          .map((r) => (r['id'] as String, r['purchase_number'] as int))
          .toList();
      expect(purchases.firstWhere((p) => p.$1 == 'pc1').$2, 1);
      expect(purchases.firstWhere((p) => p.$1 == 'pc2').$2, 2);
      final purchaseMethods = db
          .select('SELECT payment_method FROM purchases')
          .map((r) => r['payment_method'] as String)
          .toSet();
      expect(purchaseMethods, {'cash'});

      // then — numeração de DÍVIDAS por vencimento (d1=1, d2=2) e baixa
      // pendente por padrão.
      final debts = db
          .select('SELECT id, debt_number, is_paid FROM debts')
          .map((r) => (r['id'] as String, r['debt_number'] as int))
          .toList();
      expect(debts.firstWhere((d) => d.$1 == 'd1').$2, 1);
      expect(debts.firstWhere((d) => d.$1 == 'd2').$2, 2);
      final paidStates = db
          .select('SELECT is_paid FROM debts')
          .map((r) => r['is_paid'] as int)
          .toSet();
      expect(paidStates, {0});

      // then — coluna debt_id (origem fiado) existe e está vazia.
      final debtIdColumns = db
          .select('PRAGMA table_info(financial_transactions)')
          .where((r) => r['name'] == 'debt_id');
      expect(debtIdColumns, isNotEmpty);

      // then — coluna expiry_date de itens de compra existe.
      final expiryColumns = db
          .select('PRAGMA table_info(purchase_items)')
          .where((r) => r['name'] == 'expiry_date');
      expect(expiryColumns, isNotEmpty);

      // then — versão carimbada: o pior caso fica versionado.
      expect(
        db.select('PRAGMA user_version').first['user_version'],
        AppDatabase.currentSchemaVersion,
      );
    });
  });

  group('AppDatabase.openAppDatabase — falha de diretório', () {
    test(
      'deve retornar false (fallback memória) quando documentos falham',
      () async {
        // given — plataforma de path_provider que lança (dispositivo sem
        // storage acessível): o bootstrap NÃO pode quebrar o app.
        final throwing = _ThrowingPathProvider();
        final original = PathProviderPlatform.instance;
        PathProviderPlatform.instance = throwing;
        addTearDown(() => PathProviderPlatform.instance = original);

        // when
        final ok = await AppDatabase.openAppDatabase();

        // then — degradação graciosa para datasources em memória.
        expect(ok, isFalse);
      },
    );
  });

  group('datasources registrados são resolvíveis (factories lazy)', () {
    test(
      'cada factory instancia a implementação SQLite do banco aberto',
      () async {
        // given — o openAppDatabase precisa rodar antes (static global).
        final ok = await AppDatabase.openAppDatabase();
        expect(ok, isTrue);
        final getIt = GetIt.asNewInstance();
        addTearDown(getIt.reset);
        AppDatabase.registerDatasources(getIt);
        AppDatabase.registerOfflineQueue(getIt);

        // when / then — resolver CADA tipo dispara a factory lazy e
        // devolve a implementação SQLite (não a de memória).
        expect(getIt<IUnitOfWork>(), isA<SqliteUnitOfWork>());
        expect(
          getIt<ProductLocalDataSource>(),
          isA<ProductSqliteDataSourceImpl>(),
        );
        expect(getIt<SaleLocalDataSource>(), isA<SaleSqliteDataSourceImpl>());
        expect(
          getIt<FinancialTransactionLocalDataSource>(),
          isA<FinancialTransactionSqliteDataSourceImpl>(),
        );
        expect(getIt<DebtLocalDataSource>(), isA<DebtSqliteDataSourceImpl>());
        expect(
          getIt<CustomerLocalDataSource>(),
          isA<CustomerSqliteDataSourceImpl>(),
        );
        expect(
          getIt<PurchaseLocalDataSource>(),
          isA<PurchaseSqliteDataSourceImpl>(),
        );
        expect(
          getIt<StockLotLocalDataSource>(),
          isA<StockLotSqliteDataSourceImpl>(),
        );
        expect(
          getIt<CashClosingLocalDataSource>(),
          isA<CashClosingSqliteDataSourceImpl>(),
        );
        expect(
          getIt<CustomInvoiceLocalDataSource>(),
          isA<CustomInvoiceSqliteDataSourceImpl>(),
        );
        expect(
          getIt<QuotationLocalDataSource>(),
          isA<QuotationSqliteDataSourceImpl>(),
        );
        expect(
          getIt<EmployeeManagementLocalDataSource>(),
          isA<EmployeeManagementSqliteDataSourceImpl>(),
        );
        expect(getIt<IPendingOpQueue>(), isA<PendingOpQueueSqliteImpl>());
      },
    );
  });
}

/// Path provider que falha (dispositivo sem storage) — exercita o catch
/// do bootstrap que degrada para memória.
class _ThrowingPathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    throw const FileSystemException('storage indisponível');
  }
}
