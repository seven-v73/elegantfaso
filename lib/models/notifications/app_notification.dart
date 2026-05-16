import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../design/app_icons.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    this.priority = 'normal',
    this.actionLabel = '',
    this.route,
    this.data = const {},
    this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool read;
  final String priority;
  final String actionLabel;
  final String? route;
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppNotification.fromMap(doc.id, data);
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    final rawCreatedAt = data['createdAt'];
    final rawExpiresAt = data['expiresAt'];
    final nestedData = Map<String, dynamic>.from(data['data'] ?? const {});
    return AppNotification(
      id: id,
      userId:
          data['userId']?.toString() ??
          data['recipientId']?.toString() ??
          data['boutiqueId']?.toString() ??
          '',
      title: data['title']?.toString() ?? 'Notification',
      body:
          data['body']?.toString() ??
          data['message']?.toString() ??
          'Nouvelle activité sur ElegantStyle',
      type:
          data['type']?.toString() ?? data['eventType']?.toString() ?? 'system',
      read: _readValue(data),
      priority: data['priority']?.toString() ?? 'normal',
      actionLabel:
          data['actionLabel']?.toString().trim().isNotEmpty == true
              ? data['actionLabel'].toString().trim()
              : _fallbackActionLabel(
                data['type']?.toString() ?? '',
                nestedData,
              ),
      route: data['route']?.toString(),
      data: nestedData,
      createdAt: rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null,
      expiresAt: rawExpiresAt is Timestamp ? rawExpiresAt.toDate() : null,
    );
  }

  static bool _readValue(Map<String, dynamic> data) {
    final value = data['read'] ?? data['isRead'];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  String get targetType => data['targetType']?.toString() ?? '';
  String get targetId =>
      data['targetId']?.toString() ??
      data['orderId']?.toString() ??
      data['conversationId']?.toString() ??
      data['listingId']?.toString() ??
      data['productId']?.toString() ??
      data['questionId']?.toString() ??
      data['requestId']?.toString() ??
      '';
  bool get isImportant => priority == 'high' || priority == 'urgent';
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  String get category {
    if (type.contains('payment') ||
        type.contains('withdrawal') ||
        type.contains('payout')) {
      return 'Paiements';
    }
    if (type.contains('order')) return 'Commandes';
    if (type == 'message') {
      return 'Messages';
    }
    if (type.contains('appointment') || type.contains('rdv')) {
      return 'RDV';
    }
    if (type.contains('quiz') ||
        type.contains('style') ||
        type.contains('badge') ||
        type.contains('measurement')) {
      return 'Style';
    }
    if (type.contains('community') ||
        type.contains('reply') ||
        type.contains('mention') ||
        type.contains('secondhand')) {
      return 'Communauté';
    }
    if (type.contains('pro') || type.contains('boost')) return 'Espace Pro';
    return 'Tout';
  }

  IconData get icon {
    return switch (type) {
      'message' => AppIcons.messages,
      'order' => AppIcons.orders,
      'appointment' => AppIcons.appointments,
      'payment' => AppIcons.revenue,
      'boost' => AppIcons.stats,
      'coupon' => AppIcons.coupons,
      'salon' => AppIcons.salon,
      'secondhand_reserved' ||
      'secondhand_sold' ||
      'secondhand_withdrawal_available' => Icons.recycling_rounded,
      'withdrawal_paid' || 'withdrawal_blocked' => Icons.payments_rounded,
      'quiz_daily_ready' => Icons.quiz_rounded,
      'community_reply' => Icons.forum_rounded,
      _ => AppIcons.notifications,
    };
  }

  static String _fallbackActionLabel(String type, Map<String, dynamic> data) {
    return switch (type) {
      'message' => 'Répondre',
      'order' ||
      'order_payment_confirmed' ||
      'order_received_required' => 'Voir la commande',
      'payment' || 'payment_rejected' => 'Voir le paiement',
      'withdrawal_paid' || 'withdrawal_blocked' => 'Voir le retrait',
      'secondhand_reserved' ||
      'secondhand_sold' ||
      'secondhand_withdrawal_available' => 'Voir l’annonce',
      'pro_plan_approved' || 'boost_approved' => 'Voir mon espace Pro',
      'quiz_daily_ready' => 'Faire le quiz',
      'community_reply' => 'Voir la réponse',
      'profile_payment_missing' => 'Configurer',
      _ =>
        data['actionLabel']?.toString().trim().isNotEmpty == true
            ? data['actionLabel'].toString().trim()
            : 'Ouvrir',
    };
  }
}
