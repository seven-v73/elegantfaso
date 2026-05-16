# Charte graphique ElegantFaso

## Direction artistique

L'application ElegantFaso doit suivre une esthétique **Clean Modern eCommerce Design** avec une touche **Neomorphic**. L'objectif est de donner une impression premium, fluide et professionnelle, tout en restant simple à utiliser sur mobile.

Le style doit évoquer une boutique mode moderne : surfaces claires, cartes lisibles, relief doux, couleurs maîtrisées, typographie nette et parcours d'achat ou de conseil très direct.

## Principes UI

- Prioriser la lisibilité avant la décoration.
- Utiliser des surfaces claires avec de légers reliefs, jamais des ombres trop fortes.
- Garder une hiérarchie visuelle nette : titre, description, action principale.
- Réduire les animations trop spectaculaires au profit de transitions courtes et fluides.
- Favoriser des composants prévisibles : cartes, boutons, listes, filtres, onglets, champs de recherche.
- Éviter les interfaces trop chargées en dégradés, effets glassmorphism ou couleurs saturées.
- Garder les actions importantes visibles sans obliger l'utilisateur à chercher.

## Palette de couleurs

### Couleurs principales

| Usage | Couleur | Hex |
| --- | --- | --- |
| Fond principal | Gris clair doux | `#F3F5F7` |
| Surface / carte | Blanc | `#FFFFFF` |
| Texte principal | Encre foncée | `#1F2933` |
| Texte secondaire | Gris bleuté | `#7B8492` |
| Bordures fines | Gris ligne | `#E4E8EE` |
| Primaire | Vert teal élégant | `#0F766E` |
| Primaire foncé | Teal profond | `#115E59` |

### Couleurs d'accent

| Usage | Couleur | Hex |
| --- | --- | --- |
| Accent premium / recommandations | Ambre | `#F59E0B` |
| Favoris / mode / émotion | Rose profond | `#E11D48` |
| Information / mensurations | Bleu moderne | `#2563EB` |
| Succès | Vert succès | `#16A34A` |
| Alerte | Jaune | `#EAB308` |
| Erreur | Rouge | `#DC2626` |

### Règles d'utilisation

- Le fond global doit rester clair : `#F3F5F7`.
- Les cartes peuvent être blanches ou légèrement grisées, mais doivent rester sobres.
- Le teal `#0F766E` est la couleur principale pour les CTA, icônes actives et états sélectionnés.
- Les couleurs accent doivent servir à distinguer les catégories ou modules, pas à remplir tout l'écran.
- Éviter les grands fonds violets, bleus sombres ou dégradés très saturés.
- Les bordures doivent être très discrètes : `#E4E8EE` ou blanc avec faible opacité.

## Style Neomorphic

Le neomorphism doit être utilisé avec modération. Il sert à donner un relief doux aux cartes, boutons et modules, sans nuire au contraste.

### Carte en relief

```dart
BoxDecoration(
  color: Color(0xFFF3F5F7),
  borderRadius: BorderRadius.circular(22),
  border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
  boxShadow: const [
    BoxShadow(
      color: Colors.white,
      offset: Offset(-7, -7),
      blurRadius: 16,
    ),
    BoxShadow(
      color: Color(0x1A0F172A),
      offset: Offset(9, 11),
      blurRadius: 22,
    ),
  ],
)
```

### Relief interne doux

```dart
BoxDecoration(
  color: Color(0xFFF3F5F7),
  borderRadius: BorderRadius.circular(16),
  boxShadow: const [
    BoxShadow(
      color: Colors.white,
      offset: Offset(-3, -3),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0x1C0F172A),
      offset: Offset(3, 4),
      blurRadius: 9,
    ),
  ],
)
```

### Règles Neomorphic

- Utiliser deux ombres : une claire en haut-gauche et une sombre en bas-droite.
- Garder les rayons entre `14` et `28`.
- Ne pas appliquer ce style à tous les éléments en même temps.
- Préserver un contraste suffisant pour les textes et icônes.
- Les boutons importants peuvent avoir un fond plein teal plutôt qu'un relief seul.

## Typographie

La typographie doit être moderne, lisible et dense. La police recommandée est **Inter** si elle est disponible dans le projet. À défaut, utiliser la police système Flutter.

### Hiérarchie

| Élément | Taille | Poids | Usage |
| --- | --- | --- | --- |
| Grand titre | `28-32` | `w800/w900` | Hero, écran principal |
| Titre section | `20-22` | `w700/w800` | Blocs et sections |
| Titre carte | `15-18` | `w700/w800` | Produits, services, modules |
| Texte standard | `14-16` | `w400/w500` | Descriptions |
| Texte secondaire | `12-14` | `w500/w600` | Métadonnées, sous-titres |
| Label / badge | `11-13` | `w700/w800` | Statuts, chips, tags |

### Règles typo

- Letter spacing à `0`.
- Éviter les textes entièrement en majuscules, sauf badges très courts.
- Les titres doivent rester courts et orientés action.
- Les descriptions doivent tenir sur 1 à 2 lignes dans les cartes.
- Utiliser `maxLines` et `TextOverflow.ellipsis` dans les cartes et boutons.

## Icônes

Les icônes doivent être simples, arrondies et cohérentes. Utiliser de préférence les icônes Material `Rounded` ou `Outlined`.

### Recommandations

- Navigation : `chevron_right_rounded`, `arrow_forward_rounded`.
- Style / mode : `checkroom_rounded`, `style_outlined`, `auto_awesome_outlined`.
- Assistant : `psychology_alt_outlined`, `chat_bubble_outline_rounded`.
- Mensurations : `straighten_outlined`, `tune_rounded`.
- Boutique : `shopping_bag_outlined`, `storefront_outlined`.
- Favoris : `favorite_border_rounded`, `favorite_rounded`.
- Recherche : `search_rounded`.
- Filtres : `tune_rounded`, `filter_list_rounded`.

### Règles icônes

- Taille standard : `20-24`.
- Taille dans un module : `24-28`.
- Taille hero : `42-56`.
- Toujours placer les icônes dans un conteneur clair ou coloré à faible opacité.
- Éviter les SVG personnalisés si une icône Material existe déjà.

## Boutons

### Bouton principal

Le bouton principal doit être plein, lisible et très direct.

- Fond : `#0F766E`.
- Texte : blanc.
- Hauteur : `44-52`.
- Rayon : `14-16`.
- Icône optionnelle à gauche.
- Pas d'ombre forte.

### Bouton secondaire

- Fond : surface claire ou neomorphic.
- Texte : `#1F2933`.
- Icône : `#0F766E` ou couleur de module.
- Bordure discrète ou relief doux.

### Règles boutons

- Un écran doit avoir une action principale claire.
- Les boutons ne doivent pas changer la taille du layout au hover/tap.
- Ajouter un retour haptique léger sur les actions importantes.
- Les libellés doivent être courts : "Voir mes looks", "Ajouter", "Commander", "Essayer".

## Cartes et composants

### Cartes e-commerce

Une carte produit ou service doit contenir :

- Image ou icône principale.
- Titre court.
- Prix, statut ou sous-titre.
- Action rapide visible.
- Coins arrondis entre `14` et `22`.
- Espacement interne entre `12` et `18`.

### Listes

Les listes doivent être scannables :

- Icône ou image à gauche.
- Titre en gras.
- Sous-titre court.
- Chevron ou action à droite.
- Séparateur discret si la liste est dans une même surface.

### Chips et filtres

- Utiliser des chips arrondis.
- Chip actif : fond teal, texte blanc.
- Chip inactif : fond clair, texte foncé ou muted.
- Espacement horizontal confortable.

## Mise en page

### Espacements

| Token | Valeur |
| --- | --- |
| XS | `4` |
| SM | `8` |
| MD | `12` |
| LG | `16` |
| XL | `24` |
| XXL | `32` |

### Règles layout

- Padding écran mobile : `16-20`.
- Espacement entre sections : `24-32`.
- Espacement entre cartes : `12-16`.
- Utiliser des `CustomScrollView` ou `SingleChildScrollView` avec `BouncingScrollPhysics`.
- Garder les zones importantes dans le premier écran.
- Sur mobile, préférer une grille à 2 colonnes pour les modules courts.

## Animations et fluidité

Les animations doivent améliorer la perception de fluidité, pas distraire.

### Durées

| Animation | Durée |
| --- | --- |
| Apparition écran | `700-900 ms` |
| Transition page | `320-420 ms` |
| Pression bouton | `120-180 ms` |
| Pulse décoratif léger | `1800-2400 ms` |

### Courbes

- Apparition : `Curves.easeOut`.
- Slide doux : `Curves.easeOutCubic`.
- Micro-interactions : `Curves.easeInOut`.

### Règles animations

- Éviter les animations élastiques trop fortes pour une app professionnelle.
- Éviter les fonds animés permanents.
- Préférer fade + léger slide vertical.
- Les transitions entre pages doivent rester cohérentes dans toute l'app.

## Ton éditorial

Le texte doit être clair, chaleureux et orienté action.

### Style de texte

- Court.
- Direct.
- Premium sans être froid.
- En français naturel.
- Éviter le jargon technique visible par l'utilisateur.

### Exemples

- "Bonjour, Awa"
- "Composez une tenue adaptée à votre style."
- "Voir mes looks"
- "Mettre à jour mes tailles"
- "Trouver une boutique"
- "Ajouter à ma garde-robe"

## Accessibilité

- Contraste suffisant entre texte et fond.
- Ne jamais mettre du texte gris clair sur blanc pur si la taille est petite.
- Taille minimale recommandée : `12`.
- Les zones tactiles doivent faire au moins `44 x 44`.
- Ajouter `maxLines` et `overflow` pour éviter les débordements.
- Ne pas dépendre uniquement de la couleur pour indiquer un statut.

## À éviter

- Fonds violets ou bleus saturés sur tout l'écran.
- Trop de gradients dans un même écran.
- Cartes dans des cartes sans nécessité.
- Ombres noires lourdes.
- Texte en majuscules longues.
- Boutons trop hauts ou trop décoratifs.
- Animations lentes qui retardent l'action.
- Interfaces marketing quand l'utilisateur attend un outil utilisable.

## Exemple de structure d'écran

Un écran client moderne peut suivre cette structure :

1. Barre supérieure simple avec titre et action utile.
2. Hero compact avec message personnalisé et CTA principal.
3. Modules rapides en grille ou liste.
4. Section de contenu principal : produits, recommandations, tendances.
5. Actions secondaires en bas de section.

## Objectif final

Chaque écran de l'application doit donner l'impression d'un produit mode professionnel : clair, rapide, agréable à parcourir et assez premium pour inspirer confiance. La direction visuelle doit rester cohérente entre marketplace, tendances, essayage virtuel, garde-robe, profil et assistant style.
