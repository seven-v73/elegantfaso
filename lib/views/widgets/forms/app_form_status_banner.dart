import 'package:flutter/material.dart';

import '../../../design/modern_design_system.dart';
import '../../../models/forms/app_form_state.dart';

class AppFormStatusBanner extends StatelessWidget {
  const AppFormStatusBanner({super.key, required this.state, this.onRetry});

  final AppFormState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (!state.hasMessage && state.status != AppFormStatus.saving) {
      return const SizedBox.shrink();
    }

    final color = switch (state.status) {
      AppFormStatus.error => ModernColors.danger,
      AppFormStatus.offline => ModernColors.warning,
      AppFormStatus.success => ModernColors.success,
      AppFormStatus.saving => ModernColors.primary,
      _ => ModernColors.primary,
    };
    final icon = switch (state.status) {
      AppFormStatus.error => Icons.error_outline_rounded,
      AppFormStatus.offline => Icons.wifi_off_rounded,
      AppFormStatus.success => Icons.check_circle_outline_rounded,
      AppFormStatus.saving => Icons.sync_rounded,
      _ => Icons.info_outline_rounded,
    };
    final message =
        state.message.isNotEmpty ? state.message : 'Sauvegarde en cours...';

    return Container(
      padding: const EdgeInsets.all(ModernSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ModernRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: ModernSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (state.progress != null) ...[
                  const SizedBox(height: ModernSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 5,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.16),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRetry != null && state.status == AppFormStatus.error) ...[
            const SizedBox(width: ModernSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ],
      ),
    );
  }
}
