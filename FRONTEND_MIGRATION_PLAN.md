# TAREQO — Plano Técnico de Migração do Frontend

**Versão**: 1.0 — plano apenas, sem implementação
**Autor**: Arquiteto Sénior Flutter
**Data**: 3 de novembro de 2026
**Base**: `AUDIT.md`, `SCREEN_INVENTORY.md` e leitura do código em `lib/`

---

## 1. Sumário executivo

Este plano substitui **apenas a camada de apresentação** do TAREQO por um design system e ecrãs novos, mantendo intactos:

- `lib/domain/**` (entidades, use cases, contratos de repositório);
- `lib/data/**` (datasources, repositórios, serviços, modelos);
- `supabase/**`, `sqlcheck_stub.sql`, migrations e regras de negócio;
- autenticação, sessão, MFA, biometria e RLS;
- APIs, nomes de RPC, payloads e serialização.

A estratégia é **strangler fig com troca de ponto de entrada por ecrã**: cada ecrã novo é construído ao lado do antigo, entra em produção atrás de um interruptor de compilação e só substitui o antigo depois de cumprir os critérios de aceitação da fase. Em qualquer momento é possível reverter uma tela sem tocar em dados, backend ou fluxo.

**Nenhuma reconstrução é iniciada nesta fase.** O documento termina com os pontos que exigem a tua autorização.

---

## 2. Linha de base (medida, não estimada)

| Métrica | Valor |
|---|---|
| Ficheiros Dart em `lib/` | 542 (540 nas 5 camadas + `main.dart` + `app.dart`) |
| `lib/core` | 52 |
| `lib/data` | 135 |
| `lib/domain` | 202 (86 entidades + 74 use cases + 41 interfaces de repositório + 1 serviço) |
| `lib/presentation` | 147 (71 em `screens/`, 53 em `widgets/`, 23 em `controllers/`, 0 rotas) |
| Ficheiros gerados (`*.freezed.dart`, `*.g.dart`) | 54 |
| Testes (`test/` + `integration_test/`) | 261 |
| — `test/presentation` | 100 |
| — `test/data` | 64 |
| — `test/core` | 50 |
| — `test/domain` | 41 |
| — `test/docs` | 1 |
| Imagens golden | 92 em 7 ficheiros de teste |
| Rotas nomeadas | **0** (navegação por índice + `MaterialPageRoute`) |
| Localizações | pt / en / fr (`lib/l10n` + ARB) |

### 2.1 Documentos existentes que o plano respeita
- `docs/pt/23-design-system-e-convencoes-ui-ux.md` — tokens, estados, motion, acessibilidade, guard rails.
- `docs/pt/21-plano-evolucao-ui-ux.md` — princípios e fases UI/UX já executadas.
- `docs/pt/09-testes.md` — estratégia por camada.

O redesign **não contradiz** estes documentos: cria uma v5 aditiva sobre os mesmos tokens e convenções.

---

## 3. Classificação dos ficheiros por responsabilidade

> Critério: **quem pode mudar sem alterar contrato**. “Apresentação” pode ser reescrita; “Integração” e “Negócio” não.

### 3.1 Apresentação — substituível

| Caminho | Ficheiros | Notas |
|---|---|---|
| `lib/presentation/screens/**` | 71 | 40 destinos de ecrã/gate inventariados e 24 sheets/diálogos (muitos sheets são classes privadas dentro dos ficheiros de ecrã); os restantes ficheiros são `part`/widgets auxiliares (ex.: `sales_widgets`, `stores_widgets_*`, `admin_*_widgets`) |
| `lib/presentation/widgets/**` | 53 | Design system v4 (`AppButton`, `AppCard`, `AppSheet`, `EmptyState`, `ErrorView`, `Skeleton`, etc.) |
| `lib/presentation/controllers/**` | 23 | Providers Riverpod — **fronteira sensível**: orquestram use cases, mas também importam serviços de `data/` (ver §3.4) |
| `lib/presentation/routes/` | 0 | Apenas `.gitkeep` |

**Dentro da apresentação, mas com cuidado:**
- `lib/core/theme/**` (4 ficheiros) — partilhado por toda a UI. Alterações são **aditivas** (novos tokens), nunca destrutivas.
- `lib/core/ui/**` (2) — `haptics`, `dashed_circle_painter`.
- `lib/core/i18n/**` (5) e `lib/l10n/**` — apenas **adição de chaves**; nunca remover chaves em uso.

### 3.2 Integração — congelada

| Caminho | Ficheiros | Conteúdo |
|---|---|---|
| `lib/data/datasources/**` | 88 | Supabase remoto + SQLite local |
| `lib/data/repositories/**` | 30 | Implementações de repositório |
| `lib/data/services/**` | 17 | `OfflineSyncService`, `AddOnExpiryService`, conta local, etc. |
| `lib/core/network/**` | 7 | HTTP com timeout/retry, cert pinning, deep links, bootstrap Supabase |
| `lib/core/database/**` | 3 | Abertura SQLite |
| `lib/core/security/**` | 5 | Secure storage, biometria, MFA, cifra de payload |
| `lib/core/config/**` | 4 | Flavors, Supabase, suporte |
| `lib/core/platform/**`, `lib/core/observability/**` | 4 | Backup exclusion, Sentry |
| `supabase/**`, `sqlcheck_stub.sql` | — | Backend e schema |

### 3.3 Lógica de negócio — congelada

| Caminho | Ficheiros | Conteúdo |
|---|---|---|
| `lib/domain/entities/**` | 86 | 25 entidades + gerados Freezed/JSON |
| `lib/domain/usecases/**` | 74 | Regras: venda, compra, fiado, caixa, MFA, planos, produção… |
| `lib/domain/repositories/**` | 41 | Contratos |
| `lib/domain/services/**` | 1 | Serviço de domínio |
| `lib/core/share/**` | 7 | Exportadores PDF/recibo (infraestrutura de saída — **não é UI**) |
| `lib/core/utils/**` | 11 | `money`, `quantity`, `formatters`, `password_policy`, `period_utils`, `scale_barcode` |

### 3.4 Fugas de fronteira já existentes (a conter, não a “corrigir” à força)

Detetadas por análise de imports:

| Ficheiro de apresentação | Importa | Consequência |
|---|---|---|
| `controllers/account_providers.dart` | `data/services/empty_employee_realtime_signal_source.dart` | Camada de estado conhece implementação |
| `controllers/addon_expiry_provider.dart` | `data/services/addon_expiry_service.dart` | idem |
| `controllers/addon_providers.dart` | `data/datasources/local/addon_local_data_source.dart` | idem |
| `controllers/auth_providers.dart` | `data/datasources/auth/supabase_mfa_server_port.dart` | idem |
| `controllers/dashboard_providers.dart` | `data/services/offline_sync_service.dart` | idem |
| `screens/credit/add_debt_sheet.dart` | `data/services/offline_sync_service.dart` | UI conhece outbox |
| `screens/credit/debts_screen.dart` | idem | idem |
| `screens/purchases/add_purchase_sheet.dart` | idem | idem |
| `screens/sales/new_sale_sheet.dart` | idem | idem |
| `screens/sales/sale_detail_screen.dart` | idem | idem |
| `screens/auth/change_password_sheet.dart` | `package:supabase_flutter` | UI trata `AuthException` do SDK |
| `screens/auth/forgot_password_sheet.dart` | idem | idem |
| `screens/auth/login_screen.dart` | idem | idem |
| `screens/auth/set_new_password_screen.dart` | idem | idem |

**Decisão do plano:** não alterar `lib/data`. Em vez disso, criar uma **camada de adaptação na apresentação**:

```
lib/presentation/adapters/
  offline_status_presenter.dart   // expõe apenas "há pendências? quantas?" lendo OfflineSyncService
  auth_error_presenter.dart       // único ficheiro que conhece Supabase; devolve código de erro de UI
  biometric_presenter.dart        // mensagens localizadas
```

- Os ecrãs novos dependem **só** de `presentation/adapters` + providers.
- O adaptador é o único ponto com import de `data/services` ou `supabase_flutter`.
- **Limitação honesta:** eliminar por completo o tipo `AuthException` da UI exigiria tradução em `domain`/`data` — isso é uma alteração de contrato e fica **fora de âmbito**. O plano apenas confina a fuga a 1–3 ficheiros.

---

## 4. Arquitetura-alvo do frontend (sem tocar no resto)

```
lib/presentation/
├── design_system/              # NOVO — v5, 100% aditivo
│   ├── tokens/                 # aliases semânticos sobre core/theme
│   │   ├── spacing.dart
│   │   ├── radius.dart
│   │   ├── typography.dart
│   │   └── colors.dart
│   ├── primitives/             # AppButtonV5, AppCardV5, AppFieldV5,
│   │                           # AppSheetV5, AppBadgeV5, AppAvatarV5, AppRowV5
│   ├── patterns/               # PageScaffold, AsyncStateView, EmptyViewV5,
│   │                           # ErrorViewV5, FilterBar, StatTile, FormSheet,
│   │                           # ConfirmSheet, SectionHeaderV5
│   └── motion/                 # AppMotion (durações/curvas), ReducedMotion
├── features/                   # NOVO — ecrãs v5 por domínio
│   ├── dashboard/  sales/  financial/  products/  customers/
│   ├── credit/     purchases/  production/  reports/  stores/
│   ├── support/    notifications/  auth/  admin/  addons/
├── adapters/                   # NOVO — contenção de fronteiras
└── navigation/
    └── screen_registry.dart    # NOVO — ponto único de troca v4 → v5
```

**Regras de dependência (aplicadas por revisão e por lint de imports):**
1. `features/**` pode importar `design_system/**`, `adapters/**`, `controllers/**`, `domain/**` e `core/**` (tema, i18n, utilitários).
2. `features/**` **não pode** importar `data/**` nem `package:supabase_flutter`.
3. `design_system/**` **não pode** importar `controllers/**` nem `domain/**` — só Flutter + tokens.
4. Nenhum ficheiro novo em `lib/domain` ou `lib/data`.

### 4.1 Interruptor de migração (frontend-only, sem dependências novas)

`navigation/screen_registry.dart`:

```dart
// Sem go_router, sem pacotes novos.
// Um único mapa: id lógico → builder.
// A flag vem de --dart-define=V5=1 (global) ou V5_SCREENS=sales,pdv (granular).
const v5Enabled = bool.fromEnvironment('V5');
const v5Screens = String.fromEnvironment('V5_SCREENS');

WidgetBuilder resolveScreen(String id, WidgetBuilder legacy) { ... }
```

Pontos de troca reais (mapeados no inventário):
- `AppShell._sections` (7 secções);
- `MenuScreen` (7 `Navigator.push`);
- `AuthGate` (login, splash, pending/rejected/onboarding);
- `AdminShell._sections` (9 secções);
- `AddOnMarketplaceScreen._openAddOn` (6 ids);
- FABs e sheets abertos por `showAppSheet`.

**Vantagem:** rollback = desligar a flag; nenhum ficheiro antigo é apagado.

---

## 5. Estratégia de migração

### 5.1 Princípios
1. **Aditivo primeiro.** Nada antigo é editado até o substituto passar os testes.
2. **Um ecrã, um commit, um interruptor.** Cada troca é reversível isoladamente.
3. **Paridade funcional antes de polish.** Dados, ações, permissões e estados iguais aos atuais.
4. **Contratos intocáveis.** `git diff --stat lib/domain lib/data supabase` tem de ser vazio em cada fase.
5. **Testes de caracterização antes da mudança.** Fotografar o comportamento atual (widget + golden) antes de construir o novo.

### 5.2 Fluxo por ecrã (receita repetível)

```
1. Congelar comportamento
   └─ correr os testes existentes do ecrã + criar caracterização se faltar
2. Construir v5 ao lado (features/<domínio>/)
3. Testar v5 isolado (widget + golden + a11y)
4. Registar no screen_registry com flag granular
5. QA manual: 3 viewports × 2 temas × 2 escalas de texto × permissões
6. Ativar em dev → staging → produção
7. Monitorizar 1 ciclo de release
8. (Opcional, só com autorização) remover legado
```

### 5.3 O que conta como “ecrã migrado”
- Entrada no `screen_registry`;
- paridade de **dados, ações, permissões e estados** verificada;
- testes a passar sem alterar asserções antigas;
- nenhum import de `data/`/`supabase` no ficheiro novo.

---

## 6. Ordem das telas (fases)

Critério de ordenação: **risco × dependência × valor percebido**. Começa no que é folha (poucas dependências) e termina no que é crítico e transversal (auth, shell, dinheiro).

### Fase 0 — Guardrails (sem UI)
| Item | Detalhe |
|---|---|
| Baseline | `flutter analyze > baseline.txt`, `flutter test > baseline-tests.txt` |
| Proteção de contratos | CI job que falha se `lib/domain`, `lib/data` ou `supabase/` mudarem |
| Testes de caracterização | Cobrir ecrãs sem teste (ver §7.2) |
| Golden baseline | Manter as 92 imagens atuais como referência congelada |
| **Aceitação** | Analyze com o mesmo número de issues do baseline; 261 testes verdes; 92 goldens inalterados |

### Fase 1 — Design System v5 (sem ecrãs)
| Item | Detalhe |
|---|---|
| Conteúdo | `tokens/`, `primitives/`, `patterns/`, `motion/` |
| Regra | 100% aditivo; nenhum ficheiro v4 editado |
| Galeria | `test/presentation/design_system_v5_gallery_test.dart` + golden próprio |
| **Aceitação** | Tokens com contraste AA/AAA; alvos ≥48 dp; escala de texto 1.6× sem overflow na galeria; zero alterações fora de `presentation/design_system` |

### Fase 2 — Padrões partilhados v5
| Item | Detalhe |
|---|---|
| Conteúdo | `PageScaffold`, `AsyncStateView` (loading/error/empty/success), `FilterBar`, `FormSheet`, `ConfirmSheet`, `StatTile`, `SectionHeaderV5` |
| Objetivo | Eliminar as duplicações identificadas: `EmptyState`/`InlineEmpty`, `_Pill`, `_FilterChipGroup`, `_PeriodPill`, `_StatusChip` |
| **Aceitação** | Os padrões v5 reproduzem os 4 estados em teste; usados por ≥1 ecrã piloto; sem regressão nos testes v4 |

### Fase 3 — Ecrãs-folha (baixo risco)
Ordem e justificação:

| # | Ecrã | Porquê primeiro |
|---|---|---|
| 1 | `SupportScreen` + `DocReaderScreen` | Sem dados de negócio; poucas permissões |
| 2 | `SecuritySettingsScreen` + `MFASetupScreen` + `ChangePasswordSheet` | Fluxos isolados, testáveis |
| 3 | `TenantPendingScreen` + `TenantRejectedScreen` | Estáticos, sem providers de dados |
| 4 | `NotificationsScreen` (lista + detalhe) | Duas fontes, sem mutações críticas |
| 5 | `PaymentReconciliationScreen` | Ecrã de estado bloqueado |
| 6 | `_SplashScreen`, `_BlockedEmployeeScreen`, `_TenantErrorScreen` | Gates visuais, sem lógica própria |

**Aceitação da fase:** paridade de ações/estados; testes de acessibilidade; nenhuma alteração em `domain`/`data`.

### Fase 4 — Módulos de lista/detalhe (risco médio)
| # | Módulo | Ecrãs |
|---|---|---|
| 1 | Produtos | `ProductListScreen`, `_AdvancedFilterSheet`, `AddProductSheet`, `EditProductSheet` |
| 2 | Clientes | `CustomersScreen`, `AddCustomerSheet`, `_EditCustomerSheet` |
| 3 | Crédito | `DebtsScreen`, `AddDebtSheet` |
| 4 | Compras | `PurchasesScreen`, `AddPurchaseSheet`, `PurchaseDetailSheet` |
| 5 | Produção | `ProductionScreen`, `RecipeFormSheet`, `RecordProductionSheet` |
| 6 | Relatórios | `ReportsScreen` |

Ordem interna: **read-only → edição → criação**. Em cada módulo, primeiro a lista, depois os sheets.

**Aceitação da fase:** cada ecrã com teste widget + golden v5; permissões `owner`/`manager`/`employee` validadas; uso partilhado do `FilterBar`/`FormSheet`.

### Fase 5 — Superfícies de dinheiro (risco alto)
| # | Ecrã | Cuidados |
|---|---|---|
| 1 | `FinancialScreen` | Caixa, períodos, agrupamento por data |
| 2 | `AddTransactionSheet` | Tipos, estados, loja ativa |
| 3 | `CashClosingSheet` | Permissão + valores conferidos |
| 4 | `SalesScreen` | Filtros, resumo, lista agrupada |
| 5 | `SaleDetailScreen` + `SaleReceiptShareSheet` | Partilha + anulação com biometria |
| 6 | `NewSaleSheet` (PDV) | **Último e mais crítico**: carrinho, scanner, balança, pagamento, offline |

**Aceitação da fase:** paridade de totais ao cêntimo; teste de fluxo completo (criar → consultar → anular); teste offline (outbox); biometria mockada; nenhum cálculo novo na UI (reutiliza `domain`/`core/utils`).

### Fase 6 — Casca e visão geral
| # | Ecrã | Nota |
|---|---|---|
| 1 | `AppShell` | Barra/rail, FAB, banner de sync; **afeta todos** — ativar por último dentro da fase |
| 2 | `MenuScreen` | Corrigir `tileWidth` com `constraints`, separar secções |
| 3 | `DashboardScreen` | 12 providers; separar “Atividade” de “Alertas”; erros visíveis |

**Aceitação da fase:** navegação preservada (7 secções, 4 destinos, `PopScope`); testes de shell; sem regressão nos ecrãs já migrados.

### Fase 7 — Auth, Admin e Add-ons (streams paralelos)
| Stream | Ecrãs | Nota |
|---|---|---|
| A — Auth | `LoginScreen`, `ForgotPasswordSheet`, `SetNewPasswordScreen`, `MFAVerificationSheet`, `TenantOnboardingScreen`, `AuthGate` | Fluxo de entrada; exige matriz de QA manual e fallback |
| B — Admin | `AdminShell` + 9 ecrãs + sheets | Isolado do tenant; pode avançar em paralelo |
| C — Add-ons | `AddOnMarketplaceScreen` + 6 ecrãs | Gated; baixo impacto fora do owner |

**Aceitação Auth:** matriz completa (login ok, senha errada, 429, sem rede, MFA ok/inválido, recovery, tenant pending/rejected/approved/blocked); fallback `V5=false` testado.
**Aceitação Admin:** 9 secções navegáveis, badges corretos, aprovações e faturas funcionais.
**Aceitação Add-ons:** 6 ids abrem o ecrã certo; add-on inativo continua escondido.

### 6.1 Calendário indicativo (relativo, não datas)

| Fase | Esforço | Paralelizável |
|---|---|---|
| 0 | S | Não |
| 1 | M | Não |
| 2 | S | Depois da 1 |
| 3 | S | Sim |
| 4 | M | Sim (por módulo) |
| 5 | L | Não (sequencial) |
| 6 | M | Não |
| 7 | L | Sim (A/B/C) |

---

## 7. Estratégia de testes

### 7.1 Pirâmide aplicada ao projeto
| Nível | Ferramenta | Alvo |
|---|---|---|
| Contrato | `git diff` guard + testes de domínio existentes | Garantir que `domain`/`data` não mudam |
| Unidade | `test/domain`, `test/data` (105 testes) | Não tocar; correm como regressão |
| Widget | `test/presentation` (100) | 1 ficheiro por ecrã v5 |
| Golden | 7 ficheiros / 92 imagens | Novas imagens em `test/presentation/goldens/v5/`; antigas intactas |
| Acessibilidade | testes existentes (`accessibility_text_scale_test`, `pdv_accessibility_test`) | Estender a todos os ecrãs v5 |
| Fluxo | `integration_test` | F1–F6 do inventário |
| Manual | matriz de dispositivos | 3 viewports, 2 temas, 1.0×/1.6× |

### 7.2 Cobertura de caracterização a criar na Fase 0
Ecrãs sem teste dedicado (confirmado por listagem) que precisam de caracterização antes de migrar:
- `TenantPendingScreen` / `TenantRejectedScreen` / `TenantOnboardingScreen`
- `SecuritySettingsScreen` / `MFASetupScreen`
- `SupportScreen` / `DocReaderScreen`
- `ReportsScreen` (existe teste) — **verificar paridade de exportação**
- `ProductionScreen` / `RecipeFormSheet` / `RecordProductionSheet`
- Sheets privados: `_AddStoreSheet`, `_AddEmployeeSheet`, `_UpgradeSheet`, `_StoreDetailSheet`, `_EmployeeDetailSheet`
- `AdminAddOnRevenueScreen`
- `CashClosingSheet` (verificar cobertura)

### 7.3 Testes por fase
| Fase | Obrigatório |
|---|---|
| 1 | Galeria + contraste + text scale + golden do DS |
| 2 | Testes dos 4 estados de `AsyncStateView`; `FilterBar` com overflow |
| 3 | Widget + golden por ecrã; DocReader com asset real |
| 4 | Widget + golden; permissões; validação de formulários; empty/error |
| 5 | Fluxo PDV completo; totais; offline; biometria; fecho de caixa |
| 6 | Shell (índice, PopScope, FAB, badges); Dashboard com providers falhando |
| 7 | Matriz Auth; 9 secções admin; 6 add-ons |

### 7.4 Comandos de verificação (por PR)
```bash
flutter analyze
flutter test
flutter test test/presentation/goldens/v5
flutter test integration_test -d chrome --dart-define-from-file=env/dev.env
git diff --stat lib/domain lib/data supabase   # deve estar vazio
```

---

## 8. Critérios de aceitação (Definition of Done)

### 8.1 Por ecrã
- [ ] Paridade de **dados** (mesmos providers/entidades).
- [ ] Paridade de **ações** (mesmos use cases; nenhuma regra recriada na UI).
- [ ] Paridade de **permissões** (`currentAccessLevelProvider`, capabilities).
- [ ] Paridade dos **4 estados**: loading, erro, vazio, sucesso.
- [ ] Textos nos 3 idiomas (pt/en/fr), sem chaves em falta.
- [ ] Tema claro + escuro; texto 1.0× e 1.6×; 360 dp e ≥1024 dp.
- [ ] Alvos ≥48 dp; foco visível; semântica com rótulo+valor.
- [ ] `flutter analyze` sem novos issues.
- [ ] Testes antigos verdes; novos testes verdes.
- [ ] `git diff lib/domain lib/data supabase` vazio.
- [ ] Flag `V5_<ecrã>` desligada devolve o ecrã antigo (rollback comprovado).

### 8.2 Por fase
- [ ] Todas as telas da fase cumprem o DoD.
- [ ] Golden v5 aprovados por revisão (não auto-baseline).
- [ ] Sem regressão nos testes das fases anteriores.
- [ ] Relatório de fase: ecrãs migrados, riscos residuais, dívida registada.
- [ ] Aprovação explícita para avançar.

### 8.3 Critérios de “não regressão”
| Área | Métrica |
|---|---|
| Contratos | 0 alterações em `domain`/`data`/`supabase` |
| Fluxos | 100% dos passos F1–F6 executáveis |
| Permissões | Mesma matriz owner/manager/employee/admin |
| Totais | Valores iguais ao cêntimo em venda, fiado, caixa e relatórios |
| Offline | Outbox continua a enfileirar e drenar |
| Arranque | Tempo de arranque não piora >10% |
| A11y | Nenhum overflow com 1.6×; contraste mantido |

---

## 9. Matriz de riscos e mitigação

| Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|
| Regressão silenciosa em ecrãs sem teste | Alta | Alto | Fase 0 obrigatória de caracterização |
| Tema v5 afeta ecrãs v4 | Média | Alto | Tokens v5 isolados; nenhuma edição destrutiva em `core/theme` |
| Testes antigos quebram por textos/estrutura | Alta | Médio | Não alterar asserções; testes v5 separados |
| PDV com perda de venda | Baixa | Crítico | Migrar por último; flag; testes de fluxo + offline + totais |
| Auth tranca utilizadores | Baixa | Crítico | Matriz de QA; fallback para login antigo; release faseada |
| Fuga de fronteira aumentar | Média | Médio | Regra de imports; revisão por PR; adapters |
| Goldens mascararem regressões | Média | Médio | Revisão humana dos diffs; baseline v4 congelado |
| Navegação muda de comportamento | Média | Alto | Preservar índice + `PopScope`; testes de shell |
| Add-ons expostos sem permissão | Baixa | Alto | Manter gating por `activeAddOnIdsProvider`/plano |
| Escopo crescer para “backend” | Média | Alto | Guard de CI + Definition of Done |

---

## 10. Rollback

| Nível | Ação | Tempo |
|---|---|---|
| Ecrã | Desligar `V5_<ecrã>` e recompilar | minutos |
| Fase | Desligar `V5` globalmente | minutos |
| Código | Reverter commit da fase (v5 é aditivo) | minutos |
| Dados | **Não aplicável** — nenhuma migração de dados | — |

Como o v5 é aditivo e nunca substitui ficheiros antigos, o rollback não exige remoção de código: basta apontar o registo de ecrãs para o builder legado.

---

## 11. Fora de âmbito (explícito)

- Alterar `supabase/`, RPCs, tabelas, RLS ou migrations.
- Alterar `lib/domain/**` e `lib/data/**`.
- Alterar regras de negócio (venda não editável, fiado, fecho de caixa, planos).
- Introduzir novas dependências (router, state management, UI kit) — o plano usa o que já existe.
- Remover ficheiros da v4 (só com autorização posterior).
- Reescrever exportadores PDF (`core/share`).
- Alterar `main.dart`, `ServiceLocator` ou bootstrap (salvo adicionar o registo de ecrãs, que é apresentação).

---

## 12. Estrutura de entregáveis por fase

```
docs/migration/
  fase-0-baseline.md
  fase-1-design-system.md
  fase-2-padroes.md
  fase-3-ecras-folha.md
  fase-4-modulos-lista.md
  fase-5-dinheiro.md
  fase-6-casca.md
  fase-7-auth-admin-addons.md
  registo-de-decisoes.md
  matriz-qa-manual.md
```

Cada relatório de fase inclui: ecrãs migrados, flags, testes adicionados, diffs de golden revistos, riscos residuais e pedido de autorização para a fase seguinte.

---

## 13. Sequência recomendada (resumo)

```
F0 Guardrails
 → F1 Design System v5
 → F2 Padrões partilhados
 → F3 Ecrãs-folha (Suporte, Segurança, Gates, Notificações)
 → F4 Listas/Detalhe (Produtos, Clientes, Crédito, Compras, Produção, Relatórios)
 → F5 Dinheiro (Financeiro → Caixa → Vendas → PDV)
 → F6 Casca (AppShell, Menu, Dashboard)
 → F7 Auth ‖ Admin ‖ Add-ons
```

**Regra de ouro:** nenhuma fase começa sem a anterior aceite; nenhum ecrã de dinheiro ou auth é migrado antes de F1–F2 estarem estáveis.

---

## 14. Decisões que preciso de ti antes de começar

1. **Âmbito visual**: manter a identidade atual (petróleo/terracota, Inter) e elevar o polish, ou introduzir uma nova direção visual? (Recomendo manter a paleta base e elevar espaçamento, hierarquia e motion.)
2. **Navegação**: manter o modelo por índice (recomendado, zero risco de contrato) ou adotar rotas declarativas mais tarde?
3. **Tema**: manter claro+escuro desde o início de cada ecrã ou migrar primeiro em escuro (tema de produção dos testes) e validar claro depois?
4. **Flags**: `--dart-define` granular por ecrã (recomendado) ou um único interruptor global?
5. **Admin**: tratar como stream paralelo desde já ou deixar para o fim?
6. **Cleanup da v4**: autorizas remoção posterior dos ecrãs antigos, ou fica tudo preservado indefinidamente?

---

*Plano apenas. Nenhum ficheiro de código foi criado, alterado ou removido. A implementação aguarda autorização explícita.*
