# Analyse fonctionnelle ElegantStyle

## Constat Global

L'application a évolué d'un modèle à rôles séparés vers un compte multi-rôles. Un même utilisateur peut maintenant acheter comme client, créer comme créateur, vendre comme boutique, et parfois accéder à des espaces anciennement isolés. Cette évolution est pertinente pour une plateforme mode, mais elle a créé un chevauchement entre les écrans, les responsabilités et les parcours.

Le problème principal n'est pas que tout le monde puisse accéder à tout. Le problème est que les écrans ne disent pas toujours clairement dans quel contexte l'utilisateur agit: visiteur du salon, client acheteur, créateur qui gère son activité, boutique qui vend, ou administrateur. Le salon, en particulier, est devenu un espace ouvert mais il est aussi intégré comme onglet dans les dashboards client, créateur et boutique. Cela donne l'impression que certaines fonctionnalités se répètent.

## Modèle Actuel des Rôles

Le projet contient deux logiques de rôle en parallèle.

Ancienne logique:
- `role` unique: `client`, `createur`, `boutique`, `admin`
- routage direct vers un dashboard par rôle
- fichiers concernés: `lib/app/routes.dart`, `auth_wrapper.dart`, `role_router.dart`

Nouvelle logique:
- `roles`: liste des rôles possédés
- `activeRole`: espace courant
- `roleFlags`: indicateurs pratiques
- fichier central: `lib/core/account_roles.dart`
- switch d'espace: `lib/views/widgets/account/account_space_switcher.dart`

Cette transition est saine, mais elle n'est pas encore complètement stabilisée. Certains écrans utilisent encore une logique de rôle unique tandis que d'autres acceptent le multi-rôle.

## Utilisateurs de Base

### 1. Visiteur / Utilisateur Non Connecté

Objectif:
- découvrir l'application
- voir les tendances, inspirations, créateurs, boutiques
- comprendre la valeur de la plateforme avant connexion

Ce qui devrait être accessible:
- salon public en lecture
- inspirations publiques
- créateurs publics
- produits publics
- événements publics
- login / inscription

Ce qui devrait être limité:
- panier persistant
- commande
- chat privé
- rendez-vous
- publication
- gestion boutique/créateur

Problème actuel:
- certains services retournent une liste vide quand l'utilisateur n'est pas connecté, par exemple le panier. Cela peut faire croire à un panier vide plutôt qu'à un état non connecté.

Recommandation:
- créer un état explicite "Connectez-vous pour utiliser cette action".
- garder le salon consultable sans rôle.

### 2. Client

Objectif:
- découvrir la mode
- acheter
- gérer son style personnel
- suivre des créateurs ou boutiques
- prendre rendez-vous
- discuter avec un vendeur ou créateur

Fonctionnalités pertinentes:
- Accueil client
- Salon
- Boutique publique
- Marketplace / réseau mode
- Tendances
- Essayage virtuel
- Mon Style
- Garde-robe
- Mensurations
- Assistant IA
- Recommandations
- Panier et commandes
- Profil client

Écrans concernés:
- `lib/views/screens/client/home/home_screen.dart`
- `lib/views/screens/client/home/home_content_screen.dart`
- `lib/views/screens/global/salon_mode_burkinabe.dart`
- `lib/views/screens/client/marketplace/marketplace_screen.dart`
- `lib/views/screens/client/features/style/style_hub_screen.dart`
- `lib/views/screens/client/features/trends_screen.dart`
- `lib/views/screens/client/features/virtual_try_on_screen.dart`

Chevauchements:
- Salon et Marketplace montrent tous deux des créateurs/boutiques.
- Salon/Boutique et écrans boutique globaux montrent produits/promotions.
- StyleHub, InspirationTab et Tendances peuvent tous présenter des idées de style.

Clarification recommandée:
- Client Home = espace personnel du client.
- Salon = espace public de découverte et commerce.
- Marketplace = relation directe avec créateurs/boutiques, à fusionner ou repositionner comme "Réseau".
- StyleHub = outils personnels, non publics.

### 3. Créateur

Objectif:
- gérer ses créations
- gérer clients, rendez-vous et mensurations partagées
- suivre ses statistiques
- recevoir des looks partagés
- être visible dans le salon

Fonctionnalités pertinentes:
- dashboard créateur
- créations
- rendez-vous
- clients
- statistiques
- looks partagés
- profil créateur
- visibilité salon

Écrans concernés:
- `lib/views/screens/createur/createur_dashboard_screen.dart`
- `lib/views/screens/createur/createur_tabs/dashboard_tab.dart`
- `lib/views/screens/createur/createur_tabs/creations_tabs.dart`
- `lib/views/screens/createur/createur_tabs/appointments_tab.dart`
- `lib/views/screens/createur/createur_tabs/clients_tab.dart`
- `lib/views/screens/createur/createur_tabs/shared_looks_screen.dart`
- `lib/views/screens/createur/createur_tabs/stats_tab.dart`

Chevauchements:
- Le dashboard créateur intègre le salon comme onglet. Cela mélange outil de gestion et espace public.
- Certains écrans créateur affichent aussi des listes de boutiques ou créateurs, ce qui ressemble au salon.
- Les créations du créateur et les produits du salon peuvent représenter le même contenu mais sous deux angles différents.

Clarification recommandée:
- Espace Créateur = back-office.
- Salon = vitrine publique où les créations apparaissent.
- Le créateur ne devrait pas "gérer" depuis le salon, mais voir comment sa vitrine publique apparaît.

### 4. Boutique

Objectif:
- gérer les produits
- gérer commandes, rendez-vous, clients
- gérer profil boutique
- publier promotions ou galerie
- être visible dans le salon

Fonctionnalités pertinentes:
- dashboard boutique
- produits
- commandes
- rendez-vous
- profil boutique
- notifications
- avis, galerie, promos, stats, messages
- salon public

Écrans concernés:
- `lib/views/screens/boutique/dashboard/boutique_dashboard.dart`
- `lib/views/screens/boutique/dashboard/boutique_home_screen.dart`
- `lib/views/screens/boutique/products/boutique_products_screen.dart`
- `lib/views/screens/boutique/orders/boutique_orders_screen.dart`
- `lib/views/screens/boutique/appointment/boutique_appointments_screen.dart`
- `lib/views/screens/boutique/profile/boutique_profile_screen.dart`
- `lib/views/screens/boutique/features/*`

Chevauchements:
- BoutiqueDashboard intègre le salon comme onglet.
- Produits boutique et produits salon peuvent utiliser des modèles/services différents.
- Plusieurs fichiers panier/checkout existent dans `global/widgets/boutique`, en plus des nouveaux fichiers extraits du salon.

Clarification recommandée:
- Espace Boutique = gestion.
- Salon = vitrine et vente publique.
- Les produits doivent être saisis côté boutique, puis exposés côté salon.
- Les commandes doivent être créées côté salon/client, puis gérées côté boutique.

### 5. Admin

Objectif:
- gouvernance, modération, validation, statistiques globales
- gestion utilisateurs, rôles et contenus

Fonctionnalités pertinentes:
- dashboard admin
- gestion utilisateurs
- validation boutiques/créateurs
- suivi des commandes et signalements
- modération salon

Écrans concernés:
- `lib/views/screens/admin/main_admin.dart`
- `lib/views/screens/admin/dashboard/*`
- `lib/views/screens/admin/users/*`

Chevauchements:
- Le rôle admin existe dans le routage et les modèles, mais le passage multi-rôle semble moins intégré que pour client/créateur/boutique.

Clarification recommandée:
- Admin ne doit pas être un simple espace utilisateur supplémentaire.
- Admin doit rester un espace opérationnel protégé, probablement hors du switch public.

## Le Salon: Rôle Produit Recommandé

Le salon doit être considéré comme un espace ouvert transversal, pas comme un dashboard de rôle.

Positionnement recommandé:
- Découvrir: accueil public du salon
- Boutique: produits et promotions
- Créateurs: profils publics et savoir-faire
- Inspiration: contenus éditoriaux, looks, tendances
- Agenda: événements, ateliers, ventes privées
- Panier / commande: action client

Le salon ne doit pas remplacer:
- le dashboard client
- le dashboard créateur
- le dashboard boutique
- l'admin

Le salon doit exposer les contenus créés ailleurs:
- produits créés par les boutiques
- créations publiées par les créateurs
- événements publiés ou validés
- inspirations communautaires

En clair:
- Boutique crée et gère.
- Créateur crée et gère.
- Salon expose et vend.
- Client explore et achète.
- Admin contrôle.

## Chevauchements Identifiés

### Salon vs Home Client

Home Client:
- personnalisé
- missions, quiz, progression
- recommandations personnelles

Salon:
- public
- découverte commerciale
- navigation par contenu

Action:
- garder les deux, mais ne pas faire du Home Client une copie du salon.
- Home Client peut afficher des raccourcis vers le salon, pas dupliquer tout le salon.

### Salon vs Marketplace

Marketplace:
- relation directe avec créateurs/boutiques
- profils, chat, suivi, contact

Salon:
- découverte éditoriale + produits + agenda

Action:
- soit fusionner Marketplace dans l'onglet Créateurs du salon,
- soit repositionner Marketplace comme "Réseau" orienté relation, suivi et messagerie.

### Salon Boutique vs Boutique Dashboard

Salon Boutique:
- acheter
- découvrir
- comparer

Boutique Dashboard:
- gérer produits
- suivre commandes
- gérer profil et ventes

Action:
- ne jamais mélanger actions de gestion dans le salon.
- ajouter dans le dashboard boutique un bouton "Voir ma vitrine dans le salon".

### StyleHub vs Inspiration / Tendances

StyleHub:
- outils personnels: IA, mensurations, garde-robe, recommandations

Inspiration / Tendances:
- contenu public ou éditorial

Action:
- garder StyleHub comme studio personnel.
- garder Inspiration/Tendances comme exploration publique.

### Panier / Checkout Multiples

Constat:
- plusieurs anciennes versions de `CartItem`, `CartService`, `CartScreen`, `CheckoutScreen` existent dans `lib/views/screens/global/widgets/boutique`.
- une nouvelle version a été extraite dans:
  - `lib/models/global/cart_item.dart`
  - `lib/services/global/cart_service.dart`
  - `lib/views/screens/global/cart_screen.dart`
  - `lib/views/screens/global/checkout_screen.dart`

Risque:
- types incompatibles
- bugs de hot reload
- logique de commande dupliquée
- panier différent selon l'écran d'origine

Action:
- choisir une seule implémentation officielle du panier.
- migrer les widgets boutique vers `models/global/cart_item.dart` et `services/global/cart_service.dart`.
- supprimer ou déprécier les doublons après migration.

## Architecture Recommandée

### Niveau 1: Shell Principal

Créer un shell unique d'application après connexion:

- Accueil
- Salon
- Style
- Messages
- Profil

Le shell n'est pas "client" uniquement. Il représente l'application commune.

### Niveau 2: Espaces Métier

Depuis Profil ou un switcher:

- Espace Client
- Espace Créateur
- Espace Boutique
- Espace Admin si autorisé

Chaque espace métier doit avoir son dashboard de gestion, pas son propre accès dupliqué à tout.

### Niveau 3: Salon Public

Le salon devient le hub public transversal:

- Découvrir
- Boutique
- Créateurs
- Inspiration
- Agenda
- Recherche globale
- Panier

Tous les rôles peuvent y accéder, mais les actions changent selon le contexte:

- non connecté: voir, inviter à se connecter
- client: acheter, suivre, réserver
- créateur: voir sa vitrine, partager
- boutique: voir sa vitrine, partager
- admin: modérer

## Matrice Fonctionnelle Recommandée

| Fonction | Visiteur | Client | Créateur | Boutique | Admin |
|---|---:|---:|---:|---:|---:|
| Voir salon | Oui | Oui | Oui | Oui | Oui |
| Rechercher salon | Oui | Oui | Oui | Oui | Oui |
| Ajouter panier | Connexion requise | Oui | Oui, comme acheteur | Oui, comme acheteur | Optionnel |
| Commander | Non | Oui | Oui, comme acheteur | Oui, comme acheteur | Non prioritaire |
| Publier produit | Non | Non | Optionnel si créateur vend | Oui | Oui/modération |
| Publier création | Non | Non | Oui | Optionnel | Oui/modération |
| Gérer commandes reçues | Non | Non | Si vente créateur | Oui | Supervision |
| Gérer rendez-vous | Non | Demander | Recevoir/gérer | Recevoir/gérer | Supervision |
| Assistant style | Non ou limité | Oui | Oui | Oui | Optionnel |
| Mensurations | Non | Oui | Consulter si partagé | Consulter si partagé | Non |
| Admin utilisateurs | Non | Non | Non | Non | Oui |

## Navigation Recommandée

### Barre Principale Commune

Pour tous les utilisateurs connectés:

1. Accueil
2. Salon
3. Style
4. Messages
5. Profil

### Profil / Menu Compte

Contient:

- Mes informations
- Mes commandes
- Mes rendez-vous
- Changer d'espace
- Devenir créateur
- Ouvrir boutique
- Paramètres
- Déconnexion

### Espaces Métier

Espace Créateur:
- Tableau
- Créations
- RDV
- Clients
- Stats
- Voir ma vitrine

Espace Boutique:
- Tableau
- Produits
- Commandes
- RDV
- Stats
- Profil boutique
- Voir ma vitrine

Admin:
- Tableau global
- Utilisateurs
- Contenus
- Commandes
- Signalements
- Configuration

## Recommandations de Nettoyage Technique

### 1. Unifier les rôles

Utiliser partout:
- `AccountRoles`
- `AccountRoleService`
- `activeRole`
- `roles`

Éviter progressivement:
- `AppUserRoles` dans `core/types.dart`
- logique `role` unique comme source de vérité

Le champ `role` peut rester pour compatibilité, mais ne doit plus piloter toute l'expérience seul.

### 2. Créer un `AppShell`

Remplacer progressivement `HomeScreen` comme shell global. Aujourd'hui `HomeScreen` est encore très client, mais il contient déjà le salon et des fonctions transversales.

Nom possible:
- `MainShellScreen`
- `ElegantShell`
- `AppHomeShell`

### 3. Déplacer le Salon hors des dashboards métier

Au lieu d'avoir le salon comme onglet dans:
- Home client
- Dashboard créateur
- Dashboard boutique

Le salon doit être accessible depuis le shell global. Dans les dashboards métier, utiliser un bouton:

- "Voir ma vitrine dans le salon"
- "Ouvrir le salon"

### 4. Supprimer les doublons panier

Implémentation officielle proposée:
- `lib/models/global/cart_item.dart`
- `lib/services/global/cart_service.dart`
- `lib/views/screens/global/cart_screen.dart`
- `lib/views/screens/global/checkout_screen.dart`

À migrer / nettoyer:
- `lib/views/screens/global/widgets/boutique/cart_item.dart`
- `lib/views/screens/global/widgets/boutique/cart_service.dart`
- `lib/views/screens/global/widgets/boutique/cart_screen.dart`
- `lib/views/screens/global/widgets/boutique/checkout_screen.dart`
- doublons internes dans `recommended_products.dart`

### 5. Clarifier les collections Firestore

Proposition:

- `users`: identité, rôles, profils courts
- `products`: produits vendables
- `creations`: créations / portfolio
- `orders`: commandes
- `appointments`: rendez-vous
- `messages`: conversations
- `events`: événements
- `inspirations`: contenus inspiration
- `wardrobes`: garde-robes client
- `measurements`: mensurations

Chaque document vendable doit avoir:
- `ownerId`
- `ownerRole`
- `visibility`
- `status`
- `createdAt`
- `updatedAt`

### 6. Séparer contenu public et gestion

Pour chaque domaine:

Public:
- liste
- détail
- recherche
- suivre
- acheter

Gestion:
- créer
- modifier
- supprimer
- statistiques
- validation

Exemple produit:
- public: `Salon > Boutique > ProductDetail`
- gestion: `BoutiqueDashboard > Produits > EditProduct`

## Priorités de Refactor

### Phase 1: Clarification UX

1. Renommer "HomeScreen" en shell commun ou créer un nouveau shell.
2. Placer Salon comme onglet principal commun.
3. Retirer le salon des dashboards créateur/boutique ou le transformer en raccourci.
4. Ajouter dans chaque dashboard un texte clair: "Vous êtes en espace gestion".
5. Ajouter un badge d'espace actif dans l'app bar.

### Phase 2: Unification fonctionnelle

1. Unifier panier et checkout.
2. Unifier les modèles de produit/création exposés au salon.
3. Brancher les commandes du salon vers les dashboards boutique/créateur.
4. Centraliser messages et notifications.
5. Standardiser les états non connecté / accès requis.

### Phase 3: Gouvernance multi-rôle

1. Migrer tout le routage vers `AccountRoleService`.
2. Garder `role` uniquement comme compatibilité legacy.
3. Ajouter des guards par capacité plutôt que par rôle strict:
   - `canBuy`
   - `canCreate`
   - `canSell`
   - `canModerate`
4. Ajouter une page de gestion des rôles dans le profil.

### Phase 4: Nettoyage code

1. Supprimer les anciens doublons panier.
2. Extraire les widgets globaux réutilisables.
3. Réduire les fichiers très longs.
4. Ajouter tests simples sur:
   - `AccountRoles.normalize`
   - `CartService.groupItemsByVendor`
   - création commande
   - permissions par capacité

## Proposition de Structure Finale

```text
lib/
  app/
    app_shell.dart
    routes.dart
  core/
    account_roles.dart
    capabilities.dart
  models/
    global/
      cart_item.dart
      public_listing.dart
    orders/
      order.dart
  services/
    global/
      cart_service.dart
      salon_service.dart
    roles/
      role_service.dart
  views/
    screens/
      global/
        salon_mode_burkinabe.dart
        salon_search_screen.dart
        cart_screen.dart
        checkout_screen.dart
      client/
        style/
        profile/
      createur/
        dashboard/
        creations/
      boutique/
        dashboard/
        products/
        orders/
      admin/
```

## Décision Produit Recommandée

Le meilleur modèle pour ElegantStyle est:

> Un compte unique, plusieurs capacités, un salon public central, et des espaces de gestion séparés.

Cela évite de revenir à des comptes cloisonnés tout en empêchant les fonctionnalités de se chevaucher.

Le salon doit être la place publique.
Les dashboards doivent être les ateliers de gestion.
Le profil doit être le centre de contrôle du compte multi-rôle.

## Résumé Court

Aujourd'hui, l'application fonctionne comme si les anciens rôles avaient été simplement empilés dans un même compte. Il faut maintenant passer à une logique plus claire:

- `Salon`: découvrir, acheter, suivre, réserver
- `Client`: gérer son style et ses achats
- `Créateur`: gérer créations, clients, rendez-vous, stats
- `Boutique`: gérer produits, commandes, rendez-vous, stats
- `Admin`: modérer et piloter
- `Profil`: changer d'espace et gérer les capacités du compte

La priorité la plus importante est de ne plus dupliquer le salon dans chaque dashboard, mais de le rendre central et transversal.
