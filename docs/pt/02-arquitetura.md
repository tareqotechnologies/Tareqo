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
│   ├── errors/                  # Hierarquia de Failure (ServerFailure, NetworkFailure, CacheFailure)
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
│   │   └── local/               # Contratos + impls em memória e SQLite (product, sale, financial_transaction, debt) + unit of work + seed
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

- **`app_database_io.dart`** — abre `dumbhanengue.db`, cria schema, semeia demo, expõe transações re-entrantes;
- **`app_database_stub.dart`** — `openAppDatabase()` sempre retorna `false` (web cai para memória).

> ⚠️ **Manter as assinaturas de `openAppDatabase()` e `registerDatasources()` em sincronia** entre os dois arquivos (há comentário no código sobre isso).

---

## Padrão de erro: `Failure`

`lib/core/errors/failure.dart` define uma hierarquia **sealed**:

- `Failure(message)` — base;
- `ServerFailure` — erro HTTP (4xx/5xx);
- `NetworkFailure` — conectividade;
- `CacheFailure` — persistência local.

As camadas convertem exceções de infraestrutura em `Failure` antes de expor à UI, mantendo o desacoplamento. (As exceções de **domínio** — `InvalidSaleException`, `InsufficientStockException`, etc. — são lançadas pelos casos de uso e capturadas pelas telas; ver [Domínio](03-dominio.md).)

---

## Documentos relacionados

- [Domínio](03-dominio.md) — entidades, contratos e casos de uso.
- [Camada de dados](04-dados.md) — datasources, SQLite e Unit of Work.
- [Apresentação](05-apresentacao.md) — providers, telas e widgets.
