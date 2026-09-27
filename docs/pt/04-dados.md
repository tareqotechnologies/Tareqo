# 04 — Camada de Dados

A camada `lib/data/` implementa concretamente o que o domínio declara. Ela contém:

- **Datasources** — fontes de dados locais (contratos + implementações), remotas de negócio (Supabase) e remotas de auth;
- **Repositórios** — implementações dos contratos do domínio;
- **Unit of Work** — transações atômicas (SQLite);
- **Catálogo de planos** — a tabela de preços real injetada no composition root (sem dados demo).

---

## Estrutura

```text
lib/data/
├── datasources/
│ ├── auth/
│ │ ├── auth_remote_data_source.dart # Contrato de auth remota
│ │ └── supabase_auth_remote_data_source.dart # Implementação com Supabase/gotrue
│ ├── remote/
│ │ ├── supabase_datasource_helpers.dart # Cliente + user_id da sessão
│ │ ├── supabase_product_data_source.dart # Produtos (Supabase)
│ │ ├── supabase_sale_data_source.dart # Vendas (insert aninhado sale + items)
│ │ ├── supabase_stock_lot_data_source.dart # Lotes FIFO (Supabase)
│ │ ├── supabase_financial_transaction_data_source.dart # Movimentações (Supabase)
│ │ ├── supabase_debt_data_source.dart # Dívidas/fiado (Supabase)
│ │ ├── supabase_plan_data_source.dart # Planos (Supabase)
│ │ ├── supabase_tenant_data_source.dart # Tenants + aprovação (Supabase)
│ │ ├── supabase_store_data_source.dart # Lojas (Supabase)
│ │ ├── supabase_employee_data_source.dart # Funcionários (Supabase)
│ │ └── supabase_plan_request_data_source.dart # Upgrades (Supabase)
│ └── local/
│ ├── product_local_data_source.dart # Contrato
│ ├── product_local_data_source_impl.dart # Memória
│ ├── product_sqlite_data_source_impl.dart # SQLite
│ ├── stock_lot_local_data_source.dart / _impl / _sqlite # Lotes FIFO (contrato + memória + SQLite)
│ ├── sale_local_data_source.dart / _impl / _sqlite
│ ├── financial_transaction_local_data_source.dart / _impl / _sqlite
│ ├── cash_closing_local_data_source.dart / _impl / _sqlite # Fecho de caixa (Z-report)
│ ├── debt_local_data_source.dart / _impl / _sqlite
│ ├── plan_local_data_source.dart / _impl # Contrato + memória (Contas)
│ ├── tenant_local_data_source.dart / _impl # Tenants (Contas)
│ ├── store_local_data_source.dart / _impl # Lojas (Contas)
│ ├── employee_local_data_source.dart / _impl # Funcionários (Contas)
│ ├── plan_request_local_data_source.dart / _impl # Upgrades (Contas)
│ ├── sqlite_unit_of_work.dart # IUnitOfWork real (transação)
│ └── plan_catalog.dart # Planos (catálogo real)
└── repositories/
 ├── product_repository_impl.dart
 ├── sale_repository_impl.dart
 ├── financial_transaction_repository_impl.dart
 ├── debt_repository_impl.dart
 ├── auth_repository_impl.dart
 ├── plan_repository_impl.dart / tenant_repository_impl.dart
 ├── store_repository_impl.dart / employee_repository_impl.dart
 └── plan_request_repository_impl.dart
```

---

## Duas implementações, um contrato

Cada `XxxLocalDataSource` é uma **interface**; há duas implementações:

| Contrato | Memória (`*_impl.dart`) | SQLite (`*_sqlite_impl.dart`) |
| -------- | ----------------------- | ----------------------------- |
| `ProductLocalDataSource` | `List<Product>` + seed | Tabela `products` |
| `StockLotLocalDataSource` | `List<StockLot>` + seed | Tabela `stock_lots` (ordem FIFO garantida na query) |
| `SaleLocalDataSource` | `List<Sale>` + seed | Tabelas `sales` + `sale_items` + `sale_lot_consumption` (transação única) |
| `FinancialTransactionLocalDataSource` | `List<FinancialTransaction>` + seed | Tabela `financial_transactions` |
| `CashClosingLocalDataSource` | `List<CashClosing>` + seed | Tabela `cash_closings` (UPSERT por loja + dia) |
| `DebtLocalDataSource` | `List<Debt>` + seed | Tabela `debts` |

**Quem escolhe qual usar?** O `ServiceLocator`, por precedência:

```dart
if (SupabaseConfig.isConfigured) {
 _registerSupabaseDatasources(); // remoto: SaaS, RLS por tenant
} else if (await AppDatabase.openAppDatabase()) {
 AppDatabase.registerDatasources(instance); // SQLite (nativas)
} else {
 _registerInMemoryDatasources(); // memória (web/fallback)
}
```

> Com `SupabaseConfig.isConfigured = true` (padrão, credenciais embutidas), os **datasources remotos** são os ativos. Para usar persistência local, rode com `--dart-define=SUPABASE_URL= --dart-define=SUPABASE_ANON_KEY=` (vazios → `isConfigured = false`).

> Convenção de paridade: a listagem em memória ordena por nome case-insensitive e o SQLite usa `ORDER BY name COLLATE NOCASE` — a UI se comporta igual nas três fontes.

---

## Datasources remotos (Supabase)

Implementam **os mesmos contratos** (`ProductLocalDataSource`, `SaleLocalDataSource`, `FinancialTransactionLocalDataSource`, `DebtLocalDataSource`) com o backend no Postgres do Supabase — o domínio, os casos de uso e a UI não mudam.

- **Tenant isolation:** todo INSERT grava `user_id` (da sessão — `requireCurrentUserId()`); o **RLS** (`auth.uid() = user_id`) filtra no banco e o **trigger** `set_tenant_user_id()` no schema reforça o valor no servidor (à prova de forja);
- **Enums** persistidos pelo nome; **datas** como TIMESTAMPTZ (ISO 8601); **booleanos** como BOOLEAN;
- **Vendas:** a `Sale` + `SaleItem`s são gravadas em **uma única requisição** via insert aninhado do PostgREST (FK `sale_items.sale_id → sales.id`), com `defaultToNull: false`; a leitura usa embedded resource `select('*, sale_items(*)')`;
- **Unit of Work:** no-op (cada chamada REST é uma transação própria no banco) — a atomicidade cross-tabela (venda + estoque + caixa) fica a cargo das RPCs `SECURITY DEFINER` (`process_sale`, `process_purchase`), que rodam em transação única no servidor e aplicam a baixa FIFO por lotes (W11);
- **Sem sessão:** os datasources lançam `StateError` — as telas de dados só são acessíveis após o login (`AuthGate`).

### Agregações server-side (W5/H2)

Para **escala**, o app não baixa o histórico inteiro para somar no cliente: as agregações pesadas rodam **no Postgres** em RPCs `SECURITY DEFINER` (guarda `is_my_store`, valores em BIGINT/centavos), e o dispositivo recebe só os números — **UMA chamada**, payload constante. O padrão cobre quatro frentes:

| RPC | Repositório | Agrega |
| --- | ----------- | ------ |
| `get_dashboard_kpis` (W5) | `SupabaseDashboardKpisRepository` | KPIs do dashboard — faturamento, ticket, contagens — em vez de 4 listagens somadas no cliente (`GetDashboardKpisUseCase`) |
| `get_cash_flow` (H2) | `SupabaseCashFlowRepository` | entradas/saídas **paid** do período + saldo (`GetCashFlowUseCase`) |
| `get_sales_report` (H2) | `SupabaseSalesReportRepository` | faturamento, lucro bruto, top 5 vendidos e vendas por dia no fuso do dispositivo (`GetSalesReportUseCase`) |
| `get_cash_closing_summary` (H2) | `SupabaseCashClosingSummaryRepository` | prévia do Z-report: total/esperado na gaveta/abertura por forma + fecho já registrado (`GetCashClosingSummaryUseCase`) |

**Como a fiação funciona (DIP):** os casos de uso recebem um `serverRepository` **opcional** — registrado **só no modo Supabase** via `instance.isRegistered<I…Repository>()` no ServiceLocator (ex.: `ICashClosingSummaryRepository`, `ICashFlowRepository`); local/testes recebem `null` e caem no **fallback client-side** com o **mesmo critério** da RPC (ex.: `aggregateCashClosingDay` espelha `close_cash_register`/`get_cash_closing_summary`). O domínio e a UI não mudam de um modo para o outro — apenas a fiação, como em toda troca de persistência deste projeto.

**Leituras de listagem (H2):** o complemento das agregações é a **paginação keyset** (`fetchAllKeyset` — cursor estável no `id`, lotes de `SupabaseQueryLimits.pageSize`), que substitui o antigo `.limit(1000)` em todos os `getAll` remotos — resposta pequena e constante mesmo para lojas com 10k+ linhas.

> Ver o padrão completo, com diagrama do fluxo da prévia do Z-report, em [Arquitetura — Agregações server-side (H2)](02-arquitetura.md); os fluxos de negócio (fecho de caixa) em [Fluxos de negócio](08-fluxos-de-negocio.md).

O schema (tabelas, RLS, políticas, índices, triggers e seed) está em [`supabase/schema.sql`](../../supabase/schema.sql), validado em PostgreSQL 16 (CI e `sql_check.sh` rodam contra Postgres 16 em Docker).

---

## Persistência SQLite

### Onde o banco vive

- Arquivo: **`tareqo.db`** em `getApplicationDocumentsDirectory()` (via `path_provider`).
- `PRAGMA foreign_keys = ON` ao abrir.
- Na web o SQLite **não roda** (`dart:ffi` inexistente) → import condicional para `app_database_stub.dart` → memória. Em testes na VM Windows, o `package:sqlite3` cai para a `winsqlite3.dll` do sistema (ver `test/helpers/test_sqlite.dart`).

### Schema do banco

Desde a W4, dinheiro é **INTEGER em centavos**; desde a W11, quantidades são **INTEGER em milésimos** (1000 = 1 unidade/kg) — mesma filosofia dos centavos, sem ponto flutuante no dinheiro nem na quantidade.

```sql
CREATE TABLE products (
 id TEXT PRIMARY KEY,
 store_id TEXT NOT NULL DEFAULT 'st1',
 name TEXT NOT NULL,
 description TEXT NOT NULL DEFAULT '',
 purchase_price INTEGER NOT NULL CHECK (purchase_price >= 0), -- centavos (W4)
 sale_price INTEGER NOT NULL CHECK (sale_price >= 0), -- centavos (W4)
 stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0), -- milésimos (W11)
 code TEXT, -- PLU/código de balança etiquetadora (W11, opcional)
 venda_por_fracao INTEGER NOT NULL DEFAULT 0, -- 0/1: venda por peso (W11)
 unit_label TEXT NOT NULL DEFAULT 'un', -- kg | un (W11)
 type TEXT NOT NULL DEFAULT 'resale' -- tipo estrutural (Fase 1): nome do enum ProductType
);

CREATE TABLE sales (
 id TEXT PRIMARY KEY,
 store_id TEXT NOT NULL DEFAULT 'st1',
 sale_number INTEGER NOT NULL DEFAULT 0, -- sequencial por loja (S-00001)
 total_amount INTEGER NOT NULL CHECK (total_amount >= 0), -- centavos
 payment_method TEXT NOT NULL, -- nome do enum (estável)
 date_time INTEGER NOT NULL, -- epoch millis
 status TEXT NOT NULL DEFAULT 'active', -- active | cancelled (anulação)
 cancelled_at INTEGER -- momento da anulação (NULL se ativa)
);

CREATE TABLE sale_items (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 sale_id TEXT NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
 product_id TEXT NOT NULL,
 product_name TEXT NOT NULL, -- snapshot
 quantity INTEGER NOT NULL CHECK (quantity > 0), -- milésimos (W11)
 unit_price INTEGER NOT NULL CHECK (unit_price >= 0) -- centavos
);
CREATE INDEX idx_sale_items_sale_id ON sale_items(sale_id);

-- Consumo de LOTES por venda — gravado na MESMA transação da venda. Permite
-- à anulação devolver o estoque aos lotes EXATOS consumidos (preservando
-- validade e custo de cada lote).
CREATE TABLE sale_lot_consumption (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 sale_id TEXT NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
 lot_id TEXT NOT NULL,
 product_id TEXT NOT NULL,
 quantity INTEGER NOT NULL CHECK (quantity > 0) -- milésimos (W11)
);
CREATE INDEX idx_sale_lot_consumption_sale ON sale_lot_consumption(sale_id);

CREATE TABLE financial_transactions (
 id TEXT PRIMARY KEY,
 store_id TEXT NOT NULL DEFAULT 'st1',
 description TEXT NOT NULL,
 amount INTEGER NOT NULL CHECK (amount >= 0), -- centavos
 type TEXT NOT NULL, -- income | expense
 category TEXT NOT NULL,
 date INTEGER NOT NULL, -- epoch millis
 status TEXT NOT NULL DEFAULT 'paid', -- paid | pending
 debt_id TEXT -- vínculo com debts (fiado)
);

CREATE TABLE debts (
 id TEXT PRIMARY KEY,
 store_id TEXT NOT NULL DEFAULT 'st1',
 debt_number INTEGER NOT NULL DEFAULT 0, -- sequencial por loja (D-00001)
 person_name TEXT NOT NULL,
 amount INTEGER NOT NULL CHECK (amount >= 0), -- centavos
 due_date INTEGER NOT NULL, -- epoch millis
 is_customer_debt INTEGER NOT NULL, -- 0/1
 is_paid INTEGER NOT NULL DEFAULT 0, -- 0/1
 paid_at INTEGER, -- epoch millis (data da baixa)
 customer_id TEXT -- vínculo com customers
);

CREATE TABLE customers (
 id TEXT PRIMARY KEY,
 store_id TEXT NOT NULL DEFAULT 'st1',
 name TEXT NOT NULL,
 phone TEXT NOT NULL DEFAULT '',
 email TEXT NOT NULL DEFAULT ''
);

CREATE TABLE purchases (
 id TEXT PRIMARY KEY,
 store_id TEXT NOT NULL DEFAULT 'st1',
 purchase_number INTEGER NOT NULL DEFAULT 0, -- sequencial por loja (C-00001)
 supplier_name TEXT NOT NULL,
 total_amount INTEGER NOT NULL CHECK (total_amount >= 0), -- centavos
 payment_method TEXT NOT NULL DEFAULT 'cash', -- forma de pagamento do fornecedor
 date_time INTEGER NOT NULL
);

CREATE TABLE purchase_items (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 purchase_id TEXT NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
 product_id TEXT NOT NULL,
 product_name TEXT NOT NULL,
 quantity INTEGER NOT NULL CHECK (quantity > 0), -- milésimos (W11)
 unit_price INTEGER NOT NULL CHECK (unit_price >= 0), -- centavos
 expiry_date INTEGER, -- validade do lote criado por este item (W11)
 UNIQUE (purchase_id, product_id)
);
CREATE INDEX idx_purchase_items_purchase_id ON purchase_items(purchase_id);

-- W11 — Lotes FIFO: cada entrada de mercadoria cria um lote; a baixa no PDV
-- consome em ordem de validade (mais próximo primeiro) e, sem validade, por
-- data de entrada. current_quantity = quantidade ATUAL em milésimos.
CREATE TABLE stock_lots (
 id TEXT PRIMARY KEY,
 store_id TEXT NOT NULL DEFAULT 'st1',
 product_id TEXT NOT NULL,
 entry_date INTEGER NOT NULL, -- epoch millis (data de entrada)
 expiry_date INTEGER, -- validade (opcional, NULL = sem)
 initial_quantity INTEGER NOT NULL CHECK (initial_quantity >= 0), -- milésimos
 current_quantity INTEGER NOT NULL CHECK (current_quantity >= 0), -- milésimos
 cost_price INTEGER NOT NULL CHECK (cost_price >= 0) -- centavos
);
CREATE INDEX idx_stock_lots_product ON stock_lots(product_id, store_id);
CREATE INDEX idx_stock_lots_expiry ON stock_lots(expiry_date) WHERE current_quantity > 0;

-- Fecho de caixa diário (Z-report) — um fecho por loja por dia. closing_date
-- = início do dia local em ms (época); expected_cash = o que deveria estar na
-- gaveta (Σ vendas ATIVAS em DINHEIRO do dia); counted_cash = dinheiro físico
-- contado na conferência; sales_by_method = abertura por forma (JSON).
CREATE TABLE cash_closings (
 id TEXT PRIMARY KEY,
 store_id TEXT NOT NULL DEFAULT 'st1',
 closing_date INTEGER NOT NULL, -- epoch millis (início do dia local)
 total_sales INTEGER NOT NULL CHECK (total_sales >= 0), -- centavos
 expected_cash INTEGER NOT NULL CHECK (expected_cash >= 0), -- centavos
 counted_cash INTEGER NOT NULL CHECK (counted_cash >= 0), -- centavos
 sales_by_method TEXT NOT NULL DEFAULT '{}', -- JSON (method.name → centavos)
 closed_at INTEGER NOT NULL -- epoch millis
);
CREATE UNIQUE INDEX uq_cash_closings_store_day ON cash_closings(store_id, closing_date);
CREATE INDEX idx_cash_closings_store ON cash_closings(store_id);
```

**Convenções de serialização:**

| Tipo | Persistido como |
| ---- | --------------- |
| Enum | **Nome** (`payment_method`, `type`, `status`) — estável na serialização |
| `DateTime` | Epoch millis (`int`) |
| `bool` | `0`/`1` |
| Dinheiro | `INTEGER` — **centavos** (W4) |
| Quantidade | `INTEGER` — **milésimos** (W11: `1000` = 1 unidade/kg) |

Os `CHECK` (`stock_quantity >= 0`, `amount >= 0`, `quantity > 0`) são a **salvaguarda final** do banco; as regras de negócio continuam no domínio.

### Migrações leves (idempotentes)

`AppDatabase.createSchema` aplica `ALTER TABLE` para bancos já existentes:

1. **`debts.is_paid`** — adiciona com `DEFAULT 0` (dívidas antigas ficam pendentes);
2. **`financial_transactions.debt_id`** — adiciona `NULL` (dívidas antigas quitarão via nova entrada, sem duplicata);
3. **`debts.paid_at`** — adiciona `NULL` (dívidas já quitadas ficam sem data de baixa até nova quitação);
4. **`store_id`** em todas as 6 tabelas de negócio (Fase 2) — adiciona `'st1'` + índices por loja;
5. **`sales.sale_number`** — sequencial por loja (S-00001…), backfill em ordem de data; único `(store_id, sale_number)`;
6. **`purchases.purchase_number`** — sequencial por loja (C-00001…), backfill em ordem de data; único `(store_id, purchase_number)`;
7. **`debts.debt_number`** — sequencial por loja (D-00001…), backfill em ordem de vencimento; único `(store_id, debt_number)`;
8. **`purchases.payment_method`** — forma de pagamento do fornecedor (mesmo enum de vendas), adicionada como `'cash'` (compras antigas eram despesas imediatas à vista);
9. **`sales.status` + `sales.cancelled_at`** (anulação de venda) — `status` com `DEFAULT 'active'` (todas as vendas existentes são ativas — nunca foram anuladas) e `cancelled_at` NULL. Guard idempotente: presença da coluna `status`;
10. **W11 (FIFO + validade + milésimos)** — bancos antigos recebem as colunas `code`/`venda_por_fracao`/`unit_label` (products) e `expiry_date` (purchase_items); **todas as quantidades** (products, sale_items, purchase_items) são convertidas de unidades inteiras para **milésimos (×1000)**; e cada produto com estoque ganha um **lote inicial** (`lot-mig-…`, sem validade, custo = preço de compra) para a invariante `stock = Σ lotes` valer desde o primeiro dia. Guard idempotente: presença da coluna `code` (adicionada só nesta migração) — a reconversão ×1000 nunca reexecuta.
11. **Fase 1 (tipo estrutural do produto)** — bancos antigos recebem a coluna `products.type` com `DEFAULT 'resale'` (produtos existentes já eram compráveis e vendáveis e **não** são reclassificados automaticamente). **Sem `CHECK` de enum**: a validação vive no datasource (`firstWhere(...orElse: resale)`), então um valor futuro de uma versão nova do app não fica bloqueado pela restrição antiga nem quebra a leitura. Guard idempotente: presença da coluna `type`; `PRAGMA user_version` passa a **7** (`AppDatabase.currentSchemaVersion`).

As migrações de numeração rodam **depois** da de `store_id` (os backfills referenciam `store_id`). Todas usam `PRAGMA table_info` para verificar a coluna antes — **seguras para re-execução** (bancos novos já criam as colunas no `CREATE TABLE`).

### Sem seed automático

O banco **não semeia dados de demonstração**: `AppDatabase.initialize` apenas cria o schema e migra dinheiro para centavos (W4) e quantidades para milésimos (W11) — produtos, vendas, caixa, fiado, clientes e compras nascem **vazios** e só registram dados reais criados pelo usuário.

---

## Unit of Work (transações atômicas)

### Contrato (domínio)

```dart
abstract interface class IUnitOfWork {
 Future<T> run<T>(Future<T> Function() action);
}
```

### Implementação SQLite (`SqliteUnitOfWork`)

- Executa `action()` dentro de **`BEGIN IMMEDIATE` → `COMMIT`/`ROLLBACK`**.
- `BEGIN IMMEDIATE` adquire a **trava de escrita** no início — fecha a janela TOCTOU entre pré-validação de estoque e gravação.
- **Fila FIFO interna:** serializa transações concorrentes no mesmo processo (a conexão não aceita transações aninhadas de fluxos diferentes).

### Transações re-entrantes (`AppDatabase`)

O SQLite **não aceita transações aninhadas**. Por isso `AppDatabase` mantém um **contador de profundidade** (`_transactionDepth`):

- chamada externa → emite `BEGIN IMMEDIATE` de verdade (incrementa para 1);
- chamadas aninhadas (ex.: `SaleSqliteDataSourceImpl.add` dentro de `ProcessSaleUseCase` via `runInTransaction`) → apenas incrementam o contador e **se juntam** à transação externa;
- `commit`/`rollback` só são emitidos quando o contador volta a 0.

> **Atenção:** **Invariante global:** o contador é estático e assume **uma única conexão** (Database singleton) e **um** `IUnitOfWork` por processo — como o app registra. Não abra múltiplas conexões transacionais concorrentes.

### Implementação em memória

`_DirectUnitOfWork` (no `service_locator.dart`) é um **no-op**: em memória a execução já é sequencial — mas **sem garantia de atomicidade** em falha parcial (escritas em memória praticamente não falham).

---

## Repositórios (implementações)

São **portas burras**: apenas delegam para o datasource injetado.

| Implementação | Contrato do domínio | Delega para |
| ------------- | ------------------- | ----------- |
| `ProductRepositoryImpl` | `IProductRepository` | `ProductLocalDataSource` |
| `SaleRepositoryImpl` | `ISaleRepository` | `SaleLocalDataSource` |
| `FinancialTransactionRepositoryImpl` | `IFinancialTransactionRepository` | `FinancialTransactionLocalDataSource` (o filtro `getByPeriod` roda em Dart) |
| `DebtRepositoryImpl` | `IDebtRepository` | `DebtLocalDataSource` |
| `AuthRepositoryImpl` | `IAuthRepository` | `AuthRemoteDataSource` |

Nenhum repositório sabe se os dados vêm de memória, SQLite ou API — trocar a persistência é trocar **um registro no ServiceLocator**.

---

## Datasource remoto (autenticação)

- `AuthRemoteDataSource` — contrato (`signUp`, `signIn`, `signOut`, `authStateChanges`);
- `SupabaseAuthRemoteDataSourceImpl` — usa `Supabase.instance.client.auth` (gotrue) e **converte o `User` do Supabase para `AppUser`** do domínio aqui (as camadas acima nunca enxergam gotrue).

Detalhe importante: no `signUp`, se a **confirmação de e-mail** estiver ativa, `response.user` pode ser `null` (conta criada, sessão ainda não) → retorna um `AppUser` com **id placeholder** (`fallbackEmail`); a sessão real só chega após confirmar.

---

## Camada de Contas (multi-tenancy)

Os datasources de Contas (planos, tenants, lojas, funcionários e upgrades) seguem o **mesmo padrão de dupla implementação**: contrato + memória (`*_impl.dart`) no ramo local e datasource Supabase (`remote/`) no ramo remoto. Em dev local, o composition root injeta apenas o **catálogo real de planos**; tenant, lojas, funcionários e upgrades nascem vazios — o dono passa pelo onboarding e pela aprovação. Detalhes do fluxo em [Multi-tenancy e Super Admin](11-multitenancy.md).

---

## Sem dados de demonstração

O app **não semeia conteúdo de exemplo** (nem local nem no schema de produção): o único dado injetado é o **catálogo real de planos** (`PlanCatalog`, espelhado na Parte 2 do `schema.sql`). Produtos, vendas, movimentações, fiado, clientes e compras nascem vazios — os períodos (Hoje/7 dias/Mês) refletem apenas dados reais. Bases já existentes que receberam o seed antigo podem ser limpas com `supabase/cleanup_demo_data.sql`.

---

## Documentos relacionados

- [Arquitetura](02-arquitetura.md) — onde a camada de dados se encaixa.
- [Fluxos de negócio](08-fluxos-de-negocio.md) — transações em ação (venda atômica).
- [Multi-tenancy e Super Admin](11-multitenancy.md) — planos, tenants, lojas e funcionários no banco.
- [Guia do desenvolvedor](10-guia-desenvolvedor.md) — como rodar os testes SQLite.
