import 'package:flutter/material.dart';

import '../../../design/modern_design_system.dart';

class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ModernSpacing.lg),
      decoration: ModernDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: ModernColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: ModernColors.primary, size: 21),
                ),
                const SizedBox(width: ModernSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ModernSpacing.lg),
          ..._spaced(children),
        ],
      ),
    );
  }

  List<Widget> _spaced(List<Widget> widgets) {
    final spaced = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      if (i > 0) spaced.add(const SizedBox(height: ModernSpacing.md));
      spaced.add(widgets[i]);
    }
    return spaced;
  }
}
