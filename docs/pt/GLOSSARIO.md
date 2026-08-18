# Glossário pt/en/fr — termos técnicos do Dumbhanengue ERP

> Glossário dos termos técnicos usados na documentação, com o equivalente nas três línguas: **português** (variante usada nos docs — pt-BR), **inglês** e **francês**. As entradas seguem o uso real dos capítulos (`docs/pt/`, `docs/en/`, `docs/fr/`).
>
> [Glossary in English →](../en/GLOSSARY.md) · [Glossaire en français →](../fr/GLOSSAIRE.md) · Versão em português (esta página).

## 1. Negócio (domínio)

| Português | English | Français |
| --------- | ------- | -------- |
| loja | store | magasin |
| venda | sale | vente |
| compra | purchase | achat |
| produto | product | produit |
| cliente | customer | client |
| fornecedor | supplier | fournisseur |
| fiado (crédito) | credit (« fiado ») | crédit (« fiado ») |
| dívida | debt | dette |
| quitar fiado | settle a debt | solder une dette |
| estoque | stock / inventory | stock |
| lote | lot (batch) | lot |
| validade | expiry date | date de péremption |
| venda por peso | scale/weight sale | vente au poids |
| fração (de unidade) | fraction | fraction |
| mili-unidades (milésimos) | milli-units | milli-unités |
| código de barras | barcode | code-barres |
| código de balança (PLU) | scale barcode (PLU) | code d'étiquette de balance (PLU) |
| PDV (ponto de venda) | POS (point of sale) | PDV (point de vente) |
| caixa | cash register | caisse |
| gaveta da caixa | cash drawer | tiroir-caisse |
| fecho de caixa | cash closing | clôture de caisse |
| recibo | receipt | reçu |
| relatório Z | Z report | rapport Z |
| relatório de vendas | sales report | rapport de ventes |
| fluxo de caixa | cash flow | flux de trésorerie |
| lucro bruto | gross profit | bénéfice brut |
| margem | margin | marge |
| ticket médio | average ticket | ticket moyen |
| painel (dashboard) | dashboard | tableau de bord |
| estoque baixo | low stock | stock faible |

## 2. Pagamentos

| Português | English | Français |
| --------- | ------- | -------- |
| forma de pagamento | payment method | moyen de paiement |
| dinheiro | cash | espèces |
| cartão de débito | debit card | carte de débit |
| cartão de crédito | credit card | carte de crédit |
| transferência bancária | bank transfer | virement |
| M-Pesa | M-Pesa | M-Pesa |
| E-Mola | E-Mola | E-Mola |
| metical (MZN) | metical (MZN) | metical (MZN) |
| centavos | cents | centimes |

## 3. Acessos e papéis

| Português | English | Français |
| --------- | ------- | -------- |
| proprietário | owner | propriétaire |
| gerente | manager | gérant |
| funcionário | employee | employé |
| super admin | super admin | super admin |
| nível de acesso | access level | niveau d'accès |
| papel (função) | role | rôle |
| loja ativa | active store | magasin actif |
| gestão de lojas/funcionários | store/employee management | gestion des magasins/employés |

## 4. Autenticação e conta

| Português | English | Français |
| --------- | ------- | -------- |
| entrar (login) | sign in / log in | se connecter |
| criar conta (cadastro) | sign up | s'inscrire |
| senha | password | mot de passe |
| sessão | session | session |
| sair (terminar sessão) | sign out | se déconnecter |
| confirmação de e-mail | email confirmation | confirmation d'e-mail |
| verificação em duas etapas (2FA) | two-factor authentication (2FA) | authentification à deux facteurs (2FA) |
| reautenticação | reauthentication | réauthentification |
| esqueci a senha | forgot password | mot de passe oublié |
| acesso suspenso | access suspended | accès suspendu |

## 5. Multi-tenancy e planos

| Português | English | Français |
| --------- | ------- | -------- |
| locatário (tenant) | tenant | locataire (tenant) |
| plano | plan | plan (forfait) |
| catálogo de planos | plan catalog | catalogue de plans |
| limite do plano | plan limit | limite du plan |
| aprovação do tenant | tenant approval | approbation du tenant |
| onboarding (inscrição) | onboarding | onboarding (inscription) |
| upgrade de plano | plan upgrade | upgrade de plan |
| downgrade de plano | plan downgrade | downgrade de plan |
| faturamento | billing | facturation |

## 6. Banco de dados / Supabase

| Português | English | Français |
| --------- | ------- | -------- |
| esquema | schema | schéma |
| migração | migration | migration |
| idempotente | idempotent | idempotent |
| restrição (constraint) | constraint | contrainte |
| gatilho (trigger) | trigger | déclencheur (trigger) |
| chave primária | primary key | clé primaire |
| chave estrangeira | foreign key | clé étrangère |
| índice | index | index |
| transação | transaction | transaction |
| bloqueio de linha | row lock | verrou de ligne |
| RLS (segurança em nível de linha) | RLS (row level security) | RLS (sécurité au niveau des lignes) |
| RPC | RPC | RPC |
| SECURITY DEFINER | SECURITY DEFINER | SECURITY DEFINER |
| PostgREST | PostgREST | PostgREST |
| política (RLS) | policy | politique |
| função (SQL) | function | fonction |
| paginação keyset | keyset pagination | pagination keyset |
| backup | backup | sauvegarde |
| rollback | rollback | rollback (retour en arrière) |
| SQLite | SQLite | SQLite |
| BIGINT | BIGINT | BIGINT |

## 7. Arquitetura e app (Flutter)

| Português | English | Français |
| --------- | ------- | -------- |
| Clean Architecture | Clean Architecture | Clean Architecture |
| caso de uso | use case | cas d'usage |
| repositório | repository | repository (dépôt) |
| fonte de dados | datasource | source de données |
| provider (Riverpod) | provider (Riverpod) | provider (Riverpod) |
| widget | widget | widget |
| tela | screen | écran |
| bottom sheet | bottom sheet | bottom sheet (feuille modale) |
| tema | theme | thème |
| injeção de dependência | dependency injection | injection de dépendances |
| Unit of Work | Unit of Work | Unit of Work |
| modo offline | offline mode | mode hors-ligne |
| cache offline | offline cache | cache hors-ligne |
| fila de sincronização | sync queue | file de synchronisation |
| local-first | local-first | local-first (local d'abord) |
| venda atômica | atomic sale | vente atomique |

## 8. Testes e CI

| Português | English | Français |
| --------- | ------- | -------- |
| teste unitário | unit test | test unitaire |
| teste de widget | widget test | test de widget |
| teste de integração | integration test | test d'intégration |
| teste ponta a ponta (E2E) | end-to-end test (E2E) | test de bout en bout (E2E) |
| cobertura de testes | test coverage | couverture de tests |
| CI/CD | CI/CD | CI/CD |
| linter (lint) | linter (lint) | linter (lint) |
| analisador estático | static analyzer | analyseur statique |

## 9. Documentação e release

| Português | English | Français |
| --------- | ------- | -------- |
| guia do usuário | user guide | guide de l'utilisateur |
| solução de problemas | troubleshooting | dépannage |
| runbook | runbook | runbook |
| checklist de produção | production checklist | checklist de production |
| release (lançamento) | release | release (version) |
| flavor | flavor | flavor (variante) |
| assinatura (de build) | signing | signature |
| build | build | build |
| notas de versão | release notes | notes de version |

---

## Notas de convenção

- **« Fiado » permanece sem tradução** em inglês e francês: é o termo regional (crédito de balcão) usado no app e na documentação — sempre acompanhado da tradução (« credit » / « crédit ») na primeira ocorrência.
- **Identificadores de código nunca são traduzidos**: nomes de colunas (`venda_por_fracao`), valores de enums (`PaymentMethod.cash('Dinheiro')`), papéis (`'manager'`), funções RPC (`process_sale`), etc. — mesma regra dos capítulos traduzidos.
- **O português dos docs é a variante brasileira** (senha, tela, usuário), com raras formas europeias (utilizador, ecrã) em cabeçalhos.
- **M-Pesa e E-Mola** são marcas — nunca traduzidas, em nenhuma língua.
- **Siglas:** PT e FR usam **PDV**; EN usa **POS**. **RLS**, **RPC**, **KPI**, **E2E**, **CI/CD**, **2FA** e **SQL** são invariáveis nas três línguas.
