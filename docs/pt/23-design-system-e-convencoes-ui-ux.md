# Design System — tokens, componentes e convenções de UI/UX

> Fonte única para quem constrói ou revisa telas. O código é a verdade — este
> documento explica **onde** estão os tokens, **como** usar os componentes e
> **quais regras** o CI protege contra regressão.

---

## 1. Tokens (fonte única)

| Token | Arquivo | Conteúdo |
| --- | --- | --- |
| `AppColors` | `lib/core/theme/app_colors.dart` | Paleta da marca (`brand`/`brandMuted`), cores semânticas por brilho (`income`, `expense`, `warning`), neutros e `onBrandContainer*`. Toda cor nova nasce aqui |
| `AppStatusColors` | idem | `ThemeExtension` com pares claro/escuro; acessado por `Theme.of(context).income/expense/warning/accent` |
| `AppSpacing` | `lib/core/theme/app_tokens.dart` | Grelha de 4px (`xxs`=4 … `huge`=48) + `pagePaddingForWidth` (720px quebra mobile/tablet) |
| `AppRadius` | idem | Raios `xs`=8 … `full`=999 + helpers `mdAll` etc. |
| `AppDurations` | idem | `fast`=150ms, `normal`=220ms, `slow`=320ms — teto do plano para QUALQUER animação |
| `AppCurves` | idem | `standard` (easeOutCubic), `decelerate`, `emphasized` (easeInOutCubic) |
| `AppSizes` | idem | `touchTarget`=48dp (mínimo WCAG), ícones, avatares, `contentMaxWidth` |
| `ModuleColors` | idem | 6 cores de módulo (Produtos/Clientes/Fiado/Compras/Relatórios/Lojas) — conjunto FECHADO |
| `IconTone` | idem | Derivação HSL de fundo escuro + foreground claro para ícones em container |

**Regra:** cor nova → `AppColors`; nunca `Color(0x…)` inline. Os hex literais
remanescentes em `lib/presentation` são um inventário FECHADO com justificativa
documentada (ver §6 — o CI falha se crescer).

## 2. Componentes fundamentais

Usar SEMPRE o componente do design system; não recriar variantes por tela.

| Componente | Arquivo | Uso |
| --- | --- | --- |
| `AppButton` | `lib/presentation/widgets/app_button.dart` | `.primary`/`.secondary`/`.danger` — altura 48, cantos 12 |
| `AppTextField` | `lib/presentation/widgets/` | Campo padrão (label, erro, ícone) |
| `AppPickerField` | `app_picker_field.dart` | Dropdown de formulário (wrappa `DropdownButtonFormField`) |
| `AppCard` | `app_card.dart` | Card base (`elevated`, raios) |
| `SheetHeader` | `lib/presentation/widgets/app_sheet.dart` | ÚNICO cabeçalho de sheet (fechar à esquerda, título centrado, ação à direita). O antigo `AppSheetHeader` foi absorvido |
| `showAppSheet` | idem | Toda bottom sheet passa por aqui (padding do teclado incluso) |
| `SheetSection` | idem | Grupo de formulário dentro de sheet |
| `FilterDropdown` | `filter_dropdown.dart` | Chip de filtro (período/pagamento) — compartilhado Vendas/Compras |
| `EmptyState` / `ErrorView` | `empty_state.dart` / `error_view.dart` | Estados vazio e erro com retry |
| `Skeleton` / `ListSkeleton` | `skeleton.dart` | Loading — respeita `disableAnimations` |
| `AppPage` | `app_page.dart` | Página padrão (título, subtítulo, ações, FAB) |
| `StatusChip` / `PulseBadge` | `status_chip.dart` / `pulse_badge.dart` | Estado de item; badge de notificação (pulso respeita `disableAnimations`) |
| `SmartAmount` | `smart_amount.dart` | Valor monetário que encolhe sem truncar (usar em Row apertada) |
| `Haptics` | `lib/core/ui/haptics.dart` | Camada central de feedback tátil (ver §4) |

## 3. Estados de interface

Toda tela importante implementa: loading (`Skeleton`), erro (`ErrorView` com
retry), vazio (`EmptyState`), sucesso e offline. Mensagens de erro respondem:
(1) o que aconteceu, (2) o impacto, (3) o que o utilizador pode fazer — sem
jargão técnico (Exception/Socket nunca chegam ao utilizador; o log técnico vai
para o `CrashReporting`).

## 4. Haptics — regras de uso

Camada central `lib/core/ui/haptics.dart` (com preferência do utilizador nas
configurações). **Nunca** chamar `HapticFeedback` direto.

| Evento | Método |
| --- | --- |
| Venda/pagamento/compra/fiado/quitação/fecho concluídos | `Haptics.success()` (chamar ANTES do pop) |
| Erro bloqueante que exige atenção | `Haptics.error()` |
| Seleção relevante (stepper do carrinho) | `Haptics.selection()` |

Proibido: haptic por tecla do PDV, em scroll, em navegação ou em erros
comuns de validação. Teste de contrato: `test/helpers/haptic_spy.dart`
(espiona o canal de plataforma) — ver `haptics_wiring_test.dart`.

## 5. Motion

- Duração: usar `AppDurations` (máx. 320ms). Nada de animação no caminho
  crítico do PDV (o feedback do toque é o haptic).
- Curvas: `AppCurves`.
- **Obrigatório:** qualquer animação (sobretudo `repeat`) verifica
  `MediaQuery.disableAnimationsOf(context)` — ver `Skeleton`,
  `FadeIndexedStack` e `PulseBadge` como padrão.
- Efeitos decorativos (escala, gradiente, blur) exigem justificativa
  funcional; "parecer premium" não é função.

## 6. Acessibilidade

- Alvos de toque ≥ 48dp (`AppSizes.touchTarget`) — inclusive segmentos,
  chips e linhas de lista.
- Contraste de TEXTO ≥ 4.5:1 (WCAG AA); ícone/chip ≥ 3:1. Cores semânticas
  têm par claro/escuro calibrado (`theme_contrast_test.dart`).
- Estado NUNCA só pela cor: "estoque baixo", "inativo" etc. têm texto
  (leitor de ecrã e daltónicos).
- `Semantics`/tooltip em todo ícone-ação; gráficos têm alternativa textual.
- Fonte ampliada (2.0×) não pode estourar layout — `Flexible`/`FittedBox`/
  `maxLines` antes de pensar em limitar escala.
- Relógio de telas com "Hoje/Ontem": usar `AppClock` (não `DateTime.now`)
  — determinismo em testes.

## 7. Guard rails do CI

Falham o push quando violados (`flutter analyze` + `dart format` +
`flutter test` no `.github/workflows/ci.yml`):

| Guard | Onde | Protege |
| --- | --- | --- |
| Guidelines de a11y | `test/presentation/screens/pdv_accessibility_test.dart` + teste `a11y:` em 9 telas-chave (login, dashboard, vendas, caixa, estoque, clientes, fiado, relatórios, PDV) | `androidTapTargetGuideline` ≥48dp, `iOSTapTargetGuideline`, `textContrastGuideline` |
| Inventário de hex | `test/core/theme/hex_guard_test.dart` | Nenhum `Color(0x…)` novo fora da lista justificada (nem entrada obsoleta) |
| Contraste dos temas | `test/core/theme/theme_contrast_test.dart` | Cores semânticas AA nos dois modos |
| Haptics | `test/presentation/screens/haptics_wiring_test.dart` | Fluxos de DINHEIRO confirmam com sucesso/erro na camada `Haptics` |
| Movimento reduzido | `pulse_badge_test.dart`, `design_system_components_test.dart` | `disableAnimations` desliga fade e pulso sem esconder informação |
| Fonte ampliada | testes `não estoura com escala de texto 2.0` (8 telas) | Overflow com textScale 2.0 |
| Rotação | testes `sobrevivem à rotação` (vendas, clientes, fiado, relatórios, dashboard) | Layout em paisagem |
| Goldens | `test/presentation/goldens/` | Regressão visual (login, dashboard, PDV, design system — claro+escuro) |
| Cobertura ≥ 90% | `ci.yml` (job test) | Gate existente do projeto |
| L10n (chaves mortas + paridade) | `test/core/l10n` | Chaves órfãs/desalinhadas entre pt/en/fr |

### Como adicionar uma cor nova (checklist)

1. A cor representa um papel reutilizável? → `AppColors` (+ par claro/escuro
   se for semântica) + atualizar `theme_contrast_test.dart` se necessário.
2. É identidade externa (provedor de pagamento, WhatsApp) ou meio de impressão?
   → hex inline permitido, MAS atualize o inventário do
   `hex_guard_test.dart` com a justificativa.
3. Nunca introduzir hex sem passar por 1 ou 2 — o CI bloqueia.

### Como adicionar uma animação (checklist)

1. Justificativa funcional? (explica mudança, confirma ação, direciona atenção)
2. Duração ≤ `AppDurations.slow` e curva de `AppCurves`?
3. Gate `disableAnimationsOf` implementado e testado?
4. Não está no caminho crítico do PDV?
