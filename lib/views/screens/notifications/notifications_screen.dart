import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../design/app_icons.dart';
import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';
import '../../../models/notifications/app_notification.dart';
import '../../../services/notifications/app_notification_service.dart';
import '../base/client_profile_screen.dart';
import '../client/features/style/style_hub_screen.dart';
import '../client/purchases/client_purchase_history_screen.dart';
import '../client/secondhand/client_secondhand_screen.dart';
import '../messages/messages_entry_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AppNotificationService _service = AppNotificationService();
  final DateFormat _dateFormat = DateFormat('dd MMM • HH:mm');
  String _filter = 'Tout';

  static const _filters = [
    'Tout',
    'Important',
    'Commandes',
    'Messages',
    'Paiements',
    'RDV',
    'Style',
    'Communauté',
    'Espace Pro',
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: ModernColors.surface,
        foregroundColor: ModernColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (user != null)
            IconButton(
              tooltip: 'Préférences',
              onPressed: () => _openPreferences(context, user.uid),
              icon: const Icon(Icons.tune_rounded),
            ),
          if (user != null)
            TextButton(
              onPressed: () => _service.markAllAsRead(user.uid),
              child: const Text('Tout lire'),
            ),
        ],
      ),
      body:
          user == null
              ? _LoginPrompt()
              : StreamBuilder<List<AppNotification>>(
                stream: _service.watchUserNotifications(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final notifications = snapshot.data ?? const [];
                  if (notifications.isEmpty) return const _EmptyState();
                  final visible = _filterNotifications(notifications);
                  return Column(
                    children: [
                      _NotificationFilters(
                        filters: _filters,
                        selected: _filter,
                        notifications: notifications,
                        onSelected: (value) => setState(() => _filter = value),
                      ),
                      Expanded(
                        child:
                            visible.isEmpty
                                ? _EmptyState(filter: _filter)
                                : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    6,
                                    16,
                                    16,
                                  ),
                                  itemBuilder: (context, index) {
                                    final notification = visible[index];
                                    return _NotificationTile(
                                      notification: notification,
                                      dateFormat: _dateFormat,
                                      onTap:
                                          () => _openNotification(
                                            context,
                                            notification,
                                          ),
                                      onDelete:
                                          () => _service.deleteNotification(
                                            notification.id,
                                          ),
                                    );
                                  },
                                  separatorBuilder:
                                      (context, index) =>
                                          const SizedBox(height: 10),
                                  itemCount: visible.length,
                                ),
                      ),
                    ],
                  );
                },
              ),
    );
  }

  Future<void> _openPreferences(BuildContext context, String userId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) =>
              _NotificationPreferencesSheet(userId: userId, service: _service),
    );
  }

  List<AppNotification> _filterNotifications(
    List<AppNotification> notifications,
  ) {
    return notifications.where((notification) {
      if (notification.isExpired) return false;
      if (_filter == 'Tout') return true;
      if (_filter == 'Important') return notification.isImportant;
      return notification.category == _filter;
    }).toList();
  }

  Future<void> _openNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    if (!notification.read) await _service.markAsRead(notification.id);
    final route = notification.route;
    if (route != null &&
        route.isNotEmpty &&
        route != '/notifications' &&
        context.mounted) {
      Navigator.pushNamed(context, route);
      return;
    }
    if (!context.mounted) return;
    await _openNotificationTarget(context, notification);
  }

  Future<void> _openNotificationTarget(
    BuildContext context,
    AppNotification notification,
  ) async {
    final targetType = notification.targetType;
    if (targetType == 'conversation') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MessagesEntryScreen()),
      );
      return;
    }
    if (targetType == 'order' || targetType == 'withdrawal') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ClientPurchaseHistoryScreen()),
      );
      return;
    }
    if (targetType == 'secondhand_listing') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ClientSecondhandScreen()),
      );
      return;
    }
    if (targetType == 'daily_quiz' || notification.type.contains('style')) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const StyleHubScreen(showBackButton: true),
        ),
      );
      return;
    }
    if (targetType == 'profile' ||
        notification.type == 'profile_payment_missing') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ClientProfileScreen(showBackButton: true),
        ),
      );
    }
  }
}

class _NotificationFilters extends StatelessWidget {
  const _NotificationFilters({
    required this.filters,
    required this.selected,
    required this.notifications,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final List<AppNotification> notifications;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final count = _countFor(filter);
          final isSelected = selected == filter;
          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            avatar:
                count > 0
                    ? CircleAvatar(
                      radius: 10,
                      backgroundColor:
                          isSelected ? Colors.white : ModernColors.primary,
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: TextStyle(
                          color:
                              isSelected ? ModernColors.primary : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                    : null,
            label: Text(filter),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : ModernColors.primary,
              fontWeight: FontWeight.w900,
            ),
            selectedColor: ModernColors.primary,
            backgroundColor: ModernColors.primary.withValues(alpha: 0.08),
            side: BorderSide(
              color: ModernColors.primary.withValues(alpha: 0.14),
            ),
            onSelected: (_) => onSelected(filter),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: filters.length,
      ),
    );
  }

  int _countFor(String filter) {
    return notifications.where((notification) {
      if (notification.isExpired) return false;
      if (filter == 'Tout') return !notification.read;
      if (filter == 'Important') return notification.isImportant;
      return notification.category == filter && !notification.read;
    }).length;
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.dateFormat,
    required this.onTap,
    required this.onDelete,
  });

  final AppNotification notification;
  final DateFormat dateFormat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final time = notification.createdAt;
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: ModernColors.danger,
          borderRadius: BorderRadius.circular(ModernRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: AppCard(
        onTap: onTap,
        elevated: !notification.read,
        color:
            notification.read
                ? ModernColors.surface
                : ModernColors.primary.withValues(alpha: 0.06),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: ModernColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(notification.icon, color: ModernColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: ModernColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      height: 1.35,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          dateFormat.format(time),
                          style: const TextStyle(
                            color: ModernColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _NotificationMetaChip(
                          label: notification.category,
                          important: notification.isImportant,
                        ),
                      ],
                    ),
                  ],
                  if (notification.actionLabel.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        notification.actionLabel,
                        style: const TextStyle(
                          color: ModernColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.filter = 'Tout'});

  final String filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ModernColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: ModernColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              filter == 'Tout' ? 'Rien pour le moment' : 'Rien dans $filter',
              style: TextStyle(
                color: ModernColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Messages, commandes, rendez-vous, mises en avant et rappels importants apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ModernColors.inkSoft, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationMetaChip extends StatelessWidget {
  const _NotificationMetaChip({required this.label, required this.important});

  final String label;
  final bool important;

  @override
  Widget build(BuildContext context) {
    final color = important ? ModernColors.warning : ModernColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        important ? 'Important' : label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _NotificationPreferencesSheet extends StatelessWidget {
  const _NotificationPreferencesSheet({
    required this.userId,
    required this.service,
  });

  final String userId;
  final AppNotificationService service;

  static const _categoryLabels = {
    'messages': ('Messages', Icons.chat_bubble_outline_rounded),
    'orders': ('Commandes', AppIcons.orders),
    'payments': ('Paiements', Icons.account_balance_wallet_outlined),
    'appointments': ('RDV', Icons.event_available_outlined),
    'style': ('Style', Icons.auto_awesome_rounded),
    'community': ('Communauté', Icons.groups_2_outlined),
    'pro': ('Espace Pro', Icons.workspace_premium_outlined),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: StreamBuilder<Map<String, dynamic>>(
        stream: service.watchNotificationSettings(userId),
        builder: (context, snapshot) {
          final settings = snapshot.data ?? const {};
          final pushEnabled = settings['pushEnabled'] != false;
          final categories =
              settings['categories'] is Map
                  ? Map<String, dynamic>.from(settings['categories'])
                  : const <String, dynamic>{};
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ModernColors.muted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: ModernColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: ModernColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Préférences d’alertes',
                          style: TextStyle(
                            color: ModernColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Le centre garde tout. Ici, vous choisissez les push.',
                          style: TextStyle(
                            color: ModernColors.inkSoft,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AppCard(
                padding: EdgeInsets.zero,
                child: SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
                  value: pushEnabled,
                  activeThumbColor: ModernColors.primary,
                  activeTrackColor: ModernColors.primary.withValues(
                    alpha: 0.28,
                  ),
                  onChanged:
                      (value) => service.updatePushEnabled(userId, value),
                  title: const Text(
                    'Alertes push',
                    style: TextStyle(
                      color: ModernColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: const Text(
                    'Désactive uniquement les alertes instantanées.',
                    style: TextStyle(color: ModernColors.inkSoft),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Opacity(
                opacity: pushEnabled ? 1 : 0.48,
                child: AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children:
                        _categoryLabels.entries.map((entry) {
                          final enabled = categories[entry.key] != false;
                          final label = entry.value.$1;
                          final icon = entry.value.$2;
                          return SwitchListTile.adaptive(
                            contentPadding: const EdgeInsets.fromLTRB(
                              14,
                              0,
                              10,
                              0,
                            ),
                            secondary: Icon(
                              icon,
                              color:
                                  pushEnabled
                                      ? ModernColors.primary
                                      : ModernColors.muted,
                            ),
                            value: pushEnabled && enabled,
                            activeThumbColor: ModernColors.primary,
                            activeTrackColor: ModernColors.primary.withValues(
                              alpha: 0.28,
                            ),
                            onChanged:
                                pushEnabled
                                    ? (value) => service.updatePushCategory(
                                      userId,
                                      entry.key,
                                      value,
                                    )
                                    : null,
                            title: Text(
                              label,
                              style: const TextStyle(
                                color: ModernColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Les alertes urgentes restent visibles dans le centre d’attention. Les push suivent vos préférences pour réduire le bruit.',
                style: TextStyle(color: ModernColors.muted, height: 1.35),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        margin: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: ModernColors.primary,
              size: 34,
            ),
            const SizedBox(height: 12),
            const Text(
              'Connectez-vous pour voir vos notifications.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ModernColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
