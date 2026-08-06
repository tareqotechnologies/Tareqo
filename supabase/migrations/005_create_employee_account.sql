-- ============================================================================
-- 005 — Conta de funcionário via RPC create_employee_account (sem e-mail),
--       com vínculo na loja atómico (sem contas órfãs).
--
-- Problema: o app criava a conta do funcionário com `auth.signUp`. Com a
-- confirmação de e-mail ATIVA no projeto, cada tentativa enviava um e-mail
-- de confirmação — o provedor bloqueava com `over_email_send_rate_limit`
-- (429) e o cadastro falhava; e mesmo quando criava, a conta ficava
-- pendente (`email_not_confirmed`) e o funcionário não conseguia entrar.
--
-- Solução (v2, Aug 6): esta função SECURITY DEFINER NÃO depende de
-- `auth.admin_create_user` — o Supabase atual REMOVEU essa função interna
-- (a Admin API do GoTrue é HTTP e ASSÍNCRONA: quebraria a atomicidade e o
-- retorno do user_id). A conta é criada por INSERÇÃO DIRETA em
-- `auth.users` + `auth.identities` com hash bcrypt (pgcrypto) — síncrona e
-- TRANSACIONAL — e o vínculo em `store_employees` é criado na MESMA
-- transação:
--   * a conta nasce confirmada (email_confirmed_at = now()), com a senha
--     escolhida pelo dono, e NENHUM e-mail é enviado — o funcionário entra
--     direto com login/senha normais (o GoTrue verifica o hash bcrypt);
--   * se o vínculo falhar (ex.: limite de funcionários do plano — trigger
--     `enforce_employee_limit`), a conta criada é desfeita junto: NENHUMA
--     conta órfã fica para trás;
--   * a sessão do dono nunca é substituída (o antigo signUp auto-logava o
--     novo usuário com confirmação OFF — bug S1);
--   * idempotente pelo id do vínculo (retry devolve o mesmo user_id).
--
-- ⚠️ Trade-off documentado: inserir em `auth.users` é a ÚNICA forma
-- SÍNCRONA de criar a conta com atomicidade. As colunas usadas são as
-- ESTÁVEIS do GoTrue (id, instance_id, aud, role, email,
-- encrypted_password, email_confirmed_at, raw_app_meta_data,
-- raw_user_meta_data, created_at, updated_at + a identidade de e-mail em
-- auth.identities); `confirmed_at` é coluna GERADA pelo banco (nunca
-- inserida). E-mail duplicado devolve mensagem amigável (pré-checagem +
-- índice único parcial do GoTrue, tratado no EXCEPTION).
--
-- ⚠️ pgcrypto: o `CREATE EXTENSION IF NOT EXISTS pgcrypto` abaixo garante a
-- extensão, mas em projetos Supabase geridos ela costuma já existir no
-- schema `extensions` (não no `public`). Por isso a função usa
-- `SET search_path = public, extensions` — resolve crypt/gen_salt em
-- qualquer um dos dois schemas.
--
-- ⚠️ REEXECUTÁVEL: se você já aplicou a versão ANTERIOR desta migração
-- (3 parâmetros, ou a v1 com auth.admin_create_user), basta reexecutar —
-- o DROP FUNCTION abaixo remove a função antiga antes de criar a nova.
--
-- ⚠️ Executar no SQL Editor do dashboard do projeto (supabase.com).
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP FUNCTION IF EXISTS public.create_employee_account(text, text, text);

CREATE OR REPLACE FUNCTION public.create_employee_account(
  p_employee_id text,
  p_email text,
  p_password text,
  p_full_name text,
  p_store_id text,
  p_role text DEFAULT 'employee'
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
-- `extensions` no search_path: em projetos Supabase geridos as funções do
-- pgcrypto (crypt/gen_salt) vivem no schema `extensions`, não no `public`.
SET search_path = public, extensions
AS $$
DECLARE
  v_owner uuid := auth.uid();
  v_user_id uuid;
  v_tenant_id text;
  v_linked uuid;
BEGIN
  IF v_owner IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para cadastrar funcionário.';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.tenants t WHERE t.owner_user_id = v_owner
  ) THEN
    RAISE EXCEPTION 'Apenas o dono do tenant pode cadastrar funcionários.';
  END IF;
  IF char_length(p_password) < 8 THEN
    RAISE EXCEPTION 'A senha deve ter pelo menos 8 caracteres.';
  END IF;
  IF p_full_name IS NULL OR trim(p_full_name) = '' THEN
    RAISE EXCEPTION 'Informe o nome do funcionário.';
  END IF;
  IF p_role IS NULL OR p_role NOT IN ('manager', 'employee') THEN
    RAISE EXCEPTION 'Cargo inválido para o funcionário.';
  END IF;
  IF p_email IS NULL OR position('@' IN p_email) = 0 THEN
    RAISE EXCEPTION 'Informe um e-mail válido para o funcionário.';
  END IF;

  -- A loja precisa pertencer a um tenant do DONO autenticado.
  SELECT s.tenant_id INTO v_tenant_id
  FROM public.stores s
  JOIN public.tenants t ON t.id = s.tenant_id
  WHERE s.id = p_store_id AND t.owner_user_id = v_owner;
  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'Escolha uma loja do seu tenant.';
  END IF;

  -- Idempotência: retry após sucesso devolve o mesmo user_id. O vínculo é
  -- localizado PELA MESMA LOJA — nunca devolve o user_id de outra loja/tenant.
  IF EXISTS (
    SELECT 1 FROM public.store_employees
    WHERE id = p_employee_id AND store_id = p_store_id
  ) THEN
    SELECT user_id INTO v_user_id FROM public.store_employees
    WHERE id = p_employee_id AND store_id = p_store_id;
    RETURN v_user_id::text;
  END IF;

  -- E-mail duplicado (mensagem amigável). A corrida é protegida pelo
  -- índice único parcial (lower(email) WHERE deleted_at IS NULL) do GoTrue.
  IF EXISTS (
    SELECT 1 FROM auth.users u
    WHERE lower(u.email) = lower(p_email) AND u.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Já existe uma conta com este e-mail.';
  END IF;

  -- Conta confirmada (sem e-mail): inserção direta em auth.users +
  -- auth.identities com hash bcrypt (pgcrypto). Síncrona e transacional —
  -- se o vínculo abaixo falhar, a conta é desfeita junto.
  --
  -- ⚠️ O struct User do GoTrue faz SELECT * e faz scan de TODAS as colunas;
  -- os campos NÃO-anuláveis em Go (string/bool/int) NÃO podem ficar NULL no
  -- banco, senão o login do funcionário rebenta com 500 "Database error
  -- querying schema". Por isso TODAS as colunas do struct são preenchidas
  -- com os mesmos zero-values que o GoTrue grava no signup ('' / false / 0).
  -- `confirmed_at` é coluna GERADA (nunca inserida); `last_sign_in_at`,
  -- `banned_until`, `deleted_at` e os *_sent_at são *time.Time no struct
  -- (NULL é seguro nesses).
  v_user_id := gen_random_uuid();
  INSERT INTO auth.users
    (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
     confirmation_token, recovery_token,
     email_change_token_current, email_change_token_new, email_change,
     email_change_confirm_status, phone_change_token, phone_change,
     reauthentication_token, is_sso_user, is_anonymous,
     raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES
    (v_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated',
     'authenticated', lower(p_email), crypt(p_password, gen_salt('bf', 10)),
     now(), '', '', '', '', '', 0, '', '', '', FALSE, FALSE,
     '{"provider":"email","providers":["email"]}'::jsonb,
     jsonb_build_object('full_name', btrim(p_full_name)), now(), now());

  INSERT INTO auth.identities
    (id, provider_id, user_id, identity_data, provider, last_sign_in_at,
     created_at, updated_at)
  VALUES
    (gen_random_uuid(), v_user_id::text, v_user_id,
     jsonb_build_object('sub', v_user_id::text, 'email', lower(p_email),
                        'email_verified', true, 'phone_verified', false,
                        'date_last_signed_in', now()::text),
     'email', now(), now(), now());

  -- Vínculo na loja NA MESMA transação. O trigger enforce_employee_limit
  -- valida o limite do plano e a aprovação do tenant; se falhar, a conta
  -- criada acima é desfeita junto (sem contas órfãs).
  INSERT INTO public.store_employees
    (id, tenant_id, store_id, user_id, full_name, email, role)
  VALUES (p_employee_id, v_tenant_id, p_store_id, v_user_id,
          btrim(p_full_name), lower(p_email), p_role);

  RETURN v_user_id::text;

EXCEPTION
  WHEN unique_violation THEN
    -- Corrida: ou o MESMO vínculo foi criado por outra chamada (retry), ou
    -- o e-mail foi criado por outra chamada concorrente.
    SELECT user_id INTO v_linked FROM public.store_employees
    WHERE id = p_employee_id AND store_id = p_store_id;
    IF v_linked IS NOT NULL THEN
      RETURN v_linked::text;
    END IF;
    IF EXISTS (
      SELECT 1 FROM auth.users u
      WHERE lower(u.email) = lower(p_email) AND u.deleted_at IS NULL
    ) THEN
      RAISE EXCEPTION 'Já existe uma conta com este e-mail.';
    END IF;
    RAISE EXCEPTION 'Não foi possível criar a conta do funcionário. Tente novamente.';
END;
$$;
