import 'package:flutter/material.dart';

import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';

class AppStickyFormBar extends StatelessWidget {
  const AppStickyFormBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.isLoading = false,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        ModernSpacing.lg,
        ModernSpacing.md,
        ModernSpacing.lg,
        bottom + ModernSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: ModernColors.surface,
        border: Border(top: BorderSide(color: ModernColors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x140F172A),
            offset: Offset(0, -10),
            blurRadius: 24,
            spreadRadius: -16,
          ),
        ],
      ),
      child: Row(
        children: [
          if (secondaryLabel != null) ...[
            Expanded(
              child: AppButton(
                label: secondaryLabel!,
                onPressed: isLoading ? null : onSecondary,
                variant: AppButtonVariant.outline,
              ),
            ),
            const SizedBox(width: ModernSpacing.md),
          ],
          Expanded(
            flex: secondaryLabel == null ? 1 : 2,
            child: AppButton(
              label: primaryLabel,
              onPressed: onPrimary,
              loading: isLoading,
              expand: true,
            ),
          ),
        ],
      ),
    );
  }
}
