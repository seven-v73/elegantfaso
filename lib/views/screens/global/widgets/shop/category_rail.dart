import 'package:flutter/material.dart';

import '../../../../../design/modern_design_system.dart';

class CategoryRail extends StatelessWidget {
  const CategoryRail({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<ShopCategory> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final active = selected == category.label;
          return ChoiceChip(
            avatar: Icon(
              category.icon,
              size: 17,
              color: active ? ModernColors.primary : ModernColors.inkSoft,
            ),
            label: Text(category.label),
            selected: active,
            onSelected: (_) => onSelected(category.label),
            selectedColor: ModernColors.primary.withValues(alpha: 0.14),
            side: BorderSide(
              color:
                  active
                      ? ModernColors.primary.withValues(alpha: 0.26)
                      : ModernColors.line,
            ),
            labelStyle: TextStyle(
              color: active ? ModernColors.primary : ModernColors.inkSoft,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }
}

class ShopCategory {
  const ShopCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}
