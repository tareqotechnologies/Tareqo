-- ============================================================================
-- Promover um usuário a SUPER ADMIN — papel baseado em banco (auditoria C3)
-- ============================================================================
-- Após a auditoria C3, o super admin NÃO é mais definido por e-mail hardcoded:
-- o papel vive SOMENTE na tabela public.super_admins, lida pela função
-- SECURITY DEFINER is_super_admin(). Este script promove o usuário desejado
-- de forma idempotente e com feedback claro.
--
-- Onde rodar: Supabase Dashboard → SQL Editor
--   https://supabase.com/dashboard/project/<SEU_REF>/sql/new
--
-- ⚠️ Este script ESCREVE em public.super_admins — rode no SQL Editor (a
--    sessão do editor é dona do schema e ignora o RLS, que nega leitura e
--    escrita para anon/authenticated justamente para impedir auto-promoção).
--
-- Como usar:
--   1. Substitua 'SEU_EMAIL_AQUI' (abaixo) pelo e-mail cadastrado no app.
--   2. Rode o script inteiro (Run).
--   3. Confira a mensagem retornada: "promovido" / "já é super admin" / erro
--      "Nenhum usuário ... encontrado" (falha ALTA: nada é promovido sem o
--      e-mail exato existir em auth.users).
--
-- Idempotente: pode rodar de novo sem efeito colateral (guarda + ON CONFLICT).
-- ============================================================================

DO $$
DECLARE
  -- ⚠️ EDITAR AQUI — e-mail do usuário que terá acesso ao painel do super admin.
  v_email text := 'SEU_EMAIL_AQUI';
  v_uid uuid;
BEGIN
  -- Procura o usuário pelo e-mail (case-insensitive, como a migração legada).
  SELECT id INTO v_uid
  FROM auth.users
  WHERE lower(email) = lower(v_email)
  LIMIT 1;

  IF v_uid IS NULL THEN
    RAISE EXCEPTION USING MESSAGE = format(
      'Nenhum usuário com o e-mail "%s" foi encontrado em auth.users. '
      'Cadastre-se no app primeiro e confira o e-mail exato '
      '(Authentication → Users).',
      v_email
    );
  END IF;

  -- Idempotência: já promovido não gera erro nem duplicata.
  IF EXISTS (SELECT 1 FROM public.super_admins WHERE user_id = v_uid) THEN
    RAISE NOTICE 'OK: % já é super admin (nada a fazer).', v_email;
  ELSE
    INSERT INTO public.super_admins (user_id) VALUES (v_uid);
    RAISE NOTICE 'OK: % promovido a super admin (user_id %).', v_email, v_uid;
  END IF;
END
$$;

-- Confirmação: quem é super admin hoje.
SELECT sa.user_id, u.email, sa.created_at
FROM public.super_admins sa
JOIN auth.users u ON u.id = sa.user_id
ORDER BY sa.created_at;

-- ────────────────────────────────────────────────────────────────────────────
-- Alternativas (mesmo efeito — troque o e-mail):
-- ────────────────────────────────────────────────────────────────────────────
-- Promover em uma linha:
--   INSERT INTO public.super_admins (user_id)
--   SELECT id FROM auth.users WHERE lower(email) = lower('SEU_EMAIL_AQUI')
--   ON CONFLICT (user_id) DO NOTHING;
--
-- Revogar o papel (remover um super admin):
--   DELETE FROM public.super_admins
--   WHERE user_id = (SELECT id FROM auth.users
--                    WHERE lower(email) = lower('SEU_EMAIL_AQUI'));
