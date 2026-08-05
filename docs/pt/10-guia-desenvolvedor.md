# 10 — Guia do Desenvolvedor

Guia prático para rodar, testar e evoluir o Dumbhanengue ERP.

---

## Pré-requisitos

- Flutter 3.x (SDK Dart `^3.12.2`);
- Chrome (para rodar na web);
- Windows/mobile/desktop para persistência SQLite; **web** usa memória (fallback automático).

---

## Rodar o projeto

```bash
# Instalar dependências
flutter pub get

# Gerar código (Freezed + json_serializable) — necessário após criar/alterar
# classes anotadas com @freezed
dart run build_runner build --delete-conflicting-outputs

# Rodar no dispositivo/emulador
flutter run

# Rodar na web (fallback em memória)
flutter run -d chrome

# Testes
flutter test

# Análise estática
flutter analyze
```

### Apontar para outro projeto Supabase (ex.: produção)

```bash
flutter run --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=eyJ...
```

> A API base do `Dio` (`API_BASE_URL`) é configurada da mesma forma, com default `http://localhost:3000/api`.

### Definir o super admin

O super admin é identificado por um **papel em banco** — a tabela `public.super_admins` no Supabase (não existe mais e-mail hardcoded). Para promover um usuário (SQL Editor do projeto):

```sql
INSERT INTO public.super_admins (user_id)
SELECT id FROM auth.users WHERE email = 'admin@seudominio.com'
ON CONFLICT (user_id) DO NOTHING;
```

> O app consulta o papel via RPC `is_super_admin`; o RLS do servidor é a autoridade. Detalhes em [Multi-tenancy e Super Admin](11-multitenancy.md).

### Persistência ativa (Supabase × local)

Com o Supabase configurado (padrão — credenciais embutidas em `SupabaseConfig`), produtos, vendas, financeiro e fiado são gravados **remotamente** por tenant (RLS — datasources em `lib/data/datasources/remote/`). Para desenvolver com persistência local (SQLite em nativas / memória na web), rode com as variáveis **vazias**:

```bash
flutter run --dart-define=SUPABASE_URL= --dart-define=SUPABASE_ANON_KEY=
```

### Assinatura de release (Android)

A assinatura de produção lê `android/key.properties` (nunca versionado — ver `.gitignore` e o modelo documentado em `android/key.properties.example`).

- **Keystore:** `android/app/upload-keystore.jks` (já gerado — alias `upload`, RSA 2048, válido até 2053);
- **`key.properties`:** já preenchido com as credenciais geradas (senhas no arquivo — guarde-o num cofre de senhas junto com o `.jks`; se perder ambos, não publica atualizações);
- **⚠️ PKCS12 (JDK 9+):** o cofre e a chave usam a MESMA senha — `storePassword` e `keyPassword` devem ser iguais;
- **Sem `key.properties`** (CI/dev): o build de release cai para o keystore de **debug** — não publicável na loja;
- **Play Console:** publique o primeiro AAB com esta chave, ative o *Play App Signing* e registre a impressão SHA-256 da chave de upload em *Setup → App integrity*;
- **CI:** o pipeline atual NÃO assina o release (fallback debug). Para gerar artefatos publicáveis no CI, decodifique o keystore de um secret (instruções no `key.properties.example`).

Para conferir a chave:

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -storepass SUA_SENHA
```

---

## Mapa mental do fluxo de desenvolvimento

```text
Nova funcionalidade:
  1. Entidade no domínio (freezed)      → lib/domain/entities/
  2. Contrato de repositório            → lib/domain/repositories/
  3. Caso de uso + exceções de domínio  → lib/domain/usecases/
  4. Implementação no data              → lib/data/datasources/ (memória + SQLite)
                                          lib/data/datasources/remote/ (Supabase)
                                          lib/data/repositories/
  5. Registrar no ServiceLocator        → lib/core/di/service_locator.dart
  6. Provider Riverpod                  → lib/presentation/controllers/
  7. Tela/widget                        → lib/presentation/screens/ | widgets/
  8. Testes (domínio → dados → UI)      → test/
  9. `dart run build_runner build --delete-conflicting-outputs`
```

---

## Convenções do projeto

### Arquitetura (não negociável)

- **Regra de dependência:** `domain` não importa `data`, `presentation` ou `core` de infraestrutura; dependências apontam sempre para dentro;
- **Contratos como interfaces:** repositórios e datasources do domínio são `abstract interface class`; implementações vivem em `data`;
- **UI fina:** regras de negócio nos casos de uso; as telas apenas capturam exceções de domínio e exibem mensagens;
- **GetIt só no composition root:** quem entrega instâncias é o `ServiceLocator`; providers fazem a ponte para o Riverpod.

### Persistência

- **Duas implementações sempre:** ao criar um datasource, faça a versão **em memória** (`*_impl.dart`) e a **SQLite** (`*_sqlite_impl.dart`) implementando o mesmo contrato;
- **SQL parametrizado** (prepared statements) — nunca concatenação;
- **Serialização:** enums pelo nome, `DateTime` como epoch millis, `bool` como 0/1;
- **Transações:** múltiplas gravações relacionadas dentro de `IUnitOfWork` / `runInTransaction` (re-entrante);
- **Migrações leves:** `ALTER TABLE` idempotente em `AppDatabase.createSchema`, guardado por `PRAGMA table_info`;
- **⚠️ Sincronize as assinaturas** de `app_database_io.dart` ↔ `app_database_stub.dart`.

### SQLite para dados novos

Ao adicionar tabelas/colunas: crie no `createSchema` (com `CHECK` de salvaguarda), adicione migração idempotente se necessário, e estenda o seed se o demo precisar.

### Estado (Riverpod)

- Estado assíncrono → `AsyncNotifier`/`AsyncNotifierProvider` (AsyncValue: loading/error/data);
- Providers "ponte" para casos de uso via `ServiceLocator.instance<T>()`;
- `refresh()` = `invalidateSelf()` + `await future`;
- Recarregar listas dependentes com `ref.invalidate(...)` após mutações (ex.: venda → produtos, vendas, transações e caixa).

### UI

- Material 3, tema via `AppTheme` (`AppColors` para semântica: income/expense/warning);
- Formatação pt-BR via `Formatters` (moeda, data, dia relativo);
- Bottom sheets de formulário via `showAppSheet` + `AppSheetHeader`;
- Estados de tela: `EmptyState`, `ErrorView`, `KpiCard`, `StatusChip`, `SearchField`, `SectionHeader`.

### Testes

- Fakes dos contratos nos casos de uso; `openTestDatabase()` (SQLite in-memory) para dados;
- Overrides de provider nos testes de tela (`ProviderScope(overrides: [...])`);
- Toda exceção de domínio deve ter teste.

---

## Adicionando um novo módulo (passo a passo)

Exemplo fictício: módulo **Fornecedores**.

1. **Domínio:**
   - `Supplier` (entidade freezed) em `lib/domain/entities/`;
   - `ISupplierRepository` em `lib/domain/repositories/`;
   - `GetSuppliersUseCase`, `AddSupplierUseCase` em `lib/domain/usecases/`;
2. **Dados:**
   - `SupplierLocalDataSource` (contrato) + `SupplierLocalDataSourceImpl` (memória) + `SupplierSqliteDataSourceImpl`;
   - `SupplierRepositoryImpl`;
   - tabela `suppliers` em `AppDatabase.createSchema` (+ migração se houver banco antigo);
3. **DI:** registrar datasource (nos dois ramos do ServiceLocator), repositório e casos de uso;
4. **Apresentação:** `suppliers_providers.dart`, tela, sheet de cadastro;
5. **Testes:** use case, datasource SQLite, tela;
6. `dart run build_runner build --delete-conflicting-outputs` e `flutter test`.

---

## Comandos úteis

| Comando | Para quê |
| ------- | -------- |
| `flutter pub get` | Instalar dependências |
| `dart run build_runner build --delete-conflicting-outputs` | Gerar código Freezed/JSON |
| `flutter analyze` | Análise estática (lints) |
| `flutter test` | Rodar todos os testes |
| `flutter test test/<arquivo>` | Rodar um arquivo de teste |
| `flutter run -d chrome` | Rodar na web |
| `flutter run --dart-define=...` | Rodar com configurações customizadas |

---

## Documentos relacionados

- [Arquitetura](02-arquitetura.md) — regras estruturais.
- [Camada de dados](04-dados.md) — schema e convenções de persistência.
- [Multi-tenancy e Super Admin](11-multitenancy.md) — planos, aprovação de tenants e papéis.
- [Testes](09-testes.md) — como testar cada camada.
