import 'package:flutter/material.dart';

import '../../../../../models/salon/salon_highlight.dart';
import '../../../../../models/salon/salon_quick_entry.dart';
import 'live_highlights_section.dart';

class TrendingNowSection extends StatelessWidget {
  const TrendingNowSection({
    super.key,
    required this.items,
    required this.onOpenTarget,
  });

  final List<SalonHighlight> items;
  final ValueChanged<SalonQuickTarget> onOpenTarget;

  @override
  Widget build(BuildContext context) {
    return LiveHighlightsSection(
      title: 'Tendances du moment',
      subtitle: 'Styles, profils et pièces qui ressortent dans le Salon',
      items: items,
      fallbackIcon: Icons.trending_up_rounded,
      onOpenTarget: onOpenTarget,
    );
  }
}
