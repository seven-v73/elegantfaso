import 'package:flutter/material.dart';

import '../../../../../design/modern_design_system.dart';

class TalentsFilterRail extends StatelessWidget {
  const TalentsFilterRail({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<TalentRoleFilter> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final active = selected == filter.label;
          return ChoiceChip(
            avatar: Icon(
              filter.icon,
              size: 17,
              color: active ? ModernColors.creator : ModernColors.inkSoft,
            ),
            label: Text(filter.label),
            selected: active,
            onSelected: (_) => onSelected(filter.label),
            selectedColor: ModernColors.creator.withValues(alpha: 0.14),
            side: BorderSide(
              color:
                  active
                      ? ModernColors.creator.withValues(alpha: 0.3)
                      : ModernColors.line,
            ),
            labelStyle: TextStyle(
              color: active ? ModernColors.creator : ModernColors.inkSoft,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }
}

class TalentRoleFilter {
  const TalentRoleFilter(this.label, this.icon);

  final String label;
  final IconData icon;
}
