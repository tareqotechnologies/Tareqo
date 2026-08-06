-- Stub das funções/tabelas do schema auth para validar o schema.sql
-- em um PostgreSQL puro (Docker), fora do Supabase.
--
-- Espelha o suficiente do schema real do GoTrue para exercitar:
--   * auth.uid()/auth.jwt() (claims do JWT por sessão);
--   * a RPC public.create_employee_account, que hoje insere DIRETAMENTE
--     em auth.users + auth.identities (com hash bcrypt via pgcrypto) — o
--     Supabase atual removeu auth.admin_create_user;
--   * os usuários demo dos testes de RLS.
CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.users (
  id                 uuid PRIMARY KEY,
  instance_id        uuid,
  aud                varchar(255),
  role               varchar(255),
  email              varchar(255),
  encrypted_password varchar(255),
  email_confirmed_at timestamptz,
  invited_at         timestamptz,
  confirmation_token varchar(255) DEFAULT '',
  recovery_token     varchar(255) DEFAULT '',
  email_change_token_current varchar(255) DEFAULT '',
  email_change_token_new     varchar(255) DEFAULT '',
  email_change               varchar(255) DEFAULT '',
  email_change_confirm_status smallint   DEFAULT 0,
  phone_change_token  varchar(255) DEFAULT '',
  phone_change        varchar(255) DEFAULT '',
  reauthentication_token varchar(255) DEFAULT '',
  last_sign_in_at    timestamptz,
  raw_app_meta_data  jsonb,
  raw_user_meta_data jsonb,
  created_at         timestamptz,
  updated_at         timestamptz,
  deleted_at         timestamptz,
  is_sso_user        boolean NOT NULL DEFAULT FALSE,
  is_anonymous       boolean NOT NULL DEFAULT FALSE
);

-- Índice único parcial do GoTrue: impede e-mail duplicado entre usuários
-- não apagados (mesmo comportamento do Supabase real).
CREATE UNIQUE INDEX IF NOT EXISTS users_email_partial_key
  ON auth.users (lower(email)) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS auth.identities (
  id               uuid PRIMARY KEY,
  provider_id      text NOT NULL,
  user_id          uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  identity_data    jsonb NOT NULL,
  provider         text NOT NULL,
  last_sign_in_at  timestamptz,
  created_at       timestamptz,
  updated_at       timestamptz
);

CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb ->> 'sub', '')::uuid;
$$;

CREATE OR REPLACE FUNCTION auth.jwt()
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    NULLIF(current_setting('request.jwt.claims', true), '')::jsonb,
    '{}'::jsonb
  );
$$;

-- Usuários demo usados nos testes de RLS
INSERT INTO auth.users (id, email) VALUES
  ('11111111-1111-1111-1111-111111111111', 'dono@loja.com')
ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.users (id, email) VALUES
  ('22222222-2222-2222-2222-222222222222', 'funcionario@loja.com')
ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.users (id, email) VALUES
  ('99999999-9999-9999-9999-999999999999', 'admin@dumbhanengue.com')
ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.users (id, email) VALUES
  ('33333333-3333-3333-3333-333333333333', 'gerente@loja.com')
ON CONFLICT (id) DO NOTHING;
