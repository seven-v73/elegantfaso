import 'package:elegantfaso/models/notifications/app_notification.dart';
import 'package:elegantfaso/services/notifications/app_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalise une notification métier avec priorité et cible', () {
    final notification = AppNotification.fromMap('n1', {
      'userId': 'client-1',
      'title': 'Retrait payé',
      'body': 'Votre retrait a été transféré.',
      'type': 'withdrawal_paid',
      'priority': 'high',
      'read': false,
      'data': {'targetType': 'withdrawal', 'targetId': 'w1'},
    });

    expect(notification.isImportant, isTrue);
    expect(notification.category, 'Paiements');
    expect(notification.targetType, 'withdrawal');
    expect(notification.targetId, 'w1');
    expect(notification.actionLabel, 'Voir le retrait');
  });

  test('classe les réponses communauté dans le centre attention', () {
    final notification = AppNotification.fromMap('n2', {
      'recipientId': 'client-1',
      'title': 'Nouvelle réponse',
      'body': 'Quelqu’un a répondu à votre question.',
      'type': 'community_reply',
      'isRead': true,
      'data': {'questionId': 'q1'},
    });

    expect(notification.category, 'Communauté');
    expect(notification.targetId, 'q1');
    expect(notification.actionLabel, 'Voir la réponse');
  });

  test('normalise les catégories push métier', () {
    expect(AppNotificationService.categoryForType('message'), 'messages');
    expect(AppNotificationService.categoryForType('order_preparing'), 'orders');
    expect(
      AppNotificationService.categoryForType('order_payment_confirmed'),
      'payments',
    );
    expect(
      AppNotificationService.categoryForType('withdrawal_paid'),
      'payments',
    );
    expect(
      AppNotificationService.categoryForType('secondhand_reserved'),
      'community',
    );
    expect(AppNotificationService.categoryForType('quiz_daily_ready'), 'style');
    expect(AppNotificationService.categoryForType('pro_plan_approved'), 'pro');
    expect(AppNotificationService.categoryForType('pro_plan_expired'), 'pro');
    expect(
      AppNotificationService.categoryForType('appointment_confirmed'),
      'appointments',
    );
  });

  test('classe les RDV et forfaits pro dans les bons filtres', () {
    final appointment = AppNotification.fromMap('n3', {
      'recipientId': 'client-1',
      'title': 'RDV confirmé',
      'body': 'Votre rendez-vous est confirmé.',
      'type': 'appointment_confirmed',
      'data': {'appointmentId': 'a1'},
    });
    final pro = AppNotification.fromMap('n4', {
      'recipientId': 'pro-1',
      'title': 'Forfait expiré',
      'body': 'Renouvelez votre forfait.',
      'type': 'pro_plan_expired',
      'data': {'targetId': 'pro-1'},
    });

    expect(appointment.category, 'RDV');
    expect(pro.category, 'Espace Pro');
  });
}
