import 'package:flutter/material.dart';

import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';

class AppActionEmptyState extends StatelessWidget {
  const AppActionEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.accent = ModernColors.primary,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(compact ? 14 : 18),
      elevated: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 44 : 52,
            height: compact ? 44 : 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.16)),
            ),
            child: Icon(icon, color: accent, size: compact ? 22 : 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (message.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              icon: Icons.arrow_forward_rounded,
              variant: AppButtonVariant.primary,
              compact: true,
            ),
          ],
          if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            const SizedBox(height: 8),
            AppButton(
              label: secondaryActionLabel!,
              onPressed: onSecondaryAction,
              variant: AppButtonVariant.tertiary,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}
