import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import 'community_screen.dart';
import 'style_quiz.dart';

class StyleAdvisorSection extends StatelessWidget {
  const StyleAdvisorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ModernColors.creator.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.checkroom_rounded,
                  color: ModernColors.creator,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Découvrir mon style',
                      style: TextStyle(
                        color: ModernColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Quelques choix simples pour révéler couleurs, usages et envies.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StyleQuizScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.quiz_rounded, size: 18),
                  label: const Text('Commencer'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => openCommunityScreen(context),
                  icon: const Icon(Icons.forum_rounded, size: 18),
                  label: const Text(
                    'Communauté',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void openCommunityScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const CommunityScreen()),
  );
}
