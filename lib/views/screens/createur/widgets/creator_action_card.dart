import 'package:flutter/material.dart';

import '../../../../design/ecommerce_widgets.dart';

class CreatorActionCard extends StatelessWidget {
  const CreatorActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppActionTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      onTap: onTap,
    );
  }
}
