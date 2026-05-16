import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/salon/salon_quick_entry.dart';

class QuickEntryGrid extends StatelessWidget {
  const QuickEntryGrid({
    super.key,
    required this.entries,
    required this.onSelected,
  });

  final List<SalonQuickEntry> entries;
  final ValueChanged<SalonQuickEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.36,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return AppCard(
          onTap: () => onSelected(entry),
          padding: const EdgeInsets.all(13),
          elevated: index == 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: entry.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(entry.icon, color: entry.color, size: 21),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: ModernColors.inkSoft,
                    size: 18,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
