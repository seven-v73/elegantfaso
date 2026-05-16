import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/salon/salon_overview.dart';

class GuestCtaCard extends StatelessWidget {
  const GuestCtaCard({
    super.key,
    required this.overview,
    required this.onOpenWorkspace,
  });

  final SalonOverview overview;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    if (overview.isGuest) {
      return const SizedBox.shrink();
    }

    final title =
        overview.isProfessional ? 'Retour à ton espace' : 'Ton activité Salon';
    final subtitle =
        overview.isProfessional
            ? '${overview.myCreationCount + overview.myProductCount} publications, ${overview.wishlistCount} souhaits suivis.'
            : '${overview.wishlistCount} souhaits, ${overview.orderCount} commandes suivies.';

    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ModernColors.creator.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              overview.isProfessional
                  ? Icons.dashboard_customize_rounded
                  : Icons.bookmark_rounded,
              color: ModernColors.creator,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            onPressed: onOpenWorkspace,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}
