# Documentation du TAREQO ERP (français)

Bienvenue dans la documentation complète du **TAREQO ERP** — système de gestion d'entreprise (stock, ventes, finances et suivi du crédit/« fiado ») construit en Flutter avec **Clean Architecture**.

> **Langue :** ceci est la version française. La documentation portugaise vit dans ([`docs/pt/`](../pt/README.md)) et la version anglaise dans ([`docs/en/`](../en/README.md)).
>
> **Documents d'audit :** les rapports d'audit de préparation à la production ([`docs/pt/AUDIT_REPORT.md`](../pt/AUDIT_REPORT.md)) et la checklist vivante ([`docs/pt/PRODUCTION_CHECKLIST.md`](../pt/PRODUCTION_CHECKLIST.md)) sont maintenus en portugais (la langue principale du projet) et font autorité pour le statut d'audit. Un résumé anglais du dernier statut d'audit (Update 6 + éléments de production en attente) est disponible dans [15-audit-status.md](15-audit-status.md), le runbook de migration live W4 + H2 dans [16-migracao-w4-h2.md](16-migracao-w4-h2.md), le runbook de migration live W11 (lots FIFO + ventes au poids/bascule) dans [18-migracao-w11.md](18-migracao-w11.md), le runbook de clôture de caisse quotidienne (Partie 25, rapport Z) dans [19-migracao-cash-closing.md](19-migracao-cash-closing.md), et la checklist de préparation à la production dans [17-production-checklist.md](17-production-checklist.md). Les chapitres français ont été traduits depuis les miroirs anglais (synchronisés avec les changements des 5/6 août : flavors, RLS scopée magasin, super admin adossé à la base, RPC atomiques, stockage sécurisé de session, CI/CD, W4/H2/W10, consolidation SQL) — les documents portugais restent la référence principale.

Ce dossier rassemble tous les documents sur l'application : de ce qu'elle fait à comment chaque couche fonctionne, avec des exemples de code, des diagrammes et des guides pratiques pour les développeurs.

---

## Index des documents

| # | Document | Ce qu'il explique |
| - | -------- | ----------------- |
| 01 | [Vue d'ensemble](01-overview.md) | Ce qu'est l'app, objectifs, fonctionnalités, public cible, plateformes et stack |
| 02 | [Architecture](02-architecture.md) | Clean Architecture : couches, règle de dépendance, flux de données et décisions structurelles |
| 03 | [Domaine](03-domain.md) | Entités, enums, contrats de repository et tous les cas d'usage (règles métier) |
| 04 | [Couche de données](04-data.md) | Datasources (mémoire + SQLite), repositories, schéma de la base, migrations, seed et Unit of Work |
| 05 | [Présentation](05-presentation.md) | Providers Riverpod, écrans (Accueil, Produits, Ventes, Finances, Crédit), widgets, navigation et thème |
| 06 | [Authentification](06-authentication.md) | Connexion/inscription avec Supabase, session persistante, AuthGate et flux SaaS multi-tenant |
| 07 | [Sécurité](07-security.md) | Stockage sécurisé (Keychain/Keystore), RLS, ce qu'il ne faut jamais faire |
| 08 | [Flux métier](08-business-flows.md) | Traitement atomique des ventes, le cycle du « crédit », le flux de caisse et le contrôle du stock |
| 09 | [Tests](09-testing.md) | Stratégie de test, structure, comment exécuter et les modèles utilisés |
| 10 | [Guide du développeur](10-developer-guide.md) | Setup, commandes, génération de code (Freezed), conventions et comment ajouter de nouveaux modules |
| 11 | [Multi-tenancy et Super Admin](11-multitenancy.md) | Plans, approbation des tenants, magasins, employés, upgrades de plan et le panneau super admin |
| 12 | [Décisions d'architecture](12-architecture-decisions.md) | Le « pourquoi » derrière chaque décision technique : Clean Architecture, contrats, snapshot de prix, stock atomique, crédit, authentification SaaS et stockage sécurisé |
| 13 | [Build et publication par plateforme](13-build-and-release.md) | Comment compiler l'app sur Android, iOS, Windows et Web : exigences, signature, déploiement et une checklist de publication |
| 14 | [Opérations de go-live](14-go-live-ops.md) | Opérations pré-lancement et jour du lancement : configuration du projet Supabase, variables d'environnement, application SQL, scripts de vérification, rollback et monitoring |
| 15 | [Statut d'audit & éléments en attente](15-audit-status.md) | Résumé français du dernier statut d'audit (Update 6 : consolidation SQL + validation sur vraie base) et les éléments en attente de la checklist de production |
| 16 | [Runbook de migration live W4 + H2](16-migracao-w4-h2.md) | Runbook pas à pas pour appliquer `supabase/upgrade.sql` au projet de production (sauvegarde, pré-vol, application, vérification, rollback) |
| 17 | [Checklist de préparation à la production](17-production-checklist.md) | Miroir français de la checklist de production : intégrité des données, sécurité, architecture, performance, tests, ops, dépendances et statut des docs |
| 18 | [Runbook de migration live W11](18-migracao-w11.md) | Runbook pas à pas pour la Partie 22 (lots FIFO + péremption + ventes au poids) : millièmes, backfill des lots, vérification post-migration et fenêtre de publication |
| 19 | [Runbook de migration de la clôture de caisse quotidienne](19-migracao-cash-closing.md) | Runbook pas à pas pour la Partie 25 (rapport Z) : table `cash_closings` + RPC `close_cash_register` (calcul côté serveur + garde managériale), vérification post-migration (checks 32–34) et publication |
| 24 | [Runbook de migration du type de produit](24-migration-type-produit.md) | Runbook pas à pas pour la Partie 34 (Phase 1) : colonne `products.type` (TEXT, défaut `resale`), index `idx_products_store_type`, vérification (check 43), reclassement manuel (avec le backfill `tool/backfill_product_types.dart`) et rollback |

---

## Pour les utilisateurs finaux

| Document | Ce que c'est |
| --------- | ------------ |
| [Guide de l'utilisateur](GUIDE_DE_L_UTILISATEUR.md) | Manuel simple et complet de l'app : connexion, magasins (magasin actif), produits (avec photos), ventes, achats, crédit, finances, clôture de caisse, rapports et **FAQ** |
| [Dépannage](DEPANNAGE.md) | Résolution des problèmes courants : connexion et compte, photos, ventes, stock, caisse, connexion, messages d'erreur courants et quand contacter le support |
| [Glossaire pt/en/fr](GLOSSAIRE.md) | Termes techniques dans les trois langues — métier, paiements, accès, authentification, plans, base de données, architecture, tests et release |
| **Versions PDF (imprimables)** | [Guide de l'utilisateur PDF](pdf/fr/GUIDE_DE_L_UTILISATEUR.pdf) · [Dépannage PDF](pdf/fr/DEPANNAGE.pdf) — avec couverture et sommaire, prêtes à distribuer/imprimer |

> **Glossaire trilingue :** [português](../pt/GLOSSARIO.md) · [english](../en/GLOSSARY.md) · [français](GLOSSAIRE.md)

> **Dans les autres langues :** [Guide de l'utilisateur](GUIDE_DE_L_UTILISATEUR.md) → [`docs/pt/GUIA_DO_USUARIO.md`](../pt/GUIA_DO_USUARIO.md) · [`docs/en/USER_GUIDE.md`](../en/USER_GUIDE.md) — empaquetés dans l'app (lecture hors-ligne) et en PDF sous `docs/pdf/{pt,en}/`.

---

## Commencer ici

- **Vous ne connaissez pas l'app ?** → [Vue d'ensemble](01-overview.md)
- **Vous êtes utilisateur final (propriétaire/gérant/employé) ?** → [Guide de l'utilisateur](GUIDE_DE_L_UTILISATEUR.md) · [Dépannage](DEPANNAGE.md)
- **Vous voulez comprendre comment le code est organisé ?** → [Architecture](02-architecture.md)
- **Vous voulez exécuter le projet et travailler sur le code ?** → [Guide du développeur](10-developer-guide.md)

> Le `README.md` à la racine du projet est le document de présentation ; ce dossier `docs/fr/` est le manuel de référence complet.

## Cartes rapides

- **Structure des dossiers** → voir le diagramme dans [Architecture](02-architecture.md#structure-des-dossiers).
- **Schéma de la base** → voir les tables dans [Couche de données](04-data.md#schéma-de-la-base).
- **Cas d'usage** → catalogue complet dans [Domaine](03-domain.md#catalogue-des-cas-dusage).
- **Écrans** → description de chacun dans [Présentation](05-presentation.md#écrans).
