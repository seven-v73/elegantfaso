import 'package:flutter/material.dart';

import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';

class AppFormErrorBanner extends StatelessWidget {
  const AppFormErrorBanner({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(ModernSpacing.md),
      decoration: BoxDecoration(
        color: ModernColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ModernRadius.md),
        border: Border.all(color: ModernColors.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: ModernColors.danger),
          const SizedBox(width: ModernSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ModernColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRetry != null)
            AppButton(
              label: 'Réessayer',
              onPressed: onRetry,
              variant: AppButtonVariant.tertiary,
              compact: true,
            ),
        ],
      ),
    );
  }
}
