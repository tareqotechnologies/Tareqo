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
  ('99999999-9999-9999-9999-999999999999', 'admin@tareqo.com')
ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.users (id, email) VALUES
  ('33333333-3333-3333-3333-333333333333', 'gerente@loja.com')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- Stub do schema STORAGE do Supabase (secção "FOTOS DE PRODUTO" do
-- schema.sql — bucket product-images + políticas is_my_store).
-- ============================================================================
-- Em um PostgreSQL PURO (Docker) não existem nem o schema `storage` nem os
-- papéis `anon`/`authenticated` do Supabase. Sem estes stubs, a secção de
-- fotos do schema.sql falha com "role \"authenticated\" does not exist" ao
-- criar as políticas de escrita (regressão achada Aug 12).
--
-- O stub espelha o MÍNIMO que o schema.sql/upgrade.sql usam:
--   * papéis anon/authenticated (políticas `FOR ... TO authenticated`);
--   * storage.buckets (id, name, public) e storage.objects (id, bucket_id,
--     name) — as políticas referenciam apenas bucket_id + name;
--   * storage.foldername(name) — devolve os segmentos do caminho; a
--     política de escrita valida is_my_store((foldername(name))[1]).
--
-- ⚠️ O primeiro segmento do caminho de um objeto É o store_id (convenção
-- do produto — ver schema.sql); qualquer teste de política que simule um
-- upload deve usar paths como 'st1/produto.jpg'.
-- ============================================================================

-- Papéis do Supabase (PostgreSQL não tem CREATE ROLE IF NOT EXISTS).
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
END
$$;

CREATE SCHEMA IF NOT EXISTS storage;

CREATE TABLE IF NOT EXISTS storage.buckets (
  id     TEXT PRIMARY KEY,
  name   TEXT,
  public BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS storage.objects (
  id        TEXT PRIMARY KEY,
  bucket_id TEXT,
  name      TEXT
);

-- Segmentos do caminho do objeto: storage.foldername('st1/prod.jpg') =
-- {st1, prod.jpg}. Mesma assinatura do Supabase (que também aceita a
-- versão com depth).
CREATE OR REPLACE FUNCTION storage.foldername(name TEXT)
RETURNS TEXT[]
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT string_to_array(name, '/');
$$;

-- Permissões mínimas: as políticas de escrita valem TO authenticated;
-- grants de leitura no bucket/objetos são irrelevantes no stub (a RLS das
-- tabelas public não toca o storage).
GRANT USAGE ON SCHEMA storage TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.buckets, storage.objects
  TO anon, authenticated;
