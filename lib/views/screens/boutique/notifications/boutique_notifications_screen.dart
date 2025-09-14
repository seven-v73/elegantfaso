import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elegantfaso/views/screens/boutique/orders/order_detail_screen.dart';
import 'package:elegantfaso/models/boutique/boutique_order.dart';
import 'package:elegantfaso/views/screens/boutique/products/product_detail_screen.dart';
import 'package:elegantfaso/views/screens/boutique/appointment/appointment_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import 'package:shimmer/shimmer.dart';

class BoutiqueNotificationsScreen extends StatefulWidget {
  @override
  _BoutiqueNotificationsScreenState createState() => _BoutiqueNotificationsScreenState();
}

class _BoutiqueNotificationsScreenState extends State<BoutiqueNotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy • HH:mm');
  bool _isMarkingAll = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildNotificationList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        StreamBuilder<QuerySnapshot>(
          stream: _getNotificationsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();

            final unreadCount = snapshot.data!.docs
                .where((doc) => !(doc['read'] as bool))
                .length;

            return IconButton(
              icon: _isMarkingAll
                  ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                  : badges.Badge(
                showBadge: unreadCount > 0,
                badgeContent: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
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
            setState(() => _isLoading = true);
            await Future.delayed(const Duration(seconds: 1));
            setState(() => _isLoading = false);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => Divider(height: 1, indent: 72),
            itemBuilder: (context, index) => _NotificationItem(
              notification: notifications[index],
              dateFormat: _dateFormat,
              onTap: () => _handleNotificationTap(context, notifications[index]),
              onDismiss: (direction) => _dismissNotification(notifications[index]),
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
                      Container(
                        width: 200,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 12,
                        color: Colors.white,
                      ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/notifications_empty.png', width: 200, height: 200),
          const SizedBox(height: 20),
          Text('Aucune notification pour le moment', style: TextStyle(fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Vous serez notifié ici pour les nouvelles commandes, messages, rendez-vous et autres activités importantes',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A2D3E),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getNotificationsStream() {
    return _firestore
        .collection('notifications')
        .where('boutiqueId', isEqualTo: _auth.currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _handleNotificationTap(BuildContext context, DocumentSnapshot doc) async {
    final notification = doc.data() as Map<String, dynamic>;

    // Marquer comme lu si non lu
    if (!notification['read']) {
      await doc.reference.update({'read': true});
    }

    // Navigation selon le type de notification
    switch (notification['eventType']) {
      case 'order':
        if (notification['orderId'] != null) {
          final orderDoc = await _firestore.collection('orders').doc(notification['orderId']).get();
          if (orderDoc.exists) {
            final order = BoutiqueOrder.fromFirestore(orderDoc);
            Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailScreen(order: order)));
          }
        }
        break;

      case 'product':
        if (notification['productId'] != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: notification['productId'])));
        }
        break;

      case 'appointment':
        if (notification['appointmentId'] != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AppointmentDetailScreen(appointmentId: notification['appointmentId'])));
        }
        break;

      case 'message':
      // TODO: Implémenter la navigation vers l'écran de messages
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redirection vers les messages')),
        );
        break;

      default:
      // Pour les notifications système ou autres
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(notification['title']),
            content: Text(notification['message']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        break;
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() => _isMarkingAll = true);

    final batch = _firestore.batch();
    final notifications = await _getNotificationsStream().first;

    for (final doc in notifications.docs) {
      if (!doc['read']) {
        batch.update(doc.reference, {'read': true});
      }
    }

    await batch.commit();
    setState(() => _isMarkingAll = false);
  }

  Future<void> _dismissNotification(DocumentSnapshot doc) async {
    await doc.reference.delete();
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
    final isRead = data['read'] as bool;
    final time = dateFormat.format((data['createdAt'] as Timestamp).toDate());
    final eventType = data['eventType'] ?? 'system';

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
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                              color: isRead ? Colors.grey[800] : const Color(0xFF2A2D3E),
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
                      data['message'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
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

  Widget _buildNotificationIcon(BuildContext context, String eventType) {
    final icon = switch (eventType) {
      'order' => Icons.shopping_bag,
      'product' => Icons.shopping_cart,
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
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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

// Écrans fictifs pour la démonstration (à remplacer par vos vrais écrans)
class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({Key? key, required this.productId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails Produit')),
      body: Center(child: Text('Détails du produit $productId')),
    );
  }
}

class AppointmentDetailScreen extends StatelessWidget {
  final String appointmentId;

  const AppointmentDetailScreen({Key? key, required this.appointmentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails Rendez-vous')),
      body: Center(child: Text('Détails du rendez-vous $appointmentId')),
    );
  }
}