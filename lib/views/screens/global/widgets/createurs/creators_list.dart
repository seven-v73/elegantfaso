import 'package:flutter/material.dart';
import 'dart:math';

class Creator {
  final String name;
  final String specialty;
  final String description;
  final String city;
  final String region;
  final double distance;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isOnline;
  final Color categoryColor;
  final IconData categoryIcon;
  final List<String> languages;
  final String experience;
  final List<String> certifications;
  final String lastSeen;

  Creator({
    required this.name,
    required this.specialty,
    required this.description,
    required this.city,
    required this.region,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.isOnline,
    required this.categoryColor,
    required this.categoryIcon,
    required this.languages,
    required this.experience,
    required this.certifications,
    required this.lastSeen,
  });
}

class CreatorsList extends StatefulWidget {
  const CreatorsList({super.key});

  @override
  State<CreatorsList> createState() => _CreatorsListState();
}

class _CreatorsListState extends State<CreatorsList> {
  String selectedFilter = 'Populaire';

  // Données authentiques d'artisans burkinabè
  List<Creator> get creators => [
    Creator(
      name: 'Fatimata Ouédraogo',
      specialty: 'Tissage Faso Dan Fani',
      description: 'Maître tisserande, spécialisée dans le tissage traditionnel du Faso Dan Fani',
      city: 'Ouagadougou',
      region: 'Centre',
      distance: 2.3,
      rating: 4.9,
      reviewCount: 127,
      isVerified: true,
      isOnline: true,
      categoryColor: const Color(0xFF2E7D32),
      categoryIcon: Icons.checkroom,
      languages: ['Mooré', 'Français', 'Dioula'],
      experience: '15 ans',
      certifications: ['Maître Artisan certifié', 'Faso Dan Fani Authentique'],
      lastSeen: 'En ligne maintenant',
    ),
    Creator(
      name: 'Amadou Traoré',
      specialty: 'Maroquinerie Traditionnelle',
      description: 'Artisan maroquinier, créateur de sacs et sandales en cuir véritable',
      city: 'Bobo-Dioulasso',
      region: 'Hauts-Bassins',
      distance: 4.7,
      rating: 4.8,
      reviewCount: 89,
      isVerified: true,
      isOnline: false,
      categoryColor: const Color(0xFF8D6E63),
      categoryIcon: Icons.work_outline,
      languages: ['Dioula', 'Français'],
      experience: '12 ans',
      certifications: ['Chambre des Métiers', 'Cuir Authentique BF'],
      lastSeen: 'Il y a 2h',
    ),
    Creator(
      name: 'Aicha Sawadogo',
      specialty: 'Bijoux en Bronze Doré',
      description: 'Créatrice de bijoux traditionnels en bronze doré et perles locales',
      city: 'Koudougou',
      region: 'Centre-Ouest',
      distance: 1.2,
      rating: 4.7,
      reviewCount: 156,
      isVerified: true,
      isOnline: true,
      categoryColor: const Color(0xFFFF6F00),
      categoryIcon: Icons.diamond,
      languages: ['Mooré', 'Français'],
      experience: '8 ans',
      certifications: ['Bijoutier Traditionnel', 'Bronze Doré Certifié'],
      lastSeen: 'En ligne maintenant',
    ),
    Creator(
      name: 'Boureima Compaoré',
      specialty: 'Sculpture sur Bois',
      description: 'Sculpteur traditionnel, créateur de masques Bwaba et statuettes',
      city: 'Banfora',
      region: 'Cascades',
      distance: 8.9,
      rating: 4.9,
      reviewCount: 73,
      isVerified: true,
      isOnline: false,
      categoryColor: const Color(0xFF5D4037),
      categoryIcon: Icons.carpenter,
      languages: ['Sénoufo', 'Dioula', 'Français'],
      experience: '20 ans',
      certifications: ['Maître Sculpteur', 'Arts Traditionnels BF'],
      lastSeen: 'Hier',
    ),
    Creator(
      name: 'Mariam Kaboré',
      specialty: 'Poterie Traditionnelle',
      description: 'Potière experte, spécialisée dans les canaris et jarres traditionnelles',
      city: 'Ouahigouya',
      region: 'Nord',
      distance: 3.4,
      rating: 4.6,
      reviewCount: 94,
      isVerified: false,
      isOnline: true,
      categoryColor: const Color(0xFFD84315),
      categoryIcon: Icons.handyman,
      languages: ['Mooré', 'Français'],
      experience: '18 ans',
      certifications: ['Poterie Ancestrale'],
      lastSeen: 'En ligne maintenant',
    ),
    Creator(
      name: 'Idrissa Ouédraogo',
      specialty: 'Vannerie Peule',
      description: 'Artisan vannier, créateur de paniers et nattes traditionnelles peules',
      city: 'Dori',
      region: 'Sahel',
      distance: 12.1,
      rating: 4.8,
      reviewCount: 61,
      isVerified: true,
      isOnline: false,
      categoryColor: const Color(0xFF689F38),
      categoryIcon: Icons.grass,
      languages: ['Peul', 'Mooré', 'Français'],
      experience: '14 ans',
      certifications: ['Vannerie Traditionnelle', 'Sahel Authentique'],
      lastSeen: 'Il y a 4h',
    ),
    Creator(
      name: 'Salamata Zongo',
      specialty: 'Teinture Indigo',
      description: 'Spécialisée dans la teinture à l\'indigo et bogolan traditionnel',
      city: 'Kaya',
      region: 'Centre-Nord',
      distance: 6.8,
      rating: 4.7,
      reviewCount: 112,
      isVerified: true,
      isOnline: true,
      categoryColor: const Color(0xFF1565C0),
      categoryIcon: Icons.colorize,
      languages: ['Mooré', 'Français'],
      experience: '11 ans',
      certifications: ['Teinture Naturelle', 'Indigo Authentique'],
      lastSeen: 'En ligne maintenant',
    ),
    Creator(
      name: 'Souleymane Diallo',
      specialty: 'Instruments Traditionnels',
      description: 'Luthier traditionnel, fabricant de balafons et djembés authentiques',
      city: 'Gaoua',
      region: 'Sud-Ouest',
      distance: 15.3,
      rating: 4.9,
      reviewCount: 47,
      isVerified: true,
      isOnline: false,
      categoryColor: const Color(0xFF8E24AA),
      categoryIcon: Icons.music_note,
      languages: ['Lobi', 'Dioula', 'Français'],
      experience: '16 ans',
      certifications: ['Luthier Traditionnel', 'Musique Ancestrale'],
      lastSeen: 'Il y a 6h',
    ),
  ];

  List<Creator> get filteredCreators {
    switch (selectedFilter) {
      case 'Récent':
        return [...creators]..sort((a, b) => a.lastSeen.compareTo(b.lastSeen));
      case 'Note':
        return [...creators]..sort((a, b) => b.rating.compareTo(a.rating));
      case 'Distance':
        return [...creators]..sort((a, b) => a.distance.compareTo(b.distance));
      default: // Populaire
        return [...creators]..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec statistiques
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[700]!, Colors.green[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Artisans du Burkina Faso',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${creators.length} artisans authentiques • ${creators.where((c) => c.isOnline).length} en ligne',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.handshake,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Filtres et tri
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Découvrir les créateurs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButton<String>(
                  value: selectedFilter,
                  underline: Container(),
                  icon: Icon(Icons.sort, size: 16, color: Colors.grey[600]),
                  items: ['Populaire', 'Récent', 'Note', 'Distance']
                      .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: const TextStyle(fontSize: 14)),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Liste des créateurs
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredCreators.length,
            itemBuilder: (context, index) {
              final creator = filteredCreators[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: creator.categoryColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar avec icône de catégorie
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              creator.categoryColor.withOpacity(0.8),
                              creator.categoryColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                creator.categoryIcon,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                            // Indicateur en ligne
                            if (creator.isOnline)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Informations du créateur
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    creator.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (creator.isVerified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          size: 12,
                                          color: Colors.blue[700],
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Vérifié',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              creator.specialty,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: creator.categoryColor,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              creator.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Informations géographiques et évaluation
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    '${creator.city}, ${creator.region}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.near_me,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${creator.distance.toStringAsFixed(1)}km',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Note et statut
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  creator.rating.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  ' (${creator.reviewCount} avis)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: creator.isOnline
                                        ? Colors.green[50]
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: creator.isOnline
                                          ? Colors.green[200]!
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    creator.isOnline ? 'En ligne' : creator.lastSeen,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: creator.isOnline
                                          ? Colors.green[700]
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Langues et expérience
                            Row(
                              children: [
                                Icon(
                                  Icons.language,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  creator.languages.take(2).join(', '),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.work_history,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  creator.experience,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Indicateur de spécialité
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: creator.categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: creator.categoryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              creator.categoryIcon,
                              color: creator.categoryColor,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${creator.reviewCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: creator.categoryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'avis',
                              style: TextStyle(
                                fontSize: 8,
                                color: creator.categoryColor,
                                fontWeight: FontWeight.w500,
                              ),
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
    );
  }
}