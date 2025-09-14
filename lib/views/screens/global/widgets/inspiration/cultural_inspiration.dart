import 'package:flutter/material.dart';

// Modèle de données pour les articles culturels
class CulturalArticle {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String fullContent;
  final IconData icon;
  final String readTime;
  final String category;
  final bool isPopular;
  final List<String> tags;
  final String author;
  final DateTime publishDate;
  final int views;
  final String source;

  CulturalArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.fullContent,
    required this.icon,
    required this.readTime,
    required this.category,
    this.isPopular = false,
    required this.tags,
    required this.author,
    required this.publishDate,
    required this.views,
    required this.source,
  });
}

class CulturalInspiration extends StatefulWidget {
  const CulturalInspiration({super.key});

  @override
  State<CulturalInspiration> createState() => _CulturalInspirationState();
}

class _CulturalInspirationState extends State<CulturalInspiration>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<CulturalArticle> articles = [];
  bool isLoading = true;
  String selectedCategory = 'Tout';

  final List<String> categories = ['Tout', 'Tradition', 'Créateurs', 'Histoire', 'Artisanat'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCulturalContent();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadCulturalContent() async {
    await Future.delayed(const Duration(seconds: 1));

    articles = [
      CulturalArticle(
        id: '1',
        title: 'Faso Dan Fani : Le Pagne Tissé de la Patrie',
        subtitle: 'L\'étoffe emblématique du Burkina Faso',
        description: 'Découvrez l\'histoire du Faso Dan Fani, littéralement "pagne tissé de la patrie" en dioula.',
        fullContent: '''Le Faso Dan Fani, littéralement "pagne tissé de la patrie" en langue dioula, représente bien plus qu'un simple tissu. C'est l'âme du Burkina Faso tissée dans chaque fibre de coton.

HISTOIRE ET ORIGINES

Créé dans les années 1960, le Faso Dan Fani est né de la volonté du président Thomas Sankara de promouvoir l'industrie textile locale. Cette étoffe en coton, entièrement tissée à la main, symbolise l'indépendance économique et culturelle du pays.

PROCESSUS DE FABRICATION

Le processus de création du Faso Dan Fani suit plusieurs étapes traditionnelles :

• La Culture du Coton
- Cultivation dans les régions du Sud-Ouest
- Récolte manuelle respectueuse de l'environnement
- Séchage naturel au soleil

• Le Filage
- Transformation du coton en fils
- Utilisation de rouets traditionnels
- Teinture avec des colorants naturels

• Le Tissage
- Métiers à tisser manuels
- Motifs géométriques ancestraux
- Savoir-faire transmis de mère en fille

SIGNIFICATION CULTURELLE

Chaque couleur du Faso Dan Fani porte une signification :
- Rouge : le courage et la détermination
- Vert : l'espoir et la nature
- Jaune : la richesse minérale du pays
- Blanc : la paix et l'unité

IMPACT ÉCONOMIQUE

Le Faso Dan Fani représente aujourd'hui :
- Plus de 50 000 emplois directs
- Un chiffre d'affaires de plusieurs milliards de FCFA
- Une filière d'exportation vers l'Afrique de l'Ouest

Cette industrie contribue significativement à l'autonomisation des femmes rurales et au développement économique local.''',
        icon: Icons.content_cut,
        readTime: '8 min',
        category: 'Tradition',
        isPopular: true,
        tags: ['Faso Dan Fani', 'Tissage', 'Patrimoine'],
        author: 'Patrimoine Culturel BF',
        publishDate: DateTime(2024, 5, 20),
        views: 2450,
        source: 'Afrika Tiss',
      ),
      CulturalArticle(
        id: '2',
        title: 'François 1er : Pionnier de la Mode Ethnique',
        subtitle: 'Quand tradition rencontre haute couture',
        description: 'François Yaméogo, créateur spécialisé dans le Faso Dan Fani depuis 1992.',
        fullContent: '''François Yaméogo, connu sous le nom de François 1er, est l'un des créateurs de mode les plus influents du Burkina Faso. Depuis 1992, il révolutionne l'industrie textile burkinabè en mêlant tradition et modernité.

UN PARCOURS EXCEPTIONNEL

Les Débuts
François 1er a commencé sa carrière comme simple tailleur dans les rues de Ouagadougou. Passionné par le Faso Dan Fani, il a rapidement développé un style unique qui allie :
- Techniques de couture traditionnelles
- Tendances de la mode internationale
- Innovation dans les motifs et les formes

L'Évolution
Au fil des années, François 1er a :
- Formé plus de 200 jeunes artisans
- Créé des emplois pour des centaines de familles
- Exporté ses créations dans toute l'Afrique de l'Ouest

IMPACT SUR LA MODE AFRICAINE

François 1er a révolutionné la perception du textile traditionnel burkinabè en créant des pièces qui séduisent aussi bien les célébrités africaines que les fashionistas internationales.

Sa philosophie : "Valoriser notre patrimoine textile tout en s'adaptant aux goûts contemporains".''',
        icon: Icons.design_services,
        readTime: '6 min',
        category: 'Créateurs',
        isPopular: true,
        tags: ['François 1er', 'Designer', 'Innovation'],
        author: 'Burkina Mode',
        publishDate: DateTime(2024, 6, 15),
        views: 1890,
        source: 'Burkina NTIC',
      ),
      CulturalArticle(
        id: '3',
        title: 'Renaissance de la Mode Africaine Moderne',
        subtitle: 'Les jeunes créateurs burkinabé à l\'international',
        description: 'Une nouvelle génération de stylistes révolutionne la mode burkinabé sur les podiums internationaux.',
        fullContent: '''Le Burkina Faso vit une révolution créative. Une nouvelle génération de stylistes révolutionne la mode africaine en valorisant le patrimoine textile burkinabé sur les podiums du monde entier.

UNE NOUVELLE GÉNÉRATION DE TALENTS

Ces nouveaux ambassadeurs partagent une formation internationale et une vision contemporaine de l'héritage culturel.

LES PIONNIERS ACTUELS

• Zalissa Sandwidi
Formée à Paris, elle crée des pièces qui mélangent Faso Dan Fani et haute couture européenne.

• Moussa Tapsoba
Spécialisé dans le prêt-à-porter masculin, il modernise les coupes traditionnelles.

• Fatimata Compaoré
Designer de bijoux et accessoires, elle valorise l'artisanat local.

STRATÉGIES D'INTERNATIONALISATION

• Participation aux Fashion Week
- Milan Fashion Week
- Africa Fashion Week (Paris)
- Lagos Fashion Week

• Collaborations Internationales
- Partenariats avec des marques européennes
- Collections capsules
- Défilés croisés

• Utilisation des Réseaux Sociaux
- Instagram : vitrine des créations
- TikTok : processus de création
- YouTube : documentaires sur le savoir-faire

DÉFIS ET OPPORTUNITÉS

Défis :
- Financement des collections
- Logistique d'exportation
- Formation technique avancée

Opportunités :
- Demande croissante pour l'authenticité
- Soutien des institutions culturelles
- Développement du e-commerce

IMPACT SUR L'ÉCONOMIE LOCALE

Cette renaissance génère :
- Création d'emplois qualifiés
- Valorisation des matières premières locales
- Attraction d'investisseurs internationaux
- Rayonnement culturel du Burkina Faso''',
        icon: Icons.trending_up,
        readTime: '5 min',
        category: 'Créateurs',
        isPopular: true,
        tags: ['Mode moderne', 'International', 'Jeunes'],
        author: 'Fashion Africa',
        publishDate: DateTime(2024, 6, 20),
        views: 1567,
        source: 'Burkina Fashion',
      ),
      CulturalArticle(
        id: '4',
        title: 'L\'Art du Bogolan : Teinture Traditionnelle',
        subtitle: 'La technique ancestrale de teinture à la boue',
        description: 'Découvrez l\'art millénaire du bogolan, technique de teinture utilisant la boue fermentée.',
        fullContent: '''Le bogolan, littéralement "fait avec la terre" en bambara, est une technique de teinture traditionnelle qui utilise la boue fermentée pour créer des motifs uniques sur le tissu.

ORIGINES ET TRADITIONS

Cette technique ancestrale est pratiquée depuis des siècles dans plusieurs pays d'Afrique de l'Ouest, notamment au Mali et au Burkina Faso. Elle représente bien plus qu'une simple méthode de décoration textile : c'est un art chargé de symboles et de spiritualité.

PROCESSUS DE CRÉATION

La fabrication du bogolan suit un processus complexe :

• Préparation du Tissu
- Utilisation de coton blanc tissé à la main
- Lavage et blanchiment naturel
- Séchage au soleil

• Préparation de la Teinture
- Collecte de boue riche en fer
- Fermentation pendant plusieurs mois
- Mélange avec des décoctions de plantes

• Application des Motifs
- Dessin à main levée avec des bâtonnets
- Séchage et fixation au soleil
- Répétition du processus pour intensifier les couleurs

SYMBOLISME DES MOTIFS

Chaque motif raconte une histoire :
- Lignes parallèles : les chemins de la vie
- Croix : protection spirituelle
- Spirales : cycle de la vie
- Points : graines et fertilité

RENAISSANCE CONTEMPORAINE

Aujourd'hui, le bogolan connaît un renouveau grâce à des artistes qui :
- Adaptent les techniques traditionnelles
- Créent des œuvres contemporaines
- Transmettent le savoir-faire aux jeunes générations
- Exportent leurs créations à l'international''',
        icon: Icons.palette,
        readTime: '7 min',
        category: 'Artisanat',
        isPopular: false,
        tags: ['Bogolan', 'Teinture', 'Tradition'],
        author: 'Artisans du Sahel',
        publishDate: DateTime(2024, 6, 10),
        views: 1234,
        source: 'Patrimoine Artisanal',
      ),
      CulturalArticle(
        id: '5',
        title: 'Thomas Sankara et la Révolution Textile',
        subtitle: 'Comment un leader a transformé l\'industrie burkinabé',
        description: 'L\'héritage de Thomas Sankara dans la promotion du textile local et de l\'identité culturelle.',
        fullContent: '''Thomas Sankara, président révolutionnaire du Burkina Faso de 1983 à 1987, a profondément marqué l'industrie textile burkinabé par sa vision de l'autonomie économique et culturelle.

LA VISION RÉVOLUTIONNAIRE

Sankara comprenait que l'indépendance véritable passait par l'autonomie économique. Il a mis en place plusieurs initiatives pour promouvoir le textile local :

• Campagne "Consommons Burkinabé"
- Obligation pour les fonctionnaires de porter du Faso Dan Fani
- Promotion des produits locaux
- Réduction des importations textiles

• Création d'Emplois
- Développement de coopératives textiles
- Formation de jeunes artisans
- Soutien aux femmes rurales

• Identité Culturelle
- Valorisation des traditions vestimentaires
- Création d'une mode africaine moderne
- Fierté nationale retrouvée

IMPACT DURABLE

L'héritage de Sankara perdure aujourd'hui :

• Industrie Textile Locale
- Plus de 100 000 emplois créés
- Exportation vers les pays voisins
- Innovation dans les techniques de production

• Conscience Culturelle
- Port du Faso Dan Fani dans les cérémonies officielles
- Reconnaissance internationale du textile burkinabé
- Transmission des valeurs patriotiques

• Développement Économique
- Réduction de la dépendance textile
- Création de richesse locale
- Autonomisation des communautés rurales

LEÇONS CONTEMPORAINES

Les principes de Sankara inspirent encore aujourd'hui :
- Consommation responsable
- Valorisation du patrimoine local
- Développement endogène
- Fierté culturelle africaine

Son message résonne toujours : "Consommons ce que nous produisons et produisons ce que nous consommons."''',
        icon: Icons.history,
        readTime: '9 min',
        category: 'Histoire',
        isPopular: true,
        tags: ['Sankara', 'Révolution', 'Économie'],
        author: 'Histoire du Burkina',
        publishDate: DateTime(2024, 6, 5),
        views: 3210,
        source: 'Archives Nationales',
      ),
    ];

    setState(() {
      isLoading = false;
    });

    _fadeController.forward();
  }

  void _filterArticles(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  List<CulturalArticle> get filteredArticles {
    if (selectedCategory == 'Tout') {
      return articles;
    } else {
      return articles.where((article) => article.category == selectedCategory).toList();
    }
  }

  void _showReadingDialog(CulturalArticle article) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header du popup
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCategoryColor(article.category),
                        _getCategoryColor(article.category).withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              article.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        article.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenu scrollable
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(article.category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              article.icon,
                              size: 40,
                              color: _getCategoryColor(article.category),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          article.fullContent,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF2D3748),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: article.tags.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(article.category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getCategoryColor(article.category),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: const Text(
              'Inspiration Culturelle',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Color(0xFF4A5568)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: Color(0xFF4A5568)),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              _buildCategoryFilter(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredArticles.length,
                  itemBuilder: (context, index) {
                    final article = filteredArticles[index];
                    return _buildDetailedArticleCard(article);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingSection();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: 16),
            _buildQuickCategoryChips(),
            const SizedBox(height: 16),
            _buildFeaturedArticles(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3182CE)),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement du contenu culturel...',
              style: TextStyle(
                color: Color(0xFF4A5568),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inspiration Culturelle',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Découvrez notre patrimoine textile',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4A5568),
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: _navigateToFullScreen,
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('Voir tout'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3182CE),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCategoryChips() {
    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.take(4).length, // Afficher seulement 4 catégories
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => _filterArticles(category),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF3182CE),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4A5568),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedArticles() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filteredArticles.take(5).length, // Afficher max 5 articles
        itemBuilder: (context, index) {
          final article = filteredArticles[index];
          return _buildCompactArticleCard(article);
        },
      ),
    );
  }

  Widget _buildCompactArticleCard(CulturalArticle article) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête coloré avec icône
            Container(
              height: 60,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getCategoryColor(article.category),
                    _getCategoryColor(article.category).withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    article.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          article.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (article.isPopular)
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: Colors.white.withOpacity(0.8),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Populaire',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenu défilable
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Description
                      Text(
                        article.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4A5568),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Infos de lecture et bouton
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                article.readTime,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => _showReadingDialog(article),
                            style: TextButton.styleFrom(
                              foregroundColor: _getCategoryColor(article.category),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Lire',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCategoryFilter() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => _filterArticles(category),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF3182CE),
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4A5568),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              ),
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailedArticleCard(CulturalArticle article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec gradient
            Container(
              height: 100,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getCategoryColor(article.category),
                    _getCategoryColor(article.category).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      article.icon,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                article.category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (article.isPopular)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'POPULAIRE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          article.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Contenu de l'article
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A5568),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: article.tags.take(3).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(article.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          color: _getCategoryColor(article.category),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Footer avec métadonnées
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                article.author,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                article.readTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.visibility_outlined,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${article.views}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.bookmark_border,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: () {
                              // Logique pour sauvegarder l'article
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Article "${article.title}" sauvegardé'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.share_outlined,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: () {
                              // Logique pour partager l'article
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Partage de "${article.title}"'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          ElevatedButton(
                            onPressed: () => _showReadingDialog(article),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getCategoryColor(article.category),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Lire l\'article',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Tradition':
        return const Color(0xFF8B5A3C); // Brun traditionnel
      case 'Créateurs':
        return const Color(0xFF6B46C1); // Violet créatif
      case 'Histoire':
        return const Color(0xFF059669); // Vert historique
      case 'Artisanat':
        return const Color(0xFFDC2626); // Rouge artisanal
      default:
        return const Color(0xFF3182CE); // Bleu par défaut
    }
  }
}