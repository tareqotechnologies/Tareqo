# TAREQO Signature — Design System

**Versão**: 1.0
**Âmbito**: identidade visual do frontend TAREQO (ERP comercial multi-loja)
**Estado**: especificação — nenhum ecrã foi alterado
**Base**: princípios de clareza, hierarquia e contenção das Human Interface Guidelines, adaptados a um ERP de uso diário (densidade, números tabulares, teclado/scanner, luz de loja).

> **Nota de identidade.** TAREQO Signature **não replica** a interface de nenhum produto. Apropria-se de princípios — hierarquia tipográfica, superfícies calmas, cor com significado, movimento discreto — e diverge deliberadamente onde um ERP exige: alvos de toque maiores, tabelas densas, números tabulares, contraste reforçado e estados explícitos.

---

## 0. Princípios

1. **O conteúdo é a interface.** 90% da superfície é neutra; a cor entra para indicar ação ou estado, nunca para decorar.
2. **Uma ação primária por ecrã.** Se dois botões competem, um deles está errado.
3. **Hierarquia por tipografia e espaço, não por cor.** Títulos maiores, não mais coloridos.
4. **Números são dados, não texto.** Sempre tabulares, alinhados à direita, com unidade e moeda consistentes.
5. **Estados nunca só por cor.** Ícone + rótulo + cor; daltonismo e luz solar são requisitos reais de balcão.
6. **Movimento serve a compreensão.** Se a animação não explica uma mudança, remove-se.
7. **Densidade com respiração.** ERP precisa de ver mais, mas cada linha precisa de ar suficiente para não errar no toque.
8. **Reversibilidade.** Ações destrutivas pedem confirmação; ações reversíveis oferecem “Desfazer”.

---

## 1. Orçamento de cor (regra de aplicação)

| Proporção | Família | Onde |
|---|---|---|
| **~90%** | Neutros (canvas, superfície, texto, divisores) | Fundos, listas, tabelas, formulários |
| **~8%** | Azul de ação (`action`, `actionFill`, `actionText`) | CTA primária, seleção, links, foco, indicador de navegação |
| **~2%** | Semântica (sucesso, alerta, erro, informação) | Apenas estados e badges; nunca fundos de página |

Regras:
- **Máximo 1 botão preenchido azul por viewport.** Ações secundárias são contornadas ou textuais.
- **Semântica nunca é decoração.** Verde só significa sucesso/entrada; vermelho só erro/destrutivo.
- **Nunca usar duas cores semânticas no mesmo cartão** (exceto “diferença” em fecho de caixa, onde o par é o próprio conteúdo).
- **Terracota e petróleo saem da UI funcional.** Ficam reservados ao símbolo da marca e à ilustração de arranque. Isto elimina a ambiguidade atual (`IconTone.green` = terracota).

---

## 2. Paleta principal — tema claro

### 2.1 Superfícies e texto

| Token | HEX | Uso | Contraste medido |
|---|---|---|---|
| `canvas` | `#F5F5F7` | Fundo da aplicação | — |
| `surface` | `#FFFFFF` | Cartões, listas, sheets, campos | — |
| `surfaceSunken` | `#EDEDF0` | Zonas agrupadas, fundo de inputs | — |
| `surfaceRaised` | `#FFFFFF` | Superfície com elevação | — |
| `surfaceTint` | `#F0F6FF` | Zona informativa/selecionada | — |
| `border` | `#D2D2D7` | Divisores e contornos decorativos | — |
| `borderStrong` | `#C7C7CC` | Contorno de controlos (≥3:1) | — |
| `separator` | `#E5E5EA` | Linhas de lista/tabela | — |
| `textPrimary` | `#1D1D1F` | Títulos e corpo | **16.83:1** sobre `surface` · **15.46:1** sobre `canvas` |
| `textSecondary` | `#6E6E73` | Apoio, metadados | **5.07:1** sobre `surface` · **4.66:1** sobre `canvas` |
| `textTertiary` | `#636366` | Texto menos importante | **5.99:1** sobre `surface` · **5.50:1** sobre `canvas` |
| `textDisabled` | `#AEAEB2` | Desativado (isento de AA) | — |
| `textOnAction` | `#FFFFFF` | Texto sobre preenchimento de ação | ver §2.2 |

> `#8E8E93` (usado como terciário em alguns sistemas) dá apenas **3.26:1** sobre branco — **não é permitido para texto pequeno** neste sistema. Fica reservado a ícones decorativos e placeholders de ≥17 px.

### 2.2 Azul de ação — três tons, três funções

| Token | HEX | Função | Contraste |
|---|---|---|---|
| `action` | `#007AFF` | Ícones, foco, indicador de seleção, controlos (não-texto) | **4.02:1** sobre branco (UI ≥3:1 ✓) |
| `actionFill` | `#0071E3` | Fundo de botão primário | branco sobre ele: **4.70:1** (AA ✓) |
| `actionText` | `#0062CC` | Links e texto de ação sobre superfície | **5.80:1** (AA ✓) |
| `actionPressed` | `#0051A8` | Estado premido | **7.66:1** |
| `actionSoft` | `#E8F1FF` | Fundo de chip selecionado / realce | — |
| `actionBorder` | `#B3D4FF` | Contorno de seleção | — |

> **Porquê três tons:** `#007AFF` puro com texto branco a 15 px dá 4.02:1 e falha AA. Em vez de reduzir a vivacidade da marca ou aumentar o texto, separa-se a função: ícone/foco usa `#007AFF`; preenchimento de botão usa `#0071E3`; link usa `#0062CC`.

### 2.3 Paleta semântica — tema claro

| Token | HEX | Uso | Contraste |
|---|---|---|---|
| `success` | `#248A3D` | Ícone/badge de sucesso | **4.40:1** sobre branco (não-texto ✓) |
| `successText` | `#1E7A34` | Texto de sucesso | **5.40:1** (AA ✓) |
| `successSoft` | `#E7F4EA` | Fundo de badge sucesso | — |
| `warning` | `#B25000` | Texto/ícone de alerta | **5.20:1** (AA ✓) |
| `warningBright` | `#D97706` | Ícone de alerta (não-texto) | ≥3:1 |
| `warningSoft` | `#FFF3E0` | Fundo de badge alerta | — |
| `error` | `#D70015` | Erro, destrutivo | **5.38:1** (AA ✓) |
| `onError` | `#FFFFFF` | Texto sobre erro | **5.38:1** (AA ✓) |
| `errorSoft` | `#FDECEF` | Fundo de badge erro | — |
| `info` | `#0057B8` | Informação | **6.87:1** (AA ✓) |
| `infoSoft` | `#E8F1FB` | Fundo de badge informação | — |

---

## 3. Tema escuro completo

O escuro **não é uma inversão**: é uma paleta própria, com superfícies quase pretas, texto quase branco e azul mais luminoso.

| Token | HEX | Uso | Contraste medido |
|---|---|---|---|
| `canvas` | `#0B0B0D` | Fundo | — |
| `surface` | `#161618` | Cartões e listas | — |
| `surfaceRaised` | `#1C1C1E` | Sheets, diálogos, menus | — |
| `surfaceSunken` | `#0F0F11` | Inputs, zonas agrupadas | — |
| `border` | `#2C2C2E` | Divisores decorativos | 1.41:1 (não-texto) |
| `borderStrong` | `#3A3A3C` | Contorno de controlos | 1.50:1 (usar só com preenchimento contrastado) |
| `separator` | `#242426` | Linhas de lista | — |
| `textPrimary` | `#F5F5F7` | Títulos e corpo | **16.60:1** sobre `surface` · **18.06:1** sobre `canvas` |
| `textSecondary` | `#A1A1A6` | Apoio | **7.03:1** sobre `surface` |
| `textTertiary` | `#8E8E93` | Menos importante | **5.54:1** sobre `surface` |
| `textDisabled` | `#636366` | Desativado | — |
| `action` | `#0A84FF` | Ícones, foco, seleção | **4.95:1** sobre `surface` |
| `actionFill` | `#0A84FF` | Botão primário (rótulo escuro) | `#0B0B0D` sobre ele: **5.39:1** |
| `actionText` | `#0A84FF` | Links | **4.95:1** (AA ✓) |
| `actionPressed` | `#409CFF` | Premido (clareia, não escurece) | — |
| `actionSoft` | `#0F2A44` | Fundo de seleção | — |
| `success` | `#30D158` | Sucesso | **8.42:1** |
| `warning` | `#FF9F0A` | Alerta | **8.28:1** |
| `error` | `#FF453A` | Erro | **4.99:1** |
| `info` | `#64D2FF` | Informação | **9.89:1** |
| `onSemantic` | `#0B0B0D` | Rótulo sobre preenchimentos semânticos | ≥5.39:1 em todos |

**Regra do escuro:** o preenchimento primário usa rótulo **escuro** (`#0B0B0D`), não branco (branco sobre `#0A84FF` = 3.65:1, falha AA). Esta é uma decisão de identidade, não um workaround.

---

## 4. Tipografia

### 4.1 Famílias

| Uso | Família | Justificação |
|---|---|---|
| Interface e dados | **Inter** (variável, eixos `wght`/`opsz`) | Legibilidade em densidade, algarismos tabulares, licença aberta |
| Números e código | **Roboto Mono** (`monospace`) | Códigos MFA, IDs, séries de fatura |
| Fallback de plataforma | Roboto (Android), Segoe UI (Windows), Helvetica Neue (iOS/macOS), `sans-serif` (Web) | Rede de segurança de glifos via `fontFamilyFallback`; nunca se distribuí fontes proprietárias |

> **Regra de resolução:** `fontFamily` recebe o nome **exato** registado no `pubspec` (`Inter`).
> Uma lista no estilo CSS (`'Inter, -apple-system, …'`) **não** é resolvida pelo motor e cai
> silenciosamente na fonte padrão da plataforma. O fallback vive em
> `AppTypography.familyFallback`.

### 4.2 Escala (px lógicos; cresce com `textScale` até 1.6×)

Fonte única: `lib/core/theme/app_typography.dart` (`AppTypography.*`).

| Token | Tamanho / Linha | Peso | Tracking | Uso |
|---|---|---|---|---|
| `display` | 28 / 36 | 600 | −0.6 | Saldo principal, grandes destaques |
| `headline` | 24 / 32 | 600 | −0.5 | Título de página (AppBar/`AppPage`) |
| `titleLarge` | 20 / 28 | 600 | −0.35 | Título de secção |
| `titleMedium` | 16 / 24 | 500 | −0.3 | Título de card/grupo, nome de entidade |
| `bodyLarge` | 16 / 24 | 400 | −0.1 | Texto principal, texto digitado |
| `bodyMedium` | 14 / 20 | 400 | −0.1 | Texto secundário, subtítulos |
| `bodySmall` | 12 / 16 | 400 | 0 | Metadados (datas, horários, detalhes) |
| `labelLarge` | 14 / 20 | 500 | 0 | Botões, ações primárias, valores de linha |
| `labelMedium` | 12 / 16 | 500 | 0 | Filtros, status, badges, navegação |
| `labelSmall` | 11 / 16 | 500 | 0 | Apenas informação **não essencial** |

Mapeamento do `TextTheme` (15 papéis Material): `display*` → `display`; `headline*` →
`headline`; `titleSmall` → degrau 14/w500; os restantes homónimos. Um papel sem
mapeamento herdaria a escala padrão do Material (outra família e outros tamanhos).

**Regras**
- **Nunca** usar tamanho abaixo de 12 px em informação essencial (erros, valores,
  labels de campo, botões, status, navegação, instruções). 11 px é só para
  acessórios (selo de contagem, caption).
- **Nunca** reduzir texto para “caber”: quebra, trunca com `maxLines` ou usa `FittedBox`
  apenas em valores numéricos.
- **Sempre** `FontFeature.tabularFigures()` em dinheiro, quantidades, percentagens,
  datas e IDs — já embutido em todos os tokens.
- Navegação usa `labelMedium` (12), nunca 11; o item ativo sobe para w600.
- **Nenhum** `fontSize`/`fontFamily`/peso inline em telas — a guarda
  `test/presentation/widgets/typography_token_guard_test.dart` falha o contrário
  (exceções documentadas: painel admin thin, recibo impresso, pré-visualização de A4).

### 4.3 Pesos

| Peso | Uso |
|---|---|
| 400 | Corpo, linhas de lista, inputs |
| 500 | Botões, labels, status, filtros, navegação, títulos de card |
| 600 | Títulos (display/headline), valor financeiro dominante da linha |

**Só 400/500/600.** O w600 é ênfase de hierarquia, não o peso padrão de nada.
O painel thin do super admin (`AdminThin`) é a única derivação sancionada (w300),
com testes próprios.

### 4.4 Alturas de linha

Títulos: **1.29–1.33** (32/24, 36/28) · Corpo: **1.33–1.43** (16/12, 20/14, 24/16)
Nunca usar `height: 1.0` em texto multi-linha.

---

## 5. Espaçamento

Grelha base **4 px**; incrementos preferenciais: 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64.

| Token | px | Uso típico |
|---|---|---|
| `space0` | 0 | — |
| `space1` | 2 | Ajuste ótico de ícone |
| `space2` | 4 | Gap ícone-texto em badges |
| `space3` | 8 | Entre label e campo, entre linhas relacionadas |
| `space4` | 12 | Padding interno de badge, gap de chips |
| `space5` | 16 | Padding padrão de cartão, margem de página mobile |
| `space6` | 20 | Padding de cartão premium, margem de página |
| `space7` | 24 | Separação de secções, padding de diálogo |
| `space8` | 32 | Separação de blocos, margem wide |
| `space9` | 40 | Cabeçalho de ecrã |
| `space10` | 48 | Entre grupos de formulário |
| `space11` | 64 | Topo de ecrã vazio, respiro de onboarding |

**Regras**
- Margem horizontal: **16** mobile, **24** tablet, **32** ≥1024.
- Largura máxima de conteúdo: **1040**; acima disso, centrar (nunca esticar listas).
- Padding de cartão: **16**; cartão de destaque: **20–24**.
- Entre secções: **24**; entre grupos de formulário: **32**.

---

## 6. Raios de borda

| Token | px | Uso |
|---|---|---|
| `radiusXs` | 6 | Badge pequeno, checkbox |
| `radiusSm` | 10 | Chip compacto, ícone container 32 |
| `radiusMd` | 14 | **Campos e botões** (padrão) |
| `radiusLg` | 18 | **Cartões e listas agrupadas** |
| `radiusXl` | 22 | Diálogos, popovers |
| `radius2xl` | 28 | Sheets (topo), painéis |
| `radiusFull` | 999 | Pílulas, avatares, badges redondos |

**Regras**
- Um cartão e os controlos dentro dele **não** partilham o mesmo raio: cartão 18, campo 14.
- Nunca misturar raio 12 e 14 na mesma vista — é a divergência mais visível do sistema atual.
- Elementos encostados ao ecrã (sheet fullscreen) usam 0 no topo apenas em fullscreen.

---

## 7. Elevação e sombras

**Princípio:** no claro a elevação é *sombra + contorno*; no escuro é *contorno + luz*, quase sem sombra.

| Nível | Uso | Claro | Escuro |
|---|---|---|---|
| `e0` | Superfície plana (padrão) | sem sombra + borda 1 | sem sombra + borda 1 |
| `e1` | Cartão interativo em repouso | `0 1 2 rgba(0,0,0,.06)` | `0 1 1 rgba(0,0,0,.40)` |
| `e2` | Cartão elevado, menu | `0 4 12 rgba(0,0,0,.08)` | `0 6 16 rgba(0,0,0,.45)` |
| `e3` | Sheet, popover | `0 12 28 rgba(0,0,0,.12)` | `0 12 32 rgba(0,0,0,.55)` |
| `e4` | Diálogo modal | `0 24 48 rgba(0,0,0,.16)` | `0 24 56 rgba(0,0,0,.60)` |

Sombras nunca são coloridas. No escuro, adicionar realce interno `0 0 0 1 rgba(255,255,255,.04)`.

**Scrim modal:** claro `rgba(0,0,0,0.40)`; escuro `rgba(0,0,0,0.60)`.

---

## 8. Ícones e áreas de toque

### 8.1 Ícones
| Token | px | Uso |
|---|---|---|
| `iconSm` | 16 | Inline em texto, badges |
| `iconMd` | 20 | Ações de barra, prefixo de campo |
| `iconLg` | 24 | Navegação, cabeçalhos de lista |
| `iconXl` | 28 | Estado vazio, FAB |
| `iconDisplay` | 32–48 | Ilustração de estado vazio/erro |

Regras:
- Um único estilo por ecrã (outline **ou** preenchido); preenchido apenas para estado selecionado.
- Espessura de traço **1.75** consistente.
- Ícone isolado nunca é a única indicação de estado: acompanha rótulo ou `tooltip`.
- Ícones em botões de ícone têm container de toque, não são o alvo.

### 8.2 Áreas de toque
| Contexto | Mínimo | Recomendado |
|---|---|---|
| Ação primária | 44 | **48** |
| Botão de ícone | 44 | **48** |
| Linha de lista | 56 | **64** |
| Célula de tabela | 40 | **44** |
| Chip/pílula | 32 de altura | **36** (com área de toque 48) |
| FAB | 56 | **56** |

**Regra ERP:** 48 px é o padrão (não 44), porque o uso acontece em pé, com pressa, por vezes com luvas.

---

## 9. Componentes

### 9.1 Cartões
- Raio **18**, padding **16**, borda 1 px `border`, **sem sombra em repouso** (`e0`).
- Elevar para `e1`/`e2` apenas se for clicável ou contiver dados “herói”.
- Título `headline`/`title3`; apoio `footnote` `textSecondary`.
- Máximo **1** cartão “herói” por ecrã (saldo, total, KPI principal).
- Nunca colocar um cartão dentro de outro cartão com borda — usar `surfaceSunken` interno sem borda.

### 9.2 Listas
- Altura de linha **64** (densa 56), padding horizontal 16.
- Estrutura: ícone/avatar 40 → 12 → título (`body`, 500) + subtítulo (`footnote`) → 8 → trailing (valor `subhead` 600 tabular ou chevron).
- Separador 1 px `separator`, **inset 72** quando há avatar/ícone; 16 quando não há.
- Agrupar em **uma** superfície contínua com raio 18, não um cartão por linha.
- Ação destrutiva nunca é a linha inteira: usa menu `⋯` ou swipe com confirmação.
- Estados: normal, premido (8% overlay), selecionado (`actionSoft`), desativado (38% texto).

### 9.3 Tabelas (dados densos)
- Cabeçalho `overline` `textSecondary`, sticky, altura 40, fundo `surface`, separador inferior 1 px.
- Linha 44 (densa 40), sem zebra; separadores 1 px `separator`.
- **Números sempre à direita e tabulares.** Texto à esquerda. Datas em formato curto consistente.
- Larguras mínimas: texto 120, número 88, data 96, ação 48.
- Em mobile: converter em lista de duas linhas (não scroll horizontal infinito). Scroll horizontal só em admin/desktop, com primeira coluna fixa.
- Totais no rodapé, `subhead` 600, com separador superior 1 px.

### 9.4 Formulários
- Label **acima** do campo (`footnote` 500), gap 8.
- Campo altura **48**, raio **14**, fundo `surfaceSunken`, borda 1 `border`.
- Foco: borda 1.5 `action` + anel externo 3 px `action` a 20%.
- Erro: borda `error` + mensagem `caption` `error` com ícone, abaixo, gap 6.
- Helper: `caption` `textSecondary`, máximo 2 linhas.
- Placeholder nunca substitui label.
- Campos relacionados em grupo com gap 16; grupos separados por 32.
- Nunca validar apenas no submit: validar no `blur` e limpar erro ao corrigir.
- Teclado: `textInputAction` correto, `autofillHints`, foco devolvido ao campo inicial após diálogo (PDV).

### 9.5 Diálogos
- Largura máxima **400**, raio **22**, padding **24**, `e4`.
- Título `headline` (20/26/600), corpo `subhead` ou `body` `textSecondary`.
- Ações à direita em desktop; **empilhadas** em mobile, primária em cima, altura 48.
- Destrutivo: botão `error` preenchido; cancelar sempre presente e nunca ambíguo.
- Fechar por scrim só se não houver perda de dados.
- Um diálogo = uma decisão. Se precisa de scroll longo, é uma sheet ou ecrã.

### 9.6 Sheets
- Raio superior **28**, handle 36×4 `borderStrong`, header 56.
- Padding horizontal 24; bottom respeita `viewInsets` e safe area.
- Ação principal no header (à direita) ou no fundo fixo — nunca ambas.
- Fullscreen só para fluxos com teclado/scanner (PDV).
- Entrada: translate + fade 240 ms; saída 180 ms.

### 9.7 Botões
| Variante | Fundo | Texto | Borda |
|---|---|---|---|
| Primário | `actionFill` | `textOnAction` | — |
| Secundário | `surface` | `textPrimary` | 1 `borderStrong` |
| Terciário | transparente | `actionText` | — |
| Destrutivo | `error` | `onError` | — |
| Desativado | 12% `textPrimary` | 38% `textPrimary` | — |

- Altura 48 (compacto 40, herói 56), raio 14, label 15/20 600.
- Um primário por viewport; ícone opcional à esquerda com gap 8.
- Loading: manter largura, spinner 16 no lugar do ícone, desativar toque.

### 9.8 Badges e chips
- Altura 28 (chip 32), raio full, padding horizontal 8–12.
- Texto `caption` 500; ícone 12–14 quando necessário.
- Semânticos usam `*Soft` de fundo + `*Text` de texto + ícone.
- Seleção usa `actionSoft` + `actionBorder` + `actionText`; **nunca** preencher com azul sólido e texto pequeno.

### 9.9 Navegação
- Barra inferior 64 + safe area; ícone 24; label `caption2` 500.
- Indicador de seleção: pílula 64×32 `actionSoft`, ícone `action`.
- Rail (≥880): largura 80, ícone 24, label 11, seleção com pílula vertical.
- AppBar 56, título `title3`; ações 48×48.
- Título grande de secção no corpo (não duplicar no AppBar).

---

## 10. Estados de interação

| Estado | Superfície | Texto | Borda/Sinal | Duração |
|---|---|---|---|---|
| Repouso | base | base | base | — |
| Hover | +4% `textPrimary` | igual | igual | 120 ms |
| Premido | +8% `textPrimary` | igual | igual | 90 ms |
| Foco | igual | igual | anel 2 px `action`, offset 2 | 120 ms |
| Selecionado | `actionSoft` | `actionText` | 1 px `actionBorder` | 180 ms |
| Desativado | 12% fill | 38% texto | sem interação | — |
| Carregando | manter layout | spinner/skeleton | sem toque | loop |
| Erro | `errorSoft` (badge) | `error` | 1 px `error` | 180 ms |

Regras:
- **Foco por teclado é obrigatório** — há scanner e teclado físico no ERP.
- Hover só existe onde há rato; nunca depender dele para descobrir ações.
- Todo o toque tem resposta visual ≤100 ms, mesmo que a operação demore.
- Skeleton só aparece após **150 ms** de espera (evita flash).

---

## 11. Animação e feedback

### 11.1 Durações e curvas

| Token | Duração | Uso |
|---|---|---|
| `motionInstant` | 0 ms | Reduced motion |
| `motionFast` | 120 ms | Hover, toggle, chip |
| `motionBase` | 180 ms | Botão, campo, seleção |
| `motionModerate` | 240 ms | Sheet, diálogo, expansão |
| `motionSlow` | 320 ms | Transição de página |
| `motionDeliberate` | 400 ms | Contagem de valor-herói (máx.) |

| Curva | Valor | Uso |
|---|---|---|
| `standard` | `cubic-bezier(0.2, 0, 0, 1)` | Maioria |
| `entrance` | `cubic-bezier(0.32, 0.72, 0, 1)` | Entradas (sheet, diálogo) |
| `exit` | `cubic-bezier(0.4, 0, 1, 1)` | Saídas |
| `spring` | mass 1, stiffness 380, damping 32 | Sheets e gestos |

### 11.2 Regras
- Animar apenas `opacity`, `transform` e `color`; nunca `width`/`height` em listas.
- Movimento reduzido (`MediaQuery.disableAnimationsOf`): **sem parallax, sem count-up, sem scale**; crossfade ≤120 ms ou corte direto.
- Entrada de sheet: translate 24 px + fade, 240 ms. Saída: 180 ms.
- Confirmação destrutiva: sem bounce, sem celebração.
- Sucesso: check + `SnackBar` 3 s; se reversível, ação “Desfazer”.
- Erro: shake **não** é usado; usar borda + ícone + mensagem.

### 11.3 Haptics
| Evento | Feedback |
|---|---|
| Seleção de aba/chip | `selectionClick` |
| Toggle | `lightImpact` |
| Ação primária concluída | `lightImpact` |
| Confirmação destrutiva | `mediumImpact` |
| Erro de validação | `notificationError` |
| Scan de código | `lightImpact` + som opcional |

Sempre respeitar a preferência do utilizador (`Haptics.load` existente).

---

## 12. Exemplos de utilização

> Snippets ilustrativos com tokens Signature. Não são código aplicado; os ecrãs atuais permanecem inalterados.

### 12.1 Botão primário
```dart
FilledButton(
  style: FilledButton.styleFrom(
    backgroundColor: TareqoColors.actionFill,
    foregroundColor: TareqoColors.textOnAction,
    minimumSize: const Size(0, TareqoSizes.controlHeight), // 48
    padding: const EdgeInsets.symmetric(horizontal: TareqoSpace.s6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TareqoRadius.md), // 14
    ),
    textStyle: TareqoType.button, // 15/20/600
  ),
  onPressed: onSave,
  child: const Text('Guardar'),
)
```

### 12.2 Cartão
```dart
Container(
  padding: const EdgeInsets.all(TareqoSpace.s5), // 16
  decoration: BoxDecoration(
    color: TareqoColors.surface,
    borderRadius: BorderRadius.circular(TareqoRadius.lg), // 18
    border: Border.all(color: TareqoColors.border),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Saldo de caixa', style: TareqoType.footnote),
      const SizedBox(height: TareqoSpace.s3),
      Text('12 480,00 MZN', style: TareqoType.moneyHero), // tabular
    ],
  ),
)
```

### 12.3 Linha de lista
```dart
SizedBox(
  height: 64,
  child: Row(
    children: [
      const AppAvatar(initials: 'AC', size: 40),
      const SizedBox(width: TareqoSpace.s4), // 12
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ana Costa', style: TareqoType.bodyMedium),
            Text('D-00042 · vence hoje', style: TareqoType.footnoteSecondary),
          ],
        ),
      ),
      Text('1 250,00', style: TareqoType.amountInRow),
    ],
  ),
)
```

### 12.4 Estado semântico
```dart
StatusBadge(
  tone: StatusTone.success,
  label: 'Pago',
  icon: Icons.check_circle_outline,
)
// fundo: successSoft · texto: successText · ícone: success
// nunca apenas o ponto verde
```

### 12.5 Campo com erro
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Telefone',
    filled: true,
    fillColor: TareqoColors.surfaceSunken,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: TareqoSpace.s4,
      vertical: TareqoSpace.s4,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(TareqoRadius.md),
      borderSide: BorderSide(color: TareqoColors.border),
    ),
    errorText: 'Número inválido',
  ),
)
```

### 12.6 Diálogo destrutivo
```dart
AlertDialog(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(TareqoRadius.xl), // 22
  ),
  title: Text('Anular venda?', style: TareqoType.title3),
  content: Text(
    'Esta ação repõe o stock e não pode ser desfeita.',
    style: TareqoType.bodySecondary,
  ),
  actions: [
    TextButton(child: const Text('Cancelar'), onPressed: cancel),
    FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: TareqoColors.error,
        foregroundColor: TareqoColors.onError,
      ),
      onPressed: confirm,
      child: const Text('Anular'),
    ),
  ],
)
```

---

## 13. Mapeamento para o código atual (sem alterar ecrãs)

O sistema atual já tem tokens (`AppSpacing`, `AppRadius`, `AppDurations`, `AppSizes`) e tema (`AppTheme`). Signature **não os substitui de imediato**; publica uma camada `signature/*` e mapeia.

### 13.1 `ColorScheme` proposto

| Papel M3 | Claro | Escuro |
|---|---|---|
| `primary` | `#0071E3` | `#0A84FF` |
| `onPrimary` | `#FFFFFF` | `#0B0B0D` |
| `primaryContainer` | `#E8F1FF` | `#0F2A44` |
| `onPrimaryContainer` | `#0062CC` | `#0A84FF` |
| `surface` | `#FFFFFF` | `#161618` |
| `onSurface` | `#1D1D1F` | `#F5F5F7` |
| `onSurfaceVariant` | `#6E6E73` | `#A1A1A6` |
| `outline` | `#C7C7CC` | `#3A3A3C` |
| `outlineVariant` | `#D2D2D7` | `#2C2C2E` |
| `error` | `#D70015` | `#FF453A` |
| `onError` | `#FFFFFF` | `#0B0B0D` |
| `errorContainer` | `#FDECEF` | `#3A0D12` |
| `onErrorContainer` | `#D70015` | `#FFB4AB` |
| `scaffoldBackground` | `#F5F5F7` | `#0B0B0D` |

> **Atenção:** hoje `primary` é slate/bege. A mudança para azul altera a percepção de marca em todos os ecrãs. O plano de migração já prevê troca faseada com flag — este documento não a executa.

### 13.2 Tokens de espaço

| Atual | Signature |
|---|---|
| `AppSpacing.xxs` 4 | `s2` 4 |
| `xs` 8 | `s3` 8 |
| `sm` 12 | `s4` 12 |
| `md` 16 | `s5` 16 |
| `lg` 20 | `s6` 20 |
| `xl` 24 | `s7` 24 |
| `xxl` 32 | `s8` 32 |
| `xxxl` 40 | `s9` 40 |
| `huge` 48 | `s10` 48 |

### 13.3 Tokens de raio

| Atual | Signature |
|---|---|
| 8 | `radiusSm` 10 |
| 10 | `radiusSm` 10 |
| 12 | `radiusMd` 14 |
| 16 | `radiusLg` 18 |
| 20 | `radiusXl` 22 |
| 24 | `radius2xl` 28 |

### 13.4 Tipografia

| Papel Material | Token global |
|---|---|
| `displayLarge/Medium/Small` | `display` 28/600 |
| `headlineLarge/Medium/Small` | `headline` 24/600 |
| `titleLarge` | `titleLarge` 20/600 |
| `titleMedium` | `titleMedium` 16/500 |
| `titleSmall` | degrau 14/500 (labelLarge) |
| `bodyLarge` | `bodyLarge` 16/400 |
| `bodyMedium` | `bodyMedium` 14/400 |
| `bodySmall` | `bodySmall` 12/400 |
| `labelLarge` | `labelLarge` 14/500 |
| `labelMedium` | `labelMedium` 12/500 |
| `labelSmall` | `labelSmall` 11/500 (só não essencial) |

---

## 14. Critérios de qualidade visual

### 14.1 Por ecrã (gate antes de aprovar)
- [ ] Existe **uma** ação primária visível e ela é a mais provável no contexto.
- [ ] Máximo **1** cartão-herói; o resto é hierarquia secundária.
- [ ] Azul aparece em ≤8% da superfície; semântica em ≤2%.
- [ ] Todos os valores monetários são tabulares e alinhados.
- [ ] Contraste AA em texto normal; AAA em texto principal quando possível.
- [ ] Estados loading/erro/vazio/sucesso desenhados — nenhum “branco” sem explicação.
- [ ] Erros junto ao campo, não só em `SnackBar`.
- [ ] Nenhum texto <11 px; nenhum toque <44 px.
- [ ] Tema claro e escuro verificados; 1.6× de texto sem overflow.
- [ ] Foco por teclado visível em todos os controlos.
- [ ] Movimento reduzido respeitado.
- [ ] Nenhuma cor usada apenas para transmitir significado.

### 14.2 Anti-padrões (proibidos)
- Gradientes em botões, cartões ou fundos de página.
- Sombras coloridas.
- Mais de duas famílias tipográficas.
- Ícones outline e preenchidos misturados na mesma barra.
- Texto branco sobre azul `#007AFF` em tamanho pequeno.
- Verde/vermelho como única diferença entre linhas.
- Cartões dentro de cartões com borda.
- Tabelas com scroll horizontal em mobile sem alternativa.
- Diálogo com mais de duas ações.
- Animação decorativa contínua (pulse, shimmer em conteúdo real).

### 14.3 Métricas de aceitação
| Métrica | Alvo |
|---|---|
| Contraste texto normal | ≥4.5:1 |
| Contraste texto grande | ≥3:1 |
| Contraste componentes | ≥3:1 |
| Alvo de toque | ≥48 dp (mín. 44) |
| Escala de texto suportada | 1.0×–1.6× sem overflow |
| Duração de feedback ao toque | ≤100 ms |
| Ações primárias por viewport | 1 |
| Cores semânticas por cartão | ≤1 |

---

## 15. Do / Don’t

| Do | Don’t |
|---|---|
| Usar azul para indicar “podes agir aqui” | Pintar cabeçalhos e cartões de azul |
| Separar secções com espaço e tipografia | Separar com caixas coloridas |
| Mostrar “Pago” com ícone + texto | Mostrar só um ponto verde |
| Elevar o cartão que o utilizador pode tocar | Elevar todos os cartões |
| Números tabulares à direita | Números centrados em colunas |
| 48 dp de toque | 32 dp “porque cabe” |
| Um diálogo para uma decisão | Um diálogo com formulário longo |
| Sheet para tarefa contextual | Sheet para fluxo com 20 campos |
| Movimento 180–240 ms | Transições de 600 ms |
| Validar no blur | Validar tudo no submit |

---

## 16. Aplicação por módulo (hierarquia de cor)

| Módulo | Cor de ação | Semântica dominante | Nota |
|---|---|---|---|
| Dashboard | Azul (período, ver mais) | Alerta (stock/validade) | Semântica só nos alertas |
| Vendas | Azul (nova venda) | Sucesso (concluída) / erro (anulada) | Totais tabulares |
| PDV | Azul (confirmar) | Sucesso no recibo | Sem vermelho durante o carrinho |
| Financeiro | Azul (registar) | Entrada/saída | Duas semânticas apenas no fluxo |
| Crédito | Azul (quitar) | Alerta (vencido) | Nunca verde em dívida pendente |
| Produtos | Azul (adicionar) | Alerta (stock baixo) | Tipo de produto neutro |
| Clientes | Azul (adicionar) | Alerta (fiado) | Avatar neutro |
| Compras | Azul (registar) | Informação | — |
| Produção | Azul (registar) | Alerta (matéria-prima) | — |
| Relatórios | Azul (exportar) | Sucesso/erro nos deltas | Gráficos com azul + neutros |
| Lojas | Azul (adicionar) | Alerta (limites do plano) | — |
| Admin | Azul (aprovar) | Erro (rejeitar) / alerta (pendente) | Densidade maior, mesma paleta |
| Auth | Azul (entrar) | Erro (credenciais) | Sem semântica decorativa |

---

## 17. O que este documento não faz

- Não altera ecrãs, tema, tokens ou widgets existentes.
- Não introduz dependências.
- Não decide a ordem de migração — isso está em `FRONTEND_MIGRATION_PLAN.md`.
- Não substitui a validação com utilizadores reais em contexto de loja (luz, pressa, luvas).

---

*Especificação pronta para implementação futura. Todos os rácios de contraste foram calculados sobre os HEX indicados; nenhum ecrã foi modificado.*
