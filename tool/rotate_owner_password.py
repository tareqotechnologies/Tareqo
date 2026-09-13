"""Rotaciona a senha da conta OWNER de DEV ou PROD via GoTrue.

Uso:
    python tool/rotate_dev_owner_password.py                # dev (padrão)
    python tool/rotate_dev_owner_password.py --project prod # produção
    python tool/rotate_dev_owner_password.py --email ... --password ...  # 1a vez

O que faz:
 1. Gera uma senha forte localmente (secrets, 20 chars, 4 classes);
 2. Autentica na GoTrue do projeto alvo com as credenciais ATUAIS
    (lidas de env/test_accounts.env ou --email/--password);
 3. Rotaciona via PUT /auth/v1/user (self-service — mesmo fluxo do app;
    a GoTrue exige current_password);
 4. Confirma: login com a NOVA senha OK e com a ANTIGA REJEITADO;
 5. Grava o novo par APENAS em env/test_accounts.env (gitignored),
    com o prefixo do projeto (TEST_OWNER_ / PROD_OWNER_).

Dev e prod são projetos SEPARADOS (GoTrue/banco independentes): rotacionar
um NÃO cobre o outro — rode para ambos quando uma credencial vazar.
Nunca imprime a senha; nunca grava fora do arquivo gitignored.
"""
from __future__ import annotations

import argparse
import configparser
import secrets
import string
import sys
from pathlib import Path

import requests

# Projetos Supabase (dev e prod são SEPARADOS desde a migração de Set/2026
# — GoTrue/banco independentes: rotacionar um NÃO cobre o outro).
PROJECTS = {
    "dev": ("https://dotklbpqmlnhcdifiukd.supabase.co", "env/dev.env", "TEST_OWNER"),
    "prod": ("https://bcyolmheltzlddfwgqcq.supabase.co", "env/prod.env", "PROD_OWNER"),
}
ENV_FILE = Path("env/test_accounts.env")
# Sem `#`, aspas ou espaços: o parser de --dart-define-from-file (dotenv)
# corta `#` não-aspado como comentário inline — a senha de dev roteada em
# Set/2026 continha `#` e o E2E recebia uma senha TRUNCADA (bug real,
# diagnóstico em test/diag_defines_probe_test.dart, desde removido).
ALPHABETS = (
    string.ascii_lowercase,
    string.ascii_uppercase,
    string.digits,
    "!@%^*()-_=+",
)


def strong_password(length: int = 20) -> str:
    """Senha com ao menos um caractere de cada classe, embaralhada."""
    rng = secrets.SystemRandom()
    chars = [rng.choice(alpha) for alpha in ALPHABETS]
    chars += [rng.choice("".join(ALPHABETS)) for _ in range(length - len(chars))]
    rng.shuffle(chars)
    return "".join(chars)


def load_current(prefix: str) -> tuple[str, str]:
    """Credenciais ATUAIS (pré-rotação) de env/test_accounts.env.

    Valores podem estar entre aspas simples/duplas (convenção do arquivo:
    protege contra o corte de `#` pelo parser de --dart-define-from-file).
    """
    if not ENV_FILE.exists():
        sys.exit(
            f"{ENV_FILE} não existe. Rode uma vez com --email/--password "
            "para inicializá-lo com as credenciais atuais."
        )

    def unquote(value: str) -> str:
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            return value[1:-1]
        return value

    values: dict[str, str] = {}
    for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = unquote(value)
    email = values.get(f"{prefix}_EMAIL", "")
    password = values.get(f"{prefix}_PASSWORD", "")
    if not email or not password:
        sys.exit(
            f"{ENV_FILE} sem {prefix}_EMAIL/{prefix}_PASSWORD. Rode uma vez "
            "com --email/--password para inicializar este projeto."
        )
    return email, password


def save_new_credentials(prefix: str, email: str, password: str) -> None:
    """Grava o novo par PRESERVANDO as demais chaves do arquivo (dev e prod
    vivem no mesmo arquivo gitignored) e SEMPRE entre aspas."""
    lines = (
        ENV_FILE.read_text(encoding="utf-8").splitlines()
        if ENV_FILE.exists()
        else []
    )

    def quoted(value: str) -> str:
        # Sem aspas simples dentro → usa simples; senão duplas.
        if "'" in value and '"' not in value:
            return f'"{value}"'
        return f"'{value}'"

    out: list[str] = []
    seen: set[str] = set()
    email_key, password_key = f"{prefix}_EMAIL", f"{prefix}_PASSWORD"
    for line in lines:
        key = line.split("=", 1)[0].strip() if "=" in line else ""
        if key == email_key:
            out.append(f"{email_key}={quoted(email)}")
            seen.add("email")
        elif key == password_key:
            out.append(f"{password_key}={quoted(password)}")
            seen.add("password")
        else:
            out.append(line)
    if "email" not in seen:
        out.append(f"{email_key}={quoted(email)}")
    if "password" not in seen:
        out.append(f"{password_key}={quoted(password)}")
    ENV_FILE.write_text("\n".join(out) + "\n", encoding="utf-8")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--project",
        choices=sorted(PROJECTS),
        default="dev",
        help="projeto Supabase alvo (padrão: dev)",
    )
    ap.add_argument("--email", help="e-mail atual do owner (1a execução)")
    ap.add_argument("--password", help="senha atual do owner (1a execução)")
    args = ap.parse_args()

    url, env_source, prefix = PROJECTS[args.project]

    if args.email and args.password and (
        not ENV_FILE.exists() or f"{prefix}_EMAIL" not in ENV_FILE.read_text(encoding="utf-8")
    ):
        lines = (
            ENV_FILE.read_text(encoding="utf-8") if ENV_FILE.exists() else ""
        )
        lines = "".join(
            line
            for line in lines.splitlines(keepends=True)
            if not line.startswith(f"{prefix}_")
        )
        lines += f"{prefix}_EMAIL={args.email}\n{prefix}_PASSWORD={args.password}\n"
        ENV_FILE.write_text(lines, encoding="utf-8")
        print(f"[1/5] {prefix} inicializado em {ENV_FILE} (não exibido).")
    elif args.email or args.password:
        sys.exit(
            "Passe --email E --password juntos (1a execução), ou nada "
            "para rotacionar a partir do arquivo existente."
        )

    email, current = load_current(prefix)
    print(f"[2/5] Autenticando em {url} ({args.project}) ...")

    r = requests.post(
        f"{url}/auth/v1/token?grant_type=password",
        headers={"apikey": _anon_key(env_source), "Content-Type": "application/json"},
        json={"email": email, "password": current},
        timeout=30,
    )
    if r.status_code != 200:
        sys.exit(f"FALHA no login atual ({r.status_code}) — nada alterado.")
    access_token = r.json()["access_token"]

    new_password = strong_password()
    r = requests.put(
        f"{url}/auth/v1/user",
        headers={
            "apikey": _anon_key(env_source),
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        },
        # GoTrue exige a senha ATUAL junto (current_password_required) —
        # protege contra rotação por um invasor com o token roubado.
        json={"password": new_password, "current_password": current},
        timeout=30,
    )
    if r.status_code != 200:
        sys.exit(f"FALHA na rotação ({r.status_code}) — nada alterado.")
    print("[3/5] Senha rotacionada na GoTrue (PUT /auth/v1/user).")

    ok_new = requests.post(
        f"{url}/auth/v1/token?grant_type=password",
        headers={"apikey": _anon_key(env_source), "Content-Type": "application/json"},
        json={"email": email, "password": new_password},
        timeout=30,
    ).status_code
    old_rejected = requests.post(
        f"{url}/auth/v1/token?grant_type=password",
        headers={"apikey": _anon_key(env_source), "Content-Type": "application/json"},
        json={"email": email, "password": current},
        timeout=30,
    ).status_code
    if ok_new != 200 or old_rejected == 200:
        sys.exit(
            f"VERIFICAÇÃO falhou (novo={ok_new}, antigo={old_rejected}) — "
            "a senha EFETIVA é a última aceita; confira no Supabase."
        )
    print("[4/5] Verificado: nova senha aceita; antiga REJEITADA.")

    save_new_credentials(prefix, email, new_password)
    print(f"[5/5] Novo par {prefix}_EMAIL/{prefix}_PASSWORD gravado APENAS "
          f"em {ENV_FILE} (gitignored, demais chaves preservadas).")


def _anon_key(env_source: str) -> str:
    """Anon key do projeto alvo (pública por design — RLS protege os dados)."""
    for line in Path(env_source).read_text(encoding="utf-8").splitlines():
        if line.startswith("SUPABASE_ANON_KEY="):
            return line.split("=", 1)[1].strip()
    sys.exit(f"SUPABASE_ANON_KEY não encontrada em {env_source}.")


if __name__ == "__main__":
    main()
