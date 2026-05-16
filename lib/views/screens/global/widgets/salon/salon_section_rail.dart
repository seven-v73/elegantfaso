import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../models/salon/salon_item.dart';
import '../../../../../models/salon/salon_section.dart';
import 'salon_item_card.dart';

class SalonSectionRail extends StatelessWidget {
  const SalonSectionRail({
    super.key,
    required this.section,
    required this.onItemTap,
  });

  final SalonSection section;
  final ValueChanged<SalonItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          padding: EdgeInsets.zero,
          title: section.title,
          subtitle: section.subtitle,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 224,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: section.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = section.items[index];
              return SalonItemCard(
                item: item,
                compact: true,
                onTap: () => onItemTap(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
