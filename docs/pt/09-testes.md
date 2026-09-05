# 09 — Testes

O projeto tem **cobertura de testes em todas as camadas**, seguindo a testabilidade que a Clean Architecture proporciona. Os testes rodam na VM (sem emulador) — inclusive os de SQLite.

---

## Como executar

```bash
# Todos os testes
flutter test

# Um arquivo específico
flutter test test/domain/usecases/process_sale_use_case_sqlite_test.dart

# Com relatório de cobertura
flutter test --coverage
```

### Testes de schema SQL (Postgres)

- **`scripts/sql_check.sh`** — smoke test **end-to-end** contra um Postgres real (Docker/local): aplica `schema.sql` + `upgrade.sql` (confirmando idempotência), executa vendas/compras pelas RPCs e valida dinheiro (centavos), **FIFO por lotes** e a invariante `stock = Σ lotes`;
- **`scripts/sql_check_live.sh`** — verificação **read-only** do banco ao vivo (31 checks, incluindo os 7 W11: colunas, `stock_lots`/RLS/índices, corpo das RPCs e a invariante de lotes) — usado no [runbook de migração](16-migracao-w11.md).

> **SQLite na VM Windows:** o loader de `package:sqlite3` cai automaticamente para a `winsqlite3.dll` do sistema (via `AppDatabase.configureLoader` — probe defensivo em `test/helpers/test_sqlite.dart`). Nenhum setup manual é necessário.

---

## Estrutura

```text
test/
├── core/
│ ├── database/app_database_test.dart # Schema, transações re-entrantes, migrações W4/W11
│ ├── utils/quantity_test.dart # Milésimos ↔ unidades (W11)
│ ├── utils/scale_barcode_test.dart # Parser 20PPPPPWWWWW + normalização de PLU (W11)
│ └── security/secure_storage_service_test.dart # Backend em memória
├── data/
│ ├── datasources/local/
│ │ ├── product_sqlite_data_source_test.dart
│ │ ├── sale_sqlite_data_source_test.dart
│ │ ├── stock_lot_sqlite_data_source_test.dart # Ordem FIFO + escopo por loja (W11)
│ │ ├── purchase_sqlite_data_source_test.dart # Compras com validade/lote (W11)
│ │ ├── financial_transaction_sqlite_data_source_test.dart
│ │ ├── debt_sqlite_data_source_test.dart
│ │ └── sqlite_unit_of_work_test.dart
│ └── repositories/ # Repositórios (com fakes/impls em memória)
│ ├── product_repository_impl_test.dart
│ ├── sale_repository_impl_test.dart
│ ├── financial_transaction_repository_impl_test.dart
│ ├── debt_repository_impl_test.dart
│ └── auth_repository_impl_test.dart
├── domain/
│ ├── entities/ # financial_transaction_test, sale_test
│ └── usecases/
│ ├── add_debt_use_case_test.dart
│ ├── add_financial_transaction_use_case_test.dart
│ ├── get_cash_flow_use_case_test.dart
│ ├── get_pending_debts_use_case_test.dart
│ ├── get_settled_debts_use_case_test.dart
│ ├── product_use_cases_test.dart
│ ├── settle_debt_use_case_test.dart
│ ├── process_sale_use_case_test.dart # com fakes
│ ├── process_sale_use_case_sqlite_test.dart # com banco real em memória
│ ├── fifo_stock_use_case_test.dart # Baixa FIFO por lotes (W11)
│ └── add_purchase_use_case_test.dart # Entradas com validade (W11)
├── helpers/test_sqlite.dart # openTestDatabase(): sqlite in-memory + schema
├── presentation/
│ ├── controllers/expiry_alerts_provider_test.dart # Alertas vermelho/amarelo (W11)
│ └── screens/
│ ├── login_screen_test.dart
│ ├── app_shell_test.dart
│ ├── product_list_screen_test.dart
│ ├── new_sale_sheet_test.dart
│ ├── sales_screen_test.dart
│ ├── sale_detail_screen_test.dart
│ ├── financial_screen_test.dart
│ ├── add_debt_sheet_test.dart
│ ├── debts_screen_test.dart
│ ├── custom_invoice_screen_test.dart # Fluxo PERSISTIDO da factura (SQLite real)
│ └── quotation_screen_test.dart # Fluxo PERSISTIDO da cotação + transição de estado
└── widget_test.dart # Dashboard end-to-end com overrides (raiz de test/)
```

---

## Estratégia por camada

### Domínio (casos de uso)

- **Fakes dos contratos** (`IProductRepository`, `ISaleRepository`, `IDebtRepository`, `IFinancialTransactionRepository`, `IUnitOfWork`) — sem servidor, sem banco;
- Cobre cada exceção de domínio (`InvalidPriceException`, `InsufficientStockException`, `InvalidPeriodException`, `DebtNotFoundException`, idempotência da baixa...);
- **`process_sale_use_case_sqlite_test.dart`** testa o fluxo real com `openTestDatabase()` (banco em memória com schema do app) — valida atomicidade (rollback em falha) e integridade;
- **`fifo_stock_use_case_test.dart`** cobre a **baixa FIFO** (lote de validade mais próxima primeiro, excedente passando ao lote seguinte, sem validade por data de entrada), o `increase` criando lotes e a **pré-validação de estoque antes de qualquer mutação** (sem baixa parcial).

### Dados (datasources/repositórios SQLite)

- `test/helpers/test_sqlite.dart`:
 ```dart
 Database openTestDatabase() {
 AppDatabase.configureLoader();
 final db = sqlite3.openInMemory();
 db.execute('PRAGMA foreign_keys = ON;');
 AppDatabase.createSchema(db);
 return db;
 }
 ```
- Testam SQL, mapeamento de linhas (enum por nome, datas em epoch millis, bool 0/1), `CHECK` do schema e o `SqliteUnitOfWork` (BEGIN/COMMIT/ROLLBACK, fila FIFO);
- `stock_lot_sqlite_data_source_test.dart` valida a **ordem FIFO da query** (validade ASC → entrada ASC), o escopo por loja e a atualização atômica de `current_quantity`; `quantity_test.dart` e `scale_barcode_test.dart` cobrem a matemática de milésimos e o parser `20PPPPPWWWWW` (incl. normalização de PLU com zeros à esquerda).

### Apresentação (telas)

- **Providers sobrescritos** via `ProviderScope(overrides: [...])` — sem tocar no GetIt nem em datasources;
- Exemplo (`test/widget_test.dart`): simula sessão ativa (`authStateProvider.overrideWith(Stream.value(AppUser(...)))`), fakes de casos de uso e verifica KPIs + navegação do shell;
- Padrão: `await tester.pumpAndSettle()` + `expect(find.text(...), findsOneWidget)`;
- `expiry_alerts_provider_test.dart` valida a classificação dos alertas (vencido = vermelho, vencimento < 30 dias = amarelo) e a ordenação por urgência.
- **Fluxos persistidos de add-ons** (`custom_invoice_screen_test.dart`/`quotation_screen_test.dart`): criam facturas/cotações PELA UI contra o repositório real sobre `openTestDatabase()`, provam a persistência re-montando a árvore com o MESMO banco (o dado vem do SQLite, não de estado do widget) e validam a numeração sequencial (MAX+1) e a transição rascunho → enviada gravada no repositório.

---

## Padrões e convenções

| Padrão | Detalhe |
| ------ | ------- |
| Fakes por `implements` | Classes `_Fake...` implementam a interface do domínio (ex.: `_FakeGetProductsUseCase implements GetProductsUseCase`) |
| Overrides de provider | `productsProvider.overrideWithValue(...)`, `authStateProvider.overrideWith(...)` |
| Banco de teste | SQLite **em memória** (`sqlite3.openInMemory`) com schema real, sem seed |
| Atomicidade | Testes do `ProcessSaleUseCase` validam rollback total quando uma etapa falha |
| Imutabilidade | Listas imutáveis retornadas por datasources (testes verificam comportamentos de cópia/ordenação) |

---

## Documentos relacionados

- [Arquitetura](02-arquitetura.md) — por que os casos de uso são testáveis com mocks.
- [Guia do desenvolvedor](10-guia-desenvolvedor.md) — comandos e setup.
- [Fluxos de negócio](08-fluxos-de-negocio.md) — o que os testes de venda/fiado/caixa validam.
