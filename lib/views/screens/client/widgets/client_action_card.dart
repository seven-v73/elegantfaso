import 'package:flutter/material.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../models/client/client_action.dart';

class ClientActionCard extends StatelessWidget {
  final ClientAction action;
  final VoidCallback? onTap;

  const ClientActionCard({super.key, required this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppActionTile(
      title: action.title,
      subtitle: action.subtitle,
      icon: action.icon,
      color: action.color,
      onTap: onTap,
      compact: true,
    );
  }
}
