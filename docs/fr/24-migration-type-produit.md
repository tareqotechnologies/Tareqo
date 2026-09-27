# 24 — Migration du type structurel du produit (`products.type`) sur le Supabase de production (runbook)

> **Objectif :** appliquer la **Partie 34 — type structurel du produit
> (Phase 1)** au projet de production (`dotklbpqmlnhcdifiukd`) à l'aide du
> `supabase/upgrade.sql` consolidé — mêmes conventions que les runbooks 15
> (W4/H2), 16 (W11), 17 (clôture de caisse), 18 (add-ons) et 20 (MFA aal2).
>
> Ce que cette application apporte (idempotent) :
> 1. **Colonne `products.type`** (`TEXT NOT NULL DEFAULT 'resale'`) — le type
>    structurel du produit par le NOM de l'enum `ProductType` (`rawMaterial`,
>    `resale`, `manufactured`, `composite`, `packaging`) ;
> 2. **`DROP CONSTRAINT IF EXISTS products_type_check`** — supprime un CHECK
>    d'enum qu'une version antérieure du script aurait créé (il ne doit pas
>    exister ; la validation d'enum vit dans le client/datasource) ;
> 3. **Commentaire de colonne** (`COMMENT ON COLUMN`) documentant les valeurs ;
> 4. **Index `idx_products_store_type (store_id, type)`** — garde le filtre par
>    type constant dans la liste du catalogue.
>
> **Aucune fenêtre de compatibilité dure :** le défaut `'resale'` signifie que
> les produits existants étaient déjà achetables et vendables et **continuent
> de fonctionner exactement pareil** — aucune donnée n'est supprimée ni
> reclassée automatiquement. L'ancienne app ne sélectionne ni n'envoie la
> colonne (elle utilise `DEFAULT 'resale'`) ; la nouvelle app (Phase 1)
> lit/écrit le champ. Publier l'app avant ou après la migration est indifférent.
>
> Portugais (faisant foi) : [`../pt/24-migracao-tipo-produto.md`](../pt/24-migracao-tipo-produto.md)

---

## Étape 0 — Prérequis

- Accès au Dashboard du projet + **mot de passe de la base**
  (Settings → Database → Connection string).
- L'hôte direct du projet est **IPv6-only** → utiliser le **pooler**
  `aws-0-eu-north-1.pooler.supabase.com`.
- `psql` local **ou** Docker (`postgres:16` fournit `psql`).
- Attention : **NE JAMAIS** exécuter `scripts/sql_check.sh` contre la base live
  — il fait `DROP SCHEMA public CASCADE`. La vérification live se fait
  uniquement avec `scripts/sql_check_live.sh` (read-only, checks 1–44).
- ⚠️ **Ordre des parties :** le check 44 est celui de la **Phase 2**
  (production, Partie 35 — runbook 25). Si vous n'appliquez **que** la Phase 1
  (Partie 34), le check 43 passera mais le **44 échouera** (tables de
  production absentes). Le chemin attendu est d'appliquer les deux parties (34
  et 35) — ou d'accepter le 44 comme le seul en attente jusqu'à la Phase 2.
- **App compilée sur la version Phase 1** prête à publier (voir Étape 6) —
  nécessaire uniquement pour que le champ apparaisse dans le formulaire et
  pour les flux par rôle (achats/PDV).

Définissez l'URL (remplacez `MOT_DE_PASSE`) :

```bash
export SUPABASE_DB_URL='postgresql://postgres.dotklbpqmlnhcdifiukd:MOT_DE_PASSE@aws-0-eu-north-1.pooler.supabase.com:6543/postgres?sslmode=require'
```

## Étape 1 — Sauvegarde (obligatoire)

- **Option rapide :** Dashboard → Database → **Backups** → « Create a backup »
  (ou activer PITR).
- **Option CLI** (port **5432** *session* du pooler, adapté à `pg_dump`) :

```bash
pg_dump "postgresql://postgres.dotklbpqmlnhcdifiukd:MOT_DE_PASSE@aws-0-eu-north-1.pooler.supabase.com:5432/postgres?sslmode=require" \
  --schema=public -f backup_pre_product_type.sql
```

## Étape 2 — Pré-vol (read-only, SQL Editor)

**2.1 La colonne/l'index existent déjà ?** (la migration est idempotente — ceci
ne fait qu'encadrer le scénario) :

```sql
-- Colonne products.type (attendu : absente avant la migration ; si présente,
-- avec data_type=text / is_nullable=NO / column_default 'resale') :
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'products'
  AND column_name = 'type';

-- Index du filtre par type :
SELECT indexname FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'products'
  AND indexname = 'idx_products_store_type';

-- CHECK d'enum par erreur (attendu : 0 ligne) :
SELECT conname FROM pg_constraint
WHERE conrelid = 'public.products'::regclass
  AND conname = 'products_type_check';
```

**2.2 Échantillon d'intégrité** (notez-le — la migration ne doit modifier
aucune ligne) :

```sql
SELECT
  (SELECT count(*) FROM public.products)   AS produits,
  (SELECT count(*) FROM public.sales)      AS ventes,
  (SELECT count(*) FROM public.purchases)  AS achats;

-- Aucun produit ne doit être reclassé : après la migration TOUTES les lignes
-- sont en 'resale' (le défaut), sans aucun UPDATE.
SELECT type, count(*) FROM public.products GROUP BY type ORDER BY type;
```

## Étape 3 — Appliquer `supabase/upgrade.sql`

### Option A — psql via le pooler, UNE transaction (recommandée — convention du projet)

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

- `-1` = transaction unique : si **une seule** partie échoue, **tout** est
  annulé — aucun état partiel.
- La Partie 34 est `ADD COLUMN IF NOT EXISTS` + `DROP CONSTRAINT IF EXISTS` +
  `COMMENT` + `CREATE INDEX IF NOT EXISTS` + `ANALYZE` — no-op à la 2ᵉ
  exécution.

### Option B — SQL Editor du Dashboard

1. Ouvrez le **SQL Editor** du projet.
2. Collez le **contenu complet** de `supabase/upgrade.sql`.
3. Exécutez. En cas d'erreur, l'éditeur s'arrête et affiche le message ; comme
   le script est idempotent, corriger puis réexécuter est sûr.

### Option C — script isolé (seulement la Partie 34)

Pour appliquer **uniquement** cette migration (ex. : base déjà sur les Parties
précédentes), lancez le script dédié — même contenu que la Partie 34 :

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 \
  -f supabase/add_product_type_2026_09_27.sql
```

## Étape 4 — Vérification post-migration (read-only)

**4.1 Lancer le script de vérification live** (read-only, désormais avec **44
checks au total** — celui de la Phase 1 est le 43 ; le 44 est celui de la
Phase 2/production) :

```bash
SUPABASE_DB_URL="$SUPABASE_DB_URL" bash scripts/sql_check_live.sh
```

- Attendu (avec la Partie 34 et la Partie 35 appliquées) : **VÉRIFICATION
  TERMINÉE — tous les checks sont passés**, y compris le **43** — colonne
  `products.type` `TEXT NOT NULL DEFAULT 'resale'` (sans CHECK d'enum) + index
  `idx_products_store_type`.
- En n'appliquant **que** la Phase 1, le **44 échouera** (tables de production
  absentes) — appliquez aussi la Partie 35 via le runbook 25.

**4.2 Vérification manuelle (SQL Editor) :**

```sql
-- 1) Colonne avec le bon type/défaut :
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'products'
  AND column_name = 'type';
-- Attendu : type | text | NO | 'resale'::text

-- 2) Index présent :
SELECT indexdef FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'products'
  AND indexname = 'idx_products_store_type';
-- Attendu : ... ON public.products (store_id, type)

-- 3) AUCUN CHECK d'enum (le client valide ; un type futur ne doit pas être
--    bloqué par l'ancienne contrainte) :
SELECT conname FROM pg_constraint
WHERE conrelid = 'public.products'::regclass AND contype = 'c'
  AND pg_get_constraintdef(oid) ILIKE '%type%';
-- Attendu : 0 ligne.
```

**4.3 Vérification d'intégrité** — répétez 2.2 : comptes
produits/ventes/achats identiques et **tous** les produits en `'resale'`
(aucun reclassé par la migration).

**4.4 Probe REST (la nouvelle app lit/écrit le champ) :** avec l'anon key et la
session du propriétaire, le `SELECT` d'un produit renvoie déjà la colonne :

```bash
curl -s "$SUPABASE_URL/rest/v1/products?select=id,name,type&limit=1" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $OWNER_ACCESS_TOKEN"
```

- Attendu : un élément avec `"type":"resale"`. Sur une base sans la migration,
  PostgREST renvoie **`42703` (column products.type does not exist)** — preuve
  que la colonne existe.

## Étape 5 — Idempotence (facultatif ; confirme qu'une réexécution ne duplique pas)

Répétez l'Étape 3 puis vérifiez :

```sql
-- Toujours exactement UNE colonne type :
SELECT count(*) AS colonnes_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'products'
  AND column_name = 'type';
-- Attendu : 1.

-- Toujours exactement UN index idx_products_store_type :
SELECT count(*) AS index_count
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'products'
  AND indexname = 'idx_products_store_type';
-- Attendu : 1.
```

## Étape 6 — Publier l'app (Phase 1) et reclasser les produits

La migration ne change rien en soi (défaut `'resale'`) :

1. **Publier la version de l'app avec la Phase 1.** Les produits existants
   restent achetables et vendables exactement comme avant.
2. **Reclasser produit par produit** (Produits → modifier → « Type de
   produit ») : matières premières, produits fabriqués, composites et
   emballages reçoivent le bon rôle. Il est conseillé de commencer par les
   éléments qui sortiront des listes par défaut :
   - **matière première/emballage** cessent d'apparaître au PDV ;
   - **fabriqué/composite** cessent d'apparaître dans les Achats.
3. **Vérifier les flux :** au PDV le catalogue n'affiche que les rôles
   vendables (`isSellable`) ; dans les Achats que les rôles achetables
   (`isPurchasable`). Si un rôle se retrouve sans éléments, l'état vide
   explique pourquoi au lieu de dire « aucun produit ».
4. **Backfill facultatif par SQL** (seulement si vous connaissez les
   catégories — l'app ne reclasse rien toute seule) :

```sql
-- Exemple : tout ce qui est en 'resale' et contient "FARINHA" (farine) devient matière première.
UPDATE public.products SET type = 'rawMaterial'
WHERE type = 'resale' AND upper(name) LIKE '%FARINHA%';
```

> Le `UPDATE` ci-dessus est **manuel et explicite** — la migration ne
> l'exécute jamais.

**Backfill automatique (recommandé pour les gros catalogues) :** l'helper
one-off `tool/backfill_product_types.dart` généralise le `LIKE` ci-dessus avec
une table ordonnée de mots-clés
(`lib/domain/services/product_type_classifier.dart`) :

```bash
# 1) Dry-run sur DEV (rien n'est écrit) — relisez le plan :
dart run tool/backfill_product_types.dart

# 2) Appliquer sur DEV (uniquement ceux encore en 'resale') :
dart run tool/backfill_product_types.dart --apply

# 3) En PRODUCTION : dry-run, relecture, puis seulement --apply :
dart run tool/backfill_product_types.dart --prod
dart run tool/backfill_product_types.dart --prod --apply
```

- **Dry-run par défaut** : rien n'est écrit sans `--apply`.
- **N'annule jamais** une classification déjà faite — par défaut il ne regarde
  que les produits en `resale` (utilisez `--include-classified` pour réappliquer
  les règles à tous).
- Restreint à un magasin avec `--store <id>`.
- Utilise la **session du propriétaire** (RLS veille) et les identifiants
  gitignorés (`env/dev.env`/`env/test_accounts.env` ; `--prod` utilise
  `env/prod.env`).
- La règle qui a matché apparaît dans le rapport (`(règle : farinha)`) —
  relisez avant le `--apply`. La classification est heuristique : les produits
  au nom ambigu doivent être corrigés dans l'UI ensuite.

## Rollback (seulement si nécessaire)

> La migration est **additive** (colonne avec défaut, commentaire et index) et
> idempotente. Revenir signifie simplement NE PAS publier la nouvelle app ; les
> données restent valides. Pour retirer réellement :
>
> 1. **Il n'y a aucune donnée à défaire :** aucun produit n'a été reclassé
>    automatiquement (seulement des reclassements MANUELS faits à l'Étape 6.4/
>    dans l'app).
> 2. Supprimer la colonne (destructif — seulement si la nouvelle app n'est PAS
>    publiée et qu'aucun produit n'a été reclassé) :
>    `ALTER TABLE public.products DROP COLUMN IF EXISTS type;`
>    `DROP INDEX IF EXISTS public.idx_products_store_type;`
> 3. Pour les reclassements manuels, annulez les `UPDATE` faits à la main (ou
>    restaurez la sauvegarde de l'Étape 1).

---

## Checklist finale

| # | Élément | Vérification |
|---|---------|--------------|
| 1 | Sauvegarde faite | fichier `backup_pre_product_type.sql` présent |
| 2 | Pré-vol | colonne/index/CHECK catalogués (2.1) ; comptes et distribution de `type` notés (2.2) |
| 3 | `upgrade.sql` appliqué | sans erreur (transaction unique) — ou le script isolé à l'Étape 3C |
| 4 | `sql_check_live.sh` | ✓ checks 1–43 (type du produit : 43). Le 44 (production) ne passe qu'avec la Partie 35 (runbook 25) |
| 5 | Aucun CHECK d'enum | 0 contrainte de `type` (4.2.3) |
| 6 | Données intactes | comptes identiques et tous les produits en `resale` (4.3) |
| 7 | Probe REST | le produit renvoie `"type":"resale"` (4.4) |
| 8 | Réexécution sans effet | idempotence confirmée (Étape 5) |
| 9 | App Phase 1 publiée | champ « Type de produit » visible dans le formulaire |
| 10 | Reclassement (facultatif) | propriétaire/gérant classe produit par produit ; PDV/Achats filtrent par rôle |
