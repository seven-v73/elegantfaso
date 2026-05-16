import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';

class SalonEmptyState extends StatelessWidget {
  const SalonEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(icon, color: ModernColors.inkSoft, size: 38),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ModernColors.inkSoft, height: 1.35),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            AppButton(
              label: 'Réessayer',
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }
}
