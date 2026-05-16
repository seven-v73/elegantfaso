import 'package:flutter/material.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/talent/talent_profile.dart';

class TalentsStatsStrip extends StatelessWidget {
  const TalentsStatsStrip({super.key, required this.talents});

  final List<TalentProfile> talents;

  @override
  Widget build(BuildContext context) {
    final cities =
        talents
            .map((talent) => talent.city)
            .where((city) => city.isNotEmpty)
            .toSet();
    final verified = talents.where((talent) => talent.verified).length;
    final available = talents.where((talent) => talent.isAvailable).length;

    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StatCard(
            icon: AppIcons.talents,
            value: '${talents.length}',
            label: 'talents actifs',
            color: ModernColors.creator,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.place_rounded,
            value: '${cities.length}',
            label: 'villes',
            color: ModernColors.primary,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.verified_rounded,
            value: '$verified',
            label: 'vérifiés',
            color: ModernColors.client,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.check_circle_rounded,
            value: '$available',
            label: 'disponibles',
            color: ModernColors.accent,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 144,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        elevated: false,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
