# Schema DB - ElegantStyle

Ce document décrit la logique des bases et services de données utilisés dans ElegantStyle. L'objectif est de garder Firebase pour l'identité, les profils et les données applicatives, puis de déplacer les fichiers lourds vers un stockage média externe afin d'éviter Firebase Storage.

## Vision Globale

ElegantStyle repose sur une architecture hybride :

- Firebase Authentication gère l'identité des utilisateurs.
- Cloud Firestore stocke les données métier, les profils, les rôles, les produits, les créations, les conversations et les références vers les médias.
- Un service média externe, recommandé : Cloudinary, stocke les images, vidéos, logos et fichiers lourds.
- Un backend optionnel pourra être ajouté plus tard si certaines actions sensibles doivent être protégées côté serveur.

Le principe important : Firestore ne doit pas contenir les fichiers eux-mêmes. Il doit contenir uniquement les métadonnées et les URLs publiques ou sécurisées des médias.

## Firebase Authentication

Firebase Auth est la source principale pour l'identité.

Responsabilités :

- Création de compte.
- Connexion email/mot de passe.
- Connexion Google ou autres fournisseurs si activés.
- Gestion de session.
- UID unique par utilisateur.

Chaque utilisateur possède un `uid` Firebase. Ce `uid` devient la clé de référence dans Firestore.

Exemple :

```text
FirebaseAuth
  uid: "abc123"
  email: "client@example.com"
```

Dans Firestore, le profil correspondant doit être stocké dans :

```text
users/{uid}
```

Règle métier :

- Un compte est créé par défaut comme client.
- Les rôles créateur et boutique sont activables progressivement depuis "Mon Espace".
- Le même `uid` est utilisé pour tous les rôles.

## Cloud Firestore

Firestore est la base principale de données métier. Elle stocke les documents structurés, pas les fichiers lourds.

### Collection `users`

Collection centrale pour les profils et les rôles.

```text
users/{uid}
  uid
  email
  displayName
  phone
  photoUrl
  activeRole
  roles
    client: true
    creator: false
    shop: false
  creatorProfile
    specialty
    description
    city
    country
    portfolioUrls
  shopProfile
    shopName
    description
    address
    city
    country
    logoUrl
  stats
    productsCount
    creationsCount
    followersCount
  createdAt
  updatedAt
```

Usage :

- Affichage du profil client.
- Switch entre client, créateur et boutique.
- Activation progressive des rôles.
- Stockage des informations publiques des créateurs et boutiques.

Important :

- La collection `users` doit devenir la référence unique.
- Les anciennes références à `utilisateurs`, `clients` ou autres collections parallèles doivent être harmonisées progressivement.

### Collection `public_profiles`

Projection publique minimale des comptes. Elle permet au Salon, à la
messagerie, au vide-dressing et aux avis d'afficher une identité humaine sans
lire les données privées de `users/{uid}`.

```text
public_profiles/{uid}
  displayName
  photoUrl
  roles
  primaryRole
  city
  country
  specialty
  bio
  isVerified
  publicBadges
  rating
  reviewCount
  secondhandListings
  secondhandSold
  updatedAt
```

Règles métier :

- `users/{uid}` reste la source privée et complète du compte.
- `public_profiles/{uid}` sert uniquement à l'affichage public.
- Les conversations client-client et le vide-dressing doivent privilégier `public_profiles` ou les champs publics copiés dans l'annonce.
- Les secrets, téléphones privés et informations de paiement ne doivent jamais être copiés dans `public_profiles`.

### Convention des identifiants métier

Pour éviter les confusions legacy, la convention cible est :

```text
userId       utilisateur client concerné par une action
ownerId      propriétaire générique d'un contenu Salon
sellerId     vendeur d'un produit, d'une création commandable ou d'une commande
sellerRole   boutique | createur | client
shopId       boutique quand le rôle est explicitement boutique
creatorId    créateur quand le rôle est explicitement créateur
```

Compatibilité à maintenir pendant la migration :

```text
boutiqueId  ancien équivalent de shopId/sellerId
createurId  ancien équivalent de creatorId
role        champ legacy, conservé avec activeRole et roles
```

Les nouveaux écrans doivent écrire les champs cibles tout en conservant les alias nécessaires quand un ancien écran les lit encore.

### Collection `products`

Produits vendus par une boutique.

```text
products/{productId}
  ownerId
  shopId
  title
  description
  price
  currency
  category
  sizes
  colors
  stock
  media
    coverUrl
    imageUrls
    videoUrl
    cloudinaryPublicIds
  status
  zone
    country
    city
  createdAt
  updatedAt
```

Usage :

- Marketplace.
- Boutique.
- Recommandations.
- Panier et checkout.
- Catalogue Express crée d'abord des brouillons à partir de photos en lot.

Règle :

- Les images et vidéos sont stockées dans Cloudinary.
- Firestore garde seulement les URLs et les identifiants `publicId` pour pouvoir supprimer ou remplacer les médias.

### Collection `creations`

Créations publiées par les créateurs.

```text
creations/{creationId}
  creatorId
  title
  description
  category
  tags
  media
    coverUrl
    imageUrls
    videoUrl
    cloudinaryPublicIds
  priceEstimate
  isAvailableForOrder
  status
  zone
    country
    city
  createdAt
  updatedAt
```

Usage :

- Portfolio créateur.
- Inspirations.
- Commandes personnalisées.
- Découverte locale ou internationale.
- Catalogue Express peut créer plusieurs brouillons de créations à enrichir ensuite.

Champs ajoutés par Catalogue Express :

```text
source: catalogue_express
expressMode
mediaIds
media
status: draft | published
visibility: private | salon
```

### Collection `appointments`

Rendez-vous entre clients, créateurs et boutiques.

```text
appointments/{appointmentId}
  clientId
  providerId
  providerRole
  title
  description
  date
  time
  status
  location
  createdAt
  updatedAt
```

Usage :

- Réservation avec créateur.
- Rendez-vous boutique.
- Suivi des demandes.

### Collection `conversations`

Résumé des conversations.

```text
conversations/{conversationId}
  participants
  participantRoles
  lastMessage
  lastMessageAt
  unreadCounts
  createdAt
  updatedAt
```

### Collection `messages`

Messages d'une conversation.

```text
messages/{messageId}
  conversationId
  senderId
  receiverId
  type
  text
  mediaUrl
  mediaPublicId
  read
  createdAt
```

Types possibles :

- `text`
- `image`
- `video`
- `product`
- `appointment`

Règle :

- Les pièces jointes doivent partir vers Cloudinary.
- Firestore garde `mediaUrl` et `mediaPublicId`.

### Collection `wardrobe`

Garde-robe personnelle du client.

```text
wardrobe/{itemId}
  userId
  title
  category
  colors
  imageUrl
  cloudinaryPublicId
  notes
  createdAt
  updatedAt
```

Usage :

- Style advisor.
- Essayage virtuel.
- Recommandations personnalisées.

### Collection `stories`

Stories et publications courtes.

```text
stories/{storyId}
  authorId
  authorRole
  mediaUrl
  mediaType
  cloudinaryPublicId
  caption
  expiresAt
  createdAt
```

### Collection `style_guides`

Guides Style natifs pour remplacer les tutoriels YouTube intégrés.

```text
style_guides/{guideId}
  title
  subtitle
  category
  steps[]
  imageUrl
  videoUrl
  authorId
  authorRole
  authorName
  linkedProducts[]
  linkedCreations[]
  tags[]
  featured
  status        published | draft | hidden
  visibility    salon | private
  createdAt
  updatedAt
```

Usage :

- guides éditoriaux ElegantStyle;
- mini-guides publiés par boutiques et créateurs certifiés;
- continuité après quiz quotidien;
- inspiration liée aux produits, créations, stories et communautés.

### Collection `notifications`

Notifications applicatives.

```text
notifications/{notificationId}
  userId
  title
  body
  type
  data
  read
  createdAt
```

Les tokens FCM peuvent rester dans :

```text
users/{uid}.fcmTokens
```

## Stockage Média Externe

Firebase Storage n'est pas retenu comme stockage principal à cause de la contrainte de facturation. Le stockage média doit être externalisé.

Solution recommandée : Cloudinary.

Responsabilités :

- Upload des photos de profil.
- Upload des logos boutiques.
- Upload des images produits.
- Upload des images de créations.
- Upload des vidéos courtes.
- Optimisation automatique des images.
- Génération de thumbnails.
- Transformation d'images si nécessaire.

Variables minimales côté application :

```text
CLOUDINARY_CLOUD_NAME
CLOUDINARY_UPLOAD_PRESET
CLOUDINARY_FOLDER_ROOT=elegantstyle
```

L'upload preset doit être limité aux formats et tailles réellement nécessaires.

Important :

- Ne jamais mettre `CLOUDINARY_API_SECRET` dans Flutter.
- L'app mobile peut utiliser un preset unsigned limité pour démarrer.
- Les suppressions, signatures, quotas stricts et validations paiement doivent passer par backend ou Cloud Functions à terme.

Organisation recommandée :

```text
cloudinary
  elegantstyle/users/{uid}/avatar
  elegantstyle/shops/{uid}/logo
  elegantstyle/products/{sellerId}/{productId}/...
  elegantstyle/creations/{creatorId}/{creationId}/...
  elegantstyle/messages/{conversationId}/...
  elegantstyle/stories/{authorId}/{storyId}/...
  elegantstyle/wardrobe/{uid}/...
  elegantstyle/events/{eventId}/...
  elegantstyle/editorial/{articleId}/...
```

Dans Firestore, chaque média doit être enregistré ainsi :

```text
media
  id
  provider: "cloudinary"
  resourceType: "image" | "video" | "raw"
  publicId: "elegantstyle/products/sellerId/productId/image01"
  secureUrl: "https://res.cloudinary.com/..."
  optimizedUrl: "https://res.cloudinary.com/.../f_auto,q_auto..."
  thumbnailUrl: "https://res.cloudinary.com/.../c_fill,w_360,h_480..."
  width
  height
  bytes
  format
  duration
  ownerId
  ownerRole
  usage: "avatar" | "product" | "creation" | "message" | "story" | "wardrobe" | "event"
  status: "active" | "pending" | "orphaned" | "deleted"
  createdAt
  updatedAt
```

Pourquoi garder `publicId` :

- Supprimer un média.
- Remplacer une image.
- Nettoyer les fichiers inutilisés.
- Gérer les transformations Cloudinary.

### Collection `media_assets`

Pour éviter de perdre le contrôle quand l'app aura beaucoup d'images et vidéos, chaque upload important doit aussi créer une entrée centrale.

```text
media_assets/{mediaId}
  ownerId
  ownerRole
  provider: "cloudinary"
  resourceType
  usage
  publicId
  secureUrl
  optimizedUrl
  thumbnailUrl
  width
  height
  bytes
  format
  duration
  linkedCollection
  linkedDocumentId
  status
  createdAt
  updatedAt
```

Utilité :

- retrouver tous les médias d'un utilisateur;
- calculer le volume utilisé par compte;
- nettoyer les fichiers orphelins;
- modérer les contenus signalés;
- supprimer proprement une image Cloudinary via backend;
- suivre les coûts Cloudinary.

### Structure Média Recommandée Par Document

Les anciens champs `imageUrl`, `images`, `videoUrl` peuvent rester pour compatibilité, mais la nouvelle structure doit être `media`.

Exemple produit :

```text
products/{productId}
  sellerId
  title
  imageUrl: media.cover.optimizedUrl       // compatibilité UI existante
  media
    cover
      publicId
      secureUrl
      optimizedUrl
      thumbnailUrl
      width
      height
      bytes
    gallery
      [0]
        publicId
        secureUrl
        optimizedUrl
        thumbnailUrl
    video
      publicId
      secureUrl
      thumbnailUrl
      duration
```

Règle UI :

- Grilles mobile : utiliser `thumbnailUrl`.
- Fiches détail : utiliser `optimizedUrl`.
- Zoom plein écran : utiliser `secureUrl` ou une transformation large.
- Vidéos : toujours afficher `thumbnailUrl` avant lecture.

### Transformations Cloudinary Recommandées

Pour la fluidité mobile :

```text
thumbnailUrl:
  f_auto,q_auto:eco,c_fill,g_auto,w_360,h_480,dpr_auto

cardUrl:
  f_auto,q_auto:eco,c_fill,g_auto,w_600,h_800,dpr_auto

detailUrl:
  f_auto,q_auto:good,c_limit,w_1200,dpr_auto

avatarUrl:
  f_auto,q_auto:eco,c_fill,g_face,w_160,h_160,dpr_auto

videoThumbnail:
  f_jpg,q_auto:eco,w_480
```

Pourquoi :

- `f_auto` choisit WebP/AVIF/JPEG selon appareil.
- `q_auto` réduit le poids sans perte visible importante.
- `dpr_auto` adapte aux écrans haute densité.
- `c_fill,g_auto` garde les cartes propres sans déformer.

### Limites Recommandées

Pour éviter une explosion de stockage :

```text
avatar/logo:
  max 2 MB
  1 image active

produit:
  max 8 images
  max 1 vidéo courte
  image source max 6 MB
  vidéo max 30 secondes / 40 MB

création:
  max 10 images
  max 1 vidéo courte

garde-robe client:
  max gratuit: 100 médias
  premium: limite plus haute

messages:
  image max 5 MB
  vidéo max 20 MB
  expiration/nettoyage possible pour fichiers non liés

stories:
  expiration logique 24h
  nettoyage Cloudinary après expiration via backend
```

### Presets Cloudinary Conseillés

Créer plusieurs presets plutôt qu'un seul preset trop permissif :

```text
ElegantStyleImages
  unsigned: true au démarrage
  resource_type: image
  allowed_formats: jpg,png,webp,heic
  max_file_size: 6000000
  folder: elegantstyle

ElegantStyleVideos
  unsigned: true au démarrage
  resource_type: video
  allowed_formats: mp4,mov,webm
  max_file_size: 40000000
  folder: elegantstyle

ElegantStylePrivateProofs
  recommandé signé à terme
  usage: preuves paiement, documents sensibles
```

Dans `.env` :

```text
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_UPLOAD_PRESET=ElegantStyleImages
CLOUDINARY_FOLDER_ROOT=elegantstyle
```

Pour la production idéale :

```text
CLOUDINARY_IMAGE_UPLOAD_PRESET=ElegantStyleImages
CLOUDINARY_VIDEO_UPLOAD_PRESET=ElegantStyleVideos
```

L'app actuelle utilise encore `CLOUDINARY_UPLOAD_PRESET` comme preset commun pour rester simple.

### Suppression et Nettoyage

Ne pas supprimer directement depuis Flutter avec un secret Cloudinary.

Flux recommandé :

```text
Flutter marque media_assets/{mediaId}.status = "pending_delete"
Cloud Function vérifie propriétaire/admin
Cloud Function appelle Cloudinary Admin API avec API_SECRET
Cloud Function marque status = "deleted"
```

Nettoyage automatique :

- médias uploadés mais non liés après 24h -> `orphaned`;
- stories expirées -> suppression différée;
- anciens avatars/logos remplacés -> garder le dernier, supprimer les anciens après délai;
- produits supprimés -> masquer d'abord, nettoyer ensuite.

### Cache Mobile

L'application utilise `cached_network_image`. Pour garder la fluidité :

- Firestore offline persistence est active avec un cache borné;
- le cache image mémoire est limité pour éviter la pression RAM;
- l'accueil client garde un résumé court en mémoire pour limiter les rafales
  de requêtes;
- une bannière offline informe sans bloquer l'usage;
- toujours afficher les miniatures dans les listes;
- éviter de charger les images originales dans les grilles;
- utiliser des dimensions stables pour éviter les sauts de layout;
- précharger seulement les 2 ou 3 images suivantes dans les carrousels;
- paginer les galeries longues;
- garder une image placeholder locale.

### Vidéos

Les vidéos doivent rester courtes dans l'app.

Recommandations :

- utiliser Cloudinary pour héberger les vidéos uploadées par les utilisateurs;
- utiliser YouTube seulement pour les tutoriels publics externes;
- stocker `duration`, `thumbnailUrl`, `playbackUrl`;
- ne jamais lancer l'autoplay dans les listes;
- lecture seulement après action utilisateur;
- charger la vidéo en plein écran ou bottom sheet dédiée.

### Preuves de Paiement

Les preuves de paiement sont plus sensibles que les inspirations.

Recommandation :

- stocker sur Cloudinary mais dans un dossier séparé `elegantstyle/payment_proofs/{orderId}`;
- ne pas les afficher publiquement;
- Firestore garde seulement les références;
- accès UI limité à l'acheteur, au vendeur concerné et à l'admin;
- à terme, passer en upload signé.

## MongoDB

MongoDB n'est pas recommandé comme base directe depuis Flutter.

Raison :

- Une application mobile ne doit pas se connecter directement à MongoDB avec des identifiants serveur.
- Il faut passer par une API backend sécurisée.

MongoDB peut devenir utile plus tard pour :

- Recherche avancée.
- Analytics métier.
- Recommandations complexes.
- Historique massif.
- Agrégations lourdes.

Architecture possible plus tard :

```text
Flutter
  -> API Node.js / NestJS
    -> MongoDB
    -> Cloudinary
    -> Firebase Admin
```

Pour l'étape actuelle, Firestore suffit pour la logique métier.

## Backend Optionnel

Un backend pourra être ajouté si l'app a besoin de :

- Signatures sécurisées Cloudinary.
- Paiements.
- Webhooks.
- Modération automatique.
- Suppression garantie des médias.
- Règles métier sensibles.
- Synchronisation avec MongoDB ou moteur de recherche.

Sans backend, il faut utiliser des uploads Cloudinary non signés avec un preset limité. C'est simple pour démarrer, mais moins sécurisé.

Recommandation :

- Phase 1 : Cloudinary unsigned upload + Firestore.
- Phase 2 : petit backend sécurisé pour signer les uploads.

## Flux d'Upload Recommandé

Exemple pour une image produit :

1. L'utilisateur choisit une image dans Flutter.
2. L'app envoie le fichier à Cloudinary.
3. Cloudinary retourne `secure_url` et `public_id`.
4. L'app crée ou met à jour le document Firestore.
5. L'interface affiche l'image depuis `secure_url`.

```text
Flutter -> Cloudinary -> URL
Flutter -> Firestore -> document produit avec URL
```

Firestore ne reçoit jamais le fichier binaire.

## Migration Depuis Firebase Storage

Le code applicatif Flutter a été basculé vers un service média centralisé et ne doit plus appeler `FirebaseStorage.instance` directement.

Priorité de migration :

1. Photos de profil.
2. Logos boutiques.
3. Images produits.
4. Images de créations.
5. Images de messages.
6. Garde-robe.
7. Stories et contenus communautaires.

Chaque nouvel écran qui manipule des médias doit suivre ce schéma :

- Uploader vers Cloudinary.
- Enregistrer l'URL dans Firestore.
- Garder l'affichage existant basé sur URL.

Service cible :

```text
lib/services/media/media_upload_service.dart
```

Responsabilités du service :

- Uploader image.
- Uploader vidéo.
- Retourner `url`, `publicId`, `type`, `size`.
- Gérer les erreurs réseau.
- Centraliser les dossiers Cloudinary.

Le service doit retourner au minimum :

```text
MediaUploadResult
  url
  publicId
  resourceType
  optimizedUrl
  thumbnailUrl
  width
  height
  bytes
```

Dans le code actuel, `MediaUploadService` génère déjà :

- `optimizedUrl` pour les fiches et détails;
- `thumbnailUrl` pour les grilles;
- `avatarUrl()` pour les profils;
- `transformUrl()` pour créer une transformation Cloudinary à partir d'une URL existante.

## Gestion des Zones

ElegantStyle vise une audience mondiale. Les contenus doivent donc pouvoir être filtrés par zone.

Champs recommandés sur les documents publics :

```text
zone
  country
  city
  region
  latitude
  longitude
```

Usage :

- Afficher les créateurs proches.
- Afficher les boutiques proches.
- Personnaliser la marketplace.
- Garder une expérience locale tout en restant mondiale.

## Règles de Sécurité

Firestore doit contrôler les accès.

Principes :

- Un utilisateur peut lire les contenus publics.
- Un utilisateur peut modifier uniquement son profil.
- Une boutique peut modifier uniquement ses produits.
- Un créateur peut modifier uniquement ses créations.
- Les conversations sont lisibles uniquement par leurs participants.
- Les rôles doivent être vérifiés dans `users/{uid}.roles`.

Cloudinary doit être limité par :

- Upload presets dédiés.
- Taille maximale.
- Types autorisés.
- Dossiers séparés.
- Backend signé à terme.

## Source de Vérité

Source de vérité par type de donnée :

```text
Identité              -> Firebase Auth
Profil et rôles       -> Firestore users/{uid}
Produits              -> Firestore products/{productId}
Créations             -> Firestore creations/{creationId}
Messages              -> Firestore conversations + messages
Fichiers médias       -> Cloudinary
URLs médias           -> Firestore
Notifications push    -> Firebase Messaging + Firestore
Analytics avancés     -> Backend/MongoDB plus tard
```

## Décision Actuelle

Pour la suite du projet, la trajectoire recommandée est :

```text
Firebase Auth + Firestore + Cloudinary
```

Firebase garde le coeur utilisateur et métier.
Cloudinary prend en charge les médias.
MongoDB reste une option future uniquement si l'application a besoin d'un backend plus avancé.
