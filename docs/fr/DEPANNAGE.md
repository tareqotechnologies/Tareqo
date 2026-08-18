# Dépannage — Dumbhanengue ERP (résolution de problèmes)

Guide pratique pour résoudre les problèmes les plus courants de l'app au quotidien. Pour apprendre à utiliser le système, consultez le [Guide de l'utilisateur](GUIDE_DE_L_UTILISATEUR.md).

---

## Comment utiliser ce guide

1. Repérez le symptôme du problème dans la liste ci-dessous (connexion, ventes, stock, photos...).
2. Suivez les étapes dans l'ordre indiqué — commencez toujours par la plus simple.
3. Si le problème persiste, consultez la section **Messages d'erreur courants** et, en dernier recours, **Quand contacter le support**.

> **Attention :** **Règle d'or** : avant tout, vérifiez que le téléphone a **internet** et que l'app est **à jour** (magasin d'applications). Beaucoup d'« erreurs » ne sont qu'un manque de connexion ou une version ancienne.

---

## 1. Problèmes de connexion et de compte

### « Je ne peux pas me connecter »
1. Vérifiez l'**e-mail** (sans espaces, tout correct) et le **mot de passe**.
2. Touchez **« Mot de passe oublié ? »** si vous ne vous en souvenez pas — le lien arrive par e-mail (vérifiez aussi le **spam/courrier indésirable**).
3. Nouvel utilisateur : le compte doit être **approuvé** (dans les 24 h). Approbation en attente = pas de connexion.
4. Fermez complètement l'app et rouvrez-la (parfois la session reste bloquée).

### « Mon compte a été désactivé »
- Le **propriétaire** peut désactiver les employés — si c'est votre cas, l'accès est bloqué immédiatement.
- Parlez au propriétaire de l'établissement pour être réactivé.

### « J'ai saisi le mauvais e-mail à l'inscription »
- Il n'est pas possible de modifier l'e-mail d'inscription depuis l'app : contactez le **support** en indiquant le bon e-mail et le nom de l'entreprise.

---

## 2. Problèmes avec les photos de produit

### « La photo du produit n'apparaît pas dans la liste »
1. Le produit a peut-être été enregistré **sans photo** (l'envoi a échoué — ex. : sans internet). Ouvrez le produit → **Modifier le produit** → touchez la zone photo → ajoutez-la à nouveau.
2. Vérifiez que la photo a bien été sélectionnée (l'aperçu apparaît avant d'enregistrer).

### « Quand je prends une photo / choisis dans la galerie, rien ne se passe »
1. Le téléphone demande **l'autorisation caméra/stockage** — acceptez. Si vous l'avez refusée avant : **Réglages du téléphone → Applications → Dumbhanengue → Autorisations** et activez Caméra/Fichiers.
2. Fermez et rouvrez l'app, puis réessayez.

### « Il apparaît « Produit ajouté ! (photo non envoyée…) » »
- Le produit est enregistré ✓ — seule la photo n'est pas montée (pas de connexion ou erreur temporaire).
- Vous pouvez ajouter la photo **plus tard**, via l'édition du produit.
- Si cela arrive toujours, même avec internet, contactez le **support** (il peut s'agir d'une configuration du serveur).

---

## 3. Problèmes avec les ventes

### « La vente ne se confirme pas / « Impossible d'enregistrer la vente » »
1. Vérifiez l'**internet**.
2. Confirmez que **tous les champs** sont remplis (produit, quantité, moyen de paiement).
3. Vérifiez que la **quantité n'est pas zéro** et que le **total correspond** aux articles.
4. Si la vente concerne un produit **désactivé**, réactivez-le (Produits → Modifier → **Produit actif**).

### « J'ai vendu par erreur / le client n'a pas emporté »
- Ouvrez la vente → **Annuler la vente** (propriétaire/gérant uniquement). Le stock revient et la caisse est annulée.
- **L'employé ne voit pas le bouton Annuler** — c'est une opération de gestion ; demandez au propriétaire/gérant.

### « Le stock n'a pas été déduit / a été trop déduit »
1. Vérifiez dans le **détail de la vente** que les articles sont corrects.
2. Les ventes **annulées** restituent le stock — si vous avez annulé, le stock revient.
3. Vérifiez s'il y a eu des **achats** (augmentent le stock) ou des **ajustements manuels** dans l'édition du produit.
4. S'il reste une divergence, utilisez l'ajustement de stock dans l'édition du produit (propriétaire/gérant) pour corriger.

### « La balance étiqueteuse ne trouve pas le produit »
- Vérifiez le **code (PLU)** enregistré sur le produit (jusqu'à 5 chiffres, format `20PPPPPWWWWW`).
- Vérifiez que le produit est **actif** et dans le bon **magasin actif**.

---

## 4. Problèmes avec les produits et le stock

### « Le produit n'apparaît pas dans la liste / au PDV »
1. Tirez l'écran vers le bas pour **actualiser** la liste.
2. Vérifiez que vous êtes dans le bon **magasin actif** (Magasins → Réglages → Magasin actif).
3. Vérifiez que le produit n'est pas **désactivé** (Produits → Modifier → Produit actif).

### « Le stock est négatif ou erroné »
- Le système ne permet pas de vendre plus que ce qui existe — l'erreur « stock insuffisant » est le système qui vous protège.
- Corrigez les divergences via l'**ajustement manuel du stock** (édition du produit, propriétaire/gérant).

### « L'alerte de péremption n'apparaît pas »
- L'alerte apparaît quand le produit a une **date de péremption** définie (inscription ou achat avec lot).
- Les produits sans péremption ne génèrent jamais d'alerte.

---

## 5. Problèmes d'argent et de finances

### « Le solde de la caisse ne correspond pas »
1. Vérifiez s'il y a des **montants en attente** (recevoir/payer) pas encore confirmés — ils ne comptent que lorsque **Recevoir/Payer** est confirmé.
2. Les ventes **annulées** génèrent une annulation — la paire (vente + annulation) se solde à zéro.
3. Les achats et les dépenses sortent de la caisse — vérifiez qu'aucune dépense n'est oubliée.
4. Vérifiez le **magasin actif** — chaque magasin a une caisse séparée.

### « La clôture de caisse affiche un excédent/manque »
- L'**attendu dans le tiroir** ne tient compte que de **l'argent physique** (carte, M-Pesa, E-Mola, virement n'y figurent pas).
- **Excédent** : il peut y avoir de l'argent en trop (ex. : un client a payé plus, ou un paiement n'a pas été enregistré).
- **Manque** : vérifiez qu'un paiement en espèces n'a pas été oublié ou que de l'argent n'a pas été retiré du tiroir.
- Une erreur de comptage ? Vous pouvez **refaire la clôture du jour** — elle se met à jour sans doublon.

### « Je ne peux pas faire la clôture de caisse / enregistrer un achat »
- Ce sont des opérations de **gestion** (propriétaire/gérant). Les employés n'ont pas le bouton — demandez au propriétaire/gérant.

### « Le montant en attente n'entre pas en caisse quand je le reçois »
- En confirmant **Recevoir/Payer**, la transaction compte dans la caisse **réalisée**. Si elle ne compte pas, actualisez l'écran (tirez vers le bas) et vérifiez le magasin actif.

---

## 6. Problèmes de connexion et de synchronisation

### « Les données semblent anciennes / ne se mettent pas à jour »
1. **Tirez l'écran vers le bas** dans les listes pour actualiser.
2. Changez d'onglet puis revenez (l'app recharge en entrant sur l'écran).
3. Vérifiez l'internet du téléphone.

### « Sans internet, puis-je utiliser l'app ? »
- En mode **en ligne** (par défaut), l'app a besoin d'une connexion pour enregistrer les ventes, les produits, etc. Sans internet, les opérations échouent — réessayez quand la connexion revient.
- La **connexion** exige aussi internet.

### « L'app « charge » indéfiniment »
1. Vérifiez l'internet (testez en ouvrant une autre page/application).
2. Fermez l'app et rouvrez-la.
3. S'il s'agit de la **première ouverture** après une mise à jour, attendez — elle peut être en cours de synchronisation.

---

## 7. Problèmes de l'app (blocage, écran blanc, lenteur)

### « L'app se bloque ou se ferme toute seule »
1. Fermez l'app (glissez-la hors des applications récentes) et rouvrez-la.
2. **Redémarrez le téléphone** si cela continue.
3. Vérifiez le **stockage** du téléphone (très plein → app lente).
4. **Mettez à jour l'app** dans le magasin d'applications — les anciennes versions peuvent avoir des erreurs déjà corrigées.

### « Écran blanc / l'app ne s'ouvre pas »
1. Fermez et rouvrez l'app.
2. Vérifiez l'internet (l'écran de connexion en a besoin).
3. Si cela continue, **désinstallez et réinstallez** — vos données restent sur le serveur et reviennent à la connexion. Attention : Désinstaller **n'efface pas** les données de l'entreprise (elles sont dans le cloud), mais confirmez l'e-mail/mot de passe avant.

### « L'app a changé de langue / devise tout d'un coup »
- La **devise** et la **langue** sont définies par le propriétaire dans **Magasins → Réglages** et valent pour **toute l'entreprise**, immédiatement. Si c'est changé d'un coup, c'est une modification faite dans les réglages (ou sur un autre appareil avec le même compte de propriétaire) — il suffit de revenir dans **Magasins → Réglages** et de choisir à nouveau.

---

## 8. Messages d'erreur courants

> Les messages ci-dessous sont des **approximations** — la formulation exacte peut varier légèrement selon la version de l'app. Cherchez l'idée centrale.

| Message affiché (ex.) | Ce que cela signifie | Que faire |
|----------------------|-----------------|-------------|
| **« Impossible de se connecter. Vérifiez vos identifiants. »** | E-mail ou mot de passe erronés | Récupérez le mot de passe (« Mot de passe oublié ? ») ou vérifiez l'e-mail |
| **« Accès en attente d'approbation »** | Compte pas encore approuvé | Attendez l'approbation (dans les 24 h) ou contactez le support |
| **« Impossible d'ajouter le produit. Réessayez. »** | Erreur lors de l'enregistrement du produit | Vérifiez l'internet, les champs obligatoires et réessayez |
| **« Produit ajouté ! (photo non envoyée…) »** | Produit enregistré, mais la photo n'est pas montée | Ajoutez la photo plus tard via l'édition du produit |
| **« Stock insuffisant »** | Pas assez de stock pour la quantité | Réduisez la quantité, achetez plus ou ajustez le stock |
| **« Le total de la vente ne correspond pas aux articles »** | Somme des articles ≠ total | Revoyez les articles et le total avant de confirmer |
| **« Impossible d'annuler la vente. Réessayez. »** | Erreur lors de l'annulation | Vérifiez l'internet et que la vente est toujours active (non annulée) |
| **« Seul le propriétaire ou un gérant peuvent… »** | Opération réservée au propriétaire/gérant | Demandez au propriétaire/gérant de l'exécuter |
| **« Impossible de partager le reçu »** | Erreur lors du partage | Vérifiez que des apps de partage (WhatsApp) sont installées |
| **« Impossible d'exporter le rapport »** | Erreur lors de la génération du CSV/PDF | Réessayez ; si cela persiste, contactez le support |
| **« Session expirée / reconnectez-vous »** | L'ancienne session est terminée | Connectez-vous à nouveau |

---

## 9. Quand contacter le support

Contactez le support lorsque :

- Le message d'erreur **persiste** après avoir essayé les étapes ci-dessus.
- L'erreur concerne **l'argent** (caisse, clôture, ventes) et la différence n'est pas explicable.
- Vous suspectez des **données erronées sur le serveur** (ex. : une vente qui n'apparaît pas sur un autre appareil).
- L'app présente une erreur **nouvelle** ou un **comportement étrange** après une mise à jour.

**Pour aider le support, ayez sous la main :**
1. Le **message exact** affiché à l'écran (ou une capture d'écran).
2. Ce que vous étiez en train de faire quand l'erreur est survenue (ex. : « enregistrer une vente de 3 produits »).
3. Le **téléphone/modèle** et la **version de l'app** (Réglages du téléphone → Applications → Dumbhanengue).
4. Le **magasin** et l'**heure approximative** du problème.

---

*Basé sur le Guide de l'utilisateur — pour apprendre à utiliser l'app, consultez le [Guide de l'utilisateur](GUIDE_DE_L_UTILISATEUR.md).*
