#!/usr/bin/env python
# Smoke test de leitura/escrita contra o projeto DEV via PostgREST+GoTrue
# (o mesmo caminho do app Flutter). Uso:
#   python scripts/smoke_rls_rest.py            # tudo (leitura + escrita de venda)
#   python scripts/smoke_rls_rest.py --read-only
# Credenciais: env/dev.env + env/test_accounts.env (nunca impressas).
import json
import sys
import time
import urllib.request
import urllib.error

READ_ONLY = "--read-only" in sys.argv


def load_env(path):
    out = {}
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            out[k.strip()] = v.strip().strip('"').strip("'")
    return out


DEV = load_env("env/dev.env")
ACC = load_env("env/test_accounts.env")
BASE = DEV["SUPABASE_URL"].rstrip("/")
ANON = DEV["SUPABASE_ANON_KEY"]

results = []


def check(label, ok, extra=""):
    results.append((label, ok))
    print(f"[{'PASS' if ok else 'FAIL'}] {label}" + (f" — {extra}" if extra else ""))


def request(method, url, token, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("apikey", ANON)
    req.add_header("Authorization", f"Bearer {token}")
    if data:
        req.add_header("Content-Type", "application/json")
    req.add_header("Accept", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            raw = r.read()
            return r.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            return e.code, json.loads(raw) if raw else None
        except Exception:
            return e.code, raw.decode(errors="replace")[:300]


def login(email, password):
    st, body = request("POST", f"{BASE}/auth/v1/token?grant_type=password", ANON,
                       {"email": email, "password": password})
    if st != 200:
        return None, None
    return body["access_token"], body["user"]["id"]


def rest_path(token, path):
    return request("GET", f"{BASE}/rest/v1/{path}", token)


def rest_path_enc(token, path_fmt, **params):
    """GET com valores de filtro URL-encodados (datas com '+' quebram sem isso)."""
    from urllib.parse import quote
    for k, v in params.items():
        path_fmt = path_fmt.replace(f"{{{k}}}", quote(str(v), safe=""))
    return rest_path(token, path_fmt)


# ===========================================================================
print("== Stage A: login GoTrue + leituras RLS + KPI RPCs ==")
# ===========================================================================
accounts = {}
for role in ["owner", "manager", "employee"]:
    email = ACC[f"TEST_{role.upper()}_EMAIL"]
    pwd = ACC[f"TEST_{role.upper()}_PASSWORD"]
    token, uid = login(email, pwd)
    check(f"login {role}", token is not None)
    accounts[role] = {"token": token, "uid": uid}

tok_own = accounts["owner"]["token"]
tok_mgr = accounts["manager"]["token"]
tok_emp = accounts["employee"]["token"]

# (A1) dono: lojas e produtos via RLS
st, stores = rest_path(tok_own, "stores?select=id,name&limit=5")
check("dono lê stores (RLS)", st == 200 and isinstance(stores, list), f"n={len(stores) if isinstance(stores, list) else stores}")
if not (st == 200 and isinstance(stores, list) and stores):
    print("\nRESULT: leitura básica falhou — abortando (sem mudanças no banco).")
    sys.exit(1)
store_id = stores[0]["id"]

st, products = rest_path(tok_own, f"products?store_id=eq.{store_id}&select=id,name,stock_quantity,is_active&limit=5")
check("dono lê products (RLS)", st == 200 and isinstance(products, list), f"n={len(products) if isinstance(products, list) else products}")

# (A2) KPIs via RPC (usa is_my_store internamente)
st, kpis = request("POST", f"{BASE}/rest/v1/rpc/get_dashboard_kpis", tok_own,
                   {"p_store_id": store_id, "p_start": "2020-01-01T00:00:00Z", "p_end": "2030-01-01T00:00:00Z"})
check("dono executa get_dashboard_kpis (RPC)", st in (200, 204), "" if st in (200, 204) else str(kpis)[:200])

# (A3) funcionário comum: NÃO acede a relatórios gerenciais (matriz Aug 6)
st, body = rest_path(tok_emp, f"purchases?store_id=eq.{store_id}&select=id&limit=1")
check("funcionário NÃO lê purchases (RLS gerencial)", st == 200 and body == [], str(body)[:120] if st == 200 else f"http {st}")

# (A4) is_super_admin RPC (boot do painel admin)
st, body = request("POST", f"{BASE}/rest/v1/rpc/is_super_admin", tok_own, {})
check("dono executa is_super_admin (RPC)", st == 200 and body is False, f"retorno={body}")

# ===========================================================================
if READ_ONLY:
    print("\n== Modo --read-only: pulando Stage B (escrita). ==")
    ok = all(r for _, r in results)
    print(f"\nRESULT: {'SMOKE PASS' if ok else 'SMOKE FAIL'} ({sum(r for _, r in results)}/{len(results)} checks)")
    sys.exit(0 if ok else 1)

# ===========================================================================
print("\n== Stage B: escrita E2E (venda real via process_sale) ==")
# ===========================================================================
# Limpeza: anula vendas de smoke/probe anteriores que ficaram ativas
# (execuções interrompidas) para não poluir o caixa do dev.
st, leftovers = rest_path(tok_mgr,
    "sales?or=(id.like.smoke_*,id.like.probe_*)&status=eq.active&select=id,store_id")
for lv in (leftovers or []):
    st2, _ = request("POST", f"{BASE}/rest/v1/rpc/cancel_sale", tok_mgr,
                     {"p_sale_id": lv["id"], "p_store_id": lv["store_id"]})
    print(f"       (limpeza: venda {lv['id']} anterior -> cancelled, http {st2})")

# Precisa de um produto com estoque (a RPC dá baixa FIFO por lotes).
st, products = rest_path(tok_own, f"products?store_id=eq.{store_id}&select=id,name,stock_quantity&stock_quantity=gt.0&is_active=eq.true&limit=1")
if not (st == 200 and isinstance(products, list) and products):
    print("FAIL: nenhum produto com estoque para testar a venda — rode o smoke completo após cadastrar um produto.")
    sys.exit(1)
prod = products[0]

st, prev = rest_path_enc(tok_own,
    "products?id=eq.{pid}&store_id=eq.{sid}&select=stock_quantity", pid=prod["id"], sid=store_id)
stock_before = prev[0]["stock_quantity"] if st == 200 and prev else None
check("estoque antes da venda obtido", stock_before is not None, f"produto={prod['name']} stock={stock_before} (milésimos)")

# Contrato process_sale: quantity em MILÉSIMOS, total = Σ qty×preço/1000.
QTY_MILLESIMAL = 1000  # 1 unidade
UNIT_PRICE = 100  # 0,10 em centavos
TOTAL = QTY_MILLESIMAL * UNIT_PRICE // 1000

sale_id = f"smoke_{int(time.time() * 1000)}"
tx_id = "t" + sale_id
sale = {
    "id": sale_id,
    "store_id": store_id,
    "total_amount": TOTAL,
    "payment_method": "cash",
    "date_time": time.strftime("%Y-%m-%dT%H:%M:%S+00:00", time.gmtime()),
}
items = [{
    "product_id": prod["id"],
    "product_name": prod["name"],
    "quantity": QTY_MILLESIMAL,
    "unit_price": UNIT_PRICE,
}]

# (B1) vendedor comum registra a venda via RPC (o fluxo do PDV).
# PostgREST devolve 204 No Content em RPC void bem-sucedida.
st, body = request("POST", f"{BASE}/rest/v1/rpc/process_sale", tok_emp, {"p_sale": sale, "p_items": items})
check("funcionário registra venda via process_sale", st in (200, 204), "" if st in (200, 204) else str(body)[:250])
if st not in (200, 204):
    print("\nRESULT: SMOKE FAIL (venda não registrada — nada foi alterado)")
    sys.exit(1)

# (B2) estoque caiu exatamente 1 unidade (stock em MILÉSIMOS: 1 un = 1000).
st, now = rest_path_enc(tok_own,
    "products?id=eq.{pid}&store_id=eq.{sid}&select=stock_quantity", pid=prod["id"], sid=store_id)
stock_after = now[0]["stock_quantity"] if st == 200 and now else None
check("estoque caiu 1 unidade (FIFO)", st == 200 and stock_after == stock_before - QTY_MILLESIMAL,
      f"antes={stock_before} depois={stock_after} (Δ={stock_before - stock_after if stock_after is not None else '?'})")

# (B3) itens da venda visíveis via RLS.
st, si = rest_path(tok_own, f"sale_items?sale_id=eq.{sale_id}&select=id,quantity,unit_price")
check("sale_items da venda visíveis (RLS)", st == 200 and isinstance(si, list) and len(si) == 1,
      f"n={len(si) if isinstance(si, list) else si}")

# (B4) entrada no caixa gravada ('t'+id, income, paid).
st, ft = rest_path(tok_own, f"financial_transactions?id=eq.{tx_id}&select=id,amount,type,status")
check("entrada no caixa gravada", st == 200 and isinstance(ft, list) and len(ft) == 1
      and ft[0]["type"] == "income" and ft[0]["status"] == "paid",
      f"{ft if isinstance(ft, list) else st}")

# (B5) idempotência: reenvio do MESMO id não duplica (retorno 204 + 1 venda).
st2, _ = request("POST", f"{BASE}/rest/v1/rpc/process_sale", tok_emp, {"p_sale": sale, "p_items": items})
st3, dup = rest_path(tok_own, f"sales?id=eq.{sale_id}&select=id")
check("idempotência: retry não duplica venda", st2 in (200, 204) and isinstance(dup, list) and len(dup) == 1,
      f"retry={st2} vendas={len(dup) if isinstance(dup, list) else dup}")

# (B6) cancel_sale (gerencial) anula: status cancelled + estorno no caixa.
st, body = request("POST", f"{BASE}/rest/v1/rpc/cancel_sale", tok_mgr, {"p_sale_id": sale_id, "p_store_id": store_id})
check("gerente anula via cancel_sale", st in (200, 204), "" if st in (200, 204) else str(body)[:250])
st, cs = rest_path(tok_own, f"sales?id=eq.{sale_id}&select=status,cancelled_at")
check("venda marcada cancelled", st == 200 and cs and cs[0]["status"] == "cancelled",
      f"{cs if isinstance(cs, list) else st}")
# O estorno cria uma SAÍDA nova de mesmo valor (par entrada+estorno fecha zero).
st, ft_all = rest_path_enc(tok_own,
    "financial_transactions?store_id=eq.{sid}&select=id,type,amount", sid=store_id)
if st != 200 or not isinstance(ft_all, list):
    check("estorno no caixa (saída do mesmo valor)", False, f"http {st}: {str(ft_all)[:150]}")
else:
    reversal = [f for f in ft_all if f["type"] == "expense" and f["amount"] == TOTAL]
    check("estorno no caixa (saída do mesmo valor)", len(reversal) >= 1, f"estornos={len(reversal)}")

# (B7) estoque devolvido ao valor original pela anulação.
st, now2 = rest_path_enc(tok_own,
    "products?id=eq.{pid}&store_id=eq.{sid}&select=stock_quantity", pid=prod["id"], sid=store_id)
stock_final = now2[0]["stock_quantity"] if st == 200 and now2 else None
check("estoque devolvido pela anulação", st == 200 and stock_final == stock_before,
      f"antes={stock_before} final={stock_final}")

ok = all(r for _, r in results)
print(f"\nRESULT: {'SMOKE PASS' if ok else 'SMOKE FAIL'} ({sum(r for _, r in results)}/{len(results)} checks)")
sys.exit(0 if ok else 1)
