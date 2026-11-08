# Auditoria UI/UX — TAREQO (2026-11-08)

> **Método:** análise estática de código em `C:\Users\emili\OneDrive\Desktop\father`
> (545 ficheiros Dart em `lib/`, 269 em `test/`). Sem runtime, nenhum problema
> foi “confirmado visualmente” ou “confirmado por teste executado” — todos os
> confirmados são **confirmados por código** (ficheiro:linha). Último commit:
> `fbad070` — 45 ficheiros, +1473/−1127 (inclui goldens `financeiro_*` e
> `finance_providers.dart`).

## 1. Resumo executivo

- **Estado após a auditoria:** o design system central (`AppColors`,
  `AppTypography`, `AppSpacing`, `AppRadius`, `AppSizes`, `AppElevation`,
  `AppDurations`, `AppCurves`, `IconTone`, `ModuleColors`) cobre a totalidade do
  `lib/presentation` em raios, tipos de valor e cores de ação. Três problemas
  **P1** (botão de pagamento do PDV, texto branco invisível no feed, vermelho
  hardcoded) corrigidos.
- **Problemas encontrados:** 22 (3 P1, 8 P2, 8 P3, 3 P4; U-15/U-16 fechados no
  shell). **Nenhum P0 confirmado por código** — dinheiro em centavos inteiros e
  confirmação antes de mutações irreversíveis (ex.: `_settlePending`).
- **Principais riscos residuais:**
  1. 12 `fontSize:` literais em 6 ficheiros (admin + recibo) e 50 `Colors.*`
     em 26 ficheiros (maioria `transparent` funcional) — risco de regressão
     sem guard test estendido.
  2. `SizedBox` arbitrários (517 ocorrências em 75 ficheiros no levantamento
     inicial) — componente de deriva mais provável.
  3. Validação runtime pendente: `flutter analyze`, `flutter test`, goldens,
     screenshots 360dp/tablet/landscape, TalkBack.

## 2. Tabela de correções (antes → depois)

| ID | Sev | Tela | Antes | Depois | Ficheiros |
|---|---|---|---|---|---|
| U-01 | P1 | PDV confirmar | `InkWell`+`Ink`, gradiente `#D97706→#B45309`, texto `Colors.white` (≈3,3:1), sem estado desativado | `AppButton.primary(gradient: true)` (cor do scheme, `onPrimary` escuro, desabilitado visível); rodapé `scheme.surface` | `new_sale_sheet.dart` |
| U-02 | P1 | Feed Home | `amountColor: Colors.white` incondicional (invisível no claro) | `null` + fallback tema-aware (`+` → `scheme.income`, `−` → `scheme.expense`, resto → `primary`); círculos via `IconTone.darkBackground/lightForeground` | `dashboard_screen.dart` |
| U-03 | P2 | Global | `textScaler.clamp(min:1.0, max:1.6)` — viola WCAG 1.4.4 | Sem clamp; testes de escala passam de 1.3/1.6 a **1.3/1.6/2.0** | `app.dart`; 2 testes |
| U-04 | P2 | Menu | Círculo `AppColors.accentOrange` (claro fixo) + `Colors.white` em ambos os temas; alvo 32px | `IconTone.darkBackground(theme.accent)`/`lightForeground`; “Sair” com semântica de erro; `minHeight: touchTarget` | `menu_screen.dart` |
| U-05 | P2 | Financeiro badge | `fontSize: 9`, `w800` | `labelSmall` (11) + `w600` | `financial_widgets.dart` |
| U-06 | P2 | Financeiro heróis | `heroAmount.copyWith(fontSize: 36/32, w800)` | Token `heroAmount` puro (26/w600); `FontWeight.bold` (w700) → `w600` em 4 sítios | `financial_screen.dart`; `financial_widgets.dart`; `add_transaction_sheet.dart` |
| U-07 | P2 | PDV erro | `Color(0xFFB91C1C)` | `scheme.error` | `new_sale_sheet.dart` |
| U-08 | P2 | Navegação | Subsecções do Menu (Produtos/Crédito/Clientes) sem identificação | AppBar mostra rótulo real da secção + barra/título por tema | `app_shell.dart` |
| U-09 | P2 | Rotas | 17× `Navigator.push(MaterialPageRoute)` ad-hoc em 8 ficheiros; sem deep links | Tabela `app_routes.dart` (18 nomes) + `AppNavigator` + `onGenerateRoute` + deep links `tareqo://go/<rota>`; auth inalterado | `app_routes.dart` (novo); `app.dart`; `deep_link_handler.dart`; 8 telas migradas; `app_routes_test.dart` (novo) |
| U-10 | P2 | Admin thin | Sistema paralelo: `w300`, `fontSize: 19/13/14` | `w400`, tamanhos por tokens (`titleLarge`, `labelMedium`, `bodyMedium`) | `admin_thin_theme.dart`; `admin_thin_bridge.dart` |
| U-11 | P2 | Financeiro | 6 `hint: 'Erro ao …'` em PT hardcoded | Chaves de telemetria `financial_receive_pending`, `financial_pay_pending`, `financial_add_transaction`, `financial_cash_closing` | `financial_screen.dart`; `add_transaction_sheet.dart`; `cash_closing_sheet.dart` |
| U-12 | P3 | Preview factura | 16× `fontSize: 10/11/13`, `w700`, `circular(4)` | Exceção de documento documentada; tipos por tokens; raios `xsAll`; espaçamentos por tokens | `custom_invoice_preview.dart` |
| U-13 | P3 | Recibo | Sem `fontFamily` (fonte da plataforma); `w700` | `Inter` em 3 estilos + `w600`; espaçamentos por tokens | `sale_receipt_view.dart` |
| U-14 | P3 | Spacing/raios | `BorderRadius.circular(2/3/4/999/1.5)` e literais | Novo `AppRadius.microRadius`/`microAll`; **0 `circular(2/4)`** em `lib/presentation`; `circular(3/999/1.5)` → 0 | `app_tokens.dart` + 15 ficheiros + golden |
| U-15 | P3 | AppBar | 52px shell vs 56 tema vs 72 AppPage vs 52 admin | Shell usa altura do tema; subtítulo `bodySmall` | `app_shell.dart` |
| U-16 | P3 | NavigationBar | `height: 70`, raio `28` literais | `AppSizes.navBarHeight` (64), `AppRadius.xxlAll` | `app_shell.dart` |
| U-17 | P3 | Cartões | `_CashStack` xlAll vs `_DateGroup` lg com comentário “16/20” | Comentário corrigido; `indent: 60` → `huge+sm` | `financial_screen.dart` |
| U-18 | P3 | Alvos de toque | Círculos 32/36px | Linhas/tiles ≥48 verificados (TransactionCard/Menus/_ActionTile) | — (verificado) |
| U-19 | P3 | Semântica | `InkWell` sem `button`/hint | `Semantics(button: true, label, hint)` em TransactionCard/_ActionTile | `financial_widgets.dart`; `app_shell.dart` |
| U-20 | P3 | Datas | `DD/MM/AAAA` sempre, mesmo em en/fr | `DateFormat` com locale ativo (`_locale`) | `formatters.dart` |
| U-21 | P4 | Docs de cor | Comentários contraditórios (“branco 7.97:1”) | Contrastes reais; aliases `primaryLight/primaryDark` marcados LEGADO | `app_colors.dart` |
| U-22 | P4 | Laranja triplo | `IconTone.accentOrange #F28C00` ≠ `#D97706` | `sales_widgets.dart` deriva de `theme.accent`; única ref. restante = comentário | `sales_widgets.dart` |

## 3. Contagens objetivas (grep pós-correção)

| Padrão | Antes (levantamento inicial) | Depois |
|---|---|---|
| `fontSize:` inline (10/11/13/14/16/19/32/36) em `lib/presentation` | 65 / 17 ficheiros | **12 / 6 ficheiros** (admin charts/messages/shell + recibo) |
| `Colors.*` em `lib/presentation` | 62 / 31 | **50 / 26** (maioria `transparent` funcional/barcode) |
| `Color(0xFF…)` em `lib/presentation` | 28 / 8 | **22 / 7** (paletas de documento + recibo papel) |
| `BorderRadius.circular(2\|4)` em `lib/presentation` | 10 (5 ficheiros) | **0** |
| `BorderRadius.circular(3\|999\|1.5)` em `lib/` | 3 | **0** |
| `Navigator.of(context).push(` em `lib/presentation` | 17 (8 ficheiros) | **0** |
| `MaterialPageRoute` em `lib/presentation` | disperso | **5, todos em `app_routes.dart`** |
| `Semantics(` em `lib/presentation` | 18 / 16 ficheiros | **20 / 16 ficheiros** |

## 4. Recomendações (baseadas em factos e dados)

### R1 — Estender os guard tests aos padrões que regressaram em U-05/U-06/U-10
- **Facto:** os guards atuais (`typography_token_guard_test`, `spacing_grid_guard_test`,
  `font_weight_guard_test`) bloqueiam `fontSize`/`spacing`, mas os 22 problemas
  nasceram fora do alcance (há `fontSize: 9/10/11` em 6 ficheiros admin/recibo e
  `w700/w800` em 4 sítios). Sem guard, a deriva volta em semanas.
- **Ação:** adicionar regra que falha em `fontSize:` literal < 11 e em
  `FontWeight.w700|w800|bold` fora de allowlist (admin charts/messages + documento),
  e em `BorderRadius.circular(<número>)` (hoje a 0 — executável).
- **Critério:** `flutter test test/presentation/widgets/typography_token_guard_test.dart`
  falha se qualquer padrão voltar.

### R2 — Migrar os sítios admin restantes (última milha do U-12/U-14)
- **Facto:** restam `fontSize: 11` em `admin_addons_screen` (4), `admin_addon_revenue_screen`
  (2), `admin_dashboard_feed_widgets` (2), `admin_tenants_widgets` (1), e `w300`
  em `admin_dashboard_chart_widgets` (2), `admin_messages_screen` (3) e
  `admin_shell.dart` (3 — um é `selected ? w600 : w300`, ênfase de estado legítima).
- **Ação:** aplicar a receita `bodySmall`/`labelSmall` + `w400` já usada no tema
  thin (U-10), ou registar allowlist explícita para o painel admin denso.
- **Critério:** grep `fontSize: (10|11)|w300` em `lib/presentation/screens/admin` = 0
  ou allowlist documentada.

### R3 — Fechar a validação runtime (provas em falta)
- **Facto:** todas as correções foram verificadas por grep/leitura; `flutter
  analyze`, `flutter test` (goldens `financeiro_light/dark`, `pdv`, `dashboard`)
  e screenshots 360dp/tablet/landscape **não puderam ser executados** neste
  ambiente.
- **Ação:** correr CI local: `flutter analyze` (os imports não usados em
  `new_sale_sheet.dart`, `menu_screen.dart` e nas telas migradas para rotas
  foram removidos — confirmar), `flutter test --update-goldens` só para goldens
  intencionais, e matriz visual 360×640 / 800×1280 / landscape a 1.6× e 2.0×.
- **Critério:** CI verde sem `--update-goldens` em massa (diff de golden = intenção).

### R4 — Testar TalkBack/VoiceOver nos widgets com `Semantics` novo (U-19)
- **Facto:** `TransactionCard` e `_ActionTile` ganharam `Semantics(button, label, hint)`;
  a árvore final só é observável com leitor de ecrã.
- **Ação:** smoke test manual (TalkBack Android + VoiceOver iOS) nos fluxos
  Transação → Detalhe e FAB → Nova venda; confirmar anúncio “botão” + rótulo.
- **Critério:** anúncio correto nos dois fluxos; sem nós duplicados.

### R5 — Decidir a estratégia de `SizedBox` (517 ocorrências em 75 ficheiros)
- **Facto:** o levantamento inicial contou 1119 ocorrências de
  `SizedBox/EdgeInsets/BorderRadius.circular` em 100 ficheiros — após as migrações,
  os raios estão a zero literais, mas os `SizedBox(height: N)` com literais
  proliferam (gaps de 2/4/8/12/16 espalhados).
- **Ação (duas opções factuais):**
  (a) estender o `spacing_grid_guard_test` a `SizedBox(width|height: <int>)` com
  allowlist de offsets óticos (`2` = `micro`, `4` = `xxs`…); ou
  (b) aceitar gaps literais como estilo local e documentar no doc-comment de
  `AppSpacing` (menos churn, mais diversidade).
- **Critério:** decisão registada em `docs/pt/23-design-system-e-convencoes-ui-ux.md`.

### R6 — Allowlist explícita para `Colors.*`/`Color(0xFF)` restantes
- **Facto:** 50 `Colors.*` (26 ficheiros) e 22 `Color(0xFF)` (7 ficheiros) restam —
  maioria funcional (`transparent` em overlays, `black` em barcode/preview),
  mas `Colors.white` persiste em 6 ficheiros (admin + `custom_invoice_preview`
  documentado) e há `0xFF…` em `dashboard_screen`, `sale_detail_screen`,
  `payment_filter`, `invoice_template_providers`.
- **Ação:** um ficheiro `docs/pt/23-…` com allowlist comentada por ficheiro
  (documento/papel, preview, barcode) + default de migração para tokens
  (`scheme.onPrimary`, `theme.accent`, `AppColors.*`).
- **Critério:** qualquer `Colors.white`/`Color(0xFF…)` novo fora da allowlist
  falha o lint/CI.

### R7 — Medir contraste no CI com os valores reais (U-21)
- **Facto:** os comentários de `app_colors.dart` afirmavam “branco 7.97:1” quando
  o rótulo é tinta escura (≈5,0:1) — a auditoria por comentários falhou.
- **Ação:** script/teste que calcula contraste (WCAG 2.x) dos pares
  `textPrimary/surface`, `onPrimary/primary`, `warning/surface`,
  `error/surface` em claro e escuro e falha se < 4.5:1 (texto) ou < 3:1 (não-texto).
- **Critério:** `theme_contrast_test.dart` (já existe) cobre os pares declarados —
  verificar se inclui os novos tokens (`microRadius` não afeta cor).

### R8 — Decisão de migração para `go_router` vs Navigator 1.0 + nomes
- **Facto:** U-09 foi completado com `onGenerateRoute` + nomes (17 pushes → 0,
  5 `MaterialPageRoute` todos em `app_routes.dart`); `go_router` não está no
  `pubspec.yaml` (decisão de zero dependências novas).
- **Ação:** se a roadmap incluir web/deep links públicos (`https://tareqo.app/...`),
  migrar para `go_router` torna-se trivial porque todos os pushes passam por
  `AppNavigator`; caso contrário, documentar a fronteira em
  `docs/pt/12-decisoes-de-arquitetura.md`.
- **Critério:** decisão registada; se migrar, `AppNavigator.push*` mantém a
  assinatura e só `app_routes.dart` muda por dentro.

### R9 — Regenerar goldens afetados e congelar a matriz de tamanhos
- **Facto:** os goldens `financeiro_light/dark.png` foram tocados no commit
  `fbad070` (valores 36→26px, badge 9px→11px mudam pixels por design).
- **Ação:** `flutter test --update-goldens test/presentation/goldens` **apenas**
  após revisão visual da matriz (360×640, 800×1280, 1.3/1.6/2.0×), e
  adicionar `text_scale_visual_audit_test` já atualizado (1.3/1.6/2.0) ao CI.
- **Critério:** goldens estáveis em CI sem regeneração manual.

## 5. Plano de implementação (resumo)

| Prioridade | Item | Esforço |
|---|---|---|
| Próxima sprint | R3 (CI local completo) + R9 (goldens) | 1 dia |
| Próxima sprint | R1 (guard tests) + R2 (admin residual) | 1–2 dias |
| Backlog | R5 (decisão SizedBox), R6 (allowlist), R4 (TalkBack) | 1 dia |
| Decisão de produto | R8 (go_router vs Navigator) | discussão |

## 6. Informações em falta (para concluir sem “Não foi possível confirmar”)

1. Saída de `flutter analyze` e `flutter test` (incl. `app_routes_test.dart`).
2. Screenshots/goldens das telas alteradas (PDV, Feed, Menu, Financeiro,
   Marketplace, Suporte, Admin thin) em claro e escuro.
3. Resultado do smoke test com leitor de ecrã (R4).
4. Decisão sobre `go_router` (R8) e sobre `SizedBox` (R5).
