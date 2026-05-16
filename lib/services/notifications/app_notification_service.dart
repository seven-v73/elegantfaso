import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';

import '../../models/notifications/app_notification.dart';

class AppNotificationService {
  AppNotificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseMessaging? messaging,
    Logger? logger,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _messaging = messaging ?? FirebaseMessaging.instance,
       _logger = logger ?? Logger();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseMessaging _messaging;
  final Logger _logger;

  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AppNotification.fromDoc).toList());
  }

  Stream<int> watchUnreadCount(String userId) {
    if (userId.isEmpty) return Stream.value(0);
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .distinct();
  }

  Stream<Map<String, dynamic>> watchNotificationSettings(String userId) {
    if (userId.isEmpty) return Stream.value(_defaultSettings());
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      final data = doc.data() ?? const {};
      return _settingsFrom(data['notificationSettings']);
    });
  }

  Future<void> updateNotificationSettings(
    String userId, {
    required bool pushEnabled,
    required Map<String, bool> categories,
  }) {
    return _firestore.collection('users').doc(userId).set({
      'notificationSettings.pushEnabled': pushEnabled,
      'notificationSettings.categories': categories,
      'notificationSettings.updatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePushEnabled(String userId, bool enabled) {
    return _firestore.collection('users').doc(userId).set({
      'notificationSettings.pushEnabled': enabled,
      'notificationSettings.updatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePushCategory(
    String userId,
    String category,
    bool enabled,
  ) {
    if (!_defaultCategories().containsKey(category)) return Future.value();
    return _firestore.collection('users').doc(userId).set({
      'notificationSettings.categories.$category': enabled,
      'notificationSettings.updatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> createNotification({
    required String recipientId,
    required String title,
    required String body,
    String type = 'system',
    String priority = 'normal',
    String actionLabel = '',
    String? route,
    Map<String, dynamic> data = const {},
    DateTime? expiresAt,
    bool queuePush = true,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    final notificationRef = _firestore.collection('notifications').doc();
    final enrichedData = _standardizedData(type: type, data: data);
    final pushCategory = categoryForType(type);
    final shouldQueuePush =
        queuePush &&
        await _shouldQueuePush(
          recipientId: recipientId,
          type: type,
          priority: priority,
        );
    final payload = {
      'userId': recipientId,
      'recipientId': recipientId,
      'createdBy': currentUserId ?? 'system',
      'title': title,
      'body': body,
      'message': body,
      'type': type,
      'eventType': type,
      'priority': priority,
      'pushCategory': pushCategory,
      'actionLabel':
          actionLabel.isEmpty ? _defaultActionLabel(type) : actionLabel,
      'route': route ?? _defaultRouteFor(type),
      'data': enrichedData,
      'read': false,
      'isRead': false,
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = _firestore.batch()..set(notificationRef, payload);
    if (shouldQueuePush) {
      batch.set(_firestore.collection('notification_outbox').doc(), {
        'notificationId': notificationRef.id,
        'recipientId': recipientId,
        'createdBy': currentUserId ?? 'system',
        'title': title,
        'body': body,
        'type': type,
        'priority': priority,
        'pushCategory': pushCategory,
        'actionLabel':
            actionLabel.isEmpty ? _defaultActionLabel(type) : actionLabel,
        'route': route ?? _defaultRouteFor(type),
        'data': enrichedData,
        'status': 'queued',
        'attempts': 0,
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> notifyMessage({
    required String recipientId,
    required String senderName,
    required String preview,
    required String conversationId,
  }) {
    final body =
        preview.length > 120 ? '${preview.substring(0, 120)}...' : preview;
    return createNotification(
      recipientId: recipientId,
      title: 'Message de $senderName',
      body: body.isEmpty ? 'Vous avez reçu un nouveau message.' : body,
      type: 'message',
      priority: 'normal',
      actionLabel: 'Répondre',
      route: '/notifications',
      data: {
        'targetType': 'conversation',
        'targetId': conversationId,
        'conversationId': conversationId,
        'senderId': _auth.currentUser?.uid,
      },
    );
  }

  Future<void> notifyOrderStatus({
    required String recipientId,
    required String orderId,
    required String title,
    required String body,
    String status = '',
    String priority = 'high',
  }) {
    return createNotification(
      recipientId: recipientId,
      title: title,
      body: body,
      type: status.isEmpty ? 'order' : 'order_$status',
      priority: priority,
      actionLabel: 'Voir la commande',
      route: '/notifications',
      data: {
        'targetType': 'order',
        'targetId': orderId,
        'orderId': orderId,
        if (status.isNotEmpty) 'status': status,
      },
    );
  }

  Future<void> notifyWithdrawalStatus({
    required String recipientId,
    required String withdrawalId,
    required String title,
    required String body,
    String status = '',
    String priority = 'high',
  }) {
    return createNotification(
      recipientId: recipientId,
      title: title,
      body: body,
      type: status.isEmpty ? 'withdrawal' : 'withdrawal_$status',
      priority: priority,
      actionLabel: 'Voir le retrait',
      route: '/notifications',
      data: {
        'targetType': 'withdrawal',
        'targetId': withdrawalId,
        'withdrawalId': withdrawalId,
        if (status.isNotEmpty) 'status': status,
      },
    );
  }

  Future<void> notifySecondhandEvent({
    required String recipientId,
    required String listingId,
    required String title,
    required String body,
    String event = 'secondhand',
    String priority = 'normal',
  }) {
    return createNotification(
      recipientId: recipientId,
      title: title,
      body: body,
      type: event.startsWith('secondhand') ? event : 'secondhand_$event',
      priority: priority,
      actionLabel: 'Voir l’annonce',
      route: '/notifications',
      data: {
        'targetType': 'secondhand_listing',
        'targetId': listingId,
        'listingId': listingId,
      },
    );
  }

  Future<void> notifyProPlanDecision({
    required String recipientId,
    required String requestId,
    required String title,
    required String body,
    String type = 'pro_plan_approved',
  }) {
    return createNotification(
      recipientId: recipientId,
      title: title,
      body: body,
      type: type,
      priority: 'high',
      actionLabel: 'Voir mon espace Pro',
      route: '/notifications',
      data: {
        'targetType': 'pro_request',
        'targetId': requestId,
        'requestId': requestId,
      },
    );
  }

  Future<void> notifyProPlanExpiry({
    required String recipientId,
    required String planLabel,
    required DateTime expiresAt,
    bool expired = false,
  }) {
    final title = expired ? 'Forfait expiré' : 'Forfait bientôt expiré';
    final body =
        expired
            ? '$planLabel est terminé. Renouvelez pour retrouver vos avantages.'
            : '$planLabel se termine bientôt. Renouvelez pour garder vos avantages.';
    return createNotification(
      recipientId: recipientId,
      title: title,
      body: body,
      type: expired ? 'pro_plan_expired' : 'pro_plan_expiring',
      priority: expired ? 'high' : 'normal',
      actionLabel: 'Renouveler',
      route: '/notifications',
      expiresAt: expired ? null : expiresAt,
      data: {
        'targetType': 'pro_subscription',
        'targetId': recipientId,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'expired': expired,
      },
    );
  }

  Future<void> notifyAppointmentStatus({
    required String recipientId,
    required String appointmentId,
    required String title,
    required String body,
    String status = '',
    String priority = 'normal',
  }) {
    return createNotification(
      recipientId: recipientId,
      title: title,
      body: body,
      type: status.isEmpty ? 'appointment' : 'appointment_$status',
      priority: priority,
      actionLabel: 'Voir le RDV',
      route: '/notifications',
      data: {
        'targetType': 'appointment',
        'targetId': appointmentId,
        'appointmentId': appointmentId,
        if (status.isNotEmpty) 'status': status,
      },
    );
  }

  Future<void> notifyListingModeration({
    required String recipientId,
    required String itemId,
    required String title,
    required String body,
    String itemType = 'product',
    String status = '',
  }) {
    return createNotification(
      recipientId: recipientId,
      title: title,
      body: body,
      type: status.isEmpty ? '${itemType}_moderation' : '${itemType}_$status',
      priority: 'normal',
      actionLabel: itemType == 'creation' ? 'Voir création' : 'Voir produit',
      route: '/notifications',
      data: {
        'targetType': itemType,
        'targetId': itemId,
        'itemId': itemId,
        if (status.isNotEmpty) 'status': status,
      },
    );
  }

  Future<void> notifyCommunityReply({
    required String recipientId,
    required String questionId,
    required String title,
    required String body,
  }) {
    return createNotification(
      recipientId: recipientId,
      title: title,
      body: body,
      type: 'community_reply',
      priority: 'normal',
      actionLabel: 'Voir la réponse',
      route: '/notifications',
      data: {
        'targetType': 'community_question',
        'targetId': questionId,
        'questionId': questionId,
      },
    );
  }

  Future<void> notifyDailyStyleReminder({
    required String recipientId,
    String title = 'Votre quiz Style est prêt',
    String body =
        'Quelques questions rapides pour faire progresser votre parcours.',
  }) {
    return createNotification(
      recipientId: recipientId,
      title: title,
      body: body,
      type: 'quiz_daily_ready',
      priority: 'normal',
      actionLabel: 'Faire le quiz',
      route: '/notifications',
      data: const {'targetType': 'daily_quiz', 'targetId': 'today'},
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  Future<void> markAsRead(String notificationId) {
    return _firestore.collection('notifications').doc(notificationId).set({
      'read': true,
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllAsRead(String userId) async {
    if (userId.isEmpty) return;
    while (true) {
      final snapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('read', isEqualTo: false)
              .limit(100)
              .get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'read': true,
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      if (snapshot.docs.length < 100) return;
    }
  }

  Future<void> deleteNotification(String notificationId) {
    return _firestore.collection('notifications').doc(notificationId).delete();
  }

  Future<void> syncDeviceToken({String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      final safeTokenId = token.replaceAll('/', '_');
      final userRef = _firestore.collection('users').doc(uid);
      await userRef.set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'notificationSettings.updatedAt': FieldValue.serverTimestamp(),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await userRef.collection('devices').doc(safeTokenId).set({
        'token': token,
        'platform': 'mobile',
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, stack) {
      _logger.w(
        'Synchronisation du token notification impossible',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void bindTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      final uid = _auth.currentUser?.uid;
      if (uid == null || token.isEmpty) return;
      await syncDeviceToken(userId: uid);
    });
  }

  static Map<String, dynamic> _standardizedData({
    required String type,
    required Map<String, dynamic> data,
  }) {
    final normalized = <String, dynamic>{...data};
    normalized.putIfAbsent('targetType', () => _defaultTargetType(type));
    normalized.putIfAbsent(
      'targetId',
      () =>
          data['targetId'] ??
          data['orderId'] ??
          data['conversationId'] ??
          data['listingId'] ??
          data['requestId'] ??
          '',
    );
    return normalized;
  }

  Future<bool> _shouldQueuePush({
    required String recipientId,
    required String type,
    required String priority,
  }) async {
    try {
      final doc = await _firestore.collection('users').doc(recipientId).get();
      final settings = _settingsFrom(doc.data()?['notificationSettings']);
      if (settings['pushEnabled'] != true) return false;
      if (priority == 'urgent') return true;
      final categories = Map<String, bool>.from(
        settings['categories'] ?? _defaultCategories(),
      );
      return categories[categoryForType(type)] ?? true;
    } catch (_) {
      return true;
    }
  }

  static Map<String, dynamic> _settingsFrom(Object? value) {
    final raw = value is Map ? Map<String, dynamic>.from(value) : const {};
    return {
      'pushEnabled': raw['pushEnabled'] is bool ? raw['pushEnabled'] : true,
      'categories': {
        ..._defaultCategories(),
        if (raw['categories'] is Map)
          ...Map<String, dynamic>.from(
            raw['categories'],
          ).map((key, value) => MapEntry(key, value == true)),
      },
    };
  }

  static Map<String, dynamic> _defaultSettings() {
    return {'pushEnabled': true, 'categories': _defaultCategories()};
  }

  static Map<String, bool> _defaultCategories() {
    return const {
      'orders': true,
      'messages': true,
      'payments': true,
      'appointments': true,
      'style': true,
      'community': true,
      'pro': true,
      'system': true,
    };
  }

  static String categoryForType(String type) {
    if (type == 'message') return 'messages';
    if (type.contains('payment') ||
        type.contains('withdrawal') ||
        type.contains('payout')) {
      return 'payments';
    }
    if (type.contains('order')) return 'orders';
    if (type.contains('appointment') || type.contains('rdv')) {
      return 'appointments';
    }
    if (type.contains('quiz') ||
        type.contains('style') ||
        type.contains('badge') ||
        type.contains('measurement')) {
      return 'style';
    }
    if (type.contains('community') ||
        type.contains('reply') ||
        type.contains('mention') ||
        type.contains('secondhand')) {
      return 'community';
    }
    if (type.contains('pro') ||
        type.contains('boost') ||
        type.contains('subscription')) {
      return 'pro';
    }
    return 'system';
  }

  static String _defaultTargetType(String type) {
    if (type == 'message') return 'conversation';
    if (type.contains('order')) return 'order';
    if (type.contains('withdrawal') || type.contains('payout')) {
      return 'withdrawal';
    }
    if (type.contains('secondhand')) return 'secondhand_listing';
    if (type.contains('quiz')) return 'daily_quiz';
    if (type.contains('community')) return 'community';
    if (type.contains('pro') || type.contains('boost')) return 'pro_request';
    return 'general';
  }

  static String _defaultRouteFor(String type) {
    return switch (_defaultTargetType(type)) {
      'daily_quiz' => '/notifications',
      'conversation' => '/notifications',
      _ => '/notifications',
    };
  }

  static String _defaultActionLabel(String type) {
    return switch (_defaultTargetType(type)) {
      'conversation' => 'Répondre',
      'order' => 'Voir la commande',
      'withdrawal' => 'Voir le retrait',
      'secondhand_listing' => 'Voir l’annonce',
      'daily_quiz' => 'Faire le quiz',
      'community' => 'Voir la discussion',
      'pro_request' => 'Voir mon espace Pro',
      _ => 'Ouvrir',
    };
  }
}
