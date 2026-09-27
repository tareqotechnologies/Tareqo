-- =====================================================================
-- PARTE 33 — Notificações: body_params para localização na exibição
-- Data: 2026-09-27 · App: TAREQO v2.4.0+
-- =====================================================================
-- Script ISOLADO (equivale à PARTE 33 do upgrade.sql consolidado): aplica
-- apenas esta migração num banco que já recebeu as partes anteriores.
--
-- Objetivo: a coluna `body_params` (JSONB) em `invoice_notifications` guarda
-- os PARÂMETROS de interpolação do corpo (período, valor, moeda, dias,
-- add-on, datas) para a UI reconstruir a mensagem LOCALIZADA na exibição.
-- O `body` persistido permanece em PT como fallback; NULL = notificação
-- legada (a UI mostra o `body`).
--
-- O app grava via PostgREST (mapeado no datasource remoto); RLS e policies
-- ficam INALTERADAS — a coluna é aditiva.
--
-- Idempotente: pode rodar mais de uma vez sem efeito (ADD COLUMN IF EXISTS
-- + COMMENT + ANALYZE). Espelha supabase/schema.sql (a instalação nova já
-- nasce com a coluna).
-- =====================================================================

ALTER TABLE IF EXISTS public.invoice_notifications
  ADD COLUMN IF NOT EXISTS body_params JSONB;

COMMENT ON COLUMN public.invoice_notifications.body_params
  IS 'Parâmetros do corpo para localização na exibição (nulo = legado: mostra body).';

ANALYZE public.invoice_notifications;
