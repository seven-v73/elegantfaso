# Release Candidate - ElegantStyle

Ce document sert de checklist avant les tests de deploiement. L'objectif est de figer les fonctionnalites, verifier les parcours sensibles, puis corriger uniquement les bugs bloquants.

## 0. Gate automatique

- [ ] `flutter pub get` passe sur une machine propre.
- [ ] `flutter analyze` passe sans issue.
- [ ] `flutter test` passe avec tous les tests metier.
- [ ] Le workflow GitHub `Flutter Quality Gate` passe sur pull request.
- [ ] Aucun changement sensible n'est fusionne si la quality gate est rouge.
- [ ] Les workflows Firebase Hosting generiques sont verifies: ils ne doivent pas remplacer la validation Flutter mobile.

## 1. Gel fonctionnel

- [ ] Ne plus ajouter de grosse fonctionnalite avant la fin des tests.
- [ ] Creer un commit de stabilisation identifiable.
- [ ] Verifier les fichiers supprimes et non suivis avec `git status --short`.
- [ ] Confirmer que `.env`, fichiers locaux et logs Firebase ne sont pas inclus dans le commit.
- [ ] Si `.env` apparait dans `git ls-files .env`, le retirer de l'index avec `git rm --cached .env` sans supprimer le fichier local.
- [ ] Confirmer que `.env` n'est pas declare dans `pubspec.yaml` afin de ne pas embarquer les cles dans l'APK/AAB.
- [ ] Rotater toute cle deja presente dans un `.env` local partage ou capture.
- [ ] Pour les builds de test, injecter seulement les variables non sensibles via `--dart-define` ou un backend.
- [ ] Confirmer que le bootstrap admin est desactive en release.
- [ ] Verifier que `google-services.json`, `.firebaserc` et `lib/firebase_options.dart` pointent vers le bon projet de test.
- [ ] Verifier que `firebase-debug.log`, captures, exports et fichiers de preuves ne sont pas suivis par Git.

## 2. Securite Firestore

- [ ] Deployer d'abord sur un projet Firebase de staging.
- [ ] Tester les rules avec Firebase Emulator.
- [ ] Tester en staging avec 4 comptes separes: client, boutique, createur, admin.
- [ ] Client: ne lit que ses commandes, achats, garde-robe, notifications et conversations.
- [ ] Vendeur: ne lit que ses commandes, retraits, produits ou creations.
- [ ] Vendeur: peut faire avancer une commande, sans modifier paiement, devise, montant ou solde.
- [ ] Client: ne peut pas modifier points, roles, badges, soldes ou droits Pro dans `users`.
- [ ] Admin seul: valide paiement, retrait, plan, boost, litige, commission et audit.
- [ ] `admin_audit_logs`, `platform_commissions`, `seller_subscriptions`, `pro_upgrade_requests`, `boost_campaigns` et `seller_withdrawal_requests` sont proteges.
- [ ] Les plans Pro/Signature et boosts ne peuvent pas etre actives par le mobile sans validation admin.
- [ ] Les logs admin ne peuvent pas etre modifies ou supprimes apres creation.

## 3. Paiement manuel securise

- [ ] Le client voit le bon moyen de paiement admin selon le choix.
- [ ] La reference de paiement est unique et visible au client et a l'admin.
- [ ] La preuve de paiement arrive dans la fiche admin.
- [ ] Validation admin cree une trace audit.
- [ ] Refus admin notifie le client.
- [ ] Litige bloque le solde vendeur.
- [ ] Reception client deplace le solde de `en attente` vers `disponible`.
- [ ] Retrait vendeur demande une preuve ou note admin apres transfert reel.
- [ ] L'interface publique utilise "solde", "retrait", "reversement", pas "wallet" si le cadre legal n'est pas valide.
- [ ] Double validation admin impossible: si la fiche a change, l'admin voit "deja traite" ou doit recharger.
- [ ] Retrait boutique/createur et retrait vide-dressing sont distingues dans l'admin.
- [ ] Les montants affiches au client, vendeur et admin utilisent la meme devise.

## 4. Parcours critiques a tester

1. Inscription client.
2. Inscription boutique.
3. Inscription createur.
4. Choix devise dans le profil.
5. Publication produit boutique.
6. Publication creation createur.
7. Shopping: produits et creations visibles.
8. Panier multi-vendeurs separe.
9. Checkout pour moi: achat ajoute a la garde-robe apres paiement valide.
10. Checkout pour un tiers: achat reste dans historique.
11. Admin valide paiement.
12. Vendeur confirme preparation puis livraison.
13. Client confirme reception.
14. Vendeur demande retrait.
15. Admin marque retrait paye.
16. Avis apres achat visible sur fiche produit.
17. Vide-dressing: annonce, chat, reservation, vente.
18. Vide-dressing: choix retrait ou conversion en points Style.
19. Plan Pro/Signature: paiement, preuve, validation admin.
20. Boost: paiement, validation admin, visibilite Salon.
21. Litige: ouverture, analyse admin, notification.

## 4.1 Parcours reels all-in-one

- [ ] Client decouvre dans le Salon, ouvre un profil, suit une boutique ou un createur, puis retrouve ce pro dans son espace client.
- [ ] Client cherche depuis la recherche globale et obtient produits, boutiques, ateliers, events et inspirations sans sortir de l'app.
- [ ] Client achete un produit boutique, admin valide, boutique prepare, client confirme reception, boutique demande retrait.
- [ ] Createur publie une creation, elle apparait dans Talents/Salon, un client envoie un message puis cree un RDV.
- [ ] Boutique publie un produit, il apparait dans Shopping, le panier utilise le bon vendeur et le bon stock.
- [ ] Vide-dressing client: publication visible dans Shopping, discussion, reservation, vente, retrait ou points Style.
- [ ] Forfait Pro expire: les avantages sont coupes, l'interface propose renouveler sans casser les donnees.
- [ ] Boost expire: le ranking n'est plus booste et l'UI n'affiche plus "actif".

## 5. Performance mobile

- [ ] Tester sur un telephone Android moyen de gamme.
- [ ] Tester sur petit ecran Android avec clavier ouvert: formulaires, drawers, bottom sheets, admin et paiements.
- [ ] Salon charge sans blocage perceptible.
- [ ] Shopping et Vide-dressing affichent des skeletons ou etats vides propres.
- [ ] Chat charge vite les derniers messages.
- [ ] Garde-robe reste fluide avec beaucoup de pieces.
- [ ] Images Cloudinary sont compressees et mises en cache.
- [ ] Ecrans lourds a surveiller: Admin, Communaute, Garde-robe, Vide-dressing, Virtual Try-On, Chat, Mensurations.

## 6. Connexion faible et offline

- [ ] L'app affiche un etat clair si la connexion est lente.
- [ ] Garde-robe et achats recents restent consultables si possible.
- [ ] Checkout et paiement ne doivent pas valider silencieusement en cas d'echec reseau.
- [ ] Les actions critiques affichent confirmation ou erreur explicite.
- [ ] Aucun bouton sensible ne reste bloquant sans message.

## 7. IA et services externes

- [ ] Utiliser des cles de test avec quotas limites.
- [ ] Ne pas exposer OpenAI/Gemini/Stability/Replicate/SerpAPI dans l'app publique; utiliser un proxy backend/Cloud Functions.
- [ ] Verifier fallback Iris si OpenAI/Gemini indisponible.
- [ ] Verifier fallback quiz si IA indisponible.
- [ ] Verifier que le Virtual Try-On n'empeche pas le Studio Style si API indisponible.
- [ ] Planifier le deplacement des cles sensibles vers Cloud Functions ou backend proxy avant production large.

## 8. Uploads et pieces jointes

- [ ] Les preuves de paiement acceptent uniquement des images sures.
- [ ] Les chats refusent archives, scripts, APK, fichiers code, anciens documents Office macro et cles.
- [ ] Les tailles max sont testees: images 8 Mo, documents 12 Mo, audio 20 Mo, video 80 Mo.
- [ ] Les URLs et textes libres refusent les schemas dangereux comme `javascript:`.

## 9. Notifications

- [ ] Notification interne creee pour paiement valide/refuse.
- [ ] Notification vendeur apres paiement valide.
- [ ] Notification client apres livraison.
- [ ] Notification client apres confirmation/annulation RDV.
- [ ] Notification admin pour retraits, litiges, plans et boosts.
- [ ] Notification pro avant expiration du forfait et apres expiration.
- [ ] `notification_outbox` est traitee par Cloud Functions.
- [ ] Les routes et `targetId` ouvrent le bon ecran.

## 9.1 Relecture UX finale

- [ ] Les boutons principaux sont uniques par ecran.
- [ ] Les boutons secondaires sont en tonal, icone claire ou menu selon l'importance.
- [ ] Les libelles sont humains: Publier, Voir, Preparer, Retirer, Ecrire.
- [ ] Les icones panier, boutique, shopping, createur, messages et carte sont distinctes.
- [ ] Les textes explicatifs longs sont retires des ecrans operationnels.
- [ ] Les etats vides ont une phrase courte et une action utile.
- [ ] Les ecrans Client, Boutique, Createur et Admin permettent de changer d'espace sans chercher.

## 10. Decision de sortie

Passer en test public seulement si:

- [ ] `flutter analyze` passe.
- [ ] `flutter test` passe.
- [ ] La quality gate GitHub passe.
- [ ] Firestore Rules validees sur emulator/staging.
- [ ] Les 21 parcours critiques sont testes sur vrai telephone.
- [ ] Les parcours all-in-one sont testes avec comptes separes.
- [ ] Aucun bug critique sur paiement, retrait, role, devise ou notification.
- [ ] Les donnees staging peuvent etre remises a zero proprement.
