import 'package:flutter/material.dart';

class CategoryData {
  final String name;
  final IconData icon;
  final Color color;
  final double salesRate;
  final int totalSold;
  final String description;
  final List<String> popularItems;
  final String priceRange;

  CategoryData({
    required this.name,
    required this.icon,
    required this.color,
    required this.salesRate,
    required this.totalSold,
    required this.description,
    required this.popularItems,
    required this.priceRange,
  });
}

class CategoriesGrid extends StatelessWidget {
  const CategoriesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      CategoryData(
        name: 'Pagnes',
        icon: Icons.checkroom,
        color: Colors.blue,
        salesRate: 89.5,
        totalSold: 2847,
        description: 'Tissus traditionnels burkinabé, incluant le Faso Dan Fani et pagnes wax importés. Très populaires pour les cérémonies et la vie quotidienne.',
        popularItems: ['Faso Dan Fani', 'Wax hollandais', 'Bogolan', 'Batik local'],
        priceRange: '2 500 - 25 000 FCFA',
      ),
      CategoryData(
        name: 'Boubous',
        icon: Icons.style,
        color: Colors.green,
        salesRate: 76.3,
        totalSold: 1923,
        description: 'Vêtements traditionnels masculins et féminins, confectionnés localement avec des tissus de qualité.',
        popularItems: ['Boubou brodé', 'Grand boubou', 'Boubou simple', 'Ensemble complet'],
        priceRange: '8 000 - 45 000 FCFA',
      ),
      CategoryData(
        name: 'Accessoires',
        icon: Icons.watch,
        color: Colors.purple,
        salesRate: 68.7,
        totalSold: 3456,
        description: 'Accessoires de mode incluant montres, ceintures, foulards et autres articles de style.',
        popularItems: ['Montres fashion', 'Ceintures cuir', 'Foulards', 'Casquettes'],
        priceRange: '1 500 - 15 000 FCFA',
      ),
      CategoryData(
        name: 'Chaussures',
        icon: Icons.shopping_bag,
        color: Colors.orange,
        salesRate: 82.1,
        totalSold: 2134,
        description: 'Chaussures pour hommes, femmes et enfants. Du style décontracté aux chaussures de cérémonie.',
        popularItems: ['Sandales cuir', 'Baskets', 'Mocassins', 'Chaussures de soirée'],
        priceRange: '3 000 - 35 000 FCFA',
      ),
      CategoryData(
        name: 'Bijoux',
        icon: Icons.diamond,
        color: Colors.pink,
        salesRate: 71.8,
        totalSold: 1567,
        description: 'Bijoux traditionnels et modernes, incluant les créations artisanales locales en bronze et argent.',
        popularItems: ['Colliers bronze', 'Bracelets argent', 'Boucles d\'oreilles', 'Bagues traditionnelles'],
        priceRange: '2 000 - 50 000 FCFA',
      ),
      CategoryData(
        name: 'Sacs',
        icon: Icons.backpack,
        color: Colors.teal,
        salesRate: 64.2,
        totalSold: 1892,
        description: 'Sacs à main, sacs de voyage et maroquinerie. Mélange de styles modernes et traditionnels.',
        popularItems: ['Sacs à main cuir', 'Sacs en raphia', 'Sacs de voyage', 'Pochettes'],
        priceRange: '4 000 - 28 000 FCFA',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Catégories populaires',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🇧🇫 Mode BF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return GestureDetector(
                onTap: () => _showCategoryDetails(context, category),
                child: Container(
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: category.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Icon(
                            category.icon,
                            size: 32,
                            color: category.color,
                          ),
                          if (category.salesRate > 75)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: category.color,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${category.salesRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: category.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${category.totalSold} vendus',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
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

  void _showCategoryDetails(BuildContext context, CategoryData category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            category.icon,
                            size: 24,
                            color: category.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Taux de vente: ${category.salesRate}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: category.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Statistiques
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Articles vendus',
                            category.totalSold.toString(),
                            Icons.shopping_cart,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Gamme de prix',
                            category.priceRange,
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Articles populaires
                    const Text(
                      'Articles les plus populaires',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: category.popularItems.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: category.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  category.popularItems[index],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}