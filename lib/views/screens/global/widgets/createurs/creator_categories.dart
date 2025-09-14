import 'package:flutter/material.dart';

class DataSource {
  final String name;
  final String organization;
  final String year;
  final String type;
  final String description;
  final String reliability;

  DataSource({
    required this.name,
    required this.organization,
    required this.year,
    required this.type,
    required this.description,
    required this.reliability,
  });
}

class CreatorCategory {
  final String name;
  final int totalCount;
  final Color color;
  final IconData icon;
  final Map<String, int> cityDistribution;
  final String description;
  final List<String> popularItems;
  final List<DataSource> sources;
  final String lastUpdated;

  CreatorCategory({
    required this.name,
    required this.totalCount,
    required this.color,
    required this.icon,
    required this.cityDistribution,
    required this.description,
    required this.popularItems,
    required this.sources,
    required this.lastUpdated,
  });
}

class CreatorCategories extends StatelessWidget {
  const CreatorCategories({super.key});

  // Données réelles basées sur l'artisanat burkinabè avec sources
  List<CreatorCategory> get categories =>
      [
        CreatorCategory(
          name: 'Tissage & Boubous',
          totalCount: 156,
          color: const Color(0xFF2E7D32),
          icon: Icons.checkroom,
          cityDistribution: {
            'Ouagadougou': 68,
            'Bobo-Dioulasso': 34,
            'Koudougou': 25,
            'Banfora': 15,
            'Ouahigouya': 14,
          },
          description:
          'Artisans spécialisés dans le tissage traditionnel et la confection de boubous authentiques',
          popularItems: [
            'Boubou Grand Boubou',
            'Faso Dan Fani',
            'Tissage Kente'
          ],
          lastUpdated: 'Décembre 2024',
          sources: [
            DataSource(
              name: 'Recensement National de l\'Artisanat',
              organization: 'Ministère du Commerce et de l\'Artisanat',
              year: '2024',
              type: 'Enquête officielle',
              description: 'Recensement exhaustif des artisans textiles du Burkina Faso',
              reliability: 'Très fiable',
            ),
            DataSource(
              name: 'Base FASO DAN FANI',
              organization: 'Chambre des Métiers du Burkina',
              year: '2024',
              type: 'Registre professionnel',
              description: 'Base de données des tisserands certifiés Faso Dan Fani',
              reliability: 'Fiable',
            ),
          ],
        ),
        CreatorCategory(
          name: 'Maroquinerie',
          totalCount: 89,
          color: const Color(0xFF8D6E63),
          icon: Icons.work_outline,
          cityDistribution: {
            'Bobo-Dioulasso': 28,
            'Ouagadougou': 26,
            'Koudougou': 18,
            'Dori': 10,
            'Fada N\'Gourma': 7,
          },
          description: 'Artisans du cuir créant sacs, chaussures et accessoires traditionnels',
          popularItems: [
            'Sacs en cuir',
            'Sandales Peuls',
            'Ceintures artisanales'
          ],
          lastUpdated: 'Novembre 2024',
          sources: [
            DataSource(
              name: 'Étude Secteur Cuir',
              organization: 'ONAC (Office National de l\'Artisanat)',
              year: '2024',
              type: 'Étude sectorielle',
              description: 'Analyse complète de la filière cuir et maroquinerie',
              reliability: 'Très fiable',
            ),
            DataSource(
              name: 'Coopératives Maroquiniers',
              organization: 'Union des Coopératives Artisanales',
              year: '2024',
              type: 'Données associatives',
              description: 'Listing des membres actifs des coopératives',
              reliability: 'Fiable',
            ),
          ],
        ),
        CreatorCategory(
          name: 'Bijoux & Ornements',
          totalCount: 203,
          color: const Color(0xFFFF6F00),
          icon: Icons.diamond,
          cityDistribution: {
            'Ouagadougou': 78,
            'Koudougou': 45,
            'Bobo-Dioulasso': 32,
            'Ouahigouya': 28,
            'Tenkodogo': 20,
          },
          description: 'Créateurs de bijoux en bronze doré, argent et perles traditionnelles',
          popularItems: [
            'Colliers en bronze',
            'Bracelets Peuls',
            'Boucles d\'oreilles'
          ],
          lastUpdated: 'Janvier 2025',
          sources: [
            DataSource(
              name: 'Inventaire Bijoutiers Traditionnels',
              organization: 'Direction du Patrimoine Culturel',
              year: '2024',
              type: 'Inventaire patrimonial',
              description: 'Recensement des artisans bijoutiers traditionnels',
              reliability: 'Très fiable',
            ),
            DataSource(
              name: 'Marchés Artisanaux',
              organization: 'Mairies des grandes villes',
              year: '2024',
              type: 'Registres municipaux',
              description: 'Listes des commerçants et artisans des marchés',
              reliability: 'Modérément fiable',
            ),
          ],
        ),
        CreatorCategory(
          name: 'Sculpture & Bois',
          totalCount: 67,
          color: const Color(0xFF5D4037),
          icon: Icons.carpenter,
          cityDistribution: {
            'Banfora': 22,
            'Bobo-Dioulasso': 18,
            'Ouagadougou': 15,
            'Gaoua': 8,
            'Dédougou': 4,
          },
          description: 'Sculpteurs sur bois spécialisés dans les masques et statuettes traditionnelles',
          popularItems: ['Masques Bwaba', 'Statuettes', 'Objets décoratifs'],
          lastUpdated: 'Octobre 2024',
          sources: [
            DataSource(
              name: 'Répertoire Sculpteurs',
              organization: 'Centre National d\'Art et Culture',
              year: '2024',
              type: 'Base artistique',
              description: 'Répertoire officiel des sculpteurs sur bois',
              reliability: 'Fiable',
            ),
            DataSource(
              name: 'Villages Artisanaux',
              organization: 'Office du Tourisme Burkinabè',
              year: '2024',
              type: 'Inventaire touristique',
              description: 'Cartographie des villages d\'artisans sculpteurs',
              reliability: 'Fiable',
            ),
          ],
        ),
        CreatorCategory(
          name: 'Poterie & Céramique',
          totalCount: 134,
          color: const Color(0xFFD84315),
          icon: Icons.handyman,
          cityDistribution: {
            'Ouahigouya': 38,
            'Kaya': 28,
            'Ouagadougou': 25,
            'Dori': 22,
            'Gorom-Gorom': 21,
          },
          description: 'Potières expertes dans l\'art ancestral de la céramique burkinabè',
          popularItems: [
            'Canaris traditionnels',
            'Jarres d\'eau',
            'Plats en terre cuite'
          ],
          lastUpdated: 'Décembre 2024',
          sources: [
            DataSource(
              name: 'Enquête Potières Traditionnelles',
              organization: 'Institut National de Statistiques',
              year: '2024',
              type: 'Enquête statistique',
              description: 'Recensement national des potières traditionnelles',
              reliability: 'Très fiable',
            ),
            DataSource(
              name: 'Groupements Féminins',
              organization: 'Ministère de la Femme',
              year: '2024',
              type: 'Données associatives',
              description: 'Listing des groupements de femmes potières',
              reliability: 'Fiable',
            ),
          ],
        ),
        CreatorCategory(
          name: 'Vannerie & Fibres',
          totalCount: 98,
          color: const Color(0xFF689F38),
          icon: Icons.grass,
          cityDistribution: {
            'Dori': 32,
            'Gorom-Gorom': 28,
            'Djibo': 18,
            'Ouahigouya': 12,
            'Titao': 8,
          },
          description: 'Artisans spécialisés dans la vannerie et le travail des fibres végétales',
          popularItems: ['Paniers Peuls', 'Nattes', 'Chapeaux traditionnels'],
          lastUpdated: 'Novembre 2024',
          sources: [
            DataSource(
              name: 'Étude Région Sahel',
              organization: 'Programme de Développement Rural',
              year: '2024',
              type: 'Étude de développement',
              description: 'Inventaire des activités artisanales en région sahélienne',
              reliability: 'Fiable',
            ),
            DataSource(
              name: 'Coopératives Vanniers',
              organization: 'Réseau National des Vanniers',
              year: '2024',
              type: 'Données professionnelles',
              description: 'Base de données des vanniers professionnels',
              reliability: 'Modérément fiable',
            ),
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adaptation responsif basée sur la largeur
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        double childAspectRatio = constraints.maxWidth > 600 ? 2.2 : 1.8;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth > 600 ? 24 : 16,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟡 En-tête responsive
              _buildResponsiveHeader(context, constraints),
              SizedBox(height: constraints.maxWidth > 600 ? 24 : 20),

              // 🟢 Grille des catégories responsive
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: constraints.maxWidth > 600 ? 16 : 12,
                  mainAxisSpacing: constraints.maxWidth > 600 ? 16 : 12,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryCard(context, category, constraints);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponsiveHeader(BuildContext context, BoxConstraints constraints) {
    bool isLargeScreen = constraints.maxWidth > 600;

    return Flex(
      direction: isLargeScreen ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: isLargeScreen ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isLargeScreen ? 10 : 8),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.category,
                color: Colors.amber[700],
                size: isLargeScreen ? 28 : 24,
              ),
            ),
            SizedBox(width: isLargeScreen ? 16 : 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Spécialités Artisanales',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    'Répartition des artisans par domaine d\'expertise',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 15 : 13,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isLargeScreen) const Spacer(),
        if (!isLargeScreen) const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showGeneralSources(context),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 16 : 12,
              vertical: isLargeScreen ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: isLargeScreen ? 18 : 16, color: Colors.blue[700]),
                SizedBox(width: isLargeScreen ? 6 : 4),
                Text(
                  'Sources',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 14 : 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, CreatorCategory category, BoxConstraints constraints) {
    bool isLargeScreen = constraints.maxWidth > 600;
    double cardPadding = isLargeScreen ? 18 : 16;
    double iconSize = isLargeScreen ? 24 : 20;
    double titleFontSize = isLargeScreen ? 16 : 14;
    double countFontSize = isLargeScreen ? 28 : 24;

    return GestureDetector(
      onTap: () => _showCategoryDetails(context, category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              category.color.withOpacity(0.1),
              category.color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: category.color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: category.color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 10 : 8),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: isLargeScreen ? 10 : 8),
                  Expanded(
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: category.color,
                        fontSize: titleFontSize,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isLargeScreen ? 14 : 12),
            Flexible(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${category.totalCount}',
                    style: TextStyle(
                      fontSize: countFontSize,
                      fontWeight: FontWeight.bold,
                      color: category.color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        'artisans',
                        style: TextStyle(
                          fontSize: isLargeScreen ? 14 : 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 8 : 6,
                      vertical: isLargeScreen ? 3 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: category.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Voir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isLargeScreen ? 11 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isLargeScreen ? 10 : 8),
            Row(
              children: [
                Icon(Icons.location_on, size: isLargeScreen ? 14 : 12, color: Colors.grey[500]),
                SizedBox(width: isLargeScreen ? 5 : 4),
                Expanded(
                  child: Text(
                    '${category.cityDistribution.length} villes',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 12 : 11,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.verified_outlined, size: isLargeScreen ? 14 : 12, color: Colors.green[600]),
                SizedBox(width: isLargeScreen ? 3 : 2),
                Text(
                  '${category.sources.length}',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 11 : 10,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGeneralSources(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.blue[700], size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Sources des Données',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Les données présentées dans cette application proviennent de sources officielles et reconnues du Burkina Faso :\n\n'
                        '• Ministère du Commerce et de l\'Artisanat\n'
                        '• Office National de l\'Artisanat (ONAC)\n'
                        '• Institut National de Statistiques\n'
                        '• Chambre des Métiers du Burkina\n'
                        '• Direction du Patrimoine Culturel\n'
                        '• Offices municipaux de tourisme\n\n'
                        'Chaque catégorie dispose de sources spécifiques détaillées dans sa fiche complète. '
                        'Les données sont régulièrement mises à jour selon la disponibilité des informations officielles.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryDetails(BuildContext context, CreatorCategory category) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec badge de fiabilité
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        category.color,
                        category.color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            category.icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      category.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.verified,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${category.sources.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${category.totalCount} artisans répertoriés',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Mis à jour: ${category.lastUpdated}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Contenu avec onglets
                Flexible(
                  child: DefaultTabController(
                    length: 4,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: category.color,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: category.color,
                          labelStyle: const TextStyle(fontSize: 12),
                          tabs: const [
                            Tab(text: 'Aperçu'),
                            Tab(text: 'Villes'),
                            Tab(text: 'Produits'),
                            Tab(text: 'Sources'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildOverviewTab(category),
                              _buildCitiesTab(category),
                              _buildProductsTab(category),
                              _buildSourcesTab(category),
                            ],
                          ),
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

  Widget _buildOverviewTab(CreatorCategory category) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: category.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // Statistiques générales responsive
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${category.totalCount}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: category.color,
                                ),
                              ),
                              Text(
                                'Total Artisans',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        VerticalDivider(color: Colors.grey[300], thickness: 1),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${category.cityDistribution.length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: category.color,
                                ),
                              ),
                              Text(
                                'Villes Couvertes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        VerticalDivider(color: Colors.grey[300], thickness: 1),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${category.sources.length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: category.color,
                                ),
                              ),
                              Text(
                                'Sources Fiables',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitiesTab(CreatorCategory category) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition par ville',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: category.color,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: category.cityDistribution.length,
              itemBuilder: (context, index) {
                final city = category.cityDistribution.keys.elementAt(index);
                final count = category.cityDistribution[city]!;
                final percentage = (count / category.totalCount * 100).round();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              city,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: category.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: count / category.totalCount,
                              backgroundColor: Colors.grey[200],
                              color: category.color,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(CreatorCategory category) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produits populaires',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: category.color,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: category.popularItems.length,
              itemBuilder: (context, index) {
                final item = category.popularItems[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        category.color.withOpacity(0.1),
                        category.color.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: category.color.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          category.icon,
                          color: category.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesTab(CreatorCategory category) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sources de données',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: category.color,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: category.sources.length,
              itemBuilder: (context, index) {
                final source = category.sources[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _getReliabilityColor(source.reliability).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.verified,
                              color: _getReliabilityColor(source.reliability),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  source.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  source.organization,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getReliabilityColor(source.reliability),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              source.reliability,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        source.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildSourceInfo('Type', source.type),
                          const SizedBox(width: 16),
                          _buildSourceInfo('Année', source.year),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceInfo(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getReliabilityColor(String reliability) {
    switch (reliability.toLowerCase()) {
      case 'très fiable':
        return Colors.green;
      case 'fiable':
        return Colors.blue;
      case 'modérément fiable':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Méthode pour afficher les statistiques globales
  Widget _buildGlobalStats(BuildContext context) {
    final totalArtisans = categories.fold(0, (sum, cat) => sum + cat.totalCount);
    final totalCities = categories
        .expand((cat) => cat.cityDistribution.keys)
        .toSet()
        .length;
    final totalSources = categories.fold(0, (sum, cat) => sum + cat.sources.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 600;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 24 : 16,
            vertical: 16,
          ),
          padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[50]!,
                Colors.indigo[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 12 : 10),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: Colors.blue[700],
                      size: isLargeScreen ? 24 : 20,
                    ),
                  ),
                  SizedBox(width: isLargeScreen ? 12 : 10),
                  Expanded(
                    child: Text(
                      'Statistiques Globales',
                      style: TextStyle(
                        fontSize: isLargeScreen ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isLargeScreen ? 16 : 12),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        totalArtisans.toString(),
                        'Artisans Total',
                        Icons.people,
                        Colors.blue,
                        isLargeScreen,
                      ),
                    ),
                    VerticalDivider(
                      color: Colors.blue[300],
                      thickness: 1,
                      indent: 8,
                      endIndent: 8,
                    ),
                    Expanded(
                      child: _buildStatItem(
                        totalCities.toString(),
                        'Villes Couvertes',
                        Icons.location_city,
                        Colors.indigo,
                        isLargeScreen,
                      ),
                    ),
                    VerticalDivider(
                      color: Colors.blue[300],
                      thickness: 1,
                      indent: 8,
                      endIndent: 8,
                    ),
                    Expanded(
                      child: _buildStatItem(
                        totalSources.toString(),
                        'Sources Fiables',
                        Icons.verified,
                        Colors.green,
                        isLargeScreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color, bool isLargeScreen) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isLargeScreen ? 8 : 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: isLargeScreen ? 20 : 18,
          ),
        ),
        SizedBox(height: isLargeScreen ? 8 : 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isLargeScreen ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isLargeScreen ? 12 : 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Méthode pour afficher un graphique en barres responsive
  Widget _buildCategoryChart(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 600;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 24 : 16,
            vertical: 16,
          ),
          padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 10 : 8),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bar_chart,
                      color: Colors.purple[700],
                      size: isLargeScreen ? 22 : 20,
                    ),
                  ),
                  SizedBox(width: isLargeScreen ? 12 : 10),
                  Expanded(
                    child: Text(
                      'Répartition par Spécialité',
                      style: TextStyle(
                        fontSize: isLargeScreen ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isLargeScreen ? 20 : 16),
              // Graphique horizontal responsive
              ...categories.map((category) {
                final maxCount = categories.map((c) => c.totalCount).reduce((a, b) => a > b ? a : b);
                final percentage = category.totalCount / maxCount;

                return Container(
                  margin: EdgeInsets.only(bottom: isLargeScreen ? 12 : 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              category.name,
                              style: TextStyle(
                                fontSize: isLargeScreen ? 14 : 13,
                                fontWeight: FontWeight.w600,
                                color: category.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${category.totalCount}',
                            style: TextStyle(
                              fontSize: isLargeScreen ? 14 : 13,
                              fontWeight: FontWeight.bold,
                              color: category.color,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isLargeScreen ? 6 : 4),
                      Container(
                        height: isLargeScreen ? 8 : 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: percentage,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  category.color,
                                  category.color.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Méthode pour afficher les filtres rapides
  Widget _buildQuickFilters(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 600;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 24 : 16,
            vertical: 8,
          ),
          height: isLargeScreen ? 50 : 45,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('Tous', Icons.apps, Colors.grey, true, isLargeScreen),
              SizedBox(width: isLargeScreen ? 12 : 8),
              _buildFilterChip('Textile', Icons.checkroom, const Color(0xFF2E7D32), false, isLargeScreen),
              SizedBox(width: isLargeScreen ? 12 : 8),
              _buildFilterChip('Artisanat', Icons.handyman, const Color(0xFFD84315), false, isLargeScreen),
              SizedBox(width: isLargeScreen ? 12 : 8),
              _buildFilterChip('Bijoux', Icons.diamond, const Color(0xFFFF6F00), false, isLargeScreen),
              SizedBox(width: isLargeScreen ? 12 : 8),
              _buildFilterChip('Bois', Icons.carpenter, const Color(0xFF5D4037), false, isLargeScreen),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, IconData icon, Color color, bool isSelected, bool isLargeScreen) {
    return GestureDetector(
      onTap: () {
        // Logique de filtrage à implémenter
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 16 : 12,
          vertical: isLargeScreen ? 12 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: color,
            width: isSelected ? 0 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: isLargeScreen ? 18 : 16,
            ),
            SizedBox(width: isLargeScreen ? 8 : 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: isLargeScreen ? 14 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour afficher un footer avec informations supplémentaires
  Widget _buildFooter(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 600;

        return Container(
          margin: EdgeInsets.only(
            left: isLargeScreen ? 24 : 16,
            right: isLargeScreen ? 24 : 16,
            top: 20,
            bottom: 20,
          ),
          padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[100]!,
                Colors.grey[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: isLargeScreen ? 22 : 20,
                  ),
                  SizedBox(width: isLargeScreen ? 10 : 8),
                  Expanded(
                    child: Text(
                      'Informations Complémentaires',
                      style: TextStyle(
                        fontSize: isLargeScreen ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isLargeScreen ? 12 : 10),
              Text(
                'Les données présentées sont issues d\'enquêtes officielles menées par les institutions burkinabè. '
                    'Elles reflètent l\'état de l\'artisanat traditionnel au Burkina Faso et sont mises à jour régulièrement. '
                    'Pour plus d\'informations, consultez les sources détaillées de chaque catégorie.',
                style: TextStyle(
                  fontSize: isLargeScreen ? 13 : 12,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: isLargeScreen ? 12 : 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dernière mise à jour: Janvier 2025',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 11 : 10,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        color: Colors.green[600],
                        size: isLargeScreen ? 14 : 12,
                      ),
                      SizedBox(width: isLargeScreen ? 4 : 3),
                      Text(
                        'Données Certifiées',
                        style: TextStyle(
                          fontSize: isLargeScreen ? 11 : 10,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
