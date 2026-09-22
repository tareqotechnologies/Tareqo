#!/usr/bin/env python3
"""Parte 24 do upgrade.sql — normalização pt-MZ das mensagens de erro das
RPCs do servidor (auditoria tipográfica P0-3 — coerência de microcopy).

Extração MECÂNICA: cada par (antes → depois) abaixo deve existir
VERBATIM em supabase/schema.sql. Se o repo mudou e a mensagem sumiu, o
script falha em vez de adivinhar.

Aplicação:
  * repo: substitui os pares em schema.sql + upgrade.sql;
  * live: anexa a "Parte 24" ao upgrade.sql e escreve
    scripts/ptmz_rpc_delta_live.sql (DO block que LÊ cada função do
    próprio banco via pg_get_functiondef(), troca só as mensagens e
    recria com CREATE OR REPLACE — preserva drift repo/live; idempotente).

Uso:  python tool/gen_ptmz_rpc_delta.py          # gera tudo
      psql "$SUPABASE_DB_URL" -f scripts/ptmz_rpc_delta_live.sql
      (ou cole o ficheiro no SQL Editor do Supabase)
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# (mensagem atual — verbatim do schema.sql —, mensagem pt-MZ)
PAIRS = [
    ("Estoque insuficiente para o produto % (loja %).",
     "Stock insuficiente para o produto % (loja %)."),
    ("Sessão necessária para ajustar o estoque.",
     "Sessão necessária para ajustar o stock."),
    ("MFA exigido: conclua a verificação em dois fatores para ajustar o estoque.",
     "MFA exigido: conclua a verificação em dois fatores para ajustar o stock."),
    ("Apenas o dono ou um gerente podem ajustar o estoque na loja %.",
     "Apenas o dono ou um gerente podem ajustar o stock na loja %."),
    ("O estoque não pode ficar negativo.",
     "O stock não pode ficar negativo."),
    ("Estoque insuficiente para ajustar o produto % (loja %).",
     "Stock insuficiente para ajustar o produto % (loja %)."),
    ("Sessão necessária para registrar a venda.",
     "Sessão necessária para registar a venda."),
    ("A loja % não pertence ao usuário logado.",
     "A loja % não pertence ao utilizador autenticado."),
    ("Sessão necessária para registrar o fiado.",
     "Sessão necessária para registar o fiado."),
    ("MFA exigido: conclua a verificação em dois fatores para registrar fiado.",
     "MFA exigido: conclua a verificação em dois fatores para registar fiado."),
    ("Sessão necessária para registrar a compra.",
     "Sessão necessária para registar a compra."),
    ("MFA exigido: conclua a verificação em dois fatores para registrar compras.",
     "MFA exigido: conclua a verificação em dois fatores para registar compras."),
    ("Apenas o dono ou um gerente podem registrar compras na loja %.",
     "Apenas o dono ou um gerente podem registar compras na loja %."),
    # enforce_store_limit (trigger do limite do plano — user-facing)
    ("Tenant do usuário não encontrado.",
     "Tenant do utilizador não encontrado."),
]

# Funções com mensagens user-facing (cancel_sale não tem nenhuma — verificado).
FUNCS = ["process_sale", "register_debt", "settle_debt",
         "process_purchase", "adjust_product_stock",
         "lock_products_or_raise", "enforce_store_limit"]


def sql_literal(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def do_block() -> str:
    lines = [
        "    v_def := replace(v_def, %s, %s);" % (sql_literal(b), sql_literal(a))
        for b, a in PAIRS
    ]
    replaces = "\n".join(lines)
    func_list = ", ".join(sql_literal(f) for f in FUNCS)
    before_like = "\n        OR ".join(
            "pg_get_functiondef(p.oid) LIKE %s" % sql_literal("%" + b + "%")
            for b, _ in PAIRS
        )
    return f"""BEGIN;

-- Sem LOCK TABLE: a troca é só de TEXTO das mensagens — CREATE OR REPLACE
-- FUNCTION é atômico e chamadas em voo terminam com a definição antiga.
-- Vendas/compras/fiado seguem fluindo durante o patch.
DO $do$
DECLARE
  r     record;
  v_def text;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure::text AS sig,
           pg_get_functiondef(p.oid)  AS def
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.proname IN ({func_list})
  LOOP
    v_def := r.def;
{replaces}
    IF v_def IS DISTINCT FROM r.def THEN
      EXECUTE v_def;  -- def começa com CREATE OR REPLACE FUNCTION ...
      RAISE NOTICE 'Parte 24: % atualizada', r.sig;
    ELSE
      RAISE NOTICE 'Parte 24: % sem mensagens-alvo (no-op)', r.sig;
    END IF;
  END LOOP;
END
$do$;

-- Verificação (gate): nenhuma mensagem pt-BR pode sobrar nas funções tocadas.
DO $do$
DECLARE
  v_left int;
BEGIN
  SELECT count(*) INTO v_left
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public'
     AND p.proname IN ({func_list})
     AND ({before_like});
  IF v_left > 0 THEN
    RAISE EXCEPTION 'FAIL Parte 24: % mensagens pt-BR restantes', v_left;
  END IF;
  RAISE NOTICE 'PASS Parte 24: mensagens pt-MZ aplicadas';
END
$do$;

COMMIT;
"""


def main() -> None:
    schema = (ROOT / "supabase" / "schema.sql").read_text(encoding="utf-8")
    missing = [b for b, a in PAIRS
               if b not in schema and a not in schema]
    if missing:
        raise SystemExit("ERRO: ausentes no schema.sql: " + repr(missing))

    # 1) Repo — schema.sql + upgrade.sql recebem as mesmas substituições
    #    (pares já aplicados em execução anterior são pulados).
    for name in ("schema.sql", "upgrade.sql"):
        p = ROOT / "supabase" / name
        t = p.read_text(encoding="utf-8")
        for b, a in PAIRS:
            t = t.replace(b, a)
        p.write_text(t, encoding="utf-8")

    # 2) upgrade.sql — anexa/regenera a Parte 24 (idempotente).
    up = ROOT / "supabase" / "upgrade.sql"
    t = up.read_text(encoding="utf-8")
    marker = "\n-- =============================================================\n-- Parte 24"
    if marker in t:
        start = t.index(marker)
        last_commit = t.rfind("COMMIT;")
        if last_commit < start:
            raise SystemExit("ERRO: COMMIT final ausente após a Parte 24 antiga.")
        t = t[:start] + t[last_commit:]
    pairs_doc = "\n".join(f"--   {b}  →  {a}" for b, a in PAIRS)
    part24 = (
        "\n-- =============================================================\n"
        "-- Parte 24 — Normalização pt-MZ das mensagens de erro das RPCs\n"
        "-- (auditoria tipográfica P0-3 — coerência de microcopy)\n"
        "-- -------------------------------------------------------------\n"
        "-- O app foi normalizado para pt-MZ (Factura/Registar/stock);\n"
        "-- as RPCs ainda devolviam erros pt-BR. O cliente NÃO classifica\n"
        "-- erros pela mensagem (domain_error_l10n usa tipo/code) — a troca\n"
        "-- é segura. Mensagens:\n"
        f"{pairs_doc}\n"
        "-- Idempotente: lê cada função do próprio banco\n"
        "-- (pg_get_functiondef) e recria apenas se algo mudou — preserva\n"
        "-- drift repo/live. Sem LOCK TABLE: troca só de texto, CREATE OR\n"
        "-- REPLACE é atômico e chamadas em voo terminam na definição antiga.\n"
        "-- =============================================================\n"
    )
    idx = t.rstrip().rfind("COMMIT;")
    if idx == -1:
        raise SystemExit("ERRO: COMMIT final não encontrado no upgrade.sql.")
    t = t[: idx] + part24 + "\n" + t[idx:]
    up.write_text(t, encoding="utf-8")

    # 3) Patch standalone para o live.
    live = ROOT / "scripts" / "ptmz_rpc_delta_live.sql"
    live.write_text(do_block(), encoding="utf-8")
    print(f"OK: Parte 24 anexada ao upgrade.sql; patch live em {live.name}")


if __name__ == "__main__":
    main()
