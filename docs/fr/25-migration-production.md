# 25 — Migration de la fiche technique + production (`recipes`/`production_orders`) sur le Supabase de production (runbook)

> **Objectif :** appliquer la **Partie 35 — production : fiche technique + ordres
> (Phase 2)** au projet de production (`bcyolmheltzlddfwgqcq`) à l'aide du
> `supabase/upgrade.sql` consolidé — mêmes conventions que les runbooks 15
> (W4/H2), 16 (W11), 17 (clôture de caisse), 20 (MFA aal2) et 24 (type du
> produit/Phase 1).
>
> Ce que cette application apporte (idempotent) :
> 1. **4 nouvelles tables** par magasin : `recipes` (la fiche technique — UNIQUE
>    `(store_id, product_id)`), `recipe_items` (composants, FK CASCADE,
>    UNIQUE `(recipe_id, product_id)`), `production_orders` (historique, avec
>    snapshot du coût) et `production_order_items` (composants consommés par
>    ordre, UNIQUE `(production_id, product_id)`) ;
> 2. **RLS** `ENABLE` sur les 4 tables + **politiques manager** (`is_manager_of_store` ;
>    INSERT/UPDATE exigent `mfa_ok()`) — la production est **managériale**,
>    comme les achats ;
> 3. **4 index** (`recipes(store_id)`, `recipe_items(recipe_id)`,
>    `production_orders(store_id, date_time DESC)`,
>    `production_order_items(production_id)`) ;
> 4. **RPC `process_production(p_order jsonb, p_items jsonb)`**
>    `SECURITY DEFINER` — consomme les composants en FIFO et crée le lot du
>    produit fini **en UNE transaction** + `GRANT EXECUTE … TO authenticated`.
>
> **Sans fenêtre de compatibilité dure :** la migration est **purement additive**
> (nouvelles tables, aucune donnée existante n'est lue, modifiée ou reclassée).
> L'ancienne app n'a simplement pas le module Production ; la nouvelle app
> (Phase 2) lit/écrit les tables. Publier l'app avant ou après la migration est
> indifférent — sans le module, la production n'existe simplement pas.
>
> Portugais (faisant foi) : [`../pt/25-migracao-producao.md`](../pt/25-migracao-producao.md)

---

## Registre d'application

| Date | Projet | État |
|------|--------|------|
| 2026-09-27 | **DEV** — `dotklbpqmlnhcdifiukd` | ✅ Partie 35 appliquée : `recipes`/`recipe_items`/`production_orders`/`production_order_items` + RLS + RPC `process_production` ; `scripts/sql_check_live.sh` → check 44 passe |
| — | **PRODUCTION** — `bcyolmheltzlddfwgqcq` | ⏳ en attente — diagnostic REST (2026-09-27) : il manque la Partie 35 (4 tables de production + RPC `process_production`) et aussi la Partie 33 (`invoice_notifications.body_params`) ; projet pratiquement vide (1 magasin, 0 produit/vente/achat) |

> **DEV vs. production :** `env/dev.env` → `dotklbpqmlnhcdifiukd` (**DEV**) et
> `env/prod.env` → `bcyolmheltzlddfwgqcq` (**PRODUCTION**). Les exemples
> ci-dessous utilisent la référence de **production** ; pour DEV, utilisez
> `env/db.env` (`SUPABASE_DB_URL`). L'hôte du pooler (`aws-0-<région>...`)
> doit être celui du projet cible (Dashboard → Settings → Database).

---

## Étape 0 — Prérequis

- Accès au Dashboard du projet + le **mot de passe de la base**
  (Settings → Database → Connection string).
- L'hôte direct du projet est **IPv6-only** → utiliser le **pooler**
  `aws-0-eu-north-1.pooler.supabase.com`.
- `psql` local **ou** Docker (`postgres:16` fournit `psql`).
- Attention : **NE JAMAIS** lancer `scripts/sql_check.sh` contre la base live —
  il fait `DROP SCHEMA public CASCADE`. La vérification live est uniquement
  `scripts/sql_check_live.sh` (read-only, checks 1–44).
- **App compilée sur la version avec la Phase 2** prête à publier (voir Étape 6)
  — nécessaire seulement pour que le module Production apparaisse dans le menu.
- **Dépendance des phases précédentes :** la colonne `products.type` (Phase 1,
  Partie 34) doit exister — la production utilise `isProducible`
  (`manufactured`/`composite`) et le coût par le `purchase_price` du composant.
  Si vous ne l'avez pas encore appliquée, lancez aussi le runbook 24.

Définissez l'URL (remplacez `MOTDEPASSE`) :

```bash
export SUPABASE_DB_URL='postgresql://postgres.bcyolmheltzlddfwgqcq:MOTDEPASSE@aws-0-eu-north-1.pooler.supabase.com:6543/postgres?sslmode=require'
```

## Étape 1 — Sauvegarde (obligatoire)

- **Option rapide :** Dashboard → Database → **Backups** → « Create a backup »
  (ou activer PITR).
- **Option via la CLI** (port **5432** *session* du pooler, adapté à `pg_dump`) :

```bash
pg_dump "postgresql://postgres.bcyolmheltzlddfwgqcq:MOTDEPASSE@aws-0-eu-north-1.pooler.supabase.com:5432/postgres?sslmode=require" \
  --schema=public -f backup_pre_production.sql
```

## Étape 2 — Pré-vol (read-only, SQL Editor)

**2.1 Les tables/RPC existent-elles déjà ?** (la migration est idempotente —
ceci ne fait que cadrer le scénario ; attendu : absentes AVANT la migration) :

```sql
-- Les 4 tables de la production (attendu : 0 ligne avant).
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('recipes','recipe_items','production_orders','production_order_items')
ORDER BY tablename;

-- La RPC atomique (attendu : 0 ligne avant).
SELECT proname FROM pg_proc
WHERE proname = 'process_production';
```

**2.2 Échantillon d'intégrité** (notez-le — la migration ne doit modifier
aucune ligne) :

```sql
SELECT
  (SELECT count(*) FROM public.products)   AS produits,
  (SELECT count(*) FROM public.sales)      AS ventes,
  (SELECT count(*) FROM public.purchases)  AS achats,
  (SELECT count(*) FROM public.stock_lots WHERE current_quantity > 0) AS lots_actifs;
```

**2.3 La Phase 1 est-elle appliquée ?** (le coût/la production dépendent de
`products.type`) :

```sql
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'products'
  AND column_name = 'type';
-- Attendu : type | text | 'resale'::text  (sinon lancez d'abord le runbook 24)
```

## Étape 3 — Appliquer `supabase/upgrade.sql`

### Option A — psql via le pooler, UNE transaction (recommandée — convention du projet)

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

- `-1` = transaction unique : si **une** partie échoue, **tout** est annulé —
  aucun état partiel.
- La Partie 35 est `CREATE TABLE/INDEX IF NOT EXISTS` + `DROP POLICY IF EXISTS`
  + `CREATE OR REPLACE FUNCTION` + `GRANT` — un no-op à la 2ᵉ exécution.

### Option B — SQL Editor du Dashboard

1. Ouvrez le **SQL Editor** du projet.
2. Collez le **contenu complet** de `supabase/upgrade.sql`.
3. Exécutez. En cas d'erreur, l'éditeur s'arrête et affiche le message ; le
   script étant idempotent, corriger et réexécuter est sûr.

### Option C — script isolé (seulement la Partie 35)

Pour appliquer **uniquement** cette migration (ex. : base déjà sur les parties
précédentes), lancez le script dédié — même contenu que la Partie 35 :

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 \
  -f supabase/add_production_2026_09_27.sql
```

## Étape 4 — Vérification post-migration (read-only)

**4.1 Lancer le script de vérification live** (read-only, désormais avec **44
checks** — le nouveau est le 44) :

```bash
SUPABASE_DB_URL="$SUPABASE_DB_URL" bash scripts/sql_check_live.sh
```

- Attendu : **VÉRIFICATION TERMINÉE — tous les checks passent**, y compris le
  **44** — les 4 tables existent, avec RLS actif sur les 4, et
  `process_production(jsonb,jsonb)` est `SECURITY DEFINER` avec `EXECUTE` pour
  `authenticated`.

**4.2 Contrôle manuel (SQL Editor) :**

```sql
-- 1) Les 4 tables + RLS actif (attendu : 4 lignes, rls = true) :
SELECT c.relname, c.relrowsecurity AS rls
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN ('recipes','recipe_items','production_orders','production_order_items')
ORDER BY c.relname;

-- 2) Politiques manager sur les tables (attendu : 16 policies — SELECT/INSERT/
--    UPDATE/DELETE par table) :
SELECT tablename, count(*) AS policies
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('recipes','recipe_items','production_orders','production_order_items')
GROUP BY tablename ORDER BY tablename;

-- 3) RPC SECURITY DEFINER + EXECUTE pour authenticated :
SELECT p.proname, p.prosecdef,
       has_function_privilege('authenticated',
         'public.process_production(jsonb,jsonb)', 'EXECUTE') AS exec_ok
FROM pg_proc p
WHERE p.proname = 'process_production';
-- Attendu : process_production | true | true
```

**4.3 Contrôle d'intégrité** — répétez 2.2 : comptages produits/ventes/achats/lots
**identiques** (la migration ne touche pas les lignes existantes).

**4.4 Sonde REST (la nouvelle app lit/écrit les tables) :** avec l'anon key et la
session du propriétaire, le `SELECT` des nouvelles tables répond déjà (vide ou
avec des fiches) :

```bash
curl -s "$SUPABASE_URL/rest/v1/recipes?select=id,product_id,yield_quantity&limit=1" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $OWNER_ACCESS_TOKEN"
```

- Attendu : `[]` (aucune fiche) — sur une base sans la migration, PostgREST
  renvoie **`42P01` (relation "public.recipes" does not exist)**.

## Étape 5 — Idempotence (optionnel ; confirme qu'une réexécution ne duplique pas)

Répétez l'Étape 3 puis vérifiez :

```sql
-- Toujours exactement 4 tables de production :
SELECT count(*) AS tables
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('recipes','recipe_items','production_orders','production_order_items');
-- Attendu : 4.

-- Toujours exactement UNE process_production :
SELECT count(*) AS rpcs FROM pg_proc WHERE proname = 'process_production';
-- Attendu : 1.
```

## Étape 6 — Publier l'app (Phase 2) et utiliser la production

La migration seule ne change rien (tables nouvelles et vides) :

1. **Publier la version de l'app avec la Phase 2.** Le module **Production**
   apparaît dans le menu pour propriétaire/manager (gate `accessLevel != employee`).
2. **Monter les fiches techniques** (Production → Nouvelle fiche) : choisir le
   produit **fini** (seulement `manufactured`/`composite`), le rendement de la
   base et les composants/quantités. Une fiche par produit fini.
3. **Enregistrer la production** (Production → Produire) : saisir les bases —
   les composants sont consommés en FIFO et le lot du produit fini naît avec le
   coût calculé à partir du prix d'achat **actuel** des composants.
4. **Vérifier les flux :** le produit fini devient vendable au POS (revente/
   produit/assemblé) et les matières premières/emballages apparaissent dans les
   Achats.

> Un ordre de production **ne touche pas la caisse** — les composants ont déjà
> été payés à l'achat ; la production ne fait que transformer le stock.

## Rollback (seulement si nécessaire)

> La migration est **purement additive** (tables/index nouveaux, RPC nouvelle) et
> idempotente. Revenir signifie simplement NE PAS publier la nouvelle app ; les
> données existantes restent valides. Pour supprimer réellement :
>
> 1. **Les fiches, ordres et composants enregistrés seront perdus** (ce sont des
>    données NOUVELLES de cette phase — il n'y avait rien avant). Faites la
>    sauvegarde de l'Étape 1 avant.
> 2. Supprimer les objets (destructif) :
>    ```sql
>    DROP FUNCTION IF EXISTS public.process_production(jsonb, jsonb);
>    DROP TABLE IF EXISTS public.production_order_items;
>    DROP TABLE IF EXISTS public.production_orders;
>    DROP TABLE IF EXISTS public.recipe_items;
>    DROP TABLE IF EXISTS public.recipes;
>    ```
> 3. NE PAS revenir sur la colonne `products.type` ni sur les lots à cause de la
>    production : ils relèvent des Phases 1/W11 et restent valides sans ce module.

---

## Checklist finale

| # | Élément | Vérification |
|---|---------|--------------|
| 1 | Sauvegarde faite | le fichier `backup_pre_production.sql` existe |
| 2 | Pré-vol | 4 tables + RPC absentes (2.1) ; comptages notés (2.2) ; `products.type` présent (2.3) |
| 3 | `upgrade.sql` appliqué | sans erreur (transaction unique) — ou le script isolé à l'Étape 3C |
| 4 | `sql_check_live.sh` | ✓ tous les 44 checks (production : 44) |
| 5 | Tables + RLS | 4 tables avec `relrowsecurity = true` (4.2.1) |
| 6 | Politiques manager | 16 policies, INSERT/UPDATE avec `mfa_ok()` (4.2.2) |
| 7 | RPC atomique | `process_production` SECURITY DEFINER + EXECUTE à authenticated (4.2.3) |
| 8 | Données intactes | comptages produits/ventes/achats/lots identiques (4.3) |
| 9 | Sonde REST | `GET /rest/v1/recipes` répond `[]` (4.4) |
| 10 | Réexécution sans effet | idempotence confirmée (Étape 5) |
| 11 | App Phase 2 publiée | module Production visible pour propriétaire/manager |
| 12 | Fiches + production | propriétaire/manager monte la fiche et produit ; le lot du produit fini naît avec un coût |
