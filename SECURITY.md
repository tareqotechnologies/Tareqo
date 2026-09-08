# Política de Segurança

O TAREQO leva a segurança a sério: o produto lida com dados financeiros e
pessoais (PII) de pequenos comerciantes.

## Versões suportadas

Apenas a versão **mais recente** (linha `2.1.x`) recebe correções de
segurança. Atualize sempre para o último release — a loja (Google Play /
TestFlight) distribui apenas a versão atual.

| Versão | Suportada          |
| ------ | ------------------ |
| 2.1.x  | :white_check_mark: |
| 2.0.x  | :white_check_mark: (correções críticas apenas) |
| < 2.0  | :x:                |

## Reportar uma vulnerabilidade

**Por favor, NÃO abra uma issue pública** para vulnerabilidades de
segurança (o repositório pode ser público). Em vez disso:

1. Use o **GitHub Security Advisory** privado:
   `https://github.com/<owner>/<repo>/security/advisories/new`
   (preencha a descrição sem expor detalhes exploráveis publicamente);
2. Ou envie um e-mail para o mantenedor do projeto (ver perfil no GitHub)
   com o assunto `[SECURITY]`.

### O que incluir no reporte

- Tipo de vulnerabilidade (ex.: injeção SQL, vazamento de dados, XSS);
- Passos para reproduzir (o mínimo possível);
- Impacto estimado (dados afetados, privilégios necessários);
- Versão(ões) afetadas;
- Correção sugerida, se houver.

### Expectativas

- Confirmação de recebimento em até **48 horas úteis**;
- Atualização de progresso a cada ~5 dias úteis;
- Divulgação coordenada: publicamos o detalhe somente após o release da
  correção (salvo risco ativo de exploração, que pode antecipar a
  divulgação pública).

## Áreas sensíveis (contexto para pesquisadores)

- Autenticação/autorização e RLS no Supabase (`supabase/schema.sql` —
  políticas, `SECURITY DEFINER`, guardas `is_super_admin`,
  `is_manager_of_store`, `is_store_employee_active`);
- Armazenamento de sessão/tokens (Keychain/Keystore), MFA/TOTP e biometria;
- Fila offline (outbox) com payloads cifrados e RPCs atômicas do caminho
  de dinheiro (venda, compra, fiado, quitação, anulação);
- Certificado TLS pinning (intermediário WE1 — `cert_pinning_io.dart`);
- Deep links de autenticação (`tareqo://callback` — PKCE).

A anon key do Supabase em `env/dev.env`/`SupabaseConfig` é **pública por
design** (a segurança real vem do RLS) — não é considerada vulnerabilidade.
A **service role key** e o `key.properties` do keystore **nunca** devem
estar no repositório.

## Práticas do projeto

- Secrets de produção apenas nos GitHub Secrets / Keychain do CI
  (`env/prod.env` é gitignored);
- Release automatizado com guardas de flavor/assinatura (fail-fast);
- Varredura de vulnerabilidades de dependências via OSV-Scanner
  (`.github/workflows/security_scan.yml`) e Dependabot.