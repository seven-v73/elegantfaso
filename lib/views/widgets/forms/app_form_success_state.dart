import 'package:flutter/material.dart';

import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';

class AppFormSuccessState extends StatelessWidget {
  const AppFormSuccessState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ModernSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: ModernColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: ModernColors.success,
                size: 42,
              ),
            ),
            const SizedBox(height: ModernSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: ModernSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: ModernSpacing.xl),
              AppButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
