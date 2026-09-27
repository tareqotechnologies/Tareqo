# 26 — Migration des notifications : `body_params` (Partie 33) sur le Supabase de production (runbook)

> **Objectif :** appliquer la **Partie 33 — notifications : `body_params`** au
> projet de production (`bcyolmheltzlddfwgqcq`), en suivant les mêmes conventions
> que les runbooks 15 (W4/H2), 16 (W11), 17 (clôture de caisse), 20 (MFA aal2),
> 24 (type du produit) et 25 (production).
>
> Ce que cette application apporte (idempotent) :
> 1. **Colonne `body_params` (JSONB)** sur `invoice_notifications` — les
>    paramètres d'interpolation du corps (période, montant, devise, jours,
>    add-on, dates) pour que l'UI reconstruise le message **localisé** à
>    l'affichage. Le `body` persisté reste en PT comme repli ; `NULL` =
>    notification héritée (affiche le `body`).
> 2. **Commentaire de colonne** (`COMMENT ON COLUMN`) documentant le contrat.
>
> **Sans fenêtre de compatibilité dure :** la migration est **purement additive**
> (une colonne nouvelle ; aucune donnée existante n'est lue, modifiée ou
> reclassée) et idempotente. ⚠️ La NOUVELLE app **sélectionne la colonne** —
> contre une base non migrée, PostgREST échoue avec `42703`. **Publiez l'app
> après la migration.**
>
> Portugais (faisant foi) : [`../pt/26-migracao-notificacoes-body-params.md`](../pt/26-migracao-notificacoes-body-params.md)

---

## Registre d'application

| Date | Projet | État |
|------|--------|------|
| 2026-09-27 | **DEV** — `dotklbpqmlnhcdifiukd` | ✅ Partie 33 appliquée (`invoice_notifications.body_params` présente) |
| — | **PRODUCTION** — `bcyolmheltzlddfwgqcq` | ⏳ en attente — diagnostic REST (2026-09-27) : colonne absente ; projet pratiquement vide (1 magasin, 0 produit/vente/achat) |

> **DEV vs. production :** `env/dev.env` → `dotklbpqmlnhcdifiukd` (**DEV**) et
> `env/prod.env` → `bcyolmheltzlddfwgqcq` (**PRODUCTION**). Les exemples
> ci-dessous utilisent la référence de **production** ; pour DEV, utilisez
> `env/db.env` (`SUPABASE_DB_URL`).

Définissez l'URL (remplacez `MOTDEPASSE` et la région) :

```bash
export SUPABASE_DB_URL='postgresql://postgres.bcyolmheltzlddfwgqcq:MOTDEPASSE@aws-0-<région>.pooler.supabase.com:6543/postgres?sslmode=require'
```

> **Où la conserver :** mettez cette ligne dans un fichier **gitignored**
> (`env/prod.db.env`) et exportez-la (ou passez-la en ligne) — **jamais** de
> commit ni de mot de passe collé dans le chat/PR (l'ancien mot de passe DEV a
> fuité ainsi et a été changé en Aug/2026) ; le MOTDEPASSE et la région viennent
> du Dashboard → Settings → Database. Pour DEV, le chemin existe déjà :
> `env/db.env` (`SUPABASE_DB_URL`). Sans fichier : `set -a; . env/prod.db.env;
> set +a` avant le `psql`.

## Étape 0 — Prérequis

- Dashboard + le **mot de passe de la base** (Settings → Database) ; l'hôte direct
  est IPv6-only → utiliser le **pooler**.
- `psql`, Docker (`postgres:16`) **ou** Python avec `psycopg2`/`psycopg3`
  (`scripts/sql_check_live.sh` a un repli Python).
- ⚠️ **NE JAMAIS** lancer `scripts/sql_check.sh` contre la base live (il fait
  `DROP SCHEMA public CASCADE`). La vérification live est uniquement
  `scripts/sql_check_live.sh`.

## Étape 1 — Sauvegarde (obligatoire)

Dashboard → Database → **Backups** → « Create a backup » (ou PITR), ou `pg_dump`
(port **5432** du pooler).

## Étape 2 — Pré-vol (read-only)

```sql
-- Attendu AVANT la migration : 0 ligne.
SELECT column_name, data_type FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'invoice_notifications'
  AND column_name = 'body_params';
```

## Étape 3 — Appliquer

**Défaut (recommandé) — `upgrade.sql` complet.** C'est la voie pour une base en
retard de PLUS d'une partie (ex. : la production, à qui il manque les parties 33
et 35) : elle applique d'un coup toutes les parties manquantes. La Partie 33 est
la section `body_params`.

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

**Alternative — script isolé** (à utiliser UNIQUEMENT quand la base est déjà à
jour et qu'il ne manque que cette partie — évite de réexécuter les autres) :

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 \
  -f supabase/add_notification_body_params_2026_09_27.sql
```

Les deux utilisent `-1` = transaction unique : si quoi que ce soit échoue, tout
est annulé. Réexécuter est sûr (idempotent).

## Étape 4 — Vérification (read-only)

```sql
SELECT column_name, data_type FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'invoice_notifications'
  AND column_name = 'body_params';
-- Attendu : body_params | jsonb
```

**Sonde REST** (avec la session du propriétaire) :

```bash
curl -s "$SUPABASE_URL/rest/v1/invoice_notifications?select=id,body_params&limit=1" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $OWNER_ACCESS_TOKEN"
```

- Attendu : `200` (liste vide ou notifications). Avant la migration : **`42703`**
  (`column invoice_notifications.body_params does not exist`).

## Rollback

```sql
ALTER TABLE public.invoice_notifications DROP COLUMN IF EXISTS body_params;
```

> Destructif — la colonne est additive et ne modifie pas les données existantes.
> Revenir n'est nécessaire que si la nouvelle app n'est PAS publiée.

---

## Checklist finale

| # | Élément | Vérification |
|---|---------|--------------|
| 1 | Sauvegarde faite | sauvegarde de l'Étape 1 |
| 2 | Pré-vol | colonne absente avant (Étape 2) |
| 3 | Script appliqué | sans erreur (transaction unique) |
| 4 | Colonne présente | `body_params` de type `jsonb` (Étape 4) |
| 5 | Sonde REST | `select=id,body_params` répond `200` |
| 6 | Réexécution sans effet | idempotence (`ADD COLUMN IF NOT EXISTS`) |
