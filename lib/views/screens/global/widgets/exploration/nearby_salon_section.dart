import 'package:flutter/material.dart';

import '../../../../../models/salon/salon_highlight.dart';
import '../../../../../models/salon/salon_quick_entry.dart';
import 'live_highlights_section.dart';

class NearbySalonSection extends StatelessWidget {
  const NearbySalonSection({
    super.key,
    required this.city,
    required this.items,
    required this.onOpenTarget,
  });

  final String city;
  final List<SalonHighlight> items;
  final ValueChanged<SalonQuickTarget> onOpenTarget;

  @override
  Widget build(BuildContext context) {
    return LiveHighlightsSection(
      title: city.isEmpty ? 'Sélection du Salon' : 'Près de $city',
      subtitle:
          city.isEmpty
              ? 'Pièces et profils visibles maintenant'
              : 'Créations, boutiques et talents autour de toi',
      items: items,
      fallbackIcon: Icons.location_on_rounded,
      onOpenTarget: onOpenTarget,
    );
  }
}
