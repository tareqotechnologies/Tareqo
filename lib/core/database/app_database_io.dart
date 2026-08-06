import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../data/datasources/local/customer_local_data_source.dart';
import '../../data/datasources/local/customer_sqlite_data_source_impl.dart';
import '../../data/datasources/local/debt_local_data_source.dart';
import '../../data/datasources/local/debt_sqlite_data_source_impl.dart';
import '../../data/datasources/local/demo_seed.dart';
import '../../data/datasources/local/financial_transaction_local_data_source.dart';
import '../../data/datasources/local/financial_transaction_sqlite_data_source_impl.dart';
import '../../data/datasources/local/product_local_data_source.dart';
import '../../data/datasources/local/product_sqlite_data_source_impl.dart';
import '../../data/datasources/local/purchase_local_data_source.dart';
import '../../data/datasources/local/purchase_sqlite_data_source_impl.dart';
import '../../data/datasources/local/sale_local_data_source.dart';
import '../../data/datasources/local/sale_sqlite_data_source_impl.dart';
import '../../data/datasources/local/sqlite_unit_of_work.dart';
import '../../domain/repositories/i_unit_of_work.dart';

/// Implementação nativa do bootstrap SQLite (usada em Android/iOS/desktop;
/// na web entra a stub — ver `app_database.dart`).
///
/// A troca de persistência segue o processo documentado: os datasources
/// SQLite implementam **os mesmos contratos** que os de memória — apenas
/// o registro no ServiceLocator muda.
abstract final class AppDatabase {
  static Database? _database;

  /// Abre o banco persistente (`dumbhanengue.db` em documentos) e prepara
  /// o schema/seed. Retorna `true` quando o SQLite está ativo; `false`
  /// (sem efeitos colaterais) se a biblioteca nativa falhar — nesse caso
  /// o ServiceLocator usa os datasources em memória.
  ///
  /// W10: desde o sqlite3 3.x, o carregamento da biblioteca nativa é feito
  /// por BUILD HOOKS (native assets) — o pacote empacota o SQLite para
  /// todas as plataformas, sem `open.overrideFor`/`sqlite3_flutter_libs`.
  static Future<bool> openAppDatabase() async {
    if (kIsWeb) return false;

    Database? db;
    try {
      final directory = await getApplicationDocumentsDirectory();
      db = sqlite3.open(p.join(directory.path, 'dumbhanengue.db'));
      db.execute('PRAGMA foreign_keys = ON;');
      initialize(db);
      _database = db;
      return true;
    } catch (error, stackTrace) {
      db?.close();
      debugPrint(
        'AppDatabase: SQLite indisponível ($error) — usando memória.\n'
        '$stackTrace',
      );
      return false;
    }
  }

  /// Registra os datasources SQLite no GetIt (chamado somente após
  /// [openAppDatabase] retornar `true`).
  ///
  /// ⚠️ Manter as assinaturas de `openAppDatabase()` e
  /// `registerDatasources()` em sincronia com `app_database_stub.dart`.
  static void registerDatasources(GetIt instance) {
    final db = _database;
    assert(db != null, 'AppDatabase: chame openAppDatabase() antes.');
    if (db == null) return;
    instance
      ..registerLazySingleton<IUnitOfWork>(() => SqliteUnitOfWork(db))
      ..registerLazySingleton<ProductLocalDataSource>(
        () => ProductSqliteDataSourceImpl(db),
      )
      ..registerLazySingleton<SaleLocalDataSource>(
        () => SaleSqliteDataSourceImpl(db),
      )
      ..registerLazySingleton<FinancialTransactionLocalDataSource>(
        () => FinancialTransactionSqliteDataSourceImpl(db),
      )
      ..registerLazySingleton<DebtLocalDataSource>(
        () => DebtSqliteDataSourceImpl(db),
      )
      ..registerLazySingleton<CustomerLocalDataSource>(
        () => CustomerSqliteDataSourceImpl(db),
      )
      ..registerLazySingleton<PurchaseLocalDataSource>(
        () => PurchaseSqliteDataSourceImpl(db),
      );
  }

  /// Cria as tabelas (idempotente), migra dinheiro para CENTAVOS (W4) e
  /// semeia dados demo se o banco estiver vazio.
  static void initialize(Database db) {
    createSchema(db);
    migrateMoneyToCents(db);
    seedIfEmpty(db);
  }

  /// Migração W4 (centavos inteiros): bancos criados antes da migração
  /// guardavam dinheiro como REAL (reais com fração); a partir daqui o
  /// domínio e o schema usam **centavos inteiros**. Detecta o schema
  /// antigo pela afinidade REAL das colunas de dinheiro (PRAGMA
  /// table_info — o novo schema declara INTEGER) e multiplica os valores
  /// por 100, arredondando. Idempotente: bancos novos (INTEGER) não são
  /// tocados; bancos já migrados não voltam a ser multiplicados.
  ///
  /// SQLite é dinamicamente tipado: depois da multiplicação, a coluna
  /// REAL guarda inteiros (lidos como int pelo driver) — não é preciso
  /// rebuild da tabela; bancos NOVOS já nascem com INTEGER.
  static void migrateMoneyToCents(Database db) {
    // Colunas de dinheiro por tabela (schema antigo = REAL).
    const moneyColumns = <String, List<String>>{
      'products': ['purchase_price', 'sale_price'],
      'sales': ['total_amount'],
      'sale_items': ['unit_price'],
      'financial_transactions': ['amount'],
      'debts': ['amount'],
      'purchases': ['total_amount'],
      'purchase_items': ['unit_price'],
    };

    for (final entry in moneyColumns.entries) {
      final table = entry.key;
      final columns = db.select('PRAGMA table_info($table)');
      for (final column in columns) {
        final name = column['name'] as String;
        final type = column['type'] as String;
        if (type == 'REAL' && entry.value.contains(name)) {
          db.execute(
            'UPDATE $table SET $name = CAST(ROUND($name * 100) AS INTEGER) '
            'WHERE $name IS NOT NULL',
          );
        }
      }
    }
  }

  /// Profundidade de transação ativa na conexão compartilhada. SQLite não
  /// permite transações aninhadas: quando > 0, um novo begin apenas se
  /// junta à transação externa (sem BEGIN/COMMIT/ROLLBACK próprios).
  ///
  /// ⚠️ **Invariante global:** o contador é estático e assume UMA conexão
  /// (Database singleton) e UM [IUnitOfWork] no processo — como o app
  /// registra. Não abra múltiplas conexões transacionais concorrentes.
  static int _transactionDepth = 0;

  /// Inicia uma transação (re-entrante): só o chamador externo emite o
  /// `BEGIN IMMEDIATE` (que adquire a trava de escrita na hora, fechando
  /// janelas TOCTOU); chamadas aninhadas apenas incrementam a profundidade.
  ///
  /// A profundidade é incrementada **depois** do BEGIN com sucesso: se o
  /// SQL falhar, o contador permanece 0 (sem vazamento que corromperia
  /// transações futuras).
  static void beginTransaction(Database db) {
    if (_transactionDepth > 0) {
      _transactionDepth++;
      return;
    }
    db.execute('BEGIN IMMEDIATE;');
    _transactionDepth = 1;
  }

  /// Confirma a transação — apenas o chamador externo emite o `COMMIT`.
  static void commitTransaction(Database db) {
    assert(_transactionDepth > 0, 'commitTransaction sem transação ativa.');
    if (--_transactionDepth == 0) db.execute('COMMIT;');
  }

  /// Desfaz a transação — apenas o chamador externo emite o `ROLLBACK`.
  /// Chamadas aninhadas só reentram a profundidade e o erro propaga para o
  /// chamador externo, que faz o rollback de verdade.
  static void rollbackTransaction(Database db) {
    assert(_transactionDepth > 0, 'rollbackTransaction sem transação ativa.');
    if (--_transactionDepth == 0) db.execute('ROLLBACK;');
  }

  /// Executa [action] dentro de uma transação (commit no sucesso,
  /// rollback automático em qualquer erro). O `package:sqlite3` não expõe
  /// um wrapper `transaction()` — usamos SQL explícito com try/catch.
  ///
  /// **Re-entrante:** se já houver uma transação ativa na conexão (ex.: um
  /// [IUnitOfWork] envolvendo a chamada), junta-se a ela em vez de abrir
  /// uma transação aninhada (que o SQLite rejeitaria).
  static void runInTransaction(Database db, void Function() action) {
    beginTransaction(db);
    try {
      action();
      commitTransaction(db);
    } catch (_) {
      rollbackTransaction(db);
      rethrow;
    }
  }

  /// Cria o schema. Os `CHECK` são a salvaguarda final do banco contra
  /// valores inválidos (estoque/valores nunca negativos) — as regras de
  /// negócio continuam no domínio.
  ///
  /// Desde a migração W4, colunas de dinheiro são **INTEGER (centavos)**.
  static void createSchema(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL DEFAULT 'st1',
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        purchase_price INTEGER NOT NULL CHECK (purchase_price >= 0),
        sale_price INTEGER NOT NULL CHECK (sale_price >= 0),
        stock_quantity INTEGER NOT NULL DEFAULT 0
          CHECK (stock_quantity >= 0)
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL DEFAULT 'st1',
        total_amount INTEGER NOT NULL CHECK (total_amount >= 0),
        payment_method TEXT NOT NULL,
        date_time INTEGER NOT NULL
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id TEXT NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        unit_price INTEGER NOT NULL CHECK (unit_price >= 0)
      );
      CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id
        ON sale_items(sale_id);
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS financial_transactions (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL DEFAULT 'st1',
        description TEXT NOT NULL,
        amount INTEGER NOT NULL CHECK (amount >= 0),
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'paid',
        debt_id TEXT
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS debts (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL DEFAULT 'st1',
        person_name TEXT NOT NULL,
        amount INTEGER NOT NULL CHECK (amount >= 0),
        due_date INTEGER NOT NULL,
        is_customer_debt INTEGER NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        paid_at INTEGER,
        customer_id TEXT
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL DEFAULT 'st1',
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        email TEXT NOT NULL DEFAULT ''
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL DEFAULT 'st1',
        supplier_name TEXT NOT NULL,
        total_amount INTEGER NOT NULL CHECK (total_amount >= 0),
        date_time INTEGER NOT NULL
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id TEXT NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        unit_price INTEGER NOT NULL CHECK (unit_price >= 0),
        UNIQUE (purchase_id, product_id)
      );
      CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id
        ON purchase_items(purchase_id);
    ''');

    // Migração leve: bancos criados antes da coluna `is_paid` (baixa de
    // fiado) recebem a coluna com DEFAULT 0 (tudo pendente). Idempotente
    // para bancos novos, que já criam a coluna no CREATE TABLE acima.
    final debtColumns = db.select('PRAGMA table_info(debts)');
    final hasIsPaid = debtColumns.any((row) => row['name'] == 'is_paid');
    if (!hasIsPaid) {
      db.execute(
        'ALTER TABLE debts ADD COLUMN is_paid INTEGER NOT NULL DEFAULT 0',
      );
    }

    // Migração leve: bancos criados antes do vínculo `debt_id` (origem da
    // pendência de fiado) recebem a coluna NULL — dívidas antigas seguem
    // quitando via nova entrada no caixa (sem duplicata). Idempotente para
    // bancos novos.
    final transactionColumns =
        db.select('PRAGMA table_info(financial_transactions)');
    final hasDebtId =
        transactionColumns.any((row) => row['name'] == 'debt_id');
    if (!hasDebtId) {
      db.execute(
        'ALTER TABLE financial_transactions ADD COLUMN debt_id TEXT',
      );
    }

    // Migração leve: bancos criados antes do `paid_at` (data da baixa do
    // fiado — histórico de quitações) recebem a coluna NULL; dívidas já
    // quitadas ficam sem data de baixa até uma nova quitação. Idempotente.
    final debtPaidAtColumns = db.select('PRAGMA table_info(debts)');
    final hasPaidAt = debtPaidAtColumns.any((row) => row['name'] == 'paid_at');
    if (!hasPaidAt) {
      db.execute('ALTER TABLE debts ADD COLUMN paid_at INTEGER');
    }

    // Migração leve: bancos criados antes do vínculo `customer_id`
    // (módulo de clientes) recebem a coluna NULL — dívidas antigas seguem
    // exibindo apenas o personName (snapshot). Idempotente.
    final debtCustomerColumns = db.select('PRAGMA table_info(debts)');
    final hasCustomerId =
        debtCustomerColumns.any((row) => row['name'] == 'customer_id');
    if (!hasCustomerId) {
      db.execute('ALTER TABLE debts ADD COLUMN customer_id TEXT');
    }

    // Migração leve (Fase 2 do multi-tenancy): bancos criados antes do
    // escopo por loja recebem `store_id` com DEFAULT 'st1' (a loja demo) —
    // registros antigos continuam visíveis na loja de demonstração.
    // Idempotente para bancos novos (já criam a coluna no CREATE TABLE).
    final migrationTargets = <String, String>{
      'products': 'idx_products_store',
      'sales': 'idx_sales_store',
      'financial_transactions': 'idx_financial_transactions_store',
      'debts': 'idx_debts_store',
      'customers': 'idx_customers_store',
      'purchases': 'idx_purchases_store',
    };
    for (final entry in migrationTargets.entries) {
      final columns = db.select('PRAGMA table_info(${entry.key})');
      final hasStoreId = columns.any((row) => row['name'] == 'store_id');
      if (!hasStoreId) {
        db.execute(
          "ALTER TABLE ${entry.key} ADD COLUMN store_id TEXT NOT NULL "
          "DEFAULT 'st1'",
        );
      }
      db.execute('CREATE INDEX IF NOT EXISTS ${entry.value} '
          'ON ${entry.key}(store_id)');
    }
  }

  /// Semeia os dados de demonstração apenas na primeira execução. A
  /// guarda usa a tabela `products` como indicador de "banco já criado"
  /// (suposição razoável para o demo).
  static void seedIfEmpty(Database db) {
    final count = db.select('SELECT COUNT(*) AS c FROM products').first;
    if ((count['c'] as int) > 0) return;

    runInTransaction(db, () {
      for (final product in DemoSeed.products()) {
        db.execute(
          'INSERT INTO products '
          '(id, store_id, name, description, purchase_price, sale_price, '
          'stock_quantity) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            product.id,
            product.storeId,
            product.name,
            product.description,
            product.purchasePriceCents,
            product.salePriceCents,
            product.stockQuantity,
          ],
        );
      }

      for (final sale in DemoSeed.sales()) {
        db.execute(
          'INSERT INTO sales (id, store_id, total_amount, payment_method, '
          'date_time) VALUES (?, ?, ?, ?, ?)',
          [
            sale.id,
            sale.storeId,
            sale.totalAmountCents,
            sale.paymentMethod.name,
            sale.dateTime.millisecondsSinceEpoch,
          ],
        );
        for (final item in sale.items) {
          db.execute(
            'INSERT INTO sale_items '
            '(sale_id, product_id, product_name, quantity, unit_price) '
            'VALUES (?, ?, ?, ?, ?)',
            [
              sale.id,
              item.productId,
              item.productName,
              item.quantity,
              item.unitPriceCents,
            ],
          );
        }
      }

      for (final transaction in DemoSeed.transactions()) {
        db.execute(
          'INSERT INTO financial_transactions '
          '(id, store_id, description, amount, type, category, date, status, '
          'debt_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            transaction.id,
            transaction.storeId,
            transaction.description,
            transaction.amountCents,
            transaction.type.name,
            transaction.category,
            transaction.date.millisecondsSinceEpoch,
            transaction.status.name,
            transaction.debtId,
          ],
        );
      }

      for (final debt in DemoSeed.debts()) {
        db.execute(
          'INSERT INTO debts '
          '(id, store_id, person_name, amount, due_date, is_customer_debt, '
          'is_paid, paid_at, customer_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            debt.id,
            debt.storeId,
            debt.personName,
            debt.amountCents,
            debt.dueDate.millisecondsSinceEpoch,
            debt.isCustomerDebt ? 1 : 0,
            debt.isPaid ? 1 : 0,
            debt.paidAt?.millisecondsSinceEpoch,
            debt.customerId,
          ],
        );
      }

      for (final customer in DemoSeed.customers()) {
        db.execute(
          'INSERT INTO customers (id, store_id, name, phone, email) '
          'VALUES (?, ?, ?, ?, ?)',
          [
            customer.id,
            customer.storeId,
            customer.name,
            customer.phone,
            customer.email,
          ],
        );
      }

      for (final purchase in DemoSeed.purchases()) {
        db.execute(
          'INSERT INTO purchases (id, store_id, supplier_name, total_amount, '
          'date_time) VALUES (?, ?, ?, ?, ?)',
          [
            purchase.id,
            purchase.storeId,
            purchase.supplierName,
            purchase.totalAmountCents,
            purchase.dateTime.millisecondsSinceEpoch,
          ],
        );
        for (final item in purchase.items) {
          db.execute(
            'INSERT INTO purchase_items '
            '(purchase_id, product_id, product_name, quantity, unit_price) '
            'VALUES (?, ?, ?, ?, ?)',
            [
              purchase.id,
              item.productId,
              item.productName,
              item.quantity,
              item.unitPriceCents,
            ],
          );
        }
      }
    });
  }
}
