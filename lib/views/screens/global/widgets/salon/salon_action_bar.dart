import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../models/salon/salon_action.dart';

class SalonActionBar extends StatelessWidget {
  const SalonActionBar({
    super.key,
    required this.actions,
    required this.onAction,
  });

  final List<SalonAction> actions;
  final ValueChanged<SalonAction> onAction;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final primary = actions.first;
    final secondaryActions =
        actions.skip(1).map((action) {
          return AppOverflowAction(
            label: action.label,
            icon: action.icon,
            onPressed: () => onAction(action),
          );
        }).toList();

    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: primary.label,
            onPressed: () => onAction(primary),
            icon: primary.icon,
            variant: AppButtonVariant.secondary,
            compact: true,
            expand: true,
          ),
        ),
        if (secondaryActions.isNotEmpty) ...[
          const SizedBox(width: 8),
          AppOverflowMenu(actions: secondaryActions),
        ],
      ],
    );
  }
}
