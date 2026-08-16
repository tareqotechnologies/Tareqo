# Guide de l'utilisateur — Dumbhanengue ERP

Un guide simple et complet pour utiliser votre système de gestion au quotidien : stock, ventes, clients, argent et rapports — tout au même endroit.

> **Besoin de résoudre un problème ?** Consultez le [Dépannage (résolution de problèmes)](DEPANNAGE.md).

---

## 1. Se connecter au système

1. Ouvrez l'app **Dumbhanengue** sur votre téléphone.
2. Saisissez votre **e-mail** et votre **mot de passe**.
3. Touchez **Se connecter**.

> **Première fois ?** Touchez **« Pas encore de compte — s'inscrire »**, remplissez vos informations (nom, e-mail, mot de passe, nom de l'entreprise) et attendez l'**approbation** de votre accès — généralement dans les 24 h. Vous ne pouvez vous connecter qu'après approbation.

---

## 2. Écran d'accueil (Accueil)

L'écran d'accueil affiche le résumé de votre entreprise **dans le magasin actif** :

- **Total des ventes** du jour
- **Solde en caisse**
- **À recevoir (crédit)**
- **Stock en produits**
- **Alertes** ⚠️ (péremption) — voir ci-dessous

### Alertes de péremption
- 🟡 **Jaune** = le produit **va bientôt expirer** (moins de 30 jours de validité).
- 🔴 **Rouge** = le produit **a déjà expiré** et il reste du stock.
- Touchez l'alerte pour voir le produit et le lot concernés.

### Actions rapides
Les boutons principaux se trouvent sur l'écran d'accueil : **Nouvelle vente**, **Ajouter un produit**, **Enregistrer une transaction** et **Enregistrer un crédit**.

### Modules
Utilisez la barre inférieure (ou les cartes) pour naviguer : **Accueil**, **Ventes**, **Produits**, **Finances**, **Crédit**, **Clients**, **Magasins**, **Rapports**. Certains modules n'apparaissent que pour le **propriétaire/gérant** (ex. : Achats et Rapports).

---

## 3. Magasins — quel magasin est-ce que je consulte ?

Le système peut avoir **plusieurs magasins** (ex. : Magasin central, Magasin du quartier). Chaque magasin a **son propre stock, ses ventes et sa caisse**.

- L'**Accueil** affiche le nom du magasin actif.
- Pour changer : **Magasins** → onglet **Réglages** → section **« Magasin actif »** → touchez le magasin souhaité.
- Tout (stock, ventes, finances, rapports) affiche alors les données du magasin choisi.

> 💡 Avec un seul magasin, cette section n'apparaît pas — il n'y a rien à choisir.

---

## 4. Produits

### Enregistrer un produit
1. Ouvrez **Produits** → touchez **Nouveau produit**.
2. Renseignez le **nom** et, si vous voulez, la **description**.
3. Indiquez le prix d'**achat** et le prix de **vente**.
4. **Quantité en stock** : indiquez combien d'unités vous avez (ex. : `50`).
5. **Photo (facultatif)** : touchez la zone photo pour **prendre une photo** ou **choisir dans la galerie**. La photo apparaît dans la liste des produits et aide au moment du PDV.
6. **Péremption (facultatif)** : touchez **Définir la péremption** et choisissez la date d'expiration. Le système vous avertit quand elle approche.
7. **Vente au poids ?** Activez **« Vente au poids (fraction) »** pour les produits vendus au kilo/litre (ex. : riz en vrac, huile) et choisissez l'unité (kg, g, l, ml). La caisse accepte alors des quantités comme `1,75 kg`.
8. **Code-barres (PLU)** : facultatif — utilisé par les balances étiqueteuses (format `20PPPPPWWWWW`).
9. Touchez **Ajouter le produit**.

### Modifier / désactiver un produit
- Touchez un produit dans la liste → **Modifier le produit**.
- Vous pouvez modifier le nom, les prix, le stock (**ajustement manuel**), la photo, la péremption et le statut **Produit actif**.
- **Désactiver** (`Produit actif` désactivé) : le produit disparaît du PDV et des achats, mais **reste dans l'historique** avec son stock conservé — vous pouvez le réactiver plus tard.
- Pour retirer la photo, touchez **Retirer la photo**.

> ⚠️ Si la photo ne s'envoie pas (ex. : sans internet), le produit est enregistré quand même — vous verrez un avertissement et pourrez ajouter la photo plus tard via l'édition.

---

## 5. Ventes (PDV)

1. Touchez **Nouvelle vente**.
2. Recherchez le produit ou **passez le code-barres** (caméra ou balance étiqueteuse).
3. Ajustez la **quantité** (les produits au poids acceptent les décimales : `1,75`).
4. Choisissez le **moyen de paiement** : Espèces, Carte de débit, Carte de crédit, M-Pesa, E-Mola ou Virement.
5. Touchez **Confirmer la vente**.

> ✅ Le stock est déduit automatiquement — **d'abord le lot le plus ancien** (FIFO), pour que rien n'expire en rayon.

### Reçu et partage
- Touchez une vente dans la liste pour voir le **détail** (articles, total, moyen de paiement).
- **Partager le reçu** : générez le reçu de la vente et partagez-le par **WhatsApp** ou une autre app (il est aussi possible de le partager en **image**).

### Annuler une vente (propriétaire/gérant uniquement)
Si une vente a été faite par erreur :
1. Ouvrez le **détail** de la vente → **Annuler la vente** → confirmez.
2. Le stock **revient aux lots exacts** qui ont été vendus (péremption et coût préservés) et la caisse est **annulée**.
3. La vente **reste dans l'historique** avec la mention « Annulée » (pour l'audit), mais **sort des rapports, des KPI et du résumé du jour**.

---

## 6. Achats (entrée de marchandise) — propriétaire/gérant

1. Touchez **Nouvel achat**.
2. Indiquez le **fournisseur**.
3. Ajoutez les produits achetés et les quantités.
4. **Péremption (facultatif)** : pour les produits périssables, choisissez la date du lot.
5. Confirmez l'achat. Le stock augmente immédiatement et la dépense sort de la caisse.

---

## 7. Clients et Crédit (fiado)

- **Clients** : enregistrez vos clients avec nom, téléphone et e-mail.
- **Enregistrer un crédit** : quand un client emporte de la marchandise à payer plus tard, enregistrez le montant et l'échéance.
- Sur l'écran **Crédit** vous voyez :
  - **En attente** = qui doit encore (total à recevoir).
  - **Soldées** = l'historique de ceux qui ont déjà payé.
- Quand le client paie, touchez **Soldé la dette** — l'argent **entre automatiquement en caisse**.

---

## 8. Finances

- **Enregistrer une transaction** : entrées (l'argent qui entre) et sorties (factures, dépenses).
- **En attente** : cochez si le montant n'a pas encore été reçu/payé — il ne compte dans la caisse **réalisée** que lorsqu'il est reçu/payé.
- L'écran affiche les **entrées**, les **sorties** et le **solde**.
- Pour les montants en attente :
  - **Recevoir** (entrées en attente) : confirme que l'argent est entré → il compte dans la caisse.
  - **Payer** (sorties en attente — factures à payer) : confirme le paiement → il compte dans la caisse.

### Clôture de caisse du jour (Z-report) — propriétaire/gérant
Dans **Finances**, touchez la carte **Clôture de caisse** (ou l'action en haut) :

1. L'app affiche le **résumé du jour** : ventes totales, **attendu dans le tiroir** (uniquement l'argent physique — carte, M-Pesa, E-Mola et virement ne passent pas par le tiroir) et la répartition **par moyen de paiement**.
2. **Comptez l'argent physique** du tiroir et saisissez le montant dans **Espèces comptées**.
3. L'app affiche la **différence** en temps réel : **Caisse juste**, **Excédent** ou **Manque**.
4. Touchez **Confirmer la clôture**.

> 💡 Une erreur de comptage ? Vous pouvez **refaire la clôture du jour** — le montant est mis à jour, sans doublon. Après la clôture, le badge **« Caisse fermée ! »** apparaît dans Finances.

---

## 9. Rapports — propriétaire/gérant

Consultez les performances de l'entreprise :

- **Chiffre d'affaires** (combien vendu sur la période)
- **Bénéfice brut** et **marge**
- **Meilleures ventes** (les produits qui sortent le plus)
- **Ventes par jour**

Utilisez les filtres : **Aujourd'hui**, **7 jours**, **Ce mois-ci**, **Tout**.

### Exporter et partager
Touchez **Exporter** → choisissez **Exporter en CSV** ou **Exporter en PDF**. Le rapport est généré et vous pouvez le **partager** par WhatsApp, e-mail ou l'enregistrer sur le téléphone.

---

## 10. Magasins et Employés (propriétaire/gérant)

Ouvrez **Magasins** (carte sur l'Accueil) — 4 onglets :

- **Magasins** : enregistrez vos magasins. Chaque magasin a son propre stock et sa propre caisse.
- **Employés** : créez des comptes pour ceux qui travaillent avec vous et choisissez le poste :
  - **Gérant** : opère tout, sauf la gestion des magasins/employés.
  - **Employé** : ne fait que vendre (n'enregistre pas les produits, ne voit pas les rapports, ne fait ni achats, ni clôture de caisse, ni annulations).
  - Désactivez un employé à tout moment — il **perd l'accès immédiatement**.
- **Upgrades** : consultez et demandez le changement de forfait.
- **Réglages** : changez le **Magasin actif**, la **devise** (MZN, BRL, USD, EUR) et la **langue** (Português/English/Français).

---

## 11. Conseils rapides

- 🧾 Vérifiez toujours le **total** avant de confirmer une vente.
- ⚠️ Surveillez les **alertes de péremption** chaque semaine — un produit périmé, c'est de la perte.
- 📱 Dans n'importe quelle liste (ventes, produits, clients...) **tirez l'écran vers le bas** pour actualiser.
- 🖼️ Les produits avec **photo** sont bien plus faciles à identifier au PDV.
- 🔒 L'app garde votre session en sécurité — vous ne vous connectez qu'une fois.
- 💡 Besoin de connexion pour vendre ? **Oui** (en mode en ligne) — les ventes sont enregistrées immédiatement.

---

## 12. Questions fréquentes (FAQ)

**J'ai oublié mon mot de passe.**
Touchez **« Mot de passe oublié ? »** sur l'écran de connexion et suivez le lien envoyé par e-mail.

**Je me suis inscrit mais je ne peux pas me connecter.**
Votre accès doit être **approuvé** par l'administrateur (dans les 24 h). Vérifiez aussi que l'e-mail/mot de passe sont corrects. Si plus de 24 h sont passées, contactez le support.

**Un employé désactivé peut-il encore se connecter ?**
Pas pour longtemps : l'accès est **coupé immédiatement** quand le propriétaire le désactive. Si l'ancienne session est encore ouverte, fermez et rouvrez l'app.

**J'ai vendu par erreur. Comment annuler ?**
Ouvrez la vente → **Annuler la vente** (propriétaire/gérant uniquement). Le stock revient aux bons lots et la caisse est annulée. La vente reste dans l'historique marquée comme **Annulée**.

**Mon stock ne correspond pas à ce que j'ai compté.**
Vérifiez qu'il n'y a pas eu de ventes non annulées, d'achats ou d'ajustements manuels de stock lors de l'édition du produit. Pour corriger une petite divergence, utilisez l'**ajustement de stock** dans l'édition du produit (propriétaire/gérant).

**La photo du produit n'apparaît pas.**
La photo a peut-être mal été envoyée par manque de connexion au moment de l'enregistrement (le produit est quand même enregistré). Ouvrez le produit → **Modifier le produit** → ajoutez à nouveau la photo. Si le problème persiste, consultez le [Dépannage](DEPANNAGE.md).

**La clôture de caisse affiche un « Manque » d'argent.**
L'« attendu dans le tiroir » ne tient compte que des **ventes en espèces** — carte, M-Pesa, E-Mola et virement n'y figurent pas. Vérifiez qu'un paiement en espèces n'a pas été oublié ou que de l'argent n'a pas été retiré du tiroir.

**Puis-je avoir plusieurs magasins ?**
Oui — le nombre de magasins dépend de votre **forfait** (voir **Magasins → Upgrades**). Chaque magasin a un stock, des ventes et une caisse séparés.

**Les ventes annulées comptent-elles dans les rapports ?**
Non. Les ventes annulées restent dans l'historique (audit), mais **sortent** du chiffre d'affaires, des KPI et du résumé du jour.

**Puis-je exporter les rapports ?**
Oui — **Exporter en CSV** ou **Exporter en PDF** sur l'écran Rapports, et partager par WhatsApp, e-mail, etc.

**L'app a changé de langue/devise tout d'un coup ?**
La devise et la langue sont définies par le propriétaire dans **Magasins → Réglages** et valent pour toute l'entreprise, immédiatement. Si c'est changé, c'est qu'une modification a été faite dans les réglages — vous pouvez les re-modifier là.

---

*Des questions absentes de cette page ? Consultez le [Dépannage](DEPANNAGE.md) ou parlez au propriétaire de l'établissement / au support.*
