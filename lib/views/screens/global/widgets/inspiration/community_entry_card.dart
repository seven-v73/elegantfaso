import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import 'community_screen.dart';

class CommunityEntryCard extends StatelessWidget {
  const CommunityEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CommunityScreen()),
          ),
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ModernColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.forum_rounded, color: ModernColors.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avis de la communauté',
                  style: TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Demandez un avis, montrez une idée ou trouvez des conseils.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ModernColors.inkSoft,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: ModernColors.primary),
        ],
      ),
    );
  }
}
