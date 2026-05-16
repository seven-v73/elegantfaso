import 'package:flutter/material.dart';

import '../../../design/modern_design_system.dart';
import '../../../services/notifications/app_notification_service.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    required this.userId,
    required this.onPressed,
    this.icon = Icons.notifications_none_rounded,
    this.iconColor = ModernColors.inkSoft,
    this.badgeColor = ModernColors.rose,
    this.tooltip = 'Notifications',
  });

  final String? userId;
  final VoidCallback onPressed;
  final IconData icon;
  final Color iconColor;
  final Color badgeColor;
  final String tooltip;

  static final AppNotificationService _service = AppNotificationService();
  static final Map<String, Stream<int>> _unreadStreams = {};

  @override
  Widget build(BuildContext context) {
    final uid = userId;
    if (uid == null || uid.isEmpty) {
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor),
      );
    }

    return StreamBuilder<int>(
      stream: _streamFor(uid),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return IconButton(
          tooltip: count > 0 ? '$tooltip ($count)' : tooltip,
          onPressed: onPressed,
          icon: Badge(
            isLabelVisible: count > 0,
            backgroundColor: badgeColor,
            label: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Icon(icon, color: iconColor),
          ),
        );
      },
    );
  }

  static Stream<int> _streamFor(String userId) {
    return _unreadStreams.putIfAbsent(
      userId,
      () => _service.watchUnreadCount(userId).asBroadcastStream(),
    );
  }
}
