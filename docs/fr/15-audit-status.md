# 📊 Statut de l'audit et éléments de production en attente (français)

> **Source faisant autorité :** l'audit complet de préparation à la production vit en portugais dans [`../pt/AUDIT_REPORT.md`](../pt/AUDIT_REPORT.md) (la langue principale du projet). Ce chapitre est la **version française de la Mise à jour 6** (session finale, partie 3 — Aug 6, 2026), **de la Mise à jour 7** (Aug 7 — activation/désactivation des employés + matrice de création de produits) **et de la Section 9** (éléments de la checklist de production en attente). Les chiffres reflètent le rapport faisant autorité : `381/381` tests, `sql_check.sh` **12/12**, `sql_check_live.sh` **14/14**, `schema.sql` 2 311 lignes, 73 fichiers de test.

---

## Mise à jour 7 (Aug 7, 2026 — activation/désactivation des employés + matrice de création de produits)

**Activation/désactivation des employés :** le **propriétaire** active/désactive maintenant les employés (interrupteur dans Magasins → onglet Employés, avec confirmation). Un employé désactivé perd l'accès **immédiatement** via un blocage à deux niveaux : l'**app** affiche l'écran « Accès suspendu » dans l'AuthGate, et le **serveur** refuse toute opération — `is_my_store`/`is_manager_of_store` exigent un lien **actif** (`is_active = TRUE`), donc le RLS et les gardes RPC bloquent même un client modifié. Implémentation : `store_employees.is_active` (DEFAULT TRUE — les employés existants restent actifs) + RPC `set_employee_active` (SECURITY DEFINER, propriétaire uniquement, idempotente) + exigence de lien actif dans les deux helpers — `schema.sql` + `supabase/upgrade.sql` (Partie 19) ; `sql_check.sh` a gagné la section [6b] (désactiver → `is_my_store` FALSE, réactiver → TRUE, non-propriétaire rejeté).

**Matrice de création de produits :** un **employé ordinaire ne crée pas de produits** (il ne fait que lister/vendre) — le FAB « Nouveau produit » est masqué quand `currentAccessLevelProvider == employee` ; le propriétaire et le gérant le gardent (RLS `products_insert` du serveur inchangé).

**`flutter analyze` 0 issue · `flutter test` 381/381.**

---

## Mise à jour 6 (Aug 6, 2026 — session finale, partie 3 : consolidation SQL + validation sur vraie base)

Livré la **consolidation SQL** et la **validation dure sur PostgreSQL réel**.

**(a) SQL consolidé en 4 fichiers.** Les 10 fichiers de migration (`002..011`) ont été fusionnés en **un script idempotent `supabase/upgrade.sql`** (Parties 1–8 — DDL, helpers RLS, garde gérant, journal d'audit, compte d'employé, migration de colonnes W4, RPC finales en centimes). Les installations neuves utilisent `supabase/schema.sql` seul ; les bases existantes appliquent `supabase/upgrade.sql` (ré-exécutable, pas d'état partiel quand il est exécuté en une seule transaction avec `-1`).

**(b) Validation sur vraie base (Docker Postgres 16, config CI exacte — scram sur TCP).** `scripts/sql_check.sh` exécute maintenant **12/12 étapes** :

- **[1b]** `upgrade.sql` appliqué deux fois → **idempotence** confirmée
- **[10/10]** `get_dashboard_kpis` (W5) avec assertions de valeurs
- **[11/11]** `get_cash_flow` / `get_sales_report` (H2) avec assertions de valeurs
- **[12/12]** la migration W4 NUMERIC→centimes avec de vraies données (25.50 → 2550, **pas de double application**)

Cela a attrapé et corrigé un **vrai bug W4** : `SUM(bigint)` renvoie `numeric`, ce qui casse le `RETURNS TABLE` BIGINT de `get_dashboard_kpis` / `get_cash_flow` / `get_sales_report` à l'exécution — corrigé avec des casts explicites `::bigint` dans `schema.sql` et `upgrade.sql`.

**(c) `scripts/sql_check_live.sh` étendu à 14 checks en lecture seule** — 9 colonnes d'argent en BIGINT, zéro valeur fractionnaire, RPC H2 présentes avec `SECURITY DEFINER` + retours BIGINT — validé **14/14** ; la signature obsolète de `lock_products_or_raise` a été corrigée.

**(d) CI.** Les jobs `sql-check` dans `.github/workflows/ci.yml` + `.github/workflows/release.yml` exécutent les 12 étapes complètes sur Postgres 16 (validé localement avec la config exacte du service-container, scram/TCP ; `timeout-minutes: 30`).

**`flutter analyze` 0 issue · `flutter test` 300/300.** *(Mis à jour Aug 7 : **381/381** — voir la Mise à jour 7.)*

---

## Statut final de l'ingénierie interne (W4, H2, W10)

| Élément | Statut |
|---|---|
| **W4 — argent en centimes entiers de bout en bout** | ✅ Fait — `*Cents` dans le domaine, SQLite `INTEGER` + migration ×100 idempotente, Supabase `BIGINT` (+ migration de colonnes W4, Partie 7 de `upgrade.sql`), les RPC comparent/somment en centimes directement (pas de `ROUND(x*100)`), catalogue de forfaits en centimes, `Money.parse` / `Formatters.currency(cents)` |
| **H2 — agrégation côté serveur + pagination par clé** | ✅ Fait — RPC `get_cash_flow` + `get_sales_report` (SECURITY DEFINER, portées par `is_my_store`, BIGINT, buckets de jour dans le fuseau de l'appareil ; Parties 8.6–8.7 de `upgrade.sql`) ; `fetchAllKeyset` (curseur `id` stable, lots `pageSize`) remplaçant `.limit(1000)` sur les 6 `getAll` Supabase |
| **W10 — sqlite3 3.x** | ✅ Fait — `sqlite3` ^3.5.1 via build hooks/native assets ; `sqlite3_flutter_libs` (EOL) supprimé ; `dispose()` → `close()` |
| **Consolidation SQL** | ✅ Fait — 13 → 4 fichiers SQL (`schema.sql` installation neuve, `upgrade.sql` bases existantes, `promote_super_admin.sql` helper ops, `sqlcheck_stub.sql` stub de smoke-test) ; `supabase/migrations/` supprimé |
| **Validation** | ✅ `sql_check.sh` **12/12** sur vrai Postgres 16 (incl. idempotence + migration W4 avec de vraies données) · `sql_check_live.sh` **14/14** · la CI exécute la suite complète dans `ci.yml` + `release.yml` |

---

## Section 9 — Éléments de la checklist de production en attente

> Statut final (Mise à jour 6, Aug 6) : **tout le travail d'ingénierie interne est terminé** (W4, H2, W10, W1–W11, consolidation SQL) et validé sur PostgreSQL réel. **`upgrade.sql` a été appliqué au projet live le Aug 6 (ancien élément 1 ✅, retiré de la liste)** — il ne reste que des **opérations externes** (1–5) + **des éléments produit/sécurité** (6–8) + une longue traîne facultative (9).

| # | Élément (checklist) | Type | Statut |
|---|---|---|---|
| 1 | Activer **Play App Signing** + enregistrer le SHA-256 de la clé d'upload (7.1 — partie externe de C1) | Externe (Play Console) | ⏳ |
| 2 | Vérifier **confirmation d'e-mail ON** + activer la **2FA sur le super admin** (2.1/2.2 — H9) | Externe (dashboard Supabase) | ⏳ |
| 3 | `password_min_length = 8` dans les réglages du projet (M7) | Externe (dashboard Supabase) | ⏳ |
| 4 | Comptes Google Play / Apple + secrets dans la CI (7.9) | Externe | ⏳ |
| 5 | Politique de confidentialité / CGU + politique de sauvegarde (7.5/7.6) | Légal | ⏳ |
| 6 | **Facturation** (W2) — reportée par décision produit ; les limites de forfait sont déjà appliquées en base | Produit | ⏳ reporté |
| 7 | Limite de débit de création de tenants + reCAPTCHA (H6) | Sécurité | ⏳ |
| 8 | Flux d'invitation des employés (H7 — partie externe de C2) | Sécurité/UX | ⏳ |
| 9 | Longue traîne facultative : M3 (onglets paresseux), M5 (AppIds restants), M6 (gitleaks), M8 (stock faible par produit), M12 (UUID v7) ; M2 (CSP, seulement si le web est livré) | Maintenance | ⏳ facultatif |

**Terminé Aug 6 (retiré de la liste) :** application de `supabase/upgrade.sql` au projet live (ancien élément 1) — pooler eu-north-1, transaction unique `-1`, PostgreSQL 17.6 : 9 colonnes d'argent → `bigint`, zéro valeur fractionnaire, `sql_check_live.sh` **14/14 PASS**, idempotence confirmée ; sauvegarde `backup_pre_w4.sql` (gitignorée) ; E2E web re-validé après migration. Runbook : [chapitre 16](16-migracao-w4-h2.md).

Tous les éléments restants de la checklist (1.1–1.18, 2.3–2.4, 4.1–4.2, 6.2, 7.1–7.8, 8.1–8.3, 9.1–9.2) sont **✅**.

---

*Note de portée : l'audit d'origine était en lecture seule ; les corrections pour C1/C3/C4/H3 ont été implémentées lors de sessions de suivi (Aug 5, 2026) et W4/H2/W10 + la consolidation SQL lors des sessions finales (Aug 6, 2026). La vérification du schéma live a eu lieu le Aug 5 (lecture seule via pooler eu-north-1) : la couche de durcissement manquait en production, `schema.sql` a été appliqué en une transaction et re-vérifié 10/10. Les éléments externes (confirmation d'e-mail, activation de Play App Signing, console du store) doivent être vérifiés dans le dashboard Supabase et les consoles des stores, pas dans le code. Détails complets : [`../pt/AUDIT_REPORT.md`](../pt/AUDIT_REPORT.md).*
