# Cahier des charges du Salon ElegantStyle

## Vision

Le Salon doit devenir la place publique mode de l'application. Il ne doit pas etre limite au Burkina Faso ni uniquement aux pagnes ou aux boutiques locales. Il doit mettre en valeur toute la mode: tenues, creations, coiffures, chaussures, accessoires, bijoux, inspirations, evenements, lieux, createurs, boutiques, tendances locales et mondiales.

Le Salon doit etre:

- un espace de decouverte visuelle,
- une vitrine publique pour les createurs et boutiques,
- un moteur de recherche transversal,
- un espace d'inspiration et d'information,
- un point d'entree vers l'achat, le contact, le rendez-vous et la communaute.

Le Salon n'est pas un dashboard de gestion. Les createurs et boutiques publient et gerent dans leurs espaces metier; le Salon expose, recommande, connecte et vend.

## Etat actuel analyse

### Fichiers principaux

- `lib/views/screens/global/salon_mode_burkinabe.dart`
- `lib/views/screens/global/salon_search_screen.dart`
- `lib/views/screens/global/tabs/decouvrir_tab.dart`
- `lib/views/screens/global/tabs/boutique_tab.dart`
- `lib/views/screens/global/tabs/createurs_tab.dart`
- `lib/views/screens/global/tabs/inspiration_tab.dart`
- `lib/views/screens/global/tabs/agenda_tab.dart`
- `lib/views/screens/global/widgets/boutique/public_products_section.dart`
- `lib/views/screens/global/widgets/boutique/promotions_section.dart`
- `lib/views/screens/global/widgets/boutique/categories_grid.dart`
- `lib/views/screens/global/widgets/createurs/featured_creators.dart`
- `lib/views/screens/global/widgets/createurs/creator_categories.dart`
- `lib/views/screens/global/widgets/createurs/creators_list.dart`
- `lib/views/screens/global/widgets/inspiration/*`
- `lib/views/screens/global/widgets/agenda/*`

### Structure actuelle

Le Salon contient cinq onglets:

- Decouvrir
- Boutique
- Createurs
- Inspiration
- Agenda

Cette structure est saine. Elle donne une base claire pour une experience publique. Le probleme vient surtout du contenu interne: plusieurs sections sont statiques, certaines restent tres Burkina-centrees, et certaines fonctionnalites utiles existent ailleurs dans l'application mais ne sont pas encore integrees proprement au Salon.

## Forces actuelles

### Navigation claire

Le Salon utilise une navigation mobile en `NavigationBar` et une navigation desktop/tablette en onglets visuels. C'est une bonne base ergonomique.

### Separation avec les dashboards

Le Salon est maintenant separe des espaces createur et boutique. Les boutons de retour contextuels vers l'espace createur/boutique ameliorent le workflow.

### Donnees dynamiques deja presentes

Certaines sections utilisent deja Firestore:

- produits,
- creations,
- utilisateurs,
- evenements,
- inspirations,
- panier global.

La section `PublicProductsSection` utilise maintenant le panier global officiel, ce qui reduit les risques de types incompatibles et de logique dupliquee.

### Recherche globale existante

`SalonSearchScreen` recherche deja dans:

- `products`,
- `creations`,
- `users`,
- `events`,
- `inspirations`.

C'est exactement le bon principe pour un Salon transversal.

### Inspiration et communaute riches

L'onglet Inspiration contient deja:

- looks tendance,
- conseiller style,
- quiz,
- communaute,
- articles culturels,
- tutoriels.

Il y a beaucoup de matiere a reutiliser, mais elle doit etre mieux organisee et moins statique.

## Faiblesses actuelles

### Nom et positionnement trop limites

Le nom `SalonModeBurkinabeScreen` donne une intention trop locale. Le produit doit devenir un Salon mode global, capable de presenter le Burkina, l'Afrique et le monde.

Recommandation:

- garder une compatibilite technique temporaire,
- renommer progressivement vers `SalonScreen` ou `GlobalFashionSalonScreen`,
- remplacer les libelles trop limites par des textes plus inclusifs.

### Trop de donnees statiques

Plusieurs widgets contiennent encore des listes de demonstration:

- `CategoriesGrid`
- `FeaturedCreators`
- `CreatorCategories`
- `CreatorsList`
- `CulturalInspiration`
- certains fallbacks de `TrendingLooks`
- certains evenements de `UpcomingEvents`
- certains contenus de `FashionTutorials`

Ces donnees donnent une impression de contenu riche, mais elles ne representent pas les vrais utilisateurs. Elles doivent devenir des fallbacks uniquement, jamais le contenu principal.

### Trop de contenu Burkina-centre

Les textes et categories mentionnent souvent:

- Faso Dan Fani,
- Mode BF,
- Ouaga,
- Burkina Faso,
- sources burkinabe,
- evenements burkinabe.

Ces elements doivent rester comme une richesse culturelle, mais ne doivent plus etre l'axe unique du Salon.

Le Salon doit aussi couvrir:

- mode africaine contemporaine,
- streetwear,
- haute couture,
- modest fashion,
- bridal / mariage,
- casual,
- business,
- coiffures,
- barber / grooming,
- chaussures,
- bijoux,
- sacs,
- beaute,
- textile,
- upcycling,
- mode enfant,
- grandes tendances internationales.

### Inspiration trop separee du commerce

Les looks, articles et tutoriels inspirent, mais ils ne relient pas assez vers:

- produits similaires,
- createurs capables de realiser le style,
- boutiques qui vendent les pieces,
- rendez-vous,
- essayage virtuel,
- garde-robe.

Le Salon doit transformer l'inspiration en action.

### Recherche encore superficielle

La recherche charge des lots limites puis filtre cote client. C'est acceptable pour un debut, mais pas pour un Salon global.

Problemes:

- pas de filtres avances,
- pas de tri par ville, pays, prix, style, taille, categorie,
- pas de recherche geographique,
- pas de synonymes mode,
- pas de recherche par coiffure, chaussure, evenement ou createur specialise,
- pas de navigation vers une page detail riche depuis chaque resultat.

### Promotions par scraping fragile

`promotions_section.dart` contient une logique de scraping web et des sources tres locales. Cette approche est fragile, lente et difficile a maintenir.

Recommandation:

- remplacer le scraping direct par une collection Firestore `fashionFeeds` ou `externalFashionNews`,
- ajouter un service backend/cloud function pour agreger les sources,
- afficher la source, la date, le pays et le type de contenu,
- garder le scraping uniquement cote serveur si necessaire.

### Cles API exposees

Certains fichiers lies aux fonctionnalites mode contiennent des cles API en dur:

- `FashionTutorials` avec YouTube API,
- `TrendingLooks` avec Unsplash,
- `VirtualTryOnScreen` avec des cles IA.

Ces cles ne doivent pas rester dans le client. Elles doivent passer par:

- variables d'environnement,
- remote config,
- backend proxy,
- Cloud Functions,
- systeme de quotas et securite.

### Trop d'effets de cartes

Le Salon utilise beaucoup de cartes, ombres et surfaces imbriquees. Le rendu est coherent mais peut devenir lourd sur mobile.

Recommandation:

- reserver les cartes aux items,
- utiliser des sections plus aeriennes,
- eviter les cartes dans les cartes,
- donner plus de place aux images et aux creations.

## Positionnement produit cible

Le Salon doit etre organise autour de cinq grands usages:

### 1. Decouvrir

Objectif: donner envie d'explorer.

Contenu:

- hero dynamique base sur les vraies collections,
- nouveautes,
- tendances du moment,
- categories globales,
- createurs en avant,
- boutiques en avant,
- looks populaires,
- evenements proches.

Actions:

- voir les nouveautes,
- explorer par style,
- explorer pres de moi,
- ouvrir la recherche,
- passer vers inspiration ou boutique.

### 2. Acheter

Objectif: acheter ou sauvegarder des pieces.

Contenu:

- produits,
- creations vendables,
- chaussures,
- sacs,
- bijoux,
- accessoires,
- textiles,
- articles beaute/coiffure si vendables.

Filtres:

- categorie,
- style,
- prix,
- pays/ville,
- livraison,
- taille,
- couleur,
- matiere,
- occasion,
- vendeur,
- stock disponible.

Actions:

- ajouter au panier,
- voir detail,
- contacter vendeur,
- commander chez ce vendeur,
- sauvegarder,
- partager.

### 3. Trouver un talent

Objectif: trouver un createur, coiffeur, styliste, boutique ou artisan.

Profils a inclure:

- createur de mode,
- tailleur,
- styliste,
- coiffeur/coiffeuse,
- barber,
- maquilleur,
- cordonnier,
- bijoutier,
- photographe mode,
- mannequin,
- boutique,
- artisan textile.

Filtres:

- metier,
- specialite,
- ville/pays,
- disponibilite,
- note,
- portfolio,
- prix indicatif,
- langue,
- verification.

Actions:

- suivre,
- envoyer un message,
- prendre rendez-vous,
- voir portfolio,
- voir produits,
- demander un devis.

### 4. S'inspirer

Objectif: comprendre les tendances et composer son style.

Contenu:

- looks utilisateurs,
- looks createurs,
- tendances mondiales,
- tendances locales,
- coiffures,
- chaussures,
- associations de couleurs,
- inspirations mariage/bureau/ceremonie/streetwear,
- articles culturels,
- tutoriels video,
- conseils IA.

Actions:

- sauvegarder dans garde-robe,
- essayer virtuellement,
- trouver des produits similaires,
- demander conseil,
- partager a la communaute,
- contacter un createur.

### 5. Sortir / participer

Objectif: suivre les evenements mode.

Contenu:

- fashion weeks,
- ventes privees,
- pop-up stores,
- ateliers,
- formations,
- castings,
- expositions,
- lancements de collection,
- lives ou evenements en ligne.

Filtres:

- date,
- ville/pays,
- gratuit/payant,
- type,
- presentiel/en ligne,
- public cible.

Actions:

- s'inscrire,
- ajouter au calendrier,
- partager,
- contacter organisateur,
- voir les createurs participants.

## Donnees a rendre dynamiques

### Collections Firestore recommandees

#### `salonListings`

Collection unifiee pour exposer ce qui apparait dans le Salon.

Champs:

- `id`
- `type`: product, creation, look, hairstyle, shoe, accessory, event, article, tutorial
- `title`
- `description`
- `images`
- `ownerId`
- `ownerRole`
- `ownerName`
- `ownerPhoto`
- `price`
- `currency`
- `category`
- `subCategory`
- `styleTags`
- `occasionTags`
- `genderTarget`
- `country`
- `city`
- `location`
- `isSellable`
- `isBookable`
- `visibility`
- `status`
- `createdAt`
- `updatedAt`
- `stats.views`
- `stats.likes`
- `stats.saves`
- `stats.orders`

#### `fashionCategories`

Categories administrables.

Exemples:

- Vetements
- Chaussures
- Coiffures
- Bijoux
- Sacs
- Accessoires
- Textile
- Beaute
- Mariage
- Streetwear
- Business
- Traditionnel
- Luxe
- Enfant

#### `styleTaxonomy`

Taxonomie pour harmoniser les tags.

Champs:

- `style`: streetwear, chic, minimaliste, afro contemporain, traditionnel, casual, gala
- `occasion`: mariage, bureau, ceremonie, sortie, sport, quotidien
- `materials`: coton, cuir, wax, soie, denim, lin, bogolan, kente
- `colors`
- `regions`
- `hairStyles`
- `shoeTypes`

#### `fashionFeeds`

Contenus externes ou editoriaux.

Champs:

- `title`
- `summary`
- `url`
- `imageUrl`
- `source`
- `country`
- `language`
- `publishedAt`
- `topics`
- `contentType`: article, video, trend, event
- `validated`

#### `salonEvents`

Evenements normalises.

Champs:

- `title`
- `description`
- `startAt`
- `endAt`
- `country`
- `city`
- `venue`
- `isOnline`
- `organizerId`
- `organizerName`
- `coverImage`
- `price`
- `registrationUrl`
- `tags`
- `status`

## Fonctionnalites a integrer depuis les interfaces existantes

### Depuis Marketplace

A integrer dans l'onglet Talents:

- recherche createurs/boutiques,
- filtres createur/boutique,
- suivre,
- ouvrir profil public,
- contacter par message,
- consulter portfolio,
- voir localisation.

Marketplace peut devenir une vue reseau relationnel, mais le Salon doit reprendre la decouverte publique des talents.

### Depuis TrendsScreen

A integrer dans Inspiration:

- flux produits + creations,
- likes,
- signalement,
- detail look/produit,
- categories dynamiques,
- infinite scroll,
- tri par tendance.

### Depuis VirtualTryOnScreen

A integrer dans Boutique/Inspiration:

- bouton "Essayer" sur une creation compatible,
- suggestions de pieces essayables,
- selection d'une creation depuis le Salon,
- retour vers achat ou contact createur.

### Depuis StyleHub / Assistant IA

A integrer dans Inspiration:

- "Demander a Iris une tenue similaire",
- "Trouver les couleurs qui me vont",
- "Adapter ce look a ma morphologie",
- "Composer une tenue complete avec cette piece".

### Depuis CommunityScreen

A integrer dans Inspiration:

- questions mode,
- demandes d'avis sur look,
- partage de photos,
- reponses de la communaute,
- categories globales: coiffures, chaussures, mariage, bureau, streetwear, traditions, beaute.

## Ameliorations UX prioritaires

### Hero du Salon

Remplacer le hero generique par un hero editorial dynamique.

Contenu propose:

- image forte issue d'une vraie creation ou collection,
- titre de collection,
- createur/boutique associe,
- pays/ville,
- boutons: `Voir la collection`, `Explorer les styles`, `Pres de moi`.

Le hero doit changer selon:

- saison,
- tendances,
- localisation utilisateur,
- role actif,
- nouveautes.

### Navigation

Renommer les onglets pour couvrir toute la mode:

- Decouvrir
- Styles
- Shopping
- Talents
- Agenda

Ou:

- Accueil
- Boutique
- Talents
- Inspiration
- Evenements

Ajouter des sous-filtres horizontaux:

- Tenues
- Coiffures
- Chaussures
- Accessoires
- Mariage
- Streetwear
- Luxe
- Local
- Monde

### Recherche

Transformer la recherche en centre de commande.

Filtres minimum:

- mot-cle,
- categorie,
- pays,
- ville,
- prix,
- type: produit, creation, talent, evenement, article,
- style,
- occasion,
- disponible maintenant,
- pres de moi.

Resultats:

- sections groupees,
- actions rapides,
- navigation vers detail,
- suggestions de recherche.

### Detail public

Chaque item du Salon doit avoir une page detail.

Produit/creation:

- galerie images,
- prix,
- description,
- tailles/couleurs,
- createur/boutique,
- localisation,
- livraison,
- panier,
- essayer virtuellement,
- produits similaires.

Talent:

- portfolio,
- specialites,
- localisation,
- disponibilites,
- avis,
- message,
- rendez-vous,
- produits/creations.

Look/inspiration:

- images,
- tags,
- produits similaires,
- createurs capables de realiser,
- sauvegarder,
- demander conseil IA,
- partager.

### Localisation

Ajouter une logique "pres de moi" sans exclure le monde.

Modes:

- Pres de moi,
- Dans mon pays,
- Afrique,
- Monde,
- En ligne.

Champs requis:

- `country`
- `city`
- `geoPoint`
- `shippingZones`
- `availableOnline`

### Mise en valeur des creations utilisateurs

Ajouter:

- "Creations de la semaine",
- "Nouveaux talents",
- "Looks de la communaute",
- "Avant / apres",
- "Coup de coeur editorial",
- "Pieces disponibles maintenant",
- "Createurs pres de toi",
- "Coiffures tendance",
- "Chaussures qui completent le look".

## Nettoyage recommande

### A remplacer ou refondre

- `CategoriesGrid`: remplacer les statistiques statiques par `fashionCategories` + compte Firestore.
- `FeaturedCreators`: remplacer les createurs demo par les vrais users avec role createur/boutique/talent.
- `CreatorCategories`: remplacer les chiffres et sources statiques par une taxonomie administrable.
- `CreatorsList`: brancher sur Firestore et fusionner avec la logique Marketplace.
- `CulturalInspiration`: transformer en flux editorial dynamique.
- `FashionTutorials`: retirer la cle API du client et passer par backend.
- `TrendingLooks`: eviter la cle Unsplash en dur; melanger contenus utilisateurs + sources externes validees.
- `UpcomingEvents`: remplacer la simulation par `salonEvents`.
- `PromotionsSection`: remplacer le scraping direct par flux backend ou collection `fashionFeeds`.

### A renommer progressivement

- `SalonModeBurkinabeScreen` vers `SalonScreen`.
- Textes "Mode BF" vers "Mode locale" ou "Styles du monde".
- "Talents locaux" vers "Talents & ateliers".
- "Boutique" vers "Shopping" si l'onglet couvre produits, chaussures, coiffures vendables et accessoires.

## Workflow par type d'utilisateur

### Visiteur non connecte

Peut:

- explorer,
- rechercher,
- voir details,
- lire articles,
- voir evenements.

Doit se connecter pour:

- panier,
- commande,
- rendez-vous,
- message,
- sauvegarde,
- publication.

### Client

Peut:

- acheter,
- sauvegarder,
- suivre,
- demander conseil,
- essayer virtuellement,
- prendre rendez-vous,
- contacter.

### Createur

Peut:

- explorer comme client,
- voir sa vitrine publique,
- partager ses creations,
- verifier comment ses pieces apparaissent.

Ne gere pas ses creations dans le Salon. La gestion reste dans l'espace createur.

### Boutique

Peut:

- explorer comme client,
- voir sa vitrine publique,
- suivre ses produits exposes,
- partager une collection.

Ne gere pas ses produits dans le Salon. La gestion reste dans l'espace boutique.

### Admin

Peut:

- moderer,
- valider contenus externes,
- epingler une collection,
- controler les categories,
- gerer les signalements.

## Priorites de realisation

### Phase 1: Clarification et nettoyage

1. Renommer visuellement le Salon pour ne plus etre uniquement burkinabe.
2. Retirer ou transformer les donnees statiques les plus visibles.
3. Brancher `FeaturedCreators`, `CreatorsList` et `CategoriesGrid` sur Firestore.
4. Ajouter filtres globaux: categorie, pays/ville, type, style.
5. Ameliorer le hero avec vraie collection.
6. Ajouter pages detail produit/creation/talent.

### Phase 2: Mise en valeur et decouverte

1. Creer `salonListings` comme index public unifie.
2. Ajouter recommandations: nouveau, populaire, pres de moi, similaire.
3. Ajouter categories mode globales: coiffures, chaussures, accessoires, beaute.
4. Relier Inspiration vers Shopping et Talents.
5. Integrer "Essayer virtuellement" depuis les fiches compatibles.
6. Ajouter sauvegarde de looks et favoris.

### Phase 3: Informations et tendances monde

1. Creer `fashionFeeds`.
2. Remplacer scraping client par backend.
3. Ajouter sources internationales validees.
4. Ajouter videos/tutoriels via backend.
5. Ajouter moderation admin.
6. Ajouter traduction ou langue de contenu.

### Phase 4: Professionnalisation

1. Analytics Salon: vues, clics, saves, commandes, messages.
2. Ranking intelligent.
3. SEO/app links si web.
4. Notifications: nouveau drop, evenement, createur suivi.
5. Tests sur recherche, filtres, panier, details.

## Proposition d'architecture cible

```text
lib/views/screens/global/salon/
  salon_screen.dart
  salon_search_screen.dart
  models/
    salon_listing.dart
    salon_filter.dart
    fashion_category.dart
  services/
    salon_service.dart
    salon_search_service.dart
    fashion_feed_service.dart
  tabs/
    discover_tab.dart
    shopping_tab.dart
    talents_tab.dart
    inspiration_tab.dart
    events_tab.dart
  widgets/
    salon_hero.dart
    salon_filter_bar.dart
    listing_card.dart
    talent_card.dart
    inspiration_card.dart
    event_card.dart
```

## Definition de succes

Le Salon sera reussi quand:

- un utilisateur comprend en moins de 5 secondes ce qu'il peut explorer,
- les creations reelles des utilisateurs sont plus visibles que les donnees demo,
- un createur voit clairement comment ses creations sont mises en valeur,
- une boutique voit ses produits exposes sans dupliquer la gestion,
- un client peut passer de l'inspiration a l'achat ou au rendez-vous,
- la recherche trouve produits, talents, styles, evenements et informations,
- la plateforme couvre le local et le mondial sans perdre son identite culturelle.

## Decision produit

Le Salon doit devenir:

> un hub mode mondial avec une sensibilite africaine forte, centre sur les creations des utilisateurs, enrichi par des inspirations, evenements et informations verifies.

Il ne faut pas supprimer l'identite burkinabe. Il faut l'elever: elle devient une categorie forte dans une experience mode plus large, pas la limite du produit.
