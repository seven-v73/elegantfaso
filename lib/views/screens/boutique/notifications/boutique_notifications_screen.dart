import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elegantfaso/views/screens/boutique/orders/order_detail_screen.dart';
import 'package:elegantfaso/models/boutique/boutique_order.dart';
import 'package:elegantfaso/views/screens/messages/messages_entry_screen.dart';
import 'package:elegantfaso/services/salon/salon_analytics_service.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import 'package:shimmer/shimmer.dart';

import '../../../../design/app_icons.dart';

class BoutiqueNotificationsScreen extends StatefulWidget {
  const BoutiqueNotificationsScreen({super.key});

  @override
  State<BoutiqueNotificationsScreen> createState() =>
      _BoutiqueNotificationsScreenState();
}

class _BoutiqueNotificationsScreenState
    extends State<BoutiqueNotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy • HH:mm');
  bool _isMarkingAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildNotificationList());
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Notifications',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        StreamBuilder<QuerySnapshot>(
          stream: _getNotificationsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox();
            }

            final unreadCount =
                snapshot.data!.docs.where((doc) => !_isRead(doc)).length;

            return IconButton(
              icon:
                  _isMarkingAll
                      ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      )
                      : badges.Badge(
                        showBadge: unreadCount > 0,
                        badgeContent: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        badgeStyle: const badges.BadgeStyle(
                          badgeColor: Color(0xFFF93963),
                        ),
                        child: const Icon(Icons.mark_email_read),
                      ),
              tooltip: 'Marquer tous comme lus',
              onPressed: unreadCount > 0 ? _markAllAsRead : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotificationList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getNotificationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoader();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final notifications = snapshot.data!.docs;
        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: notifications.length,
            separatorBuilder:
                (context, index) => Divider(height: 1, indent: 72),
            itemBuilder:
                (context, index) => _NotificationItem(
                  notification: notifications[index],
                  dateFormat: _dateFormat,
                  onTap:
                      () =>
                          _handleNotificationTap(context, notifications[index]),
                  onDismiss:
                      (direction) => _dismissNotification(notifications[index]),
                ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(width: 200, height: 14, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 150, height: 12, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.16),
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 58,
                color: Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tout est calme pour le moment',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Commandes, messages et rendez-vous apparaîtront ici.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Actualiser'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => const MessagesEntryScreen(
                                roleOverride: 'boutique',
                              ),
                        ),
                      ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Messages'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getNotificationsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final notification = doc.data() as Map<String, dynamic>;

    // Marquer comme lu si non lu
    if (!_readFromMap(notification)) {
      await doc.reference.set({
        'read': true,
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    if (!context.mounted) return;

    final eventType = _notificationType(notification);
    final route = _stringValue(notification['route']);
    if (route.isNotEmpty && route != '/notifications') {
      Navigator.pushNamed(context, route);
      return;
    }

    // Navigation selon le type de notification
    switch (eventType) {
      case 'order':
        final orderId = _notificationTarget(notification, 'orderId');
        if (orderId.isNotEmpty) {
          final orderDoc =
              await _firestore.collection('orders').doc(orderId).get();
          if (orderDoc.exists) {
            final order = BoutiqueOrder.fromFirestore(orderDoc);
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailScreen(order: order),
              ),
            );
            return;
          }
        }
        if (!context.mounted) return;
        _showNotificationDetails(context, notification);
        break;

      case 'product':
        final productId = _notificationTarget(notification, 'productId');
        if (productId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: productId),
            ),
          );
          return;
        }
        _showNotificationDetails(context, notification);
        break;

      case 'appointment':
        final appointmentId = _notificationTarget(
          notification,
          'appointmentId',
        );
        if (appointmentId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      AppointmentDetailScreen(appointmentId: appointmentId),
            ),
          );
          return;
        }
        _showNotificationDetails(context, notification);
        break;

      case 'message':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MessagesEntryScreen(roleOverride: 'boutique'),
          ),
        );
        break;

      default:
        _showNotificationDetails(context, notification);
        break;
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() => _isMarkingAll = true);

    final batch = _firestore.batch();
    final notifications = await _getNotificationsStream().first;
    if (!mounted) return;

    for (final doc in notifications.docs) {
      if (!_isRead(doc)) {
        batch.set(doc.reference, {
          'read': true,
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    await batch.commit();
    if (mounted) setState(() => _isMarkingAll = false);
  }

  bool _isRead(DocumentSnapshot doc) {
    final data = doc.data();
    if (data is Map<String, dynamic>) return _readFromMap(data);
    return false;
  }

  bool _readFromMap(Map<String, dynamic> data) {
    final value = data['read'] ?? data['isRead'];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  String _notificationType(Map<String, dynamic> data) {
    final type = _stringValue(data['type']);
    if (type.isNotEmpty) return type;
    final eventType = _stringValue(data['eventType']);
    return eventType.isEmpty ? 'system' : eventType;
  }

  String _notificationTarget(Map<String, dynamic> data, String key) {
    final directValue = _stringValue(data[key]);
    if (directValue.isNotEmpty) return directValue;
    final nested = data['data'];
    if (nested is Map<String, dynamic>) return _stringValue(nested[key]);
    if (nested is Map) return _stringValue(nested[key]);
    return '';
  }

  String _stringValue(Object? value) => value?.toString().trim() ?? '';

  String _notificationBody(Map<String, dynamic> data) {
    final body = _stringValue(data['body']);
    if (body.isNotEmpty) return body;
    final message = _stringValue(data['message']);
    if (message.isNotEmpty) return message;
    return 'Nouvelle activité sur votre boutique.';
  }

  void _showNotificationDetails(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    final title = _stringValue(notification['title']);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title.isEmpty ? 'Notification' : title),
            content: Text(_notificationBody(notification)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  Future<void> _dismissNotification(DocumentSnapshot doc) async {
    await doc.reference.delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification supprimée'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final DocumentSnapshot notification;
  final DateFormat dateFormat;
  final VoidCallback onTap;
  final Function(DismissDirection) onDismiss;

  const _NotificationItem({
    required this.notification,
    required this.dateFormat,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final data = notification.data() as Map<String, dynamic>;
    final isRead = _readFromMap(data);
    final createdAt = data['createdAt'];
    final time =
        createdAt is Timestamp
            ? dateFormat.format(createdAt.toDate())
            : dateFormat.format(DateTime.now());
    final eventType = _notificationType(data);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: onDismiss,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isRead ? Colors.white : const Color(0xFFF0F7FF),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(context, eventType),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? 'Notification',
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                              color:
                                  isRead
                                      ? Colors.grey[800]
                                      : const Color(0xFF2A2D3E),
                            ),
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _notificationBody(data),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.circle, size: 4, color: Colors.grey[400]),
                        const SizedBox(width: 10),
                        Text(
                          _getEventTypeText(eventType),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getEventTypeColor(eventType),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _readFromMap(Map<String, dynamic> data) {
    final value = data['read'] ?? data['isRead'];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  String _notificationType(Map<String, dynamic> data) {
    final type = _stringValue(data['type']);
    if (type.isNotEmpty) return type;
    final eventType = _stringValue(data['eventType']);
    return eventType.isEmpty ? 'system' : eventType;
  }

  String _notificationBody(Map<String, dynamic> data) {
    final body = _stringValue(data['body']);
    if (body.isNotEmpty) return body;
    final message = _stringValue(data['message']);
    if (message.isNotEmpty) return message;
    return 'Nouvelle activité sur votre boutique.';
  }

  String _stringValue(Object? value) => value?.toString().trim() ?? '';

  Widget _buildNotificationIcon(BuildContext context, String eventType) {
    final icon = switch (eventType) {
      'order' => AppIcons.orders,
      'product' => AppIcons.shop,
      'message' => Icons.chat_bubble,
      'appointment' => Icons.calendar_today,
      'review' => Icons.star,
      'system' => Icons.info,
      _ => Icons.notifications,
    };

    final color = switch (eventType) {
      'order' => const Color(0xFF4CAF50),
      'product' => const Color(0xFF2196F3),
      'message' => const Color(0xFF9C27B0),
      'appointment' => const Color(0xFFFF9800),
      'review' => const Color(0xFFFFC107),
      'system' => const Color(0xFF607D8B),
      _ => Theme.of(context).primaryColor,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getEventTypeText(String eventType) {
    return switch (eventType) {
      'order' => 'Commande',
      'product' => 'Produit',
      'message' => 'Message',
      'appointment' => 'Rendez-vous',
      'review' => 'Avis',
      'system' => 'Système',
      _ => 'Notification',
    };
  }

  Color _getEventTypeColor(String eventType) {
    return switch (eventType) {
      'order' => const Color(0xFF4CAF50),
      'product' => const Color(0xFF2196F3),
      'message' => const Color(0xFF9C27B0),
      'appointment' => const Color(0xFFFF9800),
      'review' => const Color(0xFFFFC107),
      'system' => const Color(0xFF607D8B),
      _ => Colors.grey,
    };
  }
}

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final SalonAnalyticsService _analyticsService = SalonAnalyticsService();

  @override
  void initState() {
    super.initState();
    _trackProductView();
  }

  Future<void> _trackProductView() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .get();
    final data = doc.data();
    if (data == null) return;
    await _analyticsService.trackListingView(
      itemId: widget.productId,
      itemType: data['type']?.toString() == 'creation' ? 'creation' : 'product',
      ownerId:
          data['boutiqueId']?.toString() ??
          data['sellerId']?.toString() ??
          data['ownerId']?.toString() ??
          '',
      title: data['name']?.toString() ?? data['title']?.toString() ?? 'Produit',
      city: data['city']?.toString() ?? data['ville']?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails Produit')),
      body: Center(child: Text('Détails du produit ${widget.productId}')),
    );
  }
}

class AppointmentDetailScreen extends StatelessWidget {
  final String appointmentId;

  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails Rendez-vous')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('appointments')
                .doc(appointmentId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data;
          if (doc == null || !doc.exists || doc.data() == null) {
            return const _AppointmentMissingState();
          }

          final data = doc.data()!;
          final date = _appointmentDate(data);
          final dateLabel =
              date == null
                  ? 'Date à confirmer'
                  : DateFormat('EEE d MMM • HH:mm', 'fr').format(date);
          final status = _appointmentStatusLabel(data['status']);
          final client = _stringFromKeys(data, const [
            'clientName',
            'customerName',
            'userName',
            'name',
          ]);
          final reason = _stringFromKeys(data, const [
            'reason',
            'intent',
            'intention',
            'message',
            'note',
          ]);
          final linkedItem = _stringFromKeys(data, const [
            'productName',
            'creationName',
            'itemName',
            'serviceName',
          ]);
          final location = _stringFromKeys(data, const [
            'location',
            'address',
            'lieu',
          ]);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        _AppointmentPill(label: status),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      client.isEmpty ? 'Rendez-vous client' : client,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _AppointmentInfoCard(
                icon: Icons.format_quote_rounded,
                title: 'Intention',
                value: reason.isEmpty ? 'Non précisée' : reason,
              ),
              if (linkedItem.isNotEmpty) ...[
                const SizedBox(height: 10),
                _AppointmentInfoCard(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Lié à',
                  value: linkedItem,
                ),
              ],
              if (location.isNotEmpty) ...[
                const SizedBox(height: 10),
                _AppointmentInfoCard(
                  icon: Icons.place_outlined,
                  title: 'Lieu',
                  value: location,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => const MessagesEntryScreen(
                              roleOverride: 'boutique',
                            ),
                      ),
                    ),
                icon: const Icon(Icons.chat_rounded),
                label: const Text('Messages'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AppointmentMissingState extends StatelessWidget {
  const _AppointmentMissingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Ce rendez-vous n’est plus disponible.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _AppointmentPill extends StatelessWidget {
  const _AppointmentPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AppointmentInfoCard extends StatelessWidget {
  const _AppointmentInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF0F766E), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

DateTime? _appointmentDate(Map<String, dynamic> data) {
  final raw =
      data['date'] ??
      data['scheduledAt'] ??
      data['startAt'] ??
      data['appointmentDate'] ??
      data['createdAt'];
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

String _stringFromKeys(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _appointmentStatusLabel(Object? raw) {
  return switch (raw?.toString().toLowerCase()) {
    'confirmed' => 'Confirmé',
    'cancelled' => 'Annulé',
    'preparing' => 'À préparer',
    'completed' => 'Terminé',
    _ => 'À confirmer',
  };
}
