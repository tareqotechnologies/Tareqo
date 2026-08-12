# 02 — Arquitetura

## Resumo

O Dumbhanengue segue a **Clean Architecture** em três camadas, todas dentro de `lib/`:

```text
lib/
├── main.dart                    # Bootstrap: inicializa Supabase + GetIt + ProviderScope
├── app.dart                     # Widget raiz (MaterialApp, tema, AuthGate)
├── core/                        # Preocupações transversais (não pertencem a nenhuma camada)
│   ├── config/                  # Configurações (Supabase URL/anon key via --dart-define)
│   ├── database/                # Facade SQLite (import condicional io × stub)
│   ├── di/                      # Service Locator (GetIt) — registro central de dependências
│   ├── errors/                  # (vazio — exceções de domínio substituem a antiga hierarquia Failure)
│   ├── i18n/                    # Helpers de L10n + strings de descrição de transações
│   ├── observability/           # Crash reporting (Sentry) — CrashReporting
│   ├── network/                 # Bootstrap do Supabase
│   ├── security/                # Armazenamento seguro (Keychain/Keystore)
│   ├── theme/                   # Tema Material 3 (AppTheme, AppColors)
│   └── utils/                   # Helpers genéricos (Formatters pt-BR)
├── domain/                      # NÚCLEO: regras de negócio puras, sem dependências externas
│   ├── entities/                # Entidades imutáveis (Freezed): Product, Sale, SaleItem, Debt, FinancialTransaction, AppUser
│   ├── repositories/            # Contratos abstratos (IProductRepository, ISaleRepository, ...)
│   └── usecases/                # Casos de uso — orquestram as regras de negócio
├── data/                        # Implementações concretas do que o domínio define
│   ├── datasources/
│   │   ├── auth/                # AuthRemoteDataSource (Supabase)
│   │   └── local/               # Contratos + impls em memória e SQLite (product, sale, financial_transaction, debt) + unit of work + catálogo de planos
│   ├── models/                  # DTOs serializáveis (reservado)
│   └── repositories/            # Implementações dos contratos do domínio (ProductRepositoryImpl, ...)
└── presentation/                # Tudo que o usuário vê e interage
    ├── controllers/             # Providers/notifiers do Riverpod (auth, products, sales, finance, debts)
    ├── screens/                 # Telas por módulo (auth, shell, dashboard, products, sales, financial, credit)
    └── widgets/                 # Widgets compartilhados (KpiCard, EmptyState, StatusChip, AppSheet, ...)
```

---

## Regra de dependência (o coração da arquitetura)

O fluxo de dependências aponta **sempre para dentro**:

```text
presentation → domain   (a UI conhece apenas abstrações: entidades, casos de uso, contratos)
data         → domain   (implementa os contratos do domínio)
core         → nada     (serve a todas as camadas)
domain       → nada     (não conhece Flutter, Dio, SQLite, Riverpod, GetIt...)
```

- **O domínio não importa nenhuma outra camada.** Entidades, contratos e casos de uso são Dart puro (com anotações Freezed para imutabilidade e serialização).
- **A inversão acontece na fiação:** quem decide *quais* implementações concretas alimentam os contratos é o **ServiceLocator** (GetIt) no bootstrap. Trocar SQLite por memória (ou por uma API REST no futuro) **não altera uma linha** do domínio ou da apresentação.

### Exemplo real: como uma tela chega aos dados

```text
ProductListScreen (widget)
      ↓ ref.watch
productsProvider (AsyncNotifier)
      ↓ ref.read
getProductsUseCaseProvider → GetProductsUseCase (domínio)
      ↓
IProductRepository (contrato do domínio)
      ↓ (implementação injetada via GetIt)
ProductRepositoryImpl → ProductLocalDataSource (camada data)
      ↓ (SQLite em nativas / memória na web)
banco dumbhanengue.db
```

A `presentation` conhece **apenas abstrações** — `Product`, `GetProductsUseCase`, `IProductRepository` — nunca datasources, SQL, Dio ou implementações concretas.

---

## Por que Clean Architecture neste projeto?

1. **Testabilidade:** casos de uso são testados com fakes dos contratos — sem servidor, sem banco, rápidos e determinísticos.
2. **Substituibilidade:** a persistência já migrou de memória → SQLite trocando **um único registro** no ServiceLocator; uma futura API REST seguiria o mesmo caminho.
3. **Manutenibilidade:** cada camada tem um contrato claro; desenvolvedores trabalham em módulos isolados.
4. **Escalabilidade da equipe:** as interfaces do domínio funcionam como "contratos" que permitem trabalho paralelo (data e presentation contra o mesmo domínio).

---

## Decisões estruturais importantes

### Contratos como interfaces (DIP)

`IProductRepository` é uma **interface abstrata** — apenas assinaturas (`getAll`, `getById`, `add`, `updateStock`). A implementação concreta (`ProductRepositoryImpl`, usando SQLite ou memória) vive na camada `data`. O domínio depende da abstração, nunca da implementação.

### GetIt como Service Locator (composition root)

`lib/core/di/service_locator.dart` registra **tudo** em `ServiceLocator.initialize()`:

1. `Dio`, `SecureStorageService` e `IAuthRepository`;
2. **Persistência condicional:**
   - `AppDatabase.openAppDatabase()` retorna `true` (nativas) → registra datasources **SQLite** + `SqliteUnitOfWork`;
   - `false` (web ou falha da lib nativa) → registra datasources **em memória** + unit of work no-op.
3. Repositórios e casos de uso (idênticos nos dois cenários, pois dependem apenas dos contratos).

```dart
if (await AppDatabase.openAppDatabase()) {
  AppDatabase.registerDatasources(instance);
} else {
  _registerInMemoryDatasources();
}
_registerRepositoriesAndUseCases();
```

### Riverpod + GetIt juntos

O **GetIt** entrega as instâncias (dependências concretas); o **Riverpod** define o grafo de estado reativo. A ponte é feita por providers simples:

```dart
final getProductsUseCaseProvider = Provider<GetProductsUseCase>(
  (ref) => ServiceLocator.instance<GetProductsUseCase>(),
);
```

Em **testes**, esses providers são sobrescritos com `overrideWithValue`/`overrideWith` — sem tocar no GetIt nem em datasources.

### Import condicional para a web (SQLite)

`dart:ffi` não existe no navegador. `lib/core/database/app_database.dart` usa:

```dart
export 'app_database_stub.dart' if (dart.library.io) 'app_database_io.dart';
```

- **`app_database_io.dart`** — abre `dumbhanengue.db`, cria schema, não semeia dados (banco nasce vazio), expõe transações re-entrantes;
- **`app_database_stub.dart`** — `openAppDatabase()` sempre retorna `false` (web cai para memória).

> ⚠️ **Manter as assinaturas de `openAppDatabase()` e `registerDatasources()` em sincronia** entre os dois arquivos (há comentário no código sobre isso).

---

## Agregações server-side (H2): a prévia do Z-report

Desde a **H2** (escala), o app não carrega o histórico inteiro para calcular totais: as agregações pesadas rodam **no Postgres** (RPCs `SECURITY DEFINER`), em **UMA chamada** — o dispositivo recebe só o número. Esse padrão cobre o fluxo de caixa (`get_cash_flow`), o relatório de vendas (`get_sales_report`), os KPIs do dashboard (`get_dashboard_kpis`) e a **prévia do fecho de caixa diário (Z-report)** — `get_cash_closing_summary` — o foco desta seção.

### O problema que a H2 resolve

A prévia do Z-report precisa do resumo do dia da loja: **total de vendas ativas**, o **esperado na gaveta** (só vendas em **dinheiro**) e a **abertura por forma de pagamento**, além do fecho já registrado (se houver). No modo local, o `GetCashClosingSummaryUseCase` lista **todas** as vendas e soma client-side (`aggregateCashClosingDay`). Para lojas com histórico grande (10k+ linhas), isso significa baixar e processar tudo no dispositivo a cada abertura da tela — latência e memória desnecessárias.

### O fluxo no modo Supabase (H2)

```text
CashClosingSheet (Financeiro → Fecho de caixa)
      │  ref.watch
      ▼
cashClosingSummaryProvider (Riverpod — FutureProvider.autoDispose)
      │  resolve storeId ativo + day = hoje
      ▼
GetCashClosingSummaryUseCase  (domínio)
      │  serverRepository != null (registrado só no modo Supabase)
      ▼
SupabaseCashClosingSummaryRepository  (data)
      │  UMA chamada RPC — o cliente nunca lista vendas
      ▼
supabaseClient.rpc('get_cash_closing_summary', {p_store_id, p_day})
      │  PostgREST → Postgres
      ▼
get_cash_closing_summary (SECURITY DEFINER + guarda is_my_store)
      ├─ Σ total das vendas ATIVAS do dia (todas as formas)
      ├─ Σ esperado na gaveta (só payment_method = 'cash')
      ├─ jsonb_object_agg por forma → abertura (JSONB)
      └─ fecho já registrado em cash_closings (se houver)
      │  devolve JSONB
      ▼
CashClosingSummary (day, total, esperado, abertura, fecho existente)  → UI
```

### Decisões de arquitetura

- **Agregar onde os dados moram:** a RPC soma no banco (`SUM(total_amount)` com `status = 'active'` na janela do dia) — o payload de rede é **sempre pequeno e constante**, independente do histórico (escala H2).
- **Guardas no servidor, não na UI:** `SECURITY DEFINER` + `SET search_path` + a guarda **`is_my_store(p_store_id)`** — a prévia é leitura para dono **e funcionários** da loja; a *confirmação* (fechar) é gerencial (`is_manager_of_store` na RPC `close_cash_register`). Mesmo um cliente modificado chamando o PostgREST direto é bloqueado.
- **O cliente envia só os parâmetros:** `p_store_id` e `p_day` (início do dia **local** convertido a UTC — mesma semântica do `close_cash_register`, janela `[p_day, p_day + 1 dia)`). Nenhum valor calculado sai do dispositivo.
- **Mesmo critério, dois lugares:** o modo local usa `aggregateCashClosingDay` (client-side) com **exatamente o mesmo critério** da RPC (vendas ativas; anuladas ficam de fora) — critério único compartilhado também com o `CloseCashRegisterUseCase`, para a prévia e a confirmação nunca divergirem.
- **Injeção opcional (DIP):** o `GetCashClosingSummaryUseCase` recebe `serverRepository` opcional (`instance.isRegistered<ICashClosingSummaryRepository>()`). Supabase → `SupabaseCashClosingSummaryRepository` (RPC); local/testes → `null` (fallback client-side). O domínio e a UI não mudam de um modo para o outro — apenas a fiação no ServiceLocator, como em toda troca de persistência deste projeto.

> **Verificação:** o `sql_check.sh` (19.6) e o `sql_check_live.sh` (35/35) validam a RPC contra Postgres 16/17 (SECURITY DEFINER, guarda, agregação server-side); o E2E `integration_test/cash_closing_summary_live_test.dart` comprova o **payload real** (`{p_store_id, p_day}` com o dia local em UTC) contra o Supabase de verdade.

---

## Padrão de erro: exceções de domínio + `CrashReporting`

O app **não** usa hierarquia `Failure`. Erros de negócio são **exceções de domínio** (ex.: `InvalidSaleException`, `InsufficientStockException`) lançadas pelos casos de uso e capturadas pelas telas, que as traduzem em mensagens amigáveis. Erros inesperados (e qualquer exceção capturada) são roteados para **`CrashReporting.capture`** — `debugPrint` em debug, **Sentry** em release quando `SENTRY_DSN` está presente (ver `lib/core/observability/crash_reporting.dart`).

---

## Documentos relacionados

- [Domínio](03-dominio.md) — entidades, contratos e casos de uso.
- [Camada de dados](04-dados.md) — datasources, SQLite e Unit of Work.
- [Apresentação](05-apresentacao.md) — providers, telas e widgets.
- [Migração do fecho de caixa](17-migracao-fecho-caixa.md) — runbook da Parte 25/26 (tabela `cash_closings` + RPCs `close_cash_register`/`get_cash_closing_summary`) aplicada no live.
