# 21 · Plano de Evolução UI/UX — Nível Apple Design

> **Base:** auditoria de código realizada em 2026-09-17 (v2.2.0+27, main @ `d83ffe7`).
> **Baseline F0:** 1.665 testes a 100%, cobertura global 91,1% (24.500/26.893 linhas),
> `flutter analyze` sem issues. Métricas de inventário em §4.
> **Objetivo:** elevar a experiência do TAREQO ao padrão de acabamento iOS/Apple — fluidez,
> feedback tátil, clareza e coerência — **sem reescrever o app**: evoluir o design system
> existente, camada por camada, com validação por testes a cada fase.
>
> **STATUS (2026-09-26): PLANO CONCLUÍDO** — Fases 1–5 fechadas; suíte 1.832/1.832
> verde, `flutter analyze` 0 issues. Detalhe por item nas seções abaixo (marcas
> ✅); decisões registradas nos docs 05/12 e no CHANGELOG.

---

## 0 · Diagnóstico — onde estamos

O app já parte de uma base **acima da média** para um ERP Flutter. Evidências:

| Pilar | Estado atual | Evidência |
|---|---|---|
| Fundações | ✅ Forte | `AppTheme` M3 dark-first com `ColorScheme.fromSeed` + overrides auditados; `AppStatusColors` (ThemeExtension interpolado); grelha 4px (`AppSpacing`); raios `AppRadius`; durações/curvas (`AppDurations`/`AppCurves`) — *ainda subutilizados* |
| Tipografia | ✅ Forte | Escala inspirada no SF Pro (34→11), tracking negativo em títulos, eixo óptico `opsz`, tabular figures nos números — já "Apple" |
| Acessibilidade | ✅ Forte | Contraste AA calibrado por teste automatizado (`theme_contrast_test.dart`); `tooltip` nos ícones; touch target 48px |
| i18n | ✅ Forte | pt/en/fr com plurais e gênero; tabular figures; padrão V4 consolidado |
| Estados de UI | ✅ Consistente | `EmptyState` (21 telas), `ListSkeleton` (15), `ErrorView` (15), `RefreshIndicator` (16) |
| Navegação | ✅ Forte | `NavigationBar` mobile ↔ `NavigationRail` wide; indicador pílula (Stadium); `pageTransitionsTheme` com Zoom (Android/desktop) e Cupertino (iOS/macOS) — F1.2 concluída |
| Motion | ❌ Gargalo 1 | Apenas 9 arquivos com animações; **0 `HapticFeedback`** (nenhum feedback tátil em PDV, pagamento, finalização de venda); transições de rota padrão; fade 220ms único entre abas |
| A11y de conteúdo | ❌ Gargalo 2 | Apenas 5 `Semantics(` em 498 arquivos; gráficos/valores/estados sem rótulo para leitor de tela |
| Tipografia dinâmica | ⚠️ | Nenhum clamp de `textScaler`; layouts com `Row` rígido podem estourar em fontes ampliadas |
| Pulir inconsistencies | ⚠️ | Alguns pesos/respiros foram normalizados à mão (varreduras `sed` do painel admin); header de sheet UNIFICADO (`SheetHeader` — 2.1 concluída no commit 58a74f5); undo via `showUndoSnackBar` COM countdown de progresso nas ações destrutivas reversíveis (F1.3 concluída) |

**Conclusão do diagnóstico:** o gap para "nível Apple" **não é estético — é sensorial e de
consistência**. O que falta é o que se *sente*: resposta tátil, movimento com propósito,
transições contínuas e voz única em cada interação.

---

## 1 · Princípios de design (contrato interno)

Todo trabalho das fases deve respeitar estes 5 princípios, derivados do HIG:

1. **Clareza** — hierarquia por tamanho/cor/peso, nunca por decoração. (Já em prática.)
2. **Feedback imediato** — *toda* ação tocável responde em <100ms: tato + estado visual.
3. **Movimento com propósito** — animar apenas transições de contexto (entrada, rota,
   confirmação). Nada decorativo. Curva `easeOutCubic`/`emphasized`, 150–320ms.
4. **Consistência > invenção** — um único jeito de confirmar, um único jeito de sheet,
   um único jeito de erro. Componentes novos entram pelo design system, nunca inline.
5. **Deferência ao conteúdo** — cromos, sombras e bordas desaparecem quando o conteúdo
   é o protagonista (ex.: modo foco do PDV).

---

## 2 · Roadmap em 5 fases (≈ 9–11 dias úteis)

### Fase 1 — Sensação tátil e motion foundational · *~1 dia · risco baixo*

**1.1 Sistema de haptics** (novo `lib/core/ui/haptics.dart`):

```dart
abstract final class Haptics {
  static void tap() => HapticFeedback.selectionClick();      // toggle, chip, seleção
  static void success() => HapticFeedback.mediumImpact();    // venda concluída
  static void warning() => HapticFeedback.heavyImpact();     // ação destrutiva
  static void error() => HapticFeedback.vibrate();           // falha de validação
}
```

Padrão de chamada (com cancelamento de escopo):

```dart
// Venda finalizada com sucesso → Medium Impact
// then() para não travar a resposta tátil atrás do push da rota.
Haptics.success(); // após o await de finalização, ANTES de navegar/fechar
```

* *Pontos obrigatórios:* finalizar venda (PDV), abrir/fechar sheet (`showAppSheet`),
  toggle de add-on, salvar formulário (sucesso), remover item (warning),
  erro de validação (error), pull-to-refresh (light).
* **NÃO** apitar em cada tecla do campo numérico do PDV (fadiga).

**1.2 Transições de rota nativas da plataforma** — em `app_theme.dart`:

```dart
pageTransitionsTheme: PageTransitionsTheme(builders: {
  TargetPlatform.android: ZoomPageTransitionsBuilder(),   // M3, contínuo
  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),  // swipe-back nativo
}),
```

**1.3 SnackBar com progresso + undo** — elevar `SnackBar` para
`SnackBarAction` com `AppDurations.slow` (320ms) e duração de 4s; adicionar
**undo** nas ações destrutivas reversíveis (remover item de venda, arquivar
produto, desativar cliente) — padrão Material/iOS de "aço dissipável".

**Validação da fase:** `flutter analyze` + testes de widgets existentes verdes +
teste manual de haptics em device real.

---

### Fase 2 — Design system unificado (varredura de coerência) · *~2 dias · risco médio-baixo*

**2.1 Um único header de sheet.** ✅ **CONCLUÍDA** (commit 58a74f5):
`AppSheetHeader` foi absorvido pelo `SheetHeader` unificado (fechar à
esquerda, título/subtítulo centrado, acção à direita) — varredura por
`AppSheetHeader` retorna zero usos em `lib/` e `test/`; só este plano e o
doc comment do barrel citavam o nome antigo (referências atualizadas).

**2.2 Um único " destructive".** ✅ **CONCLUÍDA**: a unificação já era real
(`showConfirmDialog` centraliza a variante `.danger` + `Haptics.warning` no
toque — a varredura não encontrou `AlertDialog(` inline em telas nem
confirmações ad-hoc). Trancada por dois guard rails: fonte
(`destructive_dialog_guard_test.dart` — proíbe `AlertDialog(`/
`CupertinoAlertDialog(` fora dos componentes do design system e
`HapticFeedback.` direto fora da fachada `Haptics`) e comportamento
(`confirm_dialog_test.dart` via `HapticSpy` — confirmar destrutivo dispara
exatamente 1 `heavyImpact`; cancelar/não-destrutivo não vibram).

**2.3 Espaçamento/raios via tokens em 100%.** ✅ **CONCLUÍDA**: varredura
`grep` dos valores fora da grelha de 4px (`5|6|7|9|10|11|13|14|15|17|18|22|26|28|30`)
em `EdgeInsets` e `SizedBox` retorna **zero ocorrências** em `lib/presentation`
— os ~10% remanescentes foram normalizados para o token da grelha mais próximo
(5/6→8, 10/14→12/16, 28→24; `circular(12)`→`AppRadius.md`). Dois números
repetidos em >1 arquivo viraram tokens (regra do plano):
`AppSpacing.sheetPadding` (`fromLTRB(24, 0, 24, 24)` — 21 usos em 13 arquivos)
e `AppSpacing.fabBottomClearance` (recuo inferior sob FAB — vendas/compras/
financeiro/skeleton). Trancada por guard rail: `spacing_grid_guard_test.dart`
(mesma abordagem de grepping dos guards 2.2/2.4) proíbe valores off-grid em
`EdgeInsets`/`SizedBox`/`Wrap`/`Divider` fora do inventário estrutural
documentado (indents de timeline e alinhamento sob checkbox) — entrada
obsoleta do inventário também falha, para o teto encolher. Literais restantes
são compostos on-grid ou micro-ajustes de 1–4px (baseline de texto, hairlines).

**2.4 Unificar pesos tipográficos.** O painel admin Thin (w300/w400) e o app
principal (w500/w600) coexistem — intencional (densidade admin), mas os *estilos*
devem vir sempre do `textTheme`, nunca `copyWith(fontWeight:)` inline.
Varredura: `grep -rn "copyWith(fontWeight" lib/presentation | wc -l` → reduzir >50%.
✅ **CONCLUÍDA** (teto executável via `font_weight_guard_test.dart`):
158 → 10 (v2.4.0) → 8 → **3** — os 5 "ênfases sancionadas" finais eram
no-ops (`copyWith(fontWeight: w600)` sobre papéis que a escala já define
como w600: `titleSmall`, `titleMedium`, `labelMedium`) e foram removidos.
Os 3 restantes são estruturais e documentados no inventário do guard:
ponte thin do admin (`admin_thin_bridge.dart`, derivação w300/w400 do
painel) e recibo impresso (`sale_receipt_view.dart`, papel de tinta —
total w700/subtotal w600). O guard falha tanto com uso novo NÃO
inventariado quanto com entrada obsoleta — o inventário só encolhe.

**Validação:** analyzer + snapshot visual (screenshots de 12 telas-chave antes/depois).

---

### Fase 3 — Acessibilidade de conteúdo (o maior salto de qualidade percebida) · *~2 dias · risco médio*

**3.1 Rótulos de leitor de tela nos pontos críticos** (alvo: 5 → 60+ `Semantics`):

✅ **CONCLUÍDA na medida do app**: KPIs do dashboard, card de saldo do
Financeiro, cards de venda/produto/fiado/compra (nós compostos via
`buildComposedLabel`), `StatusChip` (nó único) e `PaymentMethodBadge`
(decorativo). **Auditoria de gráficos**: o TAREQO não tem widgets de
gráfico desenhado (fl_chart/CustomPainter de dados) — relatórios e
dashboard apresentam KPIs e séries como TEXTO (`_DailyRow`, cards),
nativos para leitores de ecrã; a alternativa "ouvir resumo" já é a
estrutura da tela. O alvo "60+ Semantics" media presença bruta; o que
importa — nenhum dado essencial invisível ao leitor — está fechado.

* KPIs do dashboard: `Semantics(label: "Vendas de hoje: 12.450 MZN")` — valor
  completo lido de uma vez, não dígito a dígito.
* Gráficos (`fl_chart`): `Semantics(label: "Gráfico de vendas por dia. Últimos 7 dias…")`
  + botão alternativo "ouvir resumo" (texto resumido) para `VoiceOver`/TalkBack.
* Selo de status (`StatusChip`, `MethodBadge`): `Semantics(label: "Pago")`,
  `Semantics(label: "Dinheiro")`.
* Cards de venda/produto: label composto (nome, preço, status).

**3.2 Tipografia dinâmica sem quebrar layouts.** Estratégia em 2 níveis:

```dart
// app.dart — clamp global (acessibilidade sem layout quebrado):
MediaQuery(textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.6), ...)
```

* Nos componentes críticos (PDV, teclado numérico, listas), usar
  `maxLines` + `ellipsis` + `Flexible` para absorver o texto ampliado.
* Auditoria com `flutter run --dart-define=A11Y_BIG_FONT=1` (flag de dev) em 1.3×, 1.6×, 2.0×.
  ✅ **Auditado (automatizado)**: `text_scale_visual_audit_test.dart` renderiza
  login, suporte, lojas e detalhe de loja em 1.3× e 1.6× — zero overflows
  (com o teto global, 1.6× é o pior caso de produção) e capturas PNG por
  tela/escala em `test/presentation/screens/goldens/text_scale_audit/`.
  A auditoria roda na CI a cada push — regressão de texto ampliado quebra a suíte.

**3.3 Foco visível em teclado físico/Bluetooth** (lojas usam scanner+teclado):
`FocusRing`-like: borda primária de 2px no widget focado (já parcial no input,
extender a cards/tiles clicáveis). ✅ **CONCLUÍDA**: widget `FocusRing`
(`focus_ring.dart`) — borda primária 2px por cima do conteúdo
(`Positioned.fill` + `IgnorePointer`), integrado no `AppCard` clicável e no
`SalesCard`; teste via Tab real (`LogicalKeyboardKey.tab`).

**Validação:** testes de widget com `SemanticsHandle`; walkthrough manual com TalkBack.

---

### Fase 4 — Apple-grade polish por superfície · *~3–4 dias · risco médio*

**4.1 PDV (a superfície mais usada):** ✅ **CONCLUÍDA** (commit 5806ee0):
modo foco (busca focada → catálogo/scanner a 40%, carrinho a 100%),
gradiente sutil no botão de pagamento habilitado + escala 0.98 no press
(80ms, opt-in no `AppButton`) — haptics do teclado já cobertos pela F1.
* **Modo foco:** dim de 40% no resto da tela enquanto digita quantidade/preço
  (`AnimatedOpacity` 200ms) — deferência ao conteúdo.
* Teclado numérico com haptics `selectionClick` (sutil) + confirmar com `mediumImpact`.
* Transição de carrinho: `AnimatedSwitcher` (fade+slide 200ms) ao adicionar item.
* Botão de pagamento: gradiente sutil quando habilitado, escala 0.98 no press
  (`ScaleTransition` 80ms) — resposta "física".

**4.2 Dashboard:** ✅ **CONCLUÍDA** — KPIs do card-hero com **contagem animada**
(`_CountUpText`, `TweenAnimationBuilder<double>` 600ms `easeOutCubic`,
respeitando `MediaQuery.disableAnimations`); trocar o período anima do valor
atual ao novo; o rótulo semântico (leitor de ecrã) continua montado com o
valor FINAL — a animação é só visual.

**4.3 Sheets e modais:** ✅ **CONCLUÍDA** (commit 5806ee0) — abrir com
**scale 0.92 + fade** (iOS "card stack"); `showAppSheet` ganhou
`builder: (context) => _SheetScaleIn(child: sheet)` — zero mudanças nos
chamadores.

**4.4 Navegação:** ✅ **CONCLUÍDA** (commit 5806ee0) — transição entre abas do
shell em **fade-through M3** (fade out 90ms + slide 24px + fade in) — padrão
iOS/Material para conteúdo não-hierárquico; mantém `IndexedStack` (estado
preservado).

**4.5 Onboarding/login:** ✅ **CONCLUÍDA** — Large Title na escala
(`displaySmall` 34/w300, cor do scheme) e **parallax** no scroll: o header
(logo + título + tagline) desliza a **meia velocidade** do conteúdo
(`Transform.translate` no listener do `ScrollController` — sem participação
no layout: em repouso, pixel-idêntico ao estático). Com `disableAnimations`
o parallax desliga (o plano anima transições de contexto, nunca custo para
quem desligou movimento). Testes: estilo/parallax 0.5× e caminho sem
movimento (`login_screen_test.dart`); goldens login + auditoria de texto
ampliado regenerados.

**4.6 Ícone/splash:** ✅ **JÁ EXISTIA** (v4.2, pré-plano) — ícone adaptativo
Android (fg/mono) + iOS 1024px a partir de `assets/branding/icon_official.png`,
splash nativo Android 12+/iOS/in-app/web com a marca até o primeiro frame
(ver CHANGELOG v4/v4.2 e checklist 7.4).

**Validação:** gravação de antes/depois de cada fluxo; 60fps verificado em
dispositivo low-end (2GB RAM) com `flutter run --profile`.

---

### Fase 5 — Instrumentação e sustentação · *~1 dia · risco baixo*

**5.1 Lint próprio anti-regressão** (`analysis_options.yaml`): ✅ **CONCLUÍDA**
```yaml
linter:
  rules:
    - prefer_const_constructors    # performance de rebuild — ~250 fixados via dart fix
```
`always_use_package_imports` NÃO se aplica: a convenção dominante do projeto é
import relativo (documentado no próprio `analysis_options.yaml`). O "CI job
design-system-guard" do plano já está atendido de forma mais forte pelos
GUARDS EXECUTÁVEIS na suíte (`font_weight_guard_test.dart`,
`spacing_grid_guard_test.dart`, `destructive_dialog_guard_test.dart`,
`hex_guard_test.dart`) — correm em TODA a CI, sem grep solto.

**5.2 Tokens como fonte única em CI.** ✅ **CONCLUÍDA** — `hex_guard_test.dart`
valida que nenhum hex novo aparece fora do inventário documentado
(paleta de template escolhida pelo usuário, identidade de provedores,
papel de recibo impresso, gradientes de uso único); entrada obsoleta
também falha — o teto só encolhe.

**5.3 Testes de a11y automatizados:** ✅ **CONCLUÍDA** —
`androidTapTargetGuideline` + `iOSTapTargetGuideline` + `textContrastGuideline`
em 10 telas-chave (login, dashboard, vendas, caixa, estoque, clientes,
fiado, relatórios, PDV, sheet de transação — ver doc 23 §a11y).

**5.4 Docs:** ✅ **CONCLUÍDA** — `docs/pt/05-apresentacao.md` e
`12-decisoes-de-arquitetura.md` atualizados com as decisões desta evolução;
este plano recebeu as marcas de conclusão por item.

---

## 3 · Sequenciamento recomendado

```
F1 (1d) ──► F2 (2d) ──► F3 (2d) ──► F4 (3-4d) ──► F5 (1d)
 haptics     unificar      a11y         polish        guard rails
 motion      design sys    conteúdo     por superfície CI
```

* F1 entrega sensação imediata com risco mínimo → vale fazer primeiro e sozinho.
* F2 cria a base de coerência para o polish da F4 não multiplicar inconsistências.
* F3 é a maior alavanca de qualidade percebida por usuários com deficiência — e
  o item mais negligenciado em apps Flutter; aqui o TAREQO pode *superar* o
  padrão típico de ERPs.
* F4 só depois de F2/F3: polir antes de unificar = retrabalho.
* F5 protege o investimento (o "nível Apple" degrada sem guard rails).

---

## 4 · Métricas de sucesso

| Métrica | Hoje | Meta F5 |
|---|---|---|
| `HapticFeedback` em arquivos | 0 | ≥ 12 arquivos-chave |
| `Semantics(` em arquivos | 5 | ≥ 25 |
| Peso inline (`copyWith(fontWeight:`) | ~200 | 3 (guard `font_weight_guard_test.dart` — ponte thin admin + recibo impresso; meta original < 100) |
| Hex inline em `lib/presentation` | 46 ocorrências (medido na F0) → 29 **legítimas documentadas** (paleta de template escolhida pelo usuário, identidade visual de provedores de pagamento/WhatsApp, papel de recibo impresso, gradientes hero de uso único, default de template) — os 17 duplicados de papéis do tema viraram `AppColors.*` | 0 não-documentados |
| Headers de sheet distintos | 2 | 1 |
| Transição de rota | padrão | plataforma-nativa (zoom/cupertino) |
| Guideline de a11y (tap targets/contrast) | não medido | 100% nas 12 telas-chave |
| Dark mode | completo | completo + splash/ícone nativos |

## 5 · Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Haptics irritar em uso intenso (PDV) | Escopo fechado de pontos; nunca por tecla; preferências do tenant (on/off) em `settings` |
| Animações em devices 2GB | Todas ≤ 320ms; respeitar `disableAnimations`; validar em --profile |
| Regressão de testes de widget na unificação de headers | Migração mecânica via grep; analyzer + 239 testes como rede |
| Fontes ampliadas quebrando PDV | Clamp 1.6× global + auditoria por tela (F3.2) |
| Admin Thin vs app principal divergirem | F2.4: pesos só via `textTheme`; ponte `AdminThin` permanece como Theme wrapper |

---

## 6 · Itens fora de escopo (registrados)

* Reescrita para `CupertinoApp` — sem ganho real sobre o tema M3 atual calibrado.
* Mudança de arquitetura de estado (Riverpod/Bloc) — fora do escopo UI/UX.
* Novos módulos de produto — apenas acabamento do existente.
