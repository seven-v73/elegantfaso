import 'package:flutter/material.dart';

import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/client/client_dashboard_summary.dart';

class ClientStyleProgressCard extends StatelessWidget {
  final ClientDashboardSummary summary;
  final VoidCallback? onOpenStyle;
  final VoidCallback? onOpenWardrobe;

  const ClientStyleProgressCard({
    super.key,
    required this.summary,
    this.onOpenStyle,
    this.onOpenWardrobe,
  });

  @override
  Widget build(BuildContext context) {
    final completion = summary.measurementCompletion.clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(AppIcons.style, color: ModernColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Studio Style',
                  style: TextStyle(
                    color: ModernColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 8,
              backgroundColor: ModernColors.line,
              color: ModernColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(completion * 100).round()}% de mensurations complétées',
            style: const TextStyle(
              color: ModernColors.inkSoft,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                icon: AppIcons.wardrobe,
                label: '${summary.wardrobeCount} pièces',
                onTap: onOpenWardrobe,
              ),
              _Chip(
                icon: AppIcons.favorites,
                label: '${summary.favoriteCount} favoris',
                onTap: onOpenWardrobe,
              ),
              _Chip(
                icon: AppIcons.style,
                label: 'Conseil style',
                onTap: onOpenStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _Chip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ModernColors.canvas,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: ModernColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
