import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../data/datasources/local/pending_op_queue.dart';
import '../../data/datasources/local/pending_op_queue_sqlite_impl.dart';
import '../../data/datasources/local/cash_closing_local_data_source.dart';
import '../../data/datasources/local/cash_closing_sqlite_data_source_impl.dart';
import '../../data/datasources/local/custom_invoice_local_data_source.dart';
import '../../data/datasources/local/custom_invoice_sqlite_data_source_impl.dart';
import '../../data/datasources/local/customer_local_data_source.dart';
import '../../data/datasources/local/customer_sqlite_data_source_impl.dart';
import '../../data/datasources/local/debt_local_data_source.dart';
import '../../data/datasources/local/debt_sqlite_data_source_impl.dart';
import '../../data/datasources/local/financial_transaction_local_data_source.dart';
import '../../data/datasources/local/financial_transaction_sqlite_data_source_impl.dart';
import '../../data/datasources/local/product_local_data_source.dart';
import '../../data/datasources/local/product_sqlite_data_source_impl.dart';
import '../../data/datasources/local/purchase_local_data_source.dart';
import '../../data/datasources/local/purchase_sqlite_data_source_impl.dart';
import '../../data/datasources/local/sale_local_data_source.dart';
import '../../data/datasources/local/sale_sqlite_data_source_impl.dart';
import '../../data/datasources/local/sqlite_unit_of_work.dart';
import '../../data/datasources/local/stock_lot_local_data_source.dart';
import '../../data/datasources/local/stock_lot_sqlite_data_source_impl.dart';
import '../../domain/repositories/i_unit_of_work.dart';

/// Implementação nativa do bootstrap SQLite (usada em Android/iOS/desktop;
/// na web entra a stub — ver `app_database.dart`).
///
/// A troca de persistência segue o processo documentado: os datasources
/// SQLite implementam **os mesmos contratos** que os de memória — apenas
/// o registro no ServiceLocator muda.
abstract final class AppDatabase {
 static Database? _database;  /// Abre o banco persistente (`tareqo.db` em documentos) e prepara
 /// o schema. Retorna `true` quando o SQLite está ativo; `false`
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
 final directory = await getApplicationDocumentsDirectory();    db = sqlite3.open(p.join(directory.path, 'tareqo.db'));
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
 /// Atenção: Manter as assinaturas de `openAppDatabase()` e
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
 )
 ..registerLazySingleton<StockLotLocalDataSource>(
 () => StockLotSqliteDataSourceImpl(db),
 )  ..registerLazySingleton<CashClosingLocalDataSource>(
    () => CashClosingSqliteDataSourceImpl(db),
  )
  ..registerLazySingleton<CustomInvoiceLocalDataSource>(
    () => CustomInvoiceSqliteDataSourceImpl(db),
  );
 }

 /// Registra a fila offline (outbox) sobre o MESMO banco SQLite.
 ///
 /// Usada no modo SaaS (onde os datasources de negócio são REMOTOS, mas a
 /// fila precisa de persistência local) e no modo local (mesmo banco).
 /// Atenção: Não registra os datasources de negócio — só a fila.
 static void registerOfflineQueue(GetIt instance) {
 final db = _database;
 if (db == null) return;
 instance.registerLazySingleton<IPendingOpQueue>(
 () => PendingOpQueueSqliteImpl(db),
 );
 }

 /// Leva o banco à versão atual do schema (migrações versionadas via
 /// `PRAGMA user_version`). Nenhum dado é semeado: o banco nasce vazio e
 /// só registra dados REAIS criados pelo usuário.
 ///
 /// Bancos NOVOS e LEGADOS (criados antes do versionamento, `user_version`
 /// = 0) rodam a migração v1 — o schema completo atual, idempotente por
 /// construção (IF NOT EXISTS + guardas por presença de coluna). Depois
 /// disso o `user_version` fica em [currentSchemaVersion] e as migrações
 /// antigas NUNCA reexecutam (startup rápido e determinístico). Mudanças
 /// futuras de schema entram como NOVAS migrações (v2, v3...) — nunca
 /// editar a v1.
 static void initialize(Database db) => _migrate(db);

 /// Versão atual do schema (`PRAGMA user_version`).
 static const int currentSchemaVersion = 3;

 /// Migrações versionadas, em ordem crescente de versão.
 ///
 /// A v1 é o schema COMPLETO atual (tabelas + migrações leves acumuladas
 /// + W4 centavos) — idempotente para bancos legados. Migrações novas:
 /// adicionar `_Migration(version: 2, description: ..., up: _migracaoV2)`
 /// e a função — o [initialize] roda apenas as pendentes.
 static final List<_Migration> _migrations = [
 _Migration(
 version: 1,
 description: 'schema completo + W4 (centavos) + numerações/backfills',
 up: _schemaV1,
 ),
 _Migration(
 version: 2,
 description: 'fila offline (outbox) — tabela pending_ops',
 up: _schemaV2,
 ),
 _Migration(
 version: 3,
 description: 'facturas personalizadas (add-on) — tabela custom_invoices',
 up: _schemaV3,
 ),
 ];

 /// Lê a versão atual do banco (0 em bancos novos/legados sem versionar).
 static int _userVersion(Database db) =>
 db.select('PRAGMA user_version').first['user_version'] as int;

 /// Roda as migrações pendentes (versão > atual), cada uma na própria
 /// transação com o `user_version` carimbado DENTRO dela — se a migração
 /// falhar, o rollback desfaz o schema E a versão; o próximo startup
 /// retenta do ponto exato.
 static void _migrate(Database db) {
 final version = _userVersion(db);
 if (version >= currentSchemaVersion) return;
 for (final migration in _migrations) {
 if (migration.version <= version) continue;
 runInTransaction(db, () {
 migration.up(db);
 db.execute('PRAGMA user_version = ${migration.version}');
 });
 }
 }

 /// Parte da migração v1 — W4 (centavos inteiros): bancos criados antes
 /// da migração guardavam dinheiro como REAL (reais com fração); a partir
 /// daqui o domínio e o schema usam **centavos inteiros**. Detecta o
 /// schema antigo pela afinidade REAL das colunas de dinheiro (PRAGMA
 /// table_info — o novo schema declara INTEGER) e multiplica os valores
 /// por 100, arredondando. Idempotente: bancos novos (INTEGER) não são
 /// tocados; bancos já migrados não voltam a ser multiplicados.
 ///
 /// SQLite é dinamicamente tipado: depois da multiplicação, a coluna
 /// REAL guarda inteiros (lidos como int pelo driver) — não é preciso
 /// rebuild da tabela; bancos NOVOS já nascem com INTEGER.
 static void _migrateMoneyToCents(Database db) {
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
 /// Atenção: **Invariante global:** o contador é estático e assume UMA conexão
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

 /// Migração v1 — schema COMPLETO atual. Os `CHECK` são a salvaguarda
 /// final do banco contra valores inválidos (estoque/valores nunca
 /// negativos) — as regras de negócio continuam no domínio.
 ///
 /// Desde a migração W4, colunas de dinheiro são **INTEGER (centavos)**.
 ///
 /// Idempotente por construção (IF NOT EXISTS + guardas por presença de
 /// coluna): roda igual em bancos NOVOS (cria tudo) e LEGADOS (apenas o
 /// que falta + backfills). Nunca editar depois do versionamento — a v1
 /// já foi aplicada nos bancos existentes; mudanças novas vão em v2+.
 static void _schemaV1(Database db) {
 db.execute('''
 CREATE TABLE IF NOT EXISTS products (
 id TEXT PRIMARY KEY,
 store_id TEXT NOT NULL DEFAULT 'st1',
 name TEXT NOT NULL,
 description TEXT NOT NULL DEFAULT '',
 purchase_price INTEGER NOT NULL CHECK (purchase_price >= 0),
 sale_price INTEGER NOT NULL CHECK (sale_price >= 0),
 -- W11: estoque em MILÉSIMOS de unidade (1000 = 1 unidade/kg).
 stock_quantity INTEGER NOT NULL DEFAULT 0
 CHECK (stock_quantity >= 0),
 -- W11: código de barras/PLU (5 dígitos, opcional) das balanças
 -- etiquetadoras; venda por peso (fração) e unidade de venda.
 code TEXT,
 venda_por_fracao INTEGER NOT NULL DEFAULT 0,
 unit_label TEXT NOT NULL DEFAULT 'un',
 -- Produto ATIVO no catálogo (padrão). Desativado, some do PDV e
 -- das compras, mas permanece na lista com o selo "Inativo" — o
 -- estoque é preservado para a reativação.
 is_active INTEGER NOT NULL DEFAULT 1,
 -- Foto do produto (opcional): caminho de arquivo local (modo
 -- SQLite) ou URL do Supabase Storage (modo SaaS). Vazio = sem foto.
 image_path TEXT
 );
 ''');
 db.execute('''
 CREATE TABLE IF NOT EXISTS sales (
 id TEXT PRIMARY KEY,
 store_id TEXT NOT NULL DEFAULT 'st1',
 -- Número SEQUENCIAL da venda dentro da loja (S-00001, S-00002...).
 -- Atribuído pelo datasource no insert (MAX+1 por loja, dentro da
 -- transação). DEFAULT 0 é apenas a migração para bancos antigos;
 -- todo INSERT informa o valor real.
 sale_number INTEGER NOT NULL DEFAULT 0,
 total_amount INTEGER NOT NULL CHECK (total_amount >= 0),
 payment_method TEXT NOT NULL,
 date_time INTEGER NOT NULL,
 -- Anulação de venda: status ('active'|'cancelled') + momento da
 -- anulação. DEFAULT 'active' preserva a leitura de vendas antigas.
 status TEXT NOT NULL DEFAULT 'active',
 cancelled_at INTEGER
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
 // Consumo de LOTES por venda — registrado na MESMA transação da venda
 // (caminho composto local). Permite à anulação devolver o estoque aos
 // lotes EXATOS consumidos (preservando validade e custo de cada lote).
 db.execute('''
 CREATE TABLE IF NOT EXISTS sale_lot_consumption (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 sale_id TEXT NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
 lot_id TEXT NOT NULL,
 product_id TEXT NOT NULL,
 quantity INTEGER NOT NULL CHECK (quantity > 0)
 );
 CREATE INDEX IF NOT EXISTS idx_sale_lot_consumption_sale
 ON sale_lot_consumption(sale_id);
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
 -- Número SEQUENCIAL da dívida dentro da loja (D-00001, D-00002...).
 -- Atribuído pelo datasource no insert (MAX+1 por loja, dentro da
 -- transação). DEFAULT 0 é apenas a migração para bancos antigos;
 -- todo INSERT informa o valor real.
 debt_number INTEGER NOT NULL DEFAULT 0,
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
 -- Número SEQUENCIAL da compra dentro da loja (C-00001, C-00002...).
 -- Atribuído pelo datasource no insert (MAX+1 por loja, dentro da
 -- transação). DEFAULT 0 é apenas a migração para bancos antigos;
 -- todo INSERT informa o valor real.
 purchase_number INTEGER NOT NULL DEFAULT 0,
 supplier_name TEXT NOT NULL,
 total_amount INTEGER NOT NULL CHECK (total_amount >= 0),
 -- Forma de pagamento do fornecedor (mesmo enum de vendas, gravado
 -- pelo NOME). DEFAULT 'cash': compras antigas não registravam o
 -- método — a migração abaixo interpreta como pagamento à vista.
 payment_method TEXT NOT NULL DEFAULT 'cash',
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
 -- W11: data de validade do lote criado por este item (NULL = sem
 -- validade — FIFO por data de entrada).
 expiry_date INTEGER,
 UNIQUE (purchase_id, product_id)
 );
 CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id
 ON purchase_items(purchase_id);
 ''');
 // W11 — Lotes FIFO: cada entrada de mercadoria cria um lote; a baixa
 // no PDV consome em ordem de validade (mais próximo primeiro) e, sem
 // validade, por data de entrada. `current_quantity` = quantidade ATUAL
 // (milésimos); `cost_price` = custo de aquisição (centavos).
 db.execute('''
 CREATE TABLE IF NOT EXISTS stock_lots (
 id TEXT PRIMARY KEY,
 store_id TEXT NOT NULL DEFAULT 'st1',
 product_id TEXT NOT NULL,
 entry_date INTEGER NOT NULL,
 expiry_date INTEGER,
 initial_quantity INTEGER NOT NULL CHECK (initial_quantity >= 0),
 current_quantity INTEGER NOT NULL CHECK (current_quantity >= 0),
 cost_price INTEGER NOT NULL CHECK (cost_price >= 0)
 );
 CREATE INDEX IF NOT EXISTS idx_stock_lots_product
 ON stock_lots(product_id, store_id);
 CREATE INDEX IF NOT EXISTS idx_stock_lots_expiry
 ON stock_lots(expiry_date) WHERE current_quantity > 0;
 ''');
 // Fecho de caixa diário (Z-report) — um fecho por loja por dia.
 // `closing_date` = início do dia local em ms (época); `expected_cash` =
 // o que deveria estar na gaveta (Σ vendas ativas em DINHEIRO do dia);
 // `counted_cash` = dinheiro físico contado na conferência;
 // `sales_by_method` = abertura por forma de pagamento (JSON).
 db.execute('''
 CREATE TABLE IF NOT EXISTS cash_closings (
 id TEXT PRIMARY KEY,
 store_id TEXT NOT NULL DEFAULT 'st1',
 closing_date INTEGER NOT NULL,
 total_sales INTEGER NOT NULL CHECK (total_sales >= 0),
 expected_cash INTEGER NOT NULL CHECK (expected_cash >= 0),
 counted_cash INTEGER NOT NULL CHECK (counted_cash >= 0),
 sales_by_method TEXT NOT NULL DEFAULT '{}',
 closed_at INTEGER NOT NULL
 );
 CREATE UNIQUE INDEX IF NOT EXISTS uq_cash_closings_store_day
 ON cash_closings(store_id, closing_date);
 CREATE INDEX IF NOT EXISTS idx_cash_closings_store
 ON cash_closings(store_id);
 ''');

 // Migração leve: bancos criados antes do `sale_number` (numeração
 // sequencial por loja) recebem a coluna com DEFAULT 0 e são re-numerados
 // em ordem de data (a venda mais antiga da loja = 1). Idempotente para
 // bancos novos, que já criam a coluna no CREATE TABLE acima.
 final salesColumns = db.select('PRAGMA table_info(sales)');
 final hasSaleNumber = salesColumns.any((row) => row['name'] == 'sale_number');
 if (!hasSaleNumber) {
 db.execute(
 'ALTER TABLE sales ADD COLUMN sale_number INTEGER NOT NULL DEFAULT 0',
 );
 db.execute('''
 WITH numbered AS (
 SELECT id, ROW_NUMBER() OVER (
 PARTITION BY store_id ORDER BY date_time, id
 ) AS rn
 FROM sales
 )
 UPDATE sales
 SET sale_number = (SELECT rn FROM numbered WHERE numbered.id = sales.id)
 ''');
 }
 // Garantia de unicidade por loja (defesa em profundidade — o datasource
 // já atribui MAX+1 dentro da transação).
 db.execute(
 'CREATE UNIQUE INDEX IF NOT EXISTS uq_sales_store_number '
 'ON sales(store_id, sale_number)',
 );

 // Migração leve (anulação de vendas): bancos criados antes do status
 // recebem `status` DEFAULT 'active' (todas as vendas existentes são
 // ativas — nunca foram anuladas) e `cancelled_at` NULL. Idempotente
 // para bancos novos, que já criam as colunas no CREATE TABLE acima.
 final salesStatusColumns = db.select('PRAGMA table_info(sales)');
 final hasStatus =
 salesStatusColumns.any((row) => row['name'] == 'status');
 if (!hasStatus) {
 db.execute(
 "ALTER TABLE sales ADD COLUMN status TEXT NOT NULL DEFAULT 'active'",
 );
 db.execute('ALTER TABLE sales ADD COLUMN cancelled_at INTEGER');
 }

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
 // escopo por loja recebem `store_id` com DEFAULT 'st1' — registros
 // antigos continuam visíveis na loja padrão. Idempotente para bancos
 // novos (já criam a coluna no CREATE TABLE).
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

 // Migração W11 (FIFO + validade + milésimos): bancos criados antes
 // do módulo recebem as colunas novas e têm TODAS as quantidades
 // convertidas de unidades inteiras para MILÉSIMOS (×1000) — produtos,
 // itens de venda e itens de compra. Depois, cada produto com estoque
 // ganha um lote inicial (sem validade, custo = preço de compra) para
 // a invariante `stock = Σ lotes` valer desde o primeiro dia. Idempotente:
 // bancos novos já criam as colunas no CREATE TABLE (o guard abaixo não
 // dispara) e a reconversão ×1000 nunca reexecuta (ligada à presença da
 // coluna `code` — adicionada apenas nesta migração).
 final productColumns = db.select('PRAGMA table_info(products)');
 final hasW11Columns = productColumns.any((row) => row['name'] == 'code');
 if (!hasW11Columns) {
 db.execute("ALTER TABLE products ADD COLUMN code TEXT");
 db.execute(
 'ALTER TABLE products ADD COLUMN venda_por_fracao '
 'INTEGER NOT NULL DEFAULT 0',
 );
 db.execute(
 "ALTER TABLE products ADD COLUMN unit_label TEXT NOT NULL "
 "DEFAULT 'un'",
 );
 // Conversão para MILÉSIMOS (W11) — roda apenas nesta migração.
 db.execute('UPDATE products SET stock_quantity = stock_quantity * 1000');
 db.execute('UPDATE sale_items SET quantity = quantity * 1000');
 db.execute('UPDATE purchase_items SET quantity = quantity * 1000');
 // Lote inicial de cada produto com estoque (FIFO sem validade).
 db.execute('''
 INSERT INTO stock_lots
 (id, store_id, product_id, entry_date, expiry_date,
 initial_quantity, current_quantity, cost_price)
 SELECT 'lot-mig-' || id, store_id, id,
 CAST(strftime('%s','now') AS INTEGER) * 1000,
 NULL, stock_quantity, stock_quantity, purchase_price
 FROM products
 WHERE stock_quantity > 0
 ''');
 }

 // Migração leve (produto inativo): bancos criados antes do campo
 // `is_active` recebem a coluna com DEFAULT 1 — todos os produtos
 // existentes permanecem ATIVOS (nunca foram desativados). Idempotente
 // para bancos novos, que já criam a coluna no CREATE TABLE acima.
 final productActiveColumns = db.select('PRAGMA table_info(products)');
 final hasIsActive = productActiveColumns.any(
 (row) => row['name'] == 'is_active',
 );
 if (!hasIsActive) {
 db.execute(
 'ALTER TABLE products ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1',
 );
 }

 // Migração leve (FOTO do produto): bancos criados antes do `image_path`
 // recebem a coluna NULL — produtos existentes ficam sem foto (a UI
 // mostra o ícone padrão). Idempotente para bancos novos, que já criam
 // a coluna no CREATE TABLE acima.
 final productImageColumns = db.select('PRAGMA table_info(products)');
 final hasImagePath = productImageColumns.any(
 (row) => row['name'] == 'image_path',
 );
 if (!hasImagePath) {
 db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
 }

 // Migração leve W11: bancos criados antes do `expiry_date` (validade
 // opcional por item de compra) recebem a coluna NULL. Idempotente.
 final purchaseItemColumns = db.select('PRAGMA table_info(purchase_items)');
 final hasExpiry = purchaseItemColumns.any((row) => row['name'] == 'expiry_date');
 if (!hasExpiry) {
 db.execute('ALTER TABLE purchase_items ADD COLUMN expiry_date INTEGER');
 }

 // Migração leve (NUMERAÇÃO SEQUENCIAL): roda DEPOIS da migração de
 // store_id acima (os backfills referenciam store_id; em bancos legados
 // a coluna acaba de ser adicionada). Bancos criados antes de
 // `purchase_number`/`debt_number` recebem a coluna com DEFAULT 0 e são
 // re-numerados (compra mais antiga da loja = 1; dívida mais antiga = 1).
 // Idempotente para bancos novos, que já criam as colunas no CREATE
 // TABLE acima.
 final purchasesColumns = db.select('PRAGMA table_info(purchases)');
 final hasPurchaseNumber =
 purchasesColumns.any((row) => row['name'] == 'purchase_number');
 if (!hasPurchaseNumber) {
 db.execute(
 'ALTER TABLE purchases ADD COLUMN purchase_number '
 'INTEGER NOT NULL DEFAULT 0',
 );
 db.execute('''
 WITH numbered AS (
 SELECT id, ROW_NUMBER() OVER (
 PARTITION BY store_id ORDER BY date_time, id
 ) AS rn
 FROM purchases
 )
 UPDATE purchases
 SET purchase_number =
 (SELECT rn FROM numbered WHERE numbered.id = purchases.id)
 ''');
 }
 // Garantia de unicidade por loja (defesa em profundidade — o datasource
 // já atribui MAX+1 dentro da transação).
 db.execute(
 'CREATE UNIQUE INDEX IF NOT EXISTS uq_purchases_store_number '
 'ON purchases(store_id, purchase_number)',
 );

 final debtNumberColumns = db.select('PRAGMA table_info(debts)');
 final hasDebtNumber =
 debtNumberColumns.any((row) => row['name'] == 'debt_number');
 if (!hasDebtNumber) {
 db.execute(
 'ALTER TABLE debts ADD COLUMN debt_number INTEGER NOT NULL DEFAULT 0',
 );
 db.execute('''
 WITH numbered AS (
 SELECT id, ROW_NUMBER() OVER (
 PARTITION BY store_id ORDER BY due_date, id
 ) AS rn
 FROM debts
 )
 UPDATE debts
 SET debt_number = (SELECT rn FROM numbered WHERE numbered.id = debts.id)
 ''');
 }
 // Garantia de unicidade por loja (defesa em profundidade — o datasource
 // já atribui MAX+1 dentro da transação).
 db.execute(
 'CREATE UNIQUE INDEX IF NOT EXISTS uq_debts_store_number '
 'ON debts(store_id, debt_number)',
 );

 // Migração leve (forma de pagamento das compras): bancos criados antes
 // da coluna `payment_method` recebem a coluna com DEFAULT 'cash' — as
 // compras antigas não registravam o método e são interpretadas como
 // pagamento à vista (mesmo enum de vendas, gravado pelo NOME).
 // Idempotente para bancos novos, que já criam a coluna no CREATE TABLE.
 final purchasePaymentColumns = db.select('PRAGMA table_info(purchases)');
 final hasPurchasePayment =
 purchasePaymentColumns.any((row) => row['name'] == 'payment_method');
 if (!hasPurchasePayment) {
 db.execute(
 "ALTER TABLE purchases ADD COLUMN payment_method TEXT NOT NULL "
 "DEFAULT 'cash'",
 );
 }

 // Migração leve (formas de pagamento): o produto trocou o Pix (BR)
 // pelas carteiras de dinheiro móvel de Moçambique (M-Pesa e E-Mola).
 // O enum PaymentMethod é persistido pelo NOME (values.byName), então
 // vendas antigas com 'pix' quebrariam a leitura — reescreve para
 // 'mPesa' (escolha do produto: operadora dominante). Idempotente:
 // reexecutar com dados é um no-op (não há mais 'pix').
 db.execute(
 "UPDATE sales SET payment_method = 'mPesa' "
 "WHERE payment_method = 'pix'",
 );

 // W4 (centavos) DEPOIS do schema: colunas legadas REAL são convertidas
 // por afinidade (bancos novos já nascem INTEGER — no-op).
 _migrateMoneyToCents(db);
 }

 /// Migração v2 — fila offline (outbox): operações do caminho de dinheiro
 /// gravadas LOCALMENTE quando o modo SaaS está sem conexão, reenviadas
 /// pelo `OfflineSyncService` assim que a rede volta. `id` AUTOINCREMENT
 /// É a ordem FIFO de replay; `payload` é o JSON do comando original
 /// (entidade + parâmetros), reexecutado de forma idempotente nas RPCs.
 static void _schemaV2(Database db) {
 db.execute('''
 CREATE TABLE IF NOT EXISTS pending_ops (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 op_type TEXT NOT NULL,
 payload TEXT NOT NULL,
 created_at INTEGER NOT NULL,
 attempt_count INTEGER NOT NULL DEFAULT 0,
 last_error TEXT
 );
 ''');
 }

 /// v3 — Facturas personalizadas (add-on `ao_custom_invoice`).
 ///
 /// Documento por loja com número sequencial dentro da loja
 /// (`UNIQUE(store_id, invoice_number)` garante que MAX+1 nunca duplica).
 /// O corpo completo é guardado como JSON (items snapshot, descontos,
 /// notas, método de pagamento) — a factura é um documento, não um
 /// agregado com RPCs de dinheiro.
 static void _schemaV3(Database db) {
 db.execute('''
 CREATE TABLE IF NOT EXISTS custom_invoices (
 id TEXT PRIMARY KEY,
 store_id TEXT NOT NULL,
 invoice_number INTEGER NOT NULL,
 payload TEXT NOT NULL,
 created_at INTEGER NOT NULL,
 UNIQUE (store_id, invoice_number)
 );
 ''');
 db.execute('''
 CREATE INDEX IF NOT EXISTS idx_custom_invoices_store
 ON custom_invoices (store_id, created_at DESC);
 ''');
 }

}

/// Uma migração de schema: versão (`PRAGMA user_version`) + função que
/// aplica a mudança. Cada migração roda na própria transação; a versão é
/// carimbada dentro dela (rollback desfaz schema E versão juntos).
class _Migration {
 const _Migration({
 required this.version,
 required this.description,
 required this.up,
 });

 /// Número da versão — deve ser estritamente crescente na lista.
 final int version;

 /// Descrição curta da mudança (auditoria do histórico de migrações).
 final String description;

 /// Aplica a migração (SQL idempotente para bancos legados).
 final void Function(Database db) up;
}
