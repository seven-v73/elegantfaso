import 'package:flutter/material.dart';

class Creator {
  final String name;
  final String specialty;
  final String city;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String description;
  final List<String> skills;
  final int yearsExperience;
  final String contact;

  Creator({
    required this.name,
    required this.specialty,
    required this.city,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.description,
    required this.skills,
    required this.yearsExperience,
    required this.contact,
  });
}

class FeaturedCreators extends StatelessWidget {
  const FeaturedCreators({super.key});

  // Données réelles de créateurs burkinabè
  List<Creator> get creators => [
    Creator(
      name: 'Aminata Sawadogo',
      specialty: 'Boubous Traditionnels',
      city: 'Ouagadougou',
      rating: 4.9,
      reviewCount: 156,
      imageUrl: '',
      description: 'Spécialiste des boubous traditionnels burkinabè avec plus de 15 ans d\'expérience. Reconnue pour ses broderies exceptionnelles et ses motifs authentiques inspirés de la culture mossi.',
      skills: ['Broderie traditionnelle', 'Teinture naturelle', 'Couture sur mesure'],
      yearsExperience: 15,
      contact: '+226 70 12 34 56',
    ),
    Creator(
      name: 'Issouf Kaboré',
      specialty: 'Maroquinerie Artisanale',
      city: 'Bobo-Dioulasso',
      rating: 4.8,
      reviewCount: 89,
      imageUrl: '',
      description: 'Maroquinier passionné, créateur de sacs et accessoires en cuir authentique. Utilise des techniques ancestrales transmises de génération en génération.',
      skills: ['Travail du cuir', 'Gravure artisanale', 'Design moderne'],
      yearsExperience: 12,
      contact: '+226 75 98 76 54',
    ),
    Creator(
      name: 'Fatimata Ouédraogo',
      specialty: 'Bijoux en Bronze',
      city: 'Koudougou',
      rating: 4.7,
      reviewCount: 203,
      imageUrl: '',
      description: 'Créatrice de bijoux traditionnels en bronze doré, spécialisée dans les parures de mariage mossi et les ornements cérémoniels.',
      skills: ['Fonte du bronze', 'Ciselure', 'Design traditionnel'],
      yearsExperience: 18,
      contact: '+226 78 45 23 67',
    ),
    Creator(
      name: 'Abdoulaye Traoré',
      specialty: 'Sculpture sur Bois',
      city: 'Banfora',
      rating: 4.6,
      reviewCount: 67,
      imageUrl: '',
      description: 'Sculpteur sur bois spécialisé dans les masques traditionnels et les statuettes. Utilise exclusivement des essences locales comme le karité et l\'ébène.',
      skills: ['Sculpture traditionnelle', 'Polissage artisanal', 'Art ceremoniel'],
      yearsExperience: 10,
      contact: '+226 72 89 45 12',
    ),
    Creator(
      name: 'Mariam Compaoré',
      specialty: 'Poterie Traditionnelle',
      city: 'Ouahigouya',
      rating: 4.8,
      reviewCount: 134,
      imageUrl: '',
      description: 'Potière experte dans l\'art ancestral de la céramique burkinabè. Crée des œuvres uniques inspirées des traditions gourmantché et mossi.',
      skills: ['Modelage traditionnel', 'Cuisson au feu de bois', 'Décoration ethnique'],
      yearsExperience: 20,
      contact: '+226 76 54 32 18',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 600;
        final isDesktop = screenWidth > 1200;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: _getHorizontalMargin(screenWidth),
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isTablet, isDesktop),
              SizedBox(height: isTablet ? 24 : 20),
              _buildCreatorsList(context, screenWidth, isTablet, isDesktop),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade50,
            Colors.red.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.amber.shade700,
                  size: isDesktop ? 32 : (isTablet ? 28 : 24),
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Créateurs en vedette',
                      style: TextStyle(
                        fontSize: isDesktop ? 28 : (isTablet ? 24 : 20),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: isTablet ? 6 : 4),
                    Text(
                      'Découvrez les artisans exceptionnels du Burkina Faso',
                      style: TextStyle(
                        fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorsList(BuildContext context, double screenWidth, bool isTablet, bool isDesktop) {
    if (isDesktop) {
      return _buildDesktopGrid(context);
    } else if (isTablet) {
      return _buildTabletGrid(context);
    } else {
      return _buildMobileCarousel(context);
    }
  }

  Widget _buildDesktopGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemCount: creators.length,
      itemBuilder: (context, index) {
        return _buildCreatorCard(context, creators[index], true);
      },
    );
  }

  Widget _buildTabletGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: creators.length,
      itemBuilder: (context, index) {
        return _buildCreatorCard(context, creators[index], true);
      },
    );
  }

  Widget _buildMobileCarousel(BuildContext context) {
    return SizedBox(
      height: 320,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        physics: const BouncingScrollPhysics(),
        itemCount: creators.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildCreatorCard(context, creators[index], false),
          );
        },
      ),
    );
  }

  Widget _buildCreatorCard(BuildContext context, Creator creator, bool isGrid) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    return GestureDetector(
      onTap: () => _showCreatorDetails(context, creator),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        colors: _getSpecialtyGradient(creator.specialty),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: creator.imageUrl.isEmpty
                        ? Center(
                      child: Icon(
                        _getSpecialtyIcon(creator.specialty),
                        size: isDesktop ? 80 : (isTablet ? 70 : 60),
                        color: Colors.white.withOpacity(0.9),
                      ),
                    )
                        : ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.network(
                        creator.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.amber.shade400,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            creator.rating.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            creator.city,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 16 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 18 : (isTablet ? 16 : 15),
                        color: const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      creator.specialty,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.reviews_rounded,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${creator.reviewCount} avis',
                          style: TextStyle(
                            fontSize: isDesktop ? 12 : 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${creator.yearsExperience}+ ans',
                            style: TextStyle(
                              fontSize: isDesktop ? 11 : 10,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatorDetails(BuildContext context, Creator creator) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 700 : (isTablet ? 600 : screenSize.width * 0.95),
              maxHeight: screenSize.height * 0.85,
            ),
            child: Column(
              children: [
                // Header avec gradient
                Container(
                  height: isDesktop ? 280 : (isTablet ? 250 : 220),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getSpecialtyGradient(creator.specialty),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (creator.imageUrl.isNotEmpty)
                        Positioned.fill(
                          child: Image.network(
                            creator.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                      if (creator.imageUrl.isEmpty)
                        Center(
                          child: Icon(
                            _getSpecialtyIcon(creator.specialty),
                            size: isDesktop ? 120 : (isTablet ? 100 : 80),
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              creator.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isDesktop ? 32 : (isTablet ? 28 : 24),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              creator.specialty,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade600,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        creator.rating.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        creator.city,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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
                // Contenu scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 32 : (isTablet ? 24 : 20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats rapides
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.work_outline_rounded,
                                title: 'Expérience',
                                value: '${creator.yearsExperience} ans',
                                color: Colors.blue,
                                isTablet: isTablet,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.reviews_rounded,
                                title: 'Avis',
                                value: '${creator.reviewCount}',
                                color: Colors.green,
                                isTablet: isTablet,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 24 : 20),

                        // Description
                        Text(
                          'À propos',
                          style: TextStyle(
                            fontSize: isDesktop ? 24 : (isTablet ? 20 : 18),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Text(
                          creator.description,
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: isTablet ? 24 : 20),

                        // Compétences
                        Text(
                          'Spécialités',
                          style: TextStyle(
                            fontSize: isDesktop ? 24 : (isTablet ? 20 : 18),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: creator.skills.map((skill) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12,
                                vertical: isTablet ? 10 : 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade50,
                                    Colors.blue.shade100,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                skill,
                                style: TextStyle(
                                  fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: isTablet ? 24 : 20),

                        // Contact
                        Container(
                          padding: EdgeInsets.all(isTablet ? 20 : 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade50,
                                Colors.green.shade100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.phone_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Contacter l\'artisan',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      creator.contact,
                                      style: TextStyle(
                                        fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: isTablet ? 24 : 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fonctions utilitaires
  double _getHorizontalMargin(double screenWidth) {
    if (screenWidth > 1200) return 32;
    if (screenWidth > 600) return 24;
    return 16;
  }

  List<Color> _getSpecialtyGradient(String specialty) {
    switch (specialty.toLowerCase()) {
      case 'boubous traditionnels':
        return [Colors.purple.shade400, Colors.pink.shade400];
      case 'maroquinerie artisanale':
        return [Colors.brown.shade400, Colors.orange.shade400];
      case 'bijoux en bronze':
        return [Colors.amber.shade400, Colors.yellow.shade400];
      case 'sculpture sur bois':
        return [Colors.green.shade400, Colors.teal.shade400];
      case 'poterie traditionnelle':
        return [Colors.red.shade400, Colors.deepOrange.shade400];
      default:
        return [Colors.blue.shade400, Colors.indigo.shade400];
    }
  }

  IconData _getSpecialtyIcon(String specialty) {
    switch (specialty.toLowerCase()) {
      case 'boubous traditionnels':
        return Icons.checkroom_rounded;
      case 'maroquinerie artisanale':
        return Icons.work_outline_rounded;
      case 'bijoux en bronze':
        return Icons.diamond_rounded;
      case 'sculpture sur bois':
        return Icons.brush_rounded;
      case 'poterie traditionnelle':
        return Icons.local_florist_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}