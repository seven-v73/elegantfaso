import 'package:flutter/material.dart';

import '../../../../design/modern_design_system.dart';

class CreatorStatusChip extends StatelessWidget {
  const CreatorStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.68,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

Color creatorStatusColor(String status) {
  return switch (status) {
    'draft' => ModernColors.accent,
    'hidden' => ModernColors.inkSoft,
    'cancelled' => ModernColors.rose,
    'confirmed' || 'completed' || 'done' => ModernColors.success,
    'preparing' => ModernColors.client,
    _ => ModernColors.creator,
  };
}
