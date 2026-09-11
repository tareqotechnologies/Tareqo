# Relatório — Telas Admin/Addon Prioritárias

## 1. Resumo da cobertura

| Métrica | Antes | Depois | Δ |
|---|---:|---:|---|
| **Cobertura total** | 60,16% | **63,20% (16.582/26.237)** | **+3,04 p.p.** |
| `advanced_reports_screen.dart` | 0,3% | **87,9% (343/390)** | +87,6 p.p. |
| `employee_management_screen.dart` | ~2% | **70,1% (365/521)** | +68 p.p. |
| Testes | 1.180 | **1.194 (+14)** | todos passando |

Instrumented lines idênticas (26.237) — **zero código de produção alterado** nesta rodada.

## 2. Testes criados (2 arquivos, 14 testes)

| Arquivo | Cobre | Cenários-chave |
|---|---|---|
| `test/presentation/screens/employee_management_screen_test.dart` (7) | Gestão de funcionários | lista com papel/loja, **clock-in → badge "Dentro" → clock-out** (workflow de ponto completo), erro de clock-in exibido com retry, **resumo de comissões ordenado** (maior primeiro, zeros omitidos), estado vazio, faltas no resumo |
| `test/presentation/screens/advanced_reports_screen_test.dart` (7) | Relatórios avançados | aba Vendas vazia, **KPIs financeiros do fluxo de caixa** (entradas 1.500 / saídas 450 / líquido 1.050) com janela de início do mês validada, **erro silencioso proibido** (mensagem + retry), aba Estoque: produtos baixos listados (Açúcar/Sal), **saudáveis excluídos**, KPI de valor **R$ 750,00** (centavos exatos — regressão do truncamento documentado no código), todos saudáveis → mensagem de estoque adequado, **troca de período refaz a consulta** com nova janela (Hoje vs Este Mês) |

## 3. Correções durante a rodada (todas em testes)

| Falha | Causa | Correção |
|---|---|---|
| "estoque adequado" não encontrado | Asserção invertida: a mensagem só renderiza quando `lowStock == 0` | Corrigida a expectativa + teste complementar do ramo vazio |
| `R$ 75,00` não encontrado | Erro de aritmética do fixture (75000 centavos = R$ 750,00) | Valor corrigido para R$ 750,00 |
| `unused_import` (material) no teste de funcionários | Import desnecessário | Removido |

## 4. Comandos executados (reais)

| Comando | Resultado |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test --coverage` | **+1194: All tests passed!** |
| Cobertura (lcov) | **63,20%** (16.582/26.237) |

## 5. Estado consolidado da sessão

| Métrica | Início | Agora |
|---|---:|---:|
| Cobertura total | 52,63% | **63,20% (+10,57 p.p.)** |
| Testes | 876 | **1.194 (+318)** |
| Camada remote+auth | 9,3% | 84,4% |
| `flutter analyze` | limpo | **limpo** |

## 6. Próximos alvos naturais

- `admin_tenants_widgets` (456 linhas), `admin_addons_screen`, `admin_audit_log_screen` — o padrão de fakes admin já está estabelecido
- Fluxos de formulário das telas restantes (product_form_sheets, quotation_screen)
- `l10n/generated` e RPCs server-side permanecem fora do escopo (código gerado / contrato do Postgres coberto pelo `sql_check.sh` no CI)

---

Dois arquivos novos não-committed: `test/presentation/screens/advanced_reports_screen_test.dart` e `test/presentation/screens/employee_management_screen_test.dart`.

---

# Rodada 2 — Painel Admin (tenants/add-ons/audit log)

## 7. Resumo da rodada

| Métrica | Antes | Depois | Δ |
|---|---:|---:|---|
| **Cobertura total** | 63,20% (16.582/26.237) | **68,14% (17.879/26.237)** | **+4,94 p.p.** |
| `admin_addons_screen.dart` | 0% | **94,8% (435/459)** | +94,8 |
| `admin_audit_log_screen.dart` | 0% | **99,7% (343/344)** | +99,7 |
| `admin_tenants_widgets.dart` | 0% | **95,7% (510/533)** | +95,7 |
| `admin_tenants_screen.dart` | ~40% | **77,1% (209/271)** | +37 (est.) |
| Testes | 1.194 | **1.214 (+20)** | todos passando |

Instrumented lines idênticas (26.237) — **zero código de produção alterado**.

## 8. Testes criados (3 arquivos, 20 testes)

| Arquivo | Cobre | Cenários-chave |
|---|---|---|
| `admin_tenants_screen_test.dart` (11) | Tela + `admin_tenants_widgets` | 5 testes pré-existentes mantidos; novos: **busca com badge de contagem + botão de limpar**, **seleção múltipla via long press → 2/2 → aprovação em lote** (`ApproveTenantUseCase` chamado 2×, snackbar "2 tenants aprovados"), **card aprovado com plano/data/badge de add-ons** (2 activos via datasource falso), **copiar owner ID → snackbar**, **detalhe pendente**: chips Estado/Pendente/Comercial, `substring(0,8)` do owner ("owner123"), MZN/PT, copiar pela info row, 3 seções vazias, fechar pela barreira; **detalhe rejeitado**: motivo da rejeição exibido; **detalhe aprovado**: **FACTURAÇÃO "Activo: 20 dias restantes"** (janela com +2h de folga contra truncamento de `inDays`), valor mensal R$ 99,00, próxima factura, **USO vs LIMITES 1/2 e 1/5**, loja com cidade, funcionário "Gestor", **atividade filtrada por `entityId`** (plan_change de outro tenant excluído) |
| `admin_audit_log_screen_test.dart` (6) | Audit log | **agrupamento por data** (HOJE/ONTEM/ESTA SEMANA/MAIS ANTIGO) com stats 4/1/1 e taxa 25%, tempo relativo "2m"; **filtros por categoria** (Tenants/Upgrades/Todos) sem alterar stats globais; **busca por entityId** + estado vazio de filtro + limpar; **sheet de detalhes** completo (#7, Data, Responsável, Entidade, Ação, payload `Detail` JSON, dot APPROVED duplo); entrada **sem status** → nenhum dot; **erro + retry** (nunca silencioso) |
| `admin_addons_screen_test.dart` (8) | Add-ons admin | **só tenants aprovados** listados (pendente/rejeitado excluídos) com "Plano: Essencial"; busca + estado vazio de busca; estado vazio sem tenants; **erro de carga exibido**; **gestão individual**: stats 5/1/4, preço "R$ 300,00/mês", switch desligado → `deactivate` persistido (stats 5/0/5), último switch ligado → `activate` `ao_multi_store` (stats 5/1/4), voltar à lista; **erro no toggle → snackbar**; **modo lote via long press**: 1/2 → checkbox 2/2 → sheet "2 tenants selecionados" com **5 add-ons disponíveis (M-Pesa/E-Mola BLOCKED excluído)** → Activar em massa → `activate('tn1'...)` + `activate('tn2'...)` + snackbar "activado em 2 tenants" + modo encerrado |

## 9. Correções durante a rodada (todas em testes)

| Falha | Causa | Correção |
|---|---|---|
| `RangeError (end): Not in inclusive range 0..1: 8` | Fixture com `ownerUserId: '1'` — o sheet faz `substring(0, 8)` | Fixtures com IDs ≥8 caracteres |
| Tiles de auditoria não encontrados | Texto renderizado em `Text.rich` (spans concatenados) — `find.text` não casa | `find.textContaining(..., findRichText: true)` |
| Overflow ~87px no sheet de activação em lote | Sheet limitado a ~560px pelo framework × fonte de teste Ahem (mais larga que a Inter) | `MediaQuery.withClampedTextScaling(maxScaleFactor: 0.75)` via `builder` do `testApp` |
| `tap()` ambíguo em `Icons.close` | Botão "Rejeitar" dos cards usa o mesmo ícone | Predicado por `size == 16` (só o ✕ do campo de busca) |
| Sheet de detalhes sumia ao fechar | Drag até o topo dispara o pull-to-dismiss do `DraggableScrollableSheet` | Fechar tocando na barreira (`tapAt`) |
| Stats do manager de add-ons | Aritmética do teste: após desligar o único activo há 5 inactivos + total 5 (dois "5") | Expectativas corrigidas (5/0/5 e 5/1/4) |
| Sheet de lote enviava `''` a `activate` | Entrar no modo bulk pelo ícone pré-seleciona o vazio | Long press no card (seleção real de tenant) |

## 10. Comandos executados (reais)

| Comando | Resultado |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test --coverage` | **+1214: All tests passed!** |
| Cobertura (lcov) | **68,14%** (17.879/26.237) |

## 11. Estado consolidado da sessão

| Métrica | Início | Agora |
|---|---:|---:|
| Cobertura total | 52,63% | **68,14% (+15,51 p.p.)** |
| Testes | 876 | **1.214 (+338)** |
| Camada remote+auth | 9,3% | 84,4% |
| `flutter analyze` | limpo | **limpo** |

## 12. Próximos alvos naturais

- `admin_invoices_screen` (20,1%) e `admin_messages_screen` (45,2%) — padrão de fakes já replicável
- Fluxos de formulário das telas restantes (product_form_sheets, quotation_screen)
- `l10n/generated` e RPCs server-side permanecem fora do escopo (código gerado / contrato do Postgres coberto pelo `sql_check.sh` no CI)

---

Três arquivos alterados/criados não-committed nesta rodada: `test/presentation/screens/admin/admin_tenants_screen_test.dart` (estendido), `test/presentation/screens/admin/admin_addons_screen_test.dart` e `test/presentation/screens/admin/admin_audit_log_screen_test.dart` (novos).

---

# Rodada 3 — Fechamento das branches de tenants + descoberta do retry do Riverpod 3

## 13. Resumo da rodada

| Métrica | Antes | Depois | Δ |
|---|---:|---:|---|
| **Cobertura total** | 68,14% (17.879/26.237) | **68,30% (17.921/26.237)** | **+0,16 p.p.** |
| `admin_tenants_screen.dart` | 77,1% (209/271) | **88,9% (241/271)** | **+11,8 p.p.** |
| `admin_addon_revenue_screen.dart` | 0% | **97,5% (158/162)** | +97,5 |
| `admin_audit_log_screen.dart` | 99,7% (343/344) | 99,7% (idem) | — |
| Testes | 1.214 | **1.218 (+4)** | todos passando |

Instrumented lines idênticas (26.237) — **zero código de produção alterado**.

> Nota: `admin_addon_revenue_screen` já estava coberto (97,5%) por testes pré-existentes
descobertos durante a análise — não foi preciso teste novo para ele.

## 14. Testes adicionados (+4 em `admin_tenants_screen_test.dart`, 16 no total)

| Cenário | Cobre |
|---|---|
| **Rejeição em lote com motivo** | Long press ×2 → "Rejeitar (2)" → diálogo "Rejeitar 2 tenants" com "Motivo da rejeição" → motivo propagado ao use case 2× (`lastReason` verificado), snackbar "2 tenants rejeitados", modo seleção encerrado |
| **Erro parcial na aprovação em lote** | `throwFor = {'tn2'}` → 2 tentativas, 1 sucesso → snackbar de **erro parcial** ("Alguns podem não ter sido processados") e não o de sucesso; `CrashReporting.capture` seguro em teste (no-op sem DSN) |
| **Erro de carga + retry duplo** | Use case a falhar desde o início → ErrorView "Não foi possível carregar as solicitações."; retry com falha persistente mantém o erro; retry com use case recuperado volta à lista |
| **Pull-to-refresh** | `AlwaysScrollableScrollPhysics` permite overscroll com lista curta → `fling` dispara o `RefreshIndicator` → recarga da lista de pendentes |

## 15. Descoberta: retry automático do Riverpod 3 em testes

O retry de erro mostrou **11 chamadas ao use case** depois de `pumpAndSettle` com o provider
sempre a falhar — é o **[automatic retry](https://riverpod.dev/docs/concepts2/retry) do Riverpod 3.4**
(reexecuta providers a falhar com backoff; `pumpAndSettle` avança os timers). Consequências
para testes:

- **Nunca** fazer `expect(useCase.calls, exactNumber)` em providers AsyncNotifier que falham — usar limites inferiores (`greaterThanOrEqualTo`)
- O contador só é determinístico enquanto o provider tem sucesso (carga inicial única)
- Tornou-se visível apenas agora porque os testes anteriores nunca exercitavam falha persistente de carga

## 16. Comandos executados (reais)

| Comando | Resultado |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test --coverage` | **+1218: All tests passed!** |
| Cobertura (lcov) | **68,30%** (17.921/26.237) |

## 17. Estado consolidado da sessão

| Métrica | Início | Agora |
|---|---:|---:|
| Cobertura total | 52,63% | **68,30% (+15,67 p.p.)** |
| Testes | 876 | **1.218 (+342)** |
| Camada remote+auth | 9,3% | 84,4% |
| `flutter analyze` | limpo | **limpo** |

## 18. Próximos alvos naturais

- `admin_invoices_screen` (20,1%) — maior tela admin ainda descoberta
- `admin_messages_screen` (45,2%)
- Fluxos de formulário das telas restantes (product_form_sheets, quotation_screen)
- `l10n/generated` e RPCs server-side permanecem fora do escopo (código gerado / contrato do Postgres coberto pelo `sql_check.sh` no CI)
