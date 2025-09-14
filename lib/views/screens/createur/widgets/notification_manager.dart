import 'package:elegantfaso/views/screens/createur/widgets/sheet_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'empty_state.dart';

class NotificationItem {
  final String id;
  final IconData icon;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String type;
  final Color color;

  NotificationItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    Color? color,
  }) : color = color ?? _getColor(type);

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final type = data['type'] ?? '';
    return NotificationItem(
      id: doc.id,
      icon: _getIcon(type),
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      timestamp: _toDateTime(data['timestamp'])!,
      isRead: data['isRead'] ?? false,
      type: type,
      color: _getColor(type),
    );
  }

  static IconData _getIcon(String type) {
    switch (type) {
      case 'review': return Icons.star_rounded;
      case 'appointment': return Icons.calendar_today_rounded;
      case 'order': return Icons.shopping_bag_rounded;
      case 'message': return Icons.message_rounded;
      case 'like': return Icons.favorite_rounded;
      case 'follow': return Icons.person_add_rounded;
      case 'look_accepted': return Icons.check_circle_rounded;
      case 'look_rejected': return Icons.cancel_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  static Color _getColor(String type) {
    switch (type) {
      case 'review': return const Color(0xFFFF9500);
      case 'appointment': return const Color(0xFF007AFF);
      case 'order': return const Color(0xFF34C759);
      case 'message': return const Color(0xFF5856D6);
      case 'like': return const Color(0xFFFF3B30);
      case 'follow': return const Color(0xFF30D158);
      case 'look_accepted': return const Color(0xFF34C759);
      case 'look_rejected': return const Color(0xFFFF3B30);
      default: return const Color(0xFF4A6FA5);
    }
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) return 'À l\'instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
    if (difference.inDays == 1) return 'Hier';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays} j';
    return DateFormat('dd/MM/yyyy').format(timestamp);
  }
}

class NotificationManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference _getCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  static Future<void> markAllAsRead(List<NotificationItem> notifications, String userId) async {
    final batch = _firestore.batch();
    final collection = _getCollection(userId);

    for (var notification in notifications.where((n) => !n.isRead)) {
      batch.update(collection.doc(notification.id), {'isRead': true});
    }

    await batch.commit();
  }

  static Future<void> markAsRead(String notificationId, String userId) async {
    await _getCollection(userId).doc(notificationId).update({'isRead': true});
  }

  static Future<void> deleteNotification(String notificationId, String userId) async {
    await _getCollection(userId).doc(notificationId).delete();
  }

  static Stream<List<NotificationItem>> getNotificationsStream(String userId) {
    return _getCollection(userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => NotificationItem.fromFirestore(doc))
        .toList());
  }
}

class NotificationIcon extends StatefulWidget {
  const NotificationIcon({super.key});

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: NotificationManager._getCollection(user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        final unreadCount = snapshot.data?.docs.length ?? 0;

        // Déclencher l'animation quand de nouvelles notifications arrivent
        if (hasUnread && unreadCount > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _triggerAnimation();
          });
        }

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showNotifications(context, user.uid);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Badge(
                          isLabelVisible: hasUnread,
                          backgroundColor: const Color(0xFFE76F51),
                          label: unreadCount > 9
                              ? const Text('9+', style: TextStyle(fontSize: 10))
                              : Text('$unreadCount', style: const TextStyle(fontSize: 10)),
                          child: Icon(
                            hasUnread ? Icons.notifications_active : Icons.notifications_none,
                            size: 26,
                            color: hasUnread
                                ? const Color(0xFFE76F51)
                                : const Color(0xFF2D3436),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNotifications(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return NotificationPanel(userId: userId);
      },
    );
  }
}

class NotificationPanel extends StatefulWidget {
  final String userId;

  const NotificationPanel({super.key, required this.userId});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel>
    with TickerProviderStateMixin {
  late Stream<List<NotificationItem>> _notificationsStream;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _notificationsStream = NotificationManager.getNotificationsStream(widget.userId);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Démarrer les animations
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              const SheetHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3436),
                      ),
                    ),
                    _AnimatedButton(
                      text: 'Tout marquer comme lu',
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final notifications = await _notificationsStream.first;
                        await NotificationManager.markAllAsRead(notifications, widget.userId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Toutes les notifications ont été marquées comme lues'),
                              backgroundColor: const Color(0xFF34C759),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<NotificationItem>>(
                  stream: _notificationsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A6FA5)),
                        ),
                      );
                    }

                    final notifications = snapshot.data ?? [];

                    return notifications.isEmpty
                        ? const EmptyState(
                      icon: Icons.notifications_off,
                      message: 'Aucune notification',
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return AnimatedNotificationTile(
                          item: notifications[index],
                          userId: widget.userId,
                          index: index,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const _AnimatedButton({
    required this.text,
    required this.onPressed,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isPressed
                    ? const Color(0xFF4A6FA5).withOpacity(0.1)
                    : const Color(0xFF4A6FA5).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF4A6FA5).withOpacity(0.2),
                ),
              ),
              child: Text(
                widget.text,
                style: const TextStyle(
                  color: Color(0xFF4A6FA5),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedNotificationTile extends StatefulWidget {
  final NotificationItem item;
  final String userId;
  final int index;

  const AnimatedNotificationTile({
    super.key,
    required this.item,
    required this.userId,
    required this.index,
  });

  @override
  State<AnimatedNotificationTile> createState() => _AnimatedNotificationTileState();
}

class _AnimatedNotificationTileState extends State<AnimatedNotificationTile>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 400 + (widget.index * 50)),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Démarrer les animations avec un délai
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _slideController.forward();
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: Key(widget.item.id),
                  background: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.delete, color: Colors.white),
                        Icon(Icons.delete, color: Colors.white),
                      ],
                    ),
                  ),
                  onDismissed: (direction) {
                    HapticFeedback.mediumImpact();
                    NotificationManager.deleteNotification(widget.item.id, widget.userId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Notification supprimée'),
                        backgroundColor: const Color(0xFFFF3B30),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTapDown: (_) {
                      setState(() => _isPressed = true);
                      _scaleController.forward();
                      HapticFeedback.selectionClick();
                    },
                    onTapUp: (_) {
                      setState(() => _isPressed = false);
                      _scaleController.reverse();
                      if (!widget.item.isRead) {
                        NotificationManager.markAsRead(widget.item.id, widget.userId);
                      }
                    },
                    onTapCancel: () {
                      setState(() => _isPressed = false);
                      _scaleController.reverse();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.item.isRead
                            ? Colors.transparent
                            : widget.item.color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.item.isRead
                              ? Colors.grey.withOpacity(0.1)
                              : widget.item.color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNotificationIcon(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.item.title,
                                        style: TextStyle(
                                          fontWeight: widget.item.isRead
                                              ? FontWeight.w500
                                              : FontWeight.bold,
                                          color: const Color(0xFF2D3436),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (!widget.item.isRead)
                                      _buildUnreadIndicator(),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.item.message,
                                  style: TextStyle(
                                    color: const Color(0xFF2D3436).withOpacity(0.7),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 12,
                                      color: Colors.grey.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.item.formattedTime,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.withOpacity(0.6),
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.item.color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.item.color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Icon(
        widget.item.icon,
        size: 20,
        color: widget.item.color,
      ),
    );
  }

  Widget _buildUnreadIndicator() {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: widget.item.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.item.color.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}