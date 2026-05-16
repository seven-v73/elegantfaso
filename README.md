# ElegantStyle

ElegantStyle est une application Flutter de mode, marketplace et accompagnement stylistique pensée comme un **compte unique avec plusieurs espaces cohérents**.

La solution n'est plus limitée au Burkina Faso. Elle vise une expérience mondiale, tout en gardant une vraie proximité locale : créateurs, boutiques, traditions textiles, coiffures, chaussures, événements, inspirations culturelles et modernité urbaine.

## Vision Produit

ElegantStyle doit être compris comme une seule plateforme, pas comme une addition de fonctionnalités séparées.

La logique cible :

- **Salon** : place publique transversale pour découvrir, chercher, acheter, suivre, apprendre et s'inspirer.
- **Client** : espace personnel pour souhaits, garde-robe, style, commandes, messages, fidélité et progression.
- **Créateur** : atelier professionnel pour créations, rendez-vous, clients, visibilité Salon et performance.
- **Boutique** : cockpit commercial pour produits, commandes, clients, rendez-vous et visibilité Salon.
- **Admin** : modération, validation, gouvernance et sécurité.

Le Salon expose ce que les autres espaces produisent ou consomment. Il ne remplace pas les dashboards métier.

Pour les comptes professionnels, la publication ne doit pas dépendre d'un
formulaire long. ElegantStyle intègre donc une logique **Catalogue Express** :
les boutiques et créateurs peuvent importer plusieurs photos, appliquer un
modèle commun, créer des brouillons puis enrichir les fiches importantes plus
tard. L'objectif est de respecter leur réalité terrain : boutique pleine,
atelier occupé, photos déjà prêtes dans la galerie ou WhatsApp.

Workflow produit recommandé :

```text
Découvrir -> Sauvegarder -> Comprendre mon style -> Essayer -> Commander / Contacter -> Suivre
```

## Avancée Actuelle

La base a été consolidée autour de quatre fondations :

- un compte unique multi-rôle avec `activeRole`;
- un Salon mondial qui reste connecté au local grâce à la recherche, aux lieux, aux talents, aux boutiques et aux événements;
- une gestion média centralisée avec Cloudinary et registre Firestore;
- des services transversaux pour commerce, fidélité, boosts, notifications et actions utilisateur.

État vérifié récemment :

- `flutter analyze` global : OK;
- `flutter test` : 98 tests passent;
- `firebase deploy --only firestore:rules --dry-run` : règles Firestore compilées avec succès;
- les services commerce, coupons, boosts, médias Cloudinary, rôles, contexte Salon, paiements gérés, notifications, essayage, vide-dressing, plans Pro/Signature et gouvernance Communauté disposent déjà de tests ciblés;
- plusieurs gros écrans ont été découpés pour réduire la dette UI sans changer le comportement visible.

Dernières passes avant phase test :

- Iris peut utiliser OpenAI ou Gemini selon `.env`, avec fallback local si les services IA sont indisponibles;
- Iris et le conseiller Style tiennent compte de la localisation enregistrée quand elle existe;
- l'écran Recommandations / Iris Style a été simplifié en parcours vertical mobile-first, sans onglets techniques en haut;
- le bouton retour de l'écran Recommandations est visible dans l'AppBar;
- le paiement manuel sécurisé est structuré autour d'une référence unique, d'une preuve, d'une validation admin, d'un solde vendeur en attente puis disponible;
- l'admin dispose d'une recherche globale, d'une file `À traiter`, d'un journal audit filtrable, de fiches détail, d'un espace litiges et d'une checklist commerce;
- l'admin mobile dispose maintenant d'une navigation plus courte, d'une file de décision, d'une recherche comptes filtrable et de cartes plus compactes;
- les règles Firestore ont été durcies sur les rôles, les soldes, les commandes, les retraits, les commissions et les journaux admin;
- la prochaine étape est une phase **Release Candidate** organisée par parcours utilisateur, pas l'ajout massif de nouvelles fonctionnalités.

## Compte Unique et Multi-Rôle

Le modèle retenu est un compte unique avec des rôles cumulables.

Par défaut, tout utilisateur démarre comme client. Depuis son espace, il peut ensuite activer :

- un espace créateur;
- un espace boutique;
- ou les deux.

La source de vérité est :

```text
lib/core/account_roles.dart
```

Règles :

- `roles` indique les espaces activés sur le compte;
- `activeRole` indique l'espace actuellement utilisé;
- `role` reste un champ legacy de compatibilité;
- un utilisateur reste toujours client par défaut;
- les rôles créateur et boutique s'activent via onboarding.

Le routage principal passe par :

```text
lib/views/screens/app/workspace_router.dart
lib/services/app/workspace_router_service.dart
```

Résolution attendue :

```text
activeRole client   -> HomeScreen
activeRole createur -> CreateurDashboardScreen
activeRole boutique -> BoutiqueDashboard
activeRole admin    -> AdminApp
visiteur            -> Salon public
```

Les permissions transversales passent par :

```text
lib/services/app/user_capability_service.dart
lib/services/app/app_action_service.dart
```

Exemples :

- un visiteur peut explorer le Salon mais doit se connecter pour sauvegarder, commander ou contacter;
- un créateur ou une boutique ne doit pas acheter son propre contenu;
- un client peut acheter, sauvegarder, contacter et prendre rendez-vous;
- un créateur peut publier ou masquer ses créations;
- une boutique peut gérer produits, commandes et visibilité;
- l'admin garde les actions de modération.


## Design System

La charte officielle est décrite dans [style.md](style.md).

Les écrans doivent respecter :

- fond global clair `#F3F5F7`;
- surfaces blanches sobres;
- CTA principal teal `#0F766E`;
- accents limités selon le rôle;
- icônes Material Rounded;
- cartes lisibles avec relief léger;
- textes courts et orientés action;
- navigation mobile prévisible.

Composants à privilégier :

```text
lib/design/modern_design_system.dart
lib/design/ecommerce_widgets.dart
```

Déclinaisons :

- Client : accent bleu en soutien, CTA teal;
- Créateur : accent violet;
- Boutique : accent orange;
- Salon : teal + accents selon le type de contenu;
- Admin : sobriété foncée.

## Architecture Data

La stratégie actuelle est :

```text
Firebase Auth + Cloud Firestore + Cloudinary
```

Firebase reste le coeur de l'identité et des données métier. Cloudinary est prévu pour prendre en charge les médias lourds afin d'éviter de dépendre de Firebase Storage.

Un document plus détaillé existe dans [schemaDB.md](schemaDB.md).

### Firebase Authentication

Firebase Auth gère :

- inscription;
- connexion;
- session utilisateur;
- fournisseurs externes comme Google Sign-In;
- UID unique utilisé dans Firestore.

Flux actuels :

- inscription email/mot de passe;
- connexion email/mot de passe;
- inscription et connexion Google;
- bootstrap admin contrôlé par `.env`;
- création ou mise à jour automatique du document `users/{uid}`;
- envoi d'un email de bienvenue via une file Firestore.

Fichiers liés :

```text
lib/data/repositories/auth_repository.dart
lib/services/auth/welcome_email_service.dart
lib/views/screens/auth/login_screen.dart
lib/views/screens/auth/register_screen.dart
```

L'email de bienvenue est écrit dans :

```text
mail/welcome_{uid}
```

L'application mobile ne contient pas de secret SMTP. L'envoi réel doit être assuré par Firebase Trigger Email Extension ou par une Cloud Function/backend qui consomme la collection `mail`.

### Cloud Firestore

Firestore stocke :

- profils utilisateurs;
- profils publics d'affichage;
- rôles actifs;
- profils créateur et boutique;
- produits;
- créations;
- brouillons issus de Catalogue Express;
- rendez-vous;
- conversations et messages;
- notifications;
- file push `notification_outbox`;
- garde-robe;
- souhaits et favoris;
- diagnostic style;
- gamification et points fidélité;
- coupons checkout et règles fidélité administrables;
- références vers les médias.

La collection centrale est :

```text
users/{uid}
```

Champs et sous-collections importants :

```text
users/{uid}
  roles
  activeRole
  roleFlags
  styleProfile
  gamification

users/{uid}/style_profile/main
  title
  description
  scores
  answers
  tags
  recommendations

users/{uid}/wardrobe/{itemId}
users/{uid}/saved_items/{itemId}
users/{uid}/wishlist/{itemId}
users/{uid}/loyalty_activity/{activityId}

public_profiles/{uid}
  displayName
  photoUrl
  roles
  primaryRole
  city
  specialty
  isVerified
  rating
  secondhandListings
  secondhandSold

notifications/{notificationId}
  userId
  recipientId
  createdBy
  title
  body
  type
  route
  data
  read
  createdAt

notification_outbox/{outboxId}
  notificationId
  recipientId
  title
  body
  type
  data
  status: queued | sent | failed
  attempts

checkout_coupons/{code}
  code
  type: percent | fixedAmount | freeShipping
  value
  active
  minSubtotal
  maxDiscount
  startsAt
  endsAt

loyalty_rules/{ruleId}
  label
  percent
  minPoints
  active

community_questions/{questionId}
  userId
  userName
  question
  category
  groupId
  groupName
  status: published | hidden | deleted
  isPublic
  isDeleted
  likesCount
  answersCount
  media
  createdAt / timestamp

community_questions/{questionId}/replies/{replyId}
  userId
  reply
  parentReplyId
  status
  isDeleted
  media

community_groups/{groupId}
  name
  slug
  description
  category
  city
  country
  ownerId
  ownerName
  status: pending | approved | rejected | suspended | closed
  accessMode: open | request | invite_only | closed
  memberIds
  memberCount
  rules
  reviewReason

community_groups/{groupId}/members/{userId}
  userId
  userName
  role: owner | moderator | member
  status: active | blocked | pending
  joinedAt

community_groups/{groupId}/join_requests/{userId}
  userId
  userName
  message
  status: pending | approved | rejected
  createdAt
  decidedAt

community_settings/main
  mode: public | members_only | restricted | closed
  reason
  allowedUserIds
  blockedUserIds
  lockedUntil
```

### Cloudinary

Cloudinary est maintenant la cible centrale pour stocker :

- photos de profil;
- logos boutiques;
- images produits;
- images de créations;
- vidéos;
- médias de chat;
- stories;
- éléments de garde-robe.

Firestore doit garder uniquement les URLs et identifiants `publicId`.

Services :

```text
lib/services/media/media_upload_service.dart
lib/services/media/media_asset_service.dart
```

Le service média produit :

- `secureUrl`;
- `optimizedUrl`;
- `thumbnailUrl`;
- `publicId`;
- `resourceType`;
- métadonnées utiles pour Firestore.

Les uploads sont organisés par dossiers métier via `CLOUDINARY_FOLDER_ROOT`, par exemple :

```text
elegantstyle/users/{uid}/profile
elegantstyle/boutiques/{uid}/products
elegantstyle/createurs/{uid}/creations
elegantstyle/wardrobe/{uid}
elegantstyle/messages/{uid}
```

Chaque média important peut être enregistré dans :

```text
media_assets/{mediaId}
```

Ce registre permet de retrouver le propriétaire, l'usage, la collection liée, le statut public/privé et les URLs optimisées.

Firebase Storage ne doit rester qu'un héritage à éliminer progressivement.

### Notifications

Le système de notifications est désormais séparé en deux niveaux :

1. **Notifications in-app** : affichées dans l'application depuis Firestore.
2. **Outbox push** : documents à traiter par un backend ou une Cloud Function pour envoyer les push FCM.

Fichiers principaux :

```text
lib/models/notifications/app_notification.dart
lib/services/notifications/app_notification_service.dart
lib/views/screens/notifications/notifications_screen.dart
```

Collections :

```text
notifications/{notificationId}
notification_outbox/{outboxId}
users/{uid}.fcmTokens
users/{uid}/devices/{tokenId}
```

Cas déjà branchés :

- messages;
- partage de mensurations;
- compteur de notifications dans les cockpits;
- page notifications réutilisable;
- écran notifications Boutique avec état vide natif, sans dépendre d'un asset image externe manquant.

Important : l'application mobile ne doit pas appeler directement l'API serveur FCM avec une clé privée. Elle crée une entrée dans `notification_outbox`. Une Cloud Function doit ensuite :

1. lire le document;
2. récupérer les tokens du destinataire;
3. envoyer le push;
4. marquer `status: sent` ou `status: failed`.

La Cloud Function `sendQueuedNotification` existe dans `functions/index.js` et traite `notification_outbox/{outboxId}`. Elle récupère les tokens dans `users/{uid}` et `users/{uid}/devices`, envoie via Firebase Admin Messaging, nettoie les tokens invalides et met à jour le statut de l'outbox.

Les notifications métier doivent être actionnables. Une notification doit autant que possible contenir :

```text
type
priority
route
actionLabel
data.targetType
data.targetId
expiresAt si utile
```

Événements prioritaires :

- paiement reçu, validé ou refusé;
- commande prête, livrée ou en attente de confirmation client;
- retrait demandé, payé ou bloqué;
- litige ouvert ou passé en analyse;
- plan Pro/Signature validé;
- boost activé;
- message reçu;
- annonce Vide-dressing réservée ou vendue;
- quiz quotidien, badge ou niveau de visibilité atteint.

## Espaces Fonctionnels

### Salon

Le Salon est la place publique de l'application.

Il contient :

- Exploration;
- Shopping;
- Talents;
- Inspiration;
- Agenda / Events;
- recherche unifiée;
- fiches universelles;
- panier et checkout;
- coupons Firestore;
- règles fidélité pilotables;
- commissions marketplace;
- abonnements Pro/Signature;
- boosts de visibilité;
- recommandations liées.

Architecture Salon :

```text
lib/models/salon/
lib/services/salon/
lib/views/screens/global/salon_mode_burkinabe.dart
lib/views/screens/global/tabs/
lib/views/screens/global/widgets/salon/
lib/views/screens/global/widgets/shop/
lib/views/screens/global/widgets/talents/
lib/views/screens/global/widgets/events/
lib/views/screens/global/widgets/inspiration/
```

Le checkout lit les promotions depuis Firestore via :

```text
lib/models/commerce/checkout_promotion.dart
lib/models/commerce/platform_revenue.dart
lib/services/commerce/checkout_promotion_service.dart
lib/services/commerce/commerce_revenue_service.dart
lib/services/admin/admin_commerce_config_service.dart
```

Collections admin recommandées :

- `platform_settings/commerce` pour taux de commission, frais RDV, boosts et prix Pro;
- `checkout_coupons` pour les codes promo;
- `loyalty_rules` pour les seuils de points et pourcentages;
- `seller_subscriptions` pour les plans créateurs/boutiques;
- `boost_campaigns` pour les mises en avant Salon;
- `platform_commissions` pour le suivi commission et reversement vendeur;
- fallback local uniquement si Firestore n'est pas encore configuré.

Chaque commande conserve maintenant :

```text
subtotal
deliveryFee
serviceFee
discount
commissionRatePercent
platformCommission
sellerPayout
grandTotal
```

L'administration peut piloter cette monétisation depuis Paramètres -> Commerce & monétisation.

### Paiement Manuel Sécurisé

Le paiement intégré par agrégateur n'est pas encore le coeur de la solution. La logique actuelle privilégie un flux manuel plus contrôlé :

```text
Client commande
-> l'app génère une référence unique
-> le client paie sur un moyen admin configuré
-> le client joint une preuve
-> l'admin vérifie et valide ou refuse
-> le vendeur traite la commande
-> le client confirme réception
-> le solde vendeur devient disponible
-> le vendeur demande un retrait
-> l'admin transfère réellement et marque le retrait payé
```

Vocabulaire recommandé dans l'interface :

- `solde en attente`;
- `solde disponible`;
- `demande de retrait`;
- `reversement vendeur`;
- `litige`;
- éviter `wallet` dans l'interface publique tant que le cadre légal n'est pas validé.

Collections liées :

```text
orders
platform_commissions
seller_withdrawal_requests
admin_audit_logs
notifications
notification_outbox
```

Statuts sensibles :

```text
paymentStatus: client_marked_paid | paid | payment_rejected | dispute
orderStatus: awaiting_admin_payment_confirmation | pending_seller_confirmation | delivered_by_seller | received_by_customer | dispute | dispute_review
sellerBalanceStatus: not_funded | pending_delivery | available | withdrawal_requested | withdrawn | disputed
managedPaymentStatus: client_marked_paid | payment_confirmed_by_admin | withdrawal_available | withdrawal_requested | completed
```

Règles importantes :

- un client ne modifie pas son solde, ses points ou ses droits Pro;
- un vendeur peut faire avancer une commande, mais ne peut pas modifier paiement, devise, total, commission ou solde;
- `platform_commissions` est réservé à l'administration;
- une demande de retrait doit correspondre à une commande ou annonce réellement disponible, avec le bon vendeur et le bon montant;
- chaque validation/refus/litige/retrait admin crée une trace audit.

Le nom historique `salon_mode_burkinabe.dart` reste pour compatibilité, mais la vision produit est désormais mondiale.

### Client

L'espace Client est un assistant personnel mode.

Navigation cible :

```text
Salon | Aujourd'hui | Style | Garde-robe | Profil
```

Fonctionnalités :

- cockpit `Aujourd'hui`;
- Salon public embarqué;
- Studio Style;
- profil client dynamique;
- souhaits et favoris;
- garde-robe;
- mensurations;
- essayage virtuel;
- commandes;
- messages;
- points fidélité;
- défis quotidiens;
- assistant IA Iris;
- essayage virtuel multi-source;
- recommandations Iris Style avec parcours vertical : demande, génération, palette, historique et sauvegarde.

Fichiers structurants :

```text
lib/views/screens/client/home/home_screen.dart
lib/views/screens/client/home/client_today_screen.dart
lib/views/screens/base/client_profile_screen.dart
lib/views/screens/client/features/style/style_hub_screen.dart
lib/views/screens/client/features/style/garde_robe.dart
lib/views/screens/client/features/style/fashion_assistant.dart
lib/views/screens/client/features/virtual_try_on_screen.dart
lib/services/client/client_dashboard_service.dart
lib/services/client/client_gamification_service.dart
```

Le profil client ne doit pas être un mini-hub statique. Il affiche les données réelles : garde-robe, souhaits, mensurations, messages, commandes, points d'entrée Style et paramètres.

#### Iris Style et Recommandations

L'écran Recommandations est maintenant organisé comme un parcours vertical mobile-first.

Structure :

```text
AppBar avec retour visible
Dashboard Iris Style
Prompts rapides
Formulaire de demande
Résultat généré
Palette intelligente
Historique récent
```

Objectifs UX :

- éviter les onglets techniques `Assistant`, `Palette`, `Historique`;
- garder l'assistant comme parcours principal;
- afficher la palette et l'historique comme des sections naturelles;
- faciliter le retour vers l'écran précédent depuis le profil ou le Studio Style.

Iris Style utilise :

- OpenAI ou Gemini selon `.env`;
- la localisation enregistrée;
- la garde-robe;
- les mensurations;
- les dernières consultations;
- un fallback local si les services IA ne répondent pas.

#### Essayage Virtuel

L'essayage est repositionné comme un **Studio d'essayage** avec plusieurs niveaux de réalisme.

Modes recommandés :

- **Aperçu libre** : overlay manuel, rapide, utile pour sacs, chaussures, accessoires et pièces non compatibles IA;
- **Accessoires visage** : lunettes, chapeaux, bijoux proches du visage, foulards, avec une piste gratuite/offline via Google ML Kit;
- **Vêtement IA** : robes, hauts, vestes, ensembles, à garder expérimental ou backendisé;
- **Studio Style** : moodboard, conseil Iris, sauvegarde et partage communauté si l'essayage IA échoue.

L'écran permet de sélectionner :

- la photo de la personne depuis la galerie;
- un vêtement depuis les produits du Salon;
- une création;
- une image locale depuis la galerie;
- une pièce de garde-robe ou un souhait, selon disponibilité des données.

État actuel :

- produits, créations et galerie sont branchés;
- les images réseau et fichiers locaux sont pris en charge;
- le modèle `WardrobeItem` lit plusieurs formats d'image (`images`, `imageUrl`, `image`, `photoUrl`, `url`, `media.secureUrl`, `media.optimizedUrl`, `media.thumbnailUrl`);
- le chargement Garde-robe/Souhaits cherche plusieurs chemins Firestore (`users/{uid}/wardrobe`, `wardrobe_items`, `wardrobe`, `saved_items`, `wishlist`, `souhaits`) et plusieurs champs propriétaire (`userId`, `ownerId`, `clientId`, `uid`).

Points à surveiller :

- comparer un document réel de garde-robe/souhait avec le mapping de `VirtualTryOnScreen`;
- garder les clés Replicate/Segmind hors du mobile avant production publique;
- prévoir un backend pour l'essayage IA vêtement;
- ne jamais bloquer le Studio Style si le service IA est indisponible.

### Parcours Style

La gamification client est présentée comme un **Parcours Style**. Elle n'est
pas un onglet séparé: elle est une couche de motivation dans `Aujourd'hui`,
le Salon, la garde-robe, le Vide-dressing et les échanges.

Elle encourage le workflow :

```text
Apprendre -> Explorer -> Partager -> Rencontrer -> Contribuer
```

Éléments actuels :

- défi quotidien;
- quiz style du jour;
- points répartis par familles;
- streak;
- badges;
- visibilité Vide-dressing selon le niveau;
- actions de continuité après quiz vers Salon, Iris et messages.

Familles de points :

```text
Style       quiz, essayage, Iris, garde-robe
Découverte  Salon, créateurs, boutiques, stories, inspirations
Communauté  échanges utiles, conseils, entraide
Confiance   profil, avis, ventes fiables, mensurations
```

Le quiz quotidien ne s'arrête plus au score. Après validation, l'utilisateur
voit ce qu'il a appris, les notions à revoir, puis des actions naturelles :

- voir une sélection du Salon liée au thème;
- demander un conseil à Iris;
- créer ou continuer un échange utile.

Principe UX :

```text
Plus tu apprends, partages et contribues avec bienveillance,
plus ton style devient visible.
```

Fichiers :

```text
lib/models/client/gamification/
  daily_quiz_model.dart
  quiz_question_model.dart
  daily_challenge_model.dart
  style_badge_model.dart
  style_progress_model.dart

lib/services/client/
  daily_quiz_service.dart
  client_gamification_service.dart

lib/views/screens/client/widgets/
  client_daily_challenge_card.dart
  client_style_progress_panel.dart
```

Les points sont stockés dans :

```text
users/{uid}.gamification
users/{uid}.gamification.pointBuckets
users/{uid}/loyalty_activity/{activityId}
```

Règle UX : les points doivent récompenser des actions utiles, pas du temps perdu dans l'app.

### Inspiration et Diagnostic Style

Le quiz Inspiration est repositionné en **Diagnostic style**.

Objectif :

- comprendre le style profond de l'utilisateur;
- équilibrer tradition, modernité, usage réel et préférences;
- rester mondial sans effacer les traditions locales;
- sauvegarder un profil durable dans le dashboard.

Fichiers :

```text
lib/views/screens/global/widgets/inspiration/style_quiz.dart
lib/views/screens/global/widgets/inspiration/style_advisor_section.dart
```

Le résultat est sauvegardé dans :

```text
users/{uid}/style_profile/main
users/{uid}.styleProfile
```

Le diagnostic peut donner un bonus fidélité limité :

- première sauvegarde : bonus plus fort;
- mise à jour après plusieurs jours : bonus léger;
- pas de farming quotidien.

Différence avec le quiz quotidien :

```text
Quiz quotidien -> fidélité, routine rapide, points.
Diagnostic style -> profil durable, recommandations, personnalisation.
```

### Guides Style

La section Tutoriels YouTube est remplacée par **Guides Style** dans
Inspiration. YouTube reste une source externe complémentaire, mais la lecture
inline WebView/iFrame n'est plus le coeur de l'expérience.

Objectif :

- proposer des guides courts, fiables et mobile-first;
- apprendre un geste, une matière, une association ou un entretien;
- relier les guides au quiz quotidien, aux créations, aux produits et aux
  stories pro;
- permettre aux boutiques et créateurs certifiés de publier des mini-guides.

Fichiers :

```text
lib/models/inspiration/style_guide.dart
lib/services/inspiration/style_guide_service.dart
lib/views/screens/global/widgets/inspiration/video_tutorials_section.dart
lib/views/screens/commerce/pro_style_guide_composer_screen.dart
```

Structure Firestore :

```text
style_guides/{guideId}
  title
  subtitle
  category
  steps
  imageUrl
  videoUrl
  authorId
  authorRole
  authorName
  linkedProducts
  linkedCreations
  status
  visibility
```

Règle produit :

```text
Guides natifs -> coeur de l'expérience.
YouTube -> ouverture externe seulement.
```

### Communauté

L'espace Communauté est maintenant pensé comme un hub social mobile-first, intégré à l'onglet Inspiration du Salon.

Il comprend trois niveaux :

- **Générale** : discussion ouverte autour de la mode, des conseils et des inspirations;
- **Mes communautés** : groupes rejoints ou gérés par l'utilisateur;
- **Découvrir** : communautés locales, métiers ou cultures mode validées par l'admin.

Exemples de communautés spécifiques :

- Abidjan Coiffure;
- Dakar Mariage;
- Paris Mode Africaine;
- Cotonou Beauté;
- Créateurs Wax;
- Boutiques Accessoires.

Workflow :

```text
Utilisateur propose une communauté
-> Admin valide ou refuse
-> Le demandeur devient gestionnaire
-> Les membres demandent l'accès
-> Le gestionnaire accepte ou refuse
-> L'admin garde le droit de fermer, suspendre ou limiter
```

Fonctionnalités actuelles :

- création de communauté via formulaire mobile;
- validation/refus depuis l'admin;
- statut `pending`, `approved`, `rejected`, `suspended`, `closed`;
- modes d'accès `open`, `request`, `invite_only`, `closed`;
- demandes d'adhésion;
- gestion des demandes par le gestionnaire;
- publication dans la communauté générale ou dans un groupe spécifique;
- édition et suppression de ses propres messages;
- suppression soft avec trace de modération;
- blocage utilisateur pour la communauté;
- restriction globale temporaire ou définitive par l'admin;
- recherche contextuelle dans les groupes et discussions.

Fichiers principaux :

```text
lib/models/community/community_access_policy.dart
lib/models/community/community_group.dart
lib/views/screens/global/widgets/inspiration/community_screen.dart
lib/views/screens/global/widgets/inspiration/community_question_card.dart
```

Tests :

```text
test/community_access_policy_test.dart
test/community_group_test.dart
```

Règle produit : une communauté spécifique ne doit pas remplacer le Salon. Elle doit créer de la proximité, de la confiance et de la rétention autour d'une ville, d'un métier, d'un style ou d'une culture mode.

### Créateur

L'espace Créateur devient un atelier professionnel.

Navigation cible :

```text
Aujourd'hui | Créations | RDV | Clients | Stats
```

Fonctionnalités :

- cockpit `Aujourd'hui`;
- créations;
- ajout et édition de créations;
- rendez-vous;
- clients;
- statistiques;
- échanges avec les clients;
- profil créateur;
- visibilité dans le Salon;
- switch vers client ou boutique.

Fichiers structurants :

```text
lib/views/screens/createur/createur_dashboard_screen.dart
lib/views/screens/createur/createur_tabs/
lib/models/createur/
lib/services/createur/
lib/views/screens/createur/widgets/
```

Le Créateur gère ses contenus dans son cockpit. Le Salon sert à voir et exposer la vitrine publique.

### Boutique

L'espace Boutique devient un cockpit commercial.

Navigation cible :

```text
Aujourd'hui | Produits | Commandes | RDV | Profil
```

Fonctionnalités :

- cockpit `Aujourd'hui`;
- produits;
- commandes;
- clients;
- rendez-vous;
- promotions;
- galerie;
- avis;
- messages;
- paramètres;
- visibilité dans le Salon;
- switch vers client ou créateur.

Fichiers structurants :

```text
lib/views/screens/boutique/dashboard/boutique_dashboard.dart
lib/views/screens/boutique/dashboard/boutique_home_screen.dart
lib/views/screens/boutique/products/
lib/views/screens/boutique/orders/
lib/views/screens/boutique/appointment/
lib/models/boutique/
lib/services/boutique/
```

La Boutique crée et gère. Le Salon expose et vend.

### Admin

L'espace Admin est devenu le cockpit opérationnel de la solution.

Il sert à superviser :

- utilisateurs;
- rôles;
- contenus;
- statistiques;
- données structurées;
- qualité;
- sécurité;
- modération;
- gouvernance des communautés générales et spécifiques.

Il couvre maintenant aussi la logique business :

- configuration commerce et monétisation;
- coupons checkout;
- règles fidélité;
- abonnements Pro/Signature;
- demandes de boost;
- commissions plateforme;
- suivi des revenus;
- validation et gouvernance des contenus;
- validation des communautés proposées;
- fermeture, suspension ou restriction d'un groupe;
- blocage d'un utilisateur dans la communauté;
- suppression ou masquage des messages communautaires.

Consolidations récentes :

- recherche globale admin : référence paiement, commande, retrait, téléphone, email, client, vendeur, produit, création, annonce, Pro, boost et signalement;
- accueil transformé en cockpit de décision : paiements à vérifier, retraits à payer, plans Pro/Signature, boosts, litiges, signalements et alertes système;
- vue **À traiter** unique : paiements, retraits, plans Pro/Signature, boosts, litiges et modération, avec action principale claire et bouton d'actualisation séparé;
- navigation mobile simplifiée : Accueil, Comptes, Paiements, Modération, Réglages et Plus;
- comptes admin plus fluides sur mobile : recherche par nom/email/ID/source, filtres Clients/Boutiques/Créateurs/Admins et cartes compactes;
- fiches détail sensibles : commandes, retraits, plans, boosts, documents retrouvés par recherche;
- bouton `Copier résumé` dans les fiches sensibles pour faciliter les contrôles et échanges support;
- journal financier audit filtrable : paiements, retraits, Pro, boosts, litiges, modération, avec traces `before/after` sur les mises à jour sensibles;
- espace litiges commandes avec passage en analyse et note admin obligatoire;
- paramètres commerce guidés avec checklist, impact client, impact vendeur, risque admin et confirmation avant sauvegarde;
- configuration des moyens de paiement admin affichés au checkout;
- numéros des moyens de paiement masqués dans les logs d'audit;
- publication des règles commerce par défaut protégée par confirmation;
- coupons checkout tracés dans l'audit admin;
- aperçu visuel rapide des contenus Salon administrables avant action;
- validation manuelle des plans Pro/Signature et boosts avec preuve;
- notifications métier vers client, vendeur et admin.

Collections liées :

```text
platform_settings/commerce
checkout_coupons
loyalty_rules
seller_subscriptions
pro_upgrade_requests
boost_campaigns
platform_commissions
seller_withdrawal_requests
admin_audit_logs
admin_activity_logs
community_groups
community_settings
community_questions
reports
```

Règle de gouvernance : `admin_audit_logs` et `admin_activity_logs` sont créables et lisibles uniquement par l'admin, mais ne doivent pas être modifiables ni supprimables. Ces logs servent de trace d'exploitation, pas de contenu éditable.

Fichiers admin :

```text
lib/views/screens/admin/dashboard/admin_dashboard.dart
lib/views/screens/admin/dashboard/admin_navigation.dart
lib/views/screens/admin/dashboard/admin_quick_widgets.dart
lib/views/screens/admin/dashboard/admin_shell_widgets.dart
lib/views/screens/admin/dashboard/admin_commerce_widgets.dart
lib/models/admin/admin_workflow_decision.dart
lib/services/admin/admin_commerce_config_service.dart
```

## Stack Technique

### Application

- Flutter
- Dart
- Material 3
- Design system custom
- Navigation par routes déclarées
- `WorkspaceRouter` pour l'espace actif

### Firebase

- Firebase Core
- Firebase Auth
- Cloud Firestore
- Firebase Messaging
- Flutter Local Notifications
- Firebase App Check
- Firebase Performance
- Cloud Functions présent dans les dépendances

Firebase Storage existe encore dans certaines parties du code historique, mais la logique cible est Cloudinary + Firestore.

### Cloud Functions

Un dossier `functions/` a été ajouté pour les actions serveur qui ne doivent pas vivre dans l'application mobile.

Fonction disponible :

```text
sendQueuedNotification
```

Déclencheur :

```text
notification_outbox/{outboxId}
```

Rôle :

- lire la demande push;
- récupérer les tokens FCM du destinataire;
- envoyer la notification via Firebase Admin;
- nettoyer les tokens invalides;
- marquer l'outbox en `sent` ou `failed`.

Commandes :

```bash
cd functions
npm install
npm run lint
npm run deploy
```

À noter : l'environnement local peut afficher un warning si Node n'est pas en version 20. Firebase Functions cible Node 20 en production.

### IA et Services Externes

- OpenAI Responses API
- Gemini / Google Generative AI
- Firebase AI
- Stability AI
- SerpApi
- YouTube API
- Unsplash API
- HTTP / Dio

Le texte IA est pilotable par `.env` :

```text
AI_TEXT_PROVIDER=openai | gemini
OPENAI_API_KEY
OPENAI_MODEL
OPENAI_FALLBACK_MODELS
GEMINI_API_KEY
GEMINI_MODEL
GEMINI_FALLBACK_MODELS
```

Comportement actuel :

- si `AI_TEXT_PROVIDER=openai`, Iris tente OpenAI en priorité;
- si OpenAI échoue et que Gemini est configuré, bascule possible vers Gemini;
- si Gemini répond quota dépassé ou modèle indisponible, bascule possible vers OpenAI;
- si aucun fournisseur IA ne répond, Iris garde une réponse locale utile au lieu de casser l'expérience.

Fichiers :

```text
lib/services/ai/openai_client.dart
lib/services/ai/gemini_client.dart
lib/views/screens/client/features/style/gemini_service.dart
lib/services/style/fashion_assistant_service.dart
```

Iris et le conseiller Style enrichissent maintenant leurs recommandations avec :

- ville / pays;
- adresse ou zone enregistrée;
- coordonnées latitude/longitude si disponibles;
- contexte boutique ou créateur associé au même compte si pertinent;
- garde-robe, mensurations et dernières recommandations sauvegardées.

À terme, les appels sensibles à ces services doivent passer par un backend ou Cloud Functions afin de ne pas exposer les clés dans l'application mobile.

### Médias et UI

- image picker;
- image cropper;
- cached network image;
- vidéo;
- audio;
- Lottie;
- SVG;
- cartes, graphiques et composants visuels;
- modèle 3D pour certaines expériences.

## Structure du Projet

Structure principale :

```text
lib/
  app/
  core/
  data/
  design/
  models/
  services/
  splash/
  views/
```

Points importants :

- `lib/main.dart` initialise l'application, Firebase, la localisation et les notifications.
- `lib/app/` contient l'application, le thème et les routes.
- `lib/core/account_roles.dart` porte la logique de rôles cumulables.
- `lib/models/app/` et `lib/services/app/` portent la logique transversale de workspace, contexte et permissions.
- `lib/data/repositories/auth_repository.dart` porte l'authentification.
- `lib/design/` contient les composants et tokens à utiliser pour respecter la charte.
- `lib/services/media/` centralise les uploads Cloudinary et le registre médias.
- `lib/services/notifications/` centralise les notifications in-app et l'outbox push.
- `lib/views/screens/` contient les écrans client, créateur, boutique, admin et globaux.
- `schemaDB.md` décrit la logique data cible.

Le projet a été nettoyé pour retirer une partie des anciens fichiers non utilisés. Il reste encore de la dette historique : gros fichiers UI, anciens noms, anciens écrans à harmoniser et usages résiduels de Firebase Storage. Ces zones doivent être améliorées progressivement tout en maintenant `flutter analyze` à zéro issue.

Découpages récents déjà effectués :

- `admin_dashboard.dart` extrait en plusieurs parts pour navigation, widgets rapides, shell et commerce;
- l'espace Admin reste volumineux mais les zones les plus sensibles sont maintenant isolées dans `admin_navigation.dart`, `admin_quick_widgets.dart`, `admin_shell_widgets.dart` et `admin_commerce_widgets.dart`;
- `community_screen.dart` extrait en plusieurs widgets/parts communauté, avec groupes thématiques validables par l'admin;
- `garde_robe.dart` extrait en fiche d'ajout, filtres et modèles de support;
- `messages/chat_screen.dart` extrait en détail produit et lecteur vidéo;
- `messages/conversations_screen.dart` extrait en item de conversation;
- `createur_profile_screen.dart` extrait pour le formulaire d'édition.

Objectif : continuer à sortir les widgets et services des gros fichiers sans casser les parcours métier.

## Configuration Firebase

Le projet Android actuel pointe vers Firebase :

```text
projectId: elegantstyle-5b186
```

Fichiers importants :

```text
android/app/google-services.json
android/google-services.json
lib/firebase_options.dart
firebase.json
```

Attention :

- `android/app/google-services.json` est le fichier utilisé par Android.
- `lib/firebase_options.dart` est utilisé par `Firebase.initializeApp`.
- Les anciens doublons de `google-services.json` ne doivent pas réapparaître dans `android/app/src/`.

Au démarrage, le log doit confirmer :

```text
Firebase initialisé: elegantstyle-5b186
```

## Variables d'Environnement

Le projet attend notamment :

```text
AI_TEXT_PROVIDER
OPENAI_API_KEY
OPENAI_MODEL
OPENAI_FALLBACK_MODELS
GEMINI_API_KEY
GEMINI_MODEL
GEMINI_FALLBACK_MODELS
STABILITY_API_KEY
SERPAPI_KEY
YOUTUBE_API_KEY
UNSPLASH_ACCESS_KEY
CLOUDINARY_CLOUD_NAME
CLOUDINARY_UPLOAD_PRESET
CLOUDINARY_IMAGE_UPLOAD_PRESET
CLOUDINARY_VIDEO_UPLOAD_PRESET
CLOUDINARY_FILE_UPLOAD_PRESET
CLOUDINARY_FOLDER_ROOT
ENABLE_DEFAULT_ADMIN_BOOTSTRAP
DEFAULT_ADMIN_EMAIL
DEFAULT_ADMIN_PASSWORD
DEFAULT_ADMIN_NAME
```

Ces clés ne doivent pas être considérées comme sécurisées si elles sont embarquées dans l'app mobile. Pour la production, il faudra les déplacer vers un backend ou des fonctions serveur.

Recommandation production :

- garder les clés OpenAI, Gemini, Stability, SerpApi, YouTube et Cloudinary signé côté serveur;
- exposer à l'app mobile uniquement des endpoints backend contrôlés;
- limiter les quotas par utilisateur ou par action;
- journaliser les erreurs IA sans afficher les secrets.

Pour Cloudinary, les presets doivent être configurés côté Cloudinary. Le mobile utilise des uploads non signés pour l'instant; une version production devrait passer par des signatures serveur pour les usages sensibles.

Pour Google Sign-In, Firebase Authentication doit avoir le provider Google activé, et les empreintes Android SHA-1/SHA-256 doivent être configurées dans Firebase.

Important :

- `.env`, `.env.*`, fichiers locaux et logs Firebase sont ignorés par `.gitignore`;
- si `.env` a déjà été suivi par Git, il faut le retirer de l'index avant commit;
- utiliser des clés de test limitées pendant la phase Release Candidate;
- ne pas exposer de clés IA ou Cloudinary signées dans un APK public.

## Commandes Utiles

Installer les dépendances :

```bash
flutter pub get
```

Lancer l'application :

```bash
flutter run
```

Analyser le projet :

```bash
flutter analyze
```

Nettoyer le build :

```bash
flutter clean
flutter pub get
```

Build Android release :

```bash
flutter build apk --release
```

Lancer les émulateurs Firebase :

```bash
firebase emulators:start
```

Vérifier les règles Firestore sans déployer :

```bash
firebase deploy --only firestore:rules --dry-run
```

Générer les fichiers liés à build runner si nécessaire :

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Parcours Prioritaires

Les parcours à stabiliser en priorité :

1. Consultation du Salon en visiteur.
2. Connexion et arrivée dans le bon espace selon `activeRole`.
3. Switch fluide entre client, créateur et boutique.
4. Cockpit Client : souhaits, garde-robe, mensurations, messages, commandes.
5. Défi quotidien et points fidélité.
6. Diagnostic style Inspiration sauvegardé.
7. Publication d'un produit boutique visible dans le Salon.
8. Publication d'une création visible dans le Salon.
9. Commande Salon vers cockpit Boutique.
10. Rendez-vous client avec créateur ou boutique.
11. Messagerie liée aux profils, produits et créations.
12. Upload média via Cloudinary et stockage de l'URL dans Firestore.
13. Notification in-app après message, partage de mensurations, commande ou rendez-vous.
14. Outbox push consommée par Cloud Function ou backend.
15. Email de bienvenue après inscription email ou Google.
16. Essayage virtuel depuis galerie, produit, création, garde-robe et souhaits.
17. Communauté générale : publier, répondre, modifier et supprimer son contenu.
18. Communautés spécifiques : proposer un groupe, validation admin, adhésion et gestion par propriétaire.
19. Recommandations Iris Style : retour écran précédent, génération OpenAI/Gemini, fallback local, sauvegarde et historique.
20. Localisation : profil client, onboarding créateur/boutique, Salon près de moi et contexte Iris.

## Plan de Test Release Candidate

La phase suivante doit être une vraie phase **Release Candidate**, structurée par parcours.

La checklist opérationnelle est dans :

```text
RELEASE_CHECKLIST.md
```

Principe :

- geler les fonctionnalités;
- nettoyer secrets et environnement;
- tester les règles Firestore sur staging/emulator;
- tester sur un vrai téléphone Android;
- corriger uniquement les bugs bloquants;
- créer un build staging reproductible;
- faire tester les profils client, boutique, créateur et admin.

### Bloc 1 - Rôles et Navigation

- visiteur -> Salon;
- inscription email;
- inscription Google;
- connexion;
- `activeRole` client;
- activation créateur;
- activation boutique;
- switch entre espaces;
- fermeture espace créateur ou boutique;
- fermeture compte client;
- retour vers le bon espace après passage dans le Salon.

### Bloc 2 - Salon et Marketplace

- recherche globale;
- filtre local / pays / monde entier;
- talents et boutiques visibles;
- admin invisible côté public;
- fiche produit;
- fiche talent;
- fiche événement;
- carte `Près de moi`;
- ajout panier;
- achat impossible sur son propre produit;
- checkout;
- preuve paiement;
- coupons;
- points fidélité;
- validation admin;
- création d'une commande boutique;
- création d'une commande création;
- séparation stricte du panier par fournisseur;
- achat pour moi vers garde-robe après paiement validé;
- achat pour un tiers vers historique seulement;
- avis après usage visible sur le produit.

### Bloc 3 - Client et Style

- cockpit `Aujourd'hui`;
- garde-robe;
- souhaits;
- mensurations;
- diagnostic style;
- recommandations Iris Style;
- chat Iris;
- localisation prise en compte;
- essayage virtuel galerie / produit / création;
- essayage virtuel garde-robe et souhaits à diagnostiquer;
- sauvegarde d'une recommandation;
- historique.

### Bloc 4 - Créateur, Boutique et Admin

- publication création;
- publication produit;
- Catalogue Express et brouillons rapides;
- story Pro visible 24h dans le Salon;
- guide Style Pro;
- visibilité Salon;
- demandes client;
- rendez-vous;
- messages multi-rôle;
- commandes boutique;
- boosts partagés par compte;
- plans Pro/Signature;
- paiement plan avec preuve;
- boost avec preuve;
- solde en attente puis disponible;
- retrait vendeur;
- litige commande;
- modération admin;
- recherche globale admin;
- file `À traiter`;
- journal audit filtrable;
- gestion communauté;
- suspension/réactivation utilisateur;
- revenus, commissions et payouts.

### Bloc 5 - Vide-dressing

- entrée visible côté client;
- publication annonce;
- discussion client-client;
- réservation;
- vente finalisée;
- solde disponible;
- choix retrait ou conversion en points Style;
- visibilité selon niveau de gamification;
- signalement/modération.

Critère de sortie de test :

```text
flutter analyze OK
flutter test OK
firebase deploy --only firestore:rules --dry-run OK
aucun overflow bloquant sur petits écrans
aucune route sans retour
aucune action sensible sans contrôle de rôle
aucun upload critique non vérifié
aucun bug critique sur paiement, retrait, devise, rôle ou notification
```

## Médias et Stockage

La logique média actuelle privilégie Cloudinary.

Zones déjà concernées :

1. Photos de profil.
2. Logos boutiques.
3. Images produits.
4. Images de créations.
5. Médias de messages.
6. Garde-robe.
7. Stories et communauté.
8. Essayage virtuel pour les images locales et distantes.
9. Médias communautaires liés aux questions, réponses et groupes.

Service cible recommandé :

```text
lib/services/media/media_upload_service.dart
lib/services/media/media_asset_service.dart
```

Ces services centralisent :

- upload image;
- upload vidéo;
- upload fichier;
- gestion des erreurs;
- retour `secureUrl`, `optimizedUrl`, `thumbnailUrl` et `publicId`;
- choix du dossier Cloudinary;
- enregistrement dans `media_assets`;
- suppression ou remplacement futur de média.

À faire ensuite :

- vérifier tous les anciens écrans qui utiliseraient encore Firebase Storage;
- ajouter uploads signés côté serveur;
- ajouter politiques de taille, format et compression par usage;
- prévoir nettoyage Cloudinary quand un média est supprimé côté Firestore.

## Sécurité

Points à renforcer avant production publique :

- compléter les tests automatisés des règles Firestore;
- tester les règles avec Firebase Emulator;
- ne pas exposer les clés IA côté client;
- déplacer les appels sensibles vers backend;
- envoyer les emails transactionnels via extension Firebase ou backend;
- envoyer les push FCM via Cloud Function depuis `notification_outbox`;
- utiliser App Check réellement sur les services exposés;
- vérifier les permissions par rôle;
- tester les actions centrales `save`, `buy`, `book`, `contact`, `publish`, `manage`;
- empêcher les achats de ses propres produits ou créations;
- éviter les uploads directs non contrôlés;
- nettoyer les anciennes collections ou doublons.

État actuel de durcissement :

- les commandes sont lisibles par le client concerné, le vendeur concerné ou l'administration;
- les mises à jour de commandes sont limitées : le vendeur peut faire avancer le statut opérationnel, mais ne peut pas modifier paiement, devise, total, commission ou solde;
- le client peut confirmer la réception uniquement dans le cadre attendu, afin de déplacer le solde vendeur de `pending_delivery` vers `available`;
- les produits et créations vérifient le propriétaire (`ownerId`, `sellerId`, `boutiqueId`, `creatorId` ou alias legacy) avant modification;
- les champs sensibles de `users/{uid}` sont protégés contre les modifications client : rôles, points, badges, soldes, droits Pro, permissions admin;
- `platform_commissions` est réservé à l'administration;
- les demandes de retrait doivent correspondre à une commande ou annonce réellement disponible, avec le bon vendeur et le bon montant;
- les plans Pro/Signature et boosts sont modifiables uniquement par l'admin après validation;
- les litiges sont traçables dans `admin_audit_logs`;
- `admin_audit_logs` et `admin_activity_logs` sont protégés contre toute modification ou suppression côté règles Firestore;
- les actions admin sensibles relisent l'état Firestore avant décision pour limiter les doubles validations ou décisions obsolètes;
- les réglages commerce, coupons et règles par défaut sont tracés dans l'audit;
- `public_profiles` sert de projection publique pour éviter de lire `users/{uid}` dans les parcours Salon, messagerie et vide-dressing.

Vérification récente :

```bash
firebase deploy --only firestore:rules --dry-run
```

Résultat : compilation des rules OK.

## Qualité Technique

La base fonctionnelle est riche, mais le projet doit encore être consolidé.

Axes de stabilisation :

- réduire les services dupliqués;
- sortir la logique métier des gros fichiers UI;
- unifier les modèles utilisateur;
- harmoniser les collections `users`, `utilisateurs`, `clients`;
- remplacer les usages restants de `FirebaseStorage`;
- maintenir `flutter analyze` global à zéro issue;
- ajouter des tests sur auth, rôles, Firestore rules, panier, rendez-vous et chat;
- supprimer ou repositionner les écrans doublons de marketplace si le Salon couvre déjà le besoin;
- garder le diagnostic style et la gamification séparés dans leur intention.

## Roadmap Conseillée

### Phase 1 - Stabilisation Base

- Finaliser Firebase ElegantStyle.
- Vérifier inscription email, connexion email, Google Sign-In et rôles cumulables.
- Vérifier l'email de bienvenue via la collection `mail`.
- Stabiliser `WorkspaceRouter`.
- Stabiliser `AccountSpaceSwitcher`.
- Documenter les collections principales.
- Ajouter les règles Firestore minimales.

### Phase 2 - Migration Médias

- Cloudinary est ajouté.
- Le service média commun existe.
- Migrer et vérifier tous les écrans restants.
- Ajouter signatures serveur.
- Retirer progressivement Firebase Storage.

### Phase 3 - Notifications et Actions

- Consolider `notifications`.
- Brancher commandes, rendez-vous, paiements, boosts et support.
- Brancher demandes d'adhésion communauté, validation de groupe et décisions gestionnaire.
- Créer la Cloud Function qui consomme `notification_outbox`.
- Ajouter préférences utilisateur : messages, commandes, RDV, promotions.
- Ajouter navigation profonde depuis une notification quand la route existe.

### Phase 4 - Salon et Marketplace Unifiés

- Stabiliser recherche Salon unifiée.
- Finaliser fiches produit, talent, inspiration et événement.
- Finaliser l'expérience Communauté : logos de groupes, notifications, règles Firestore et modération fine des réponses.
- Finaliser profils publics créateurs et boutiques.
- Solidifier panier, checkout et commandes.
- Ajouter statuts de commande.
- Renforcer avis et confiance.

### Phase 5 - Expérience Client Premium

- Finaliser cockpit Client.
- Stabiliser points fidélité et badges.
- Connecter diagnostic style à Iris, Salon et garde-robe.
- Finaliser l'essayage virtuel multi-source, notamment Garde-robe et Souhaits sur données réelles.
- Ajouter suivi des avantages fidélité.
- Rendre les recommandations plus personnelles.

### Phase 6 - Internationalisation Locale

- Ajouter champs pays, ville et zone.
- Filtrer contenus par proximité.
- Garder la découverte mondiale possible.
- Adapter textes et devises.

### Phase 7 - Production

- Sécuriser secrets.
- Ajouter backend pour IA, uploads signés et paiements.
- Ajouter tests automatisés.
- Tester sur appareils Android réels.
- Préparer une bêta privée.

### Phase 8 - Release Candidate

- Geler les fonctionnalités.
- Suivre [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md).
- Tester les 21 parcours critiques sur staging.
- Vérifier `flutter analyze`, `flutter test` et dry-run Firestore Rules.
- Vérifier les notifications push via Cloud Function.
- Vérifier paiements, retraits, litiges, plans Pro/Signature et boosts.
- Corriger seulement les bugs bloquants avant build public.

## État Actuel

Le projet dispose déjà d'une base applicative avancée :

- multi-rôles;
- Google Sign-In;
- email de bienvenue;
- Salon public;
- marketplace;
- profils créateurs;
- boutiques;
- chat;
- notifications in-app;
- outbox push serveur;
- agenda;
- IA style;
- OpenAI / Gemini avec fallback;
- essayage virtuel;
- inspiration;
- gamification client;
- diagnostic style;
- Vide-dressing avec discussion client-client, réservation, vente, retrait ou conversion en points Style;
- paiement manuel sécurisé avec preuve, validation admin, audit et solde vendeur;
- plans Pro/Signature, stories Pro 24h, guides Style Pro et boosts;
- admin;
- admin avancé : recherche globale, file `À traiter`, litiges, audit filtrable, paramètres commerce guidés;
- Firebase Auth et Firestore.

Les décisions récentes importantes sont :

- repositionnement vers ElegantStyle mondial;
- compte unique client par défaut;
- rôles créateur et boutique activables;
- switch entre espaces depuis `AccountSpaceSwitcher`;
- routage par `activeRole` via `WorkspaceRouter`;
- Salon comme place publique transversale;
- Client comme cockpit personnel;
- Créateur comme atelier professionnel;
- Boutique comme cockpit commercial;
- gamification quotidienne dans `Aujourd'hui`;
- diagnostic style sauvegardable dans Inspiration;
- monétisation pro avec plans Pro/Signature et boosts liés au compte;
- boosts partagés entre les espaces Créateur et Boutique du même compte;
- contenus boostés remontés dans Découvrir, Recherche Salon, Shopping et Talents;
- admin capable de valider paiements, retraits, plans, boosts, coupons, modération, litiges et revenus;
- paiement manuel sécurisé avec référence unique, preuve, audit et reversement vendeur;
- règles Firestore durcies sur rôles, commandes, retraits, commissions et soldes;
- notifications centralisées avec `AppNotificationService`;
- Cloud Function `sendQueuedNotification` pour traiter `notification_outbox`;
- messages et mensurations branchés sur le système de notifications;
- communauté refondue en hub mobile avec communauté générale, groupes spécifiques, demandes d'adhésion et gouvernance admin;
- Firebase pour identité et données métier;
- Cloudinary centralisé pour les médias;
- registre `media_assets`;
- abandon progressif de Firebase Storage;
- Iris enrichie par localisation, garde-robe et mensurations;
- écran Recommandations simplifié sans onglets supérieurs;
- analyse globale et tests automatisés actuellement verts;
- 98 tests automatisés passent;
- cockpit Admin mobile-first renforcé : file de décision, comptes filtrables, audit protégé, commerce guidé et logs masqués;
- dry-run Firestore Rules OK.

Points ouverts à traiter ensuite :

- diagnostiquer pourquoi les onglets Garde-robe et Souhaits de l'essayage ne remontent pas encore les données visibles côté application;
- ajouter un diagnostic temporaire dans l'UI d'essayage pour inspecter le `uid`, les chemins lus et les champs images;
- brancher les notifications sur les demandes d'adhésion communauté, validation de groupe et décisions gestionnaire;
- ajouter une image/logo Cloudinary sur les communautés spécifiques;
- finaliser le backend de paiement réel si un agrégateur devient accessible;
- déplacer les appels IA et VTO sensibles vers backend;
- poursuivre le découpage des très gros écrans restants;
- ajouter des tests automatisés Firestore Rules;
- poursuivre la consolidation performance mobile sur les écrans lourds.

## Conclusion

ElegantStyle a maintenant une direction claire : une plateforme de mode mondiale, capable de rester proche des utilisateurs grâce à la localisation, aux créateurs, aux boutiques et aux cultures de leur zone.

La priorité n'est plus d'ajouter des fonctionnalités dispersées. Elle est de solidifier les fondations : rôles cumulables, données propres, stockage média externe, sécurité, Salon transversal, cockpits métier, fidélité utile et cohérence UI selon [style.md](style.md).

## Pré-lancement Business

À vérifier avant bêta :

- suivre [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md);
- exécuter `flutter analyze`, `flutter test` et `firebase deploy --only firestore:rules --dry-run`;
- déployer `firestore.rules` sur staging après chaque changement de rôles, boosts, paiements ou admin;
- configurer `platform_settings/commerce` depuis l'admin;
- configurer les moyens de paiement admin visibles au checkout;
- vérifier que les moyens de paiement admin sont masqués dans les logs et complets dans le checkout;
- publier les coupons et règles fidélité par défaut depuis l'onglet Coupons;
- vérifier que `admin_audit_logs` et `admin_activity_logs` ne peuvent pas être modifiés ni supprimés après création;
- créer au moins un client, un créateur, une boutique et un admin de test;
- tester une demande Pro depuis Créateur, puis vérifier que Boutique hérite du plan;
- tester une demande Boost depuis Boutique, puis vérifier que Créateur hérite aussi du boost;
- vérifier que les contenus boostés remontent dans le Salon sans masquer les résultats naturels;
- tester une commande boutique avec preuve de paiement, validation admin, livraison, réception, solde disponible et retrait;
- tester une commande création avec un fournisseur différent;
- tester un panier multi-vendeurs et vérifier la séparation stricte;
- tester le Vide-dressing : annonce, chat, réservation, vente, retrait ou conversion en points Style;
- tester un litige et vérifier qu'il bloque le solde;
- vérifier la création de `notifications` et `notification_outbox`;
- tester la création d'une communauté spécifique, validation admin, demande d'adhésion et publication dans le groupe;
- vérifier que l'admin peut fermer, suspendre ou restreindre une communauté;
- déployer et vérifier la Cloud Function FCM avant d'attendre des push réels;
- vérifier l'email de bienvenue via Firebase Trigger Email ou backend mail;
- vérifier que `.env` et les clés sensibles ne sont pas commitées;
- connecter un paiement réel ou garder explicitement le mode manuel sécurisé avant activation publique.
