import 'package:flutter/material.dart';

import '../../../../../design/modern_design_system.dart';

class EventFilterItem {
  const EventFilterItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

class EventFilterRail extends StatelessWidget {
  const EventFilterRail({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<EventFilterItem> filters;
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
          final item = filters[index];
          final isSelected = item.label == selected;
          return ChoiceChip(
            avatar: Icon(
              item.icon,
              size: 16,
              color: isSelected ? ModernColors.shop : ModernColors.inkSoft,
            ),
            label: Text(item.label),
            selected: isSelected,
            onSelected: (_) => onSelected(item.label),
            selectedColor: ModernColors.accent.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: isSelected ? ModernColors.shop : ModernColors.inkSoft,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            side: BorderSide(
              color:
                  isSelected
                      ? ModernColors.accent.withValues(alpha: 0.38)
                      : ModernColors.line,
            ),
          );
        },
      ),
    );
  }
}
