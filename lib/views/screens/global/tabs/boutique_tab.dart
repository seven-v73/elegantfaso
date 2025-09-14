import 'package:flutter/material.dart';

import '../widgets/boutique/search_and_filters.dart';
import '../widgets/boutique/promotions_section.dart';
import '../widgets/boutique/categories_grid.dart';
import '../widgets/boutique/recommended_products.dart';

class BoutiqueTab extends StatelessWidget {
  const BoutiqueTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          // SearchAndFilters(),
          PromotionsSection(),
          CategoriesGrid(),
          RecommendedProducts(),
        ],
      ),
    );
  }
}