import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegantfaso/models/admin/admin_workflow_decision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const now = 'now';

  group('AdminWorkflowDecision', () {
    test('prépare une décision de modération avec note admin', () {
      final patch = AdminWorkflowDecision.moderationPatch(
        fields: const {'status': 'hidden', 'isPublic': false},
        action: 'hidden',
        note: 'Image non conforme',
        adminId: 'admin_1',
        now: now,
      );

      expect(patch['status'], 'hidden');
      expect(patch['isPublic'], isFalse);
      expect(patch['moderationStatus'], 'hidden');
      expect(patch['updatedAt'], now);
      expect(patch['moderation'], {
        'status': 'hidden',
        'action': 'hidden',
        'note': 'Image non conforme',
        'reviewedBy': 'admin_1',
        'reviewedAt': now,
      });
    });

    test('valide un paiement et prépare la commission à reverser', () {
      final orderPatch = AdminWorkflowDecision.orderPaymentPatch(
        decision: 'paid',
        orderStatus: 'pending_seller_confirmation',
        note: 'Preuve correcte',
        adminId: 'admin_1',
        sellerAmount: 18400,
        currency: 'XOF',
        now: now,
      );
      final commissionPatch = AdminWorkflowDecision.commissionPaymentPatch(
        decision: 'paid',
        orderStatus: 'pending_seller_confirmation',
        note: 'Preuve correcte',
        now: now,
      );

      expect(orderPatch['paymentStatus'], 'paid');
      expect(orderPatch['orderStatus'], 'pending_seller_confirmation');
      expect(orderPatch['paidAt'], now);
      expect(orderPatch['managedPaymentStatus'], 'payment_confirmed_by_admin');
      expect(orderPatch['sellerBalanceStatus'], 'pending_delivery');
      expect(orderPatch['sellerBalance']['pendingBalance'], 18400);
      expect(orderPatch['sellerBalance']['availableBalance'], 0);
      expect(orderPatch['inventoryFlowStatus'], 'deduction_pending');
      expect(orderPatch['inventoryDeducted'], isFalse);
      expect(orderPatch['paymentReview']['reviewedBy'], 'admin_1');
      expect(orderPatch.containsKey('paymentTimeline'), isTrue);
      expect(commissionPatch['status'], 'pending_settlement');
      expect(commissionPatch['paymentStatus'], 'paid');
    });

    test('refuse un paiement sans marquer paidAt', () {
      final patch = AdminWorkflowDecision.orderPaymentPatch(
        decision: 'payment_rejected',
        orderStatus: 'payment_rejected',
        note: 'Montant illisible',
        adminId: 'admin_1',
        now: now,
      );

      expect(patch['paymentStatus'], 'payment_rejected');
      expect(patch.containsKey('paidAt'), isFalse);
      expect(patch['inventoryFlowStatus'], 'released');
      expect(patch['paymentReview']['note'], 'Montant illisible');
    });

    test('crée un payout vendeur réglé avec historique', () {
      final commissionPatch = AdminWorkflowDecision.payoutCommissionPatch(
        decision: 'settled',
        note: 'Virement effectué',
        adminId: 'admin_1',
        now: now,
      );
      final payoutPatch = AdminWorkflowDecision.sellerPayoutPatch(
        commissionId: 'commission_1',
        orderId: 'order_1',
        sellerId: 'seller_1',
        amount: 18400,
        decision: 'settled',
        note: 'Virement effectué',
        adminId: 'admin_1',
        now: now,
      );

      expect(commissionPatch['status'], 'settled');
      expect(commissionPatch['payoutStatus'], 'settled');
      expect(commissionPatch['settledAt'], now);
      expect(payoutPatch['amount'], 18400);
      expect(payoutPatch['paidAt'], now);
      expect(payoutPatch['reviewedBy'], 'admin_1');
    });

    test('bloque un payout sans paidAt', () {
      final payoutPatch = AdminWorkflowDecision.sellerPayoutPatch(
        commissionId: 'commission_1',
        orderId: 'order_1',
        sellerId: 'seller_1',
        amount: 18400,
        decision: 'blocked',
        note: 'Litige client',
        adminId: 'admin_1',
        now: now,
      );

      expect(payoutPatch['status'], 'blocked');
      expect(payoutPatch['blockedAt'], now);
      expect(payoutPatch.containsKey('paidAt'), isFalse);
    });

    test('active un plan premium partagé entre rôles pro', () {
      final startsAt = Timestamp.fromDate(DateTime(2026));
      final expiresAt = Timestamp.fromDate(DateTime(2026, 2));
      final patch = AdminWorkflowDecision.planEntitlementPatch(
        plan: 'premium',
        rolesApplied: const ['createur', 'boutique'],
        startsAt: startsAt,
        expiresAt: expiresAt,
        now: now,
      );
      final entitlement = patch['businessEntitlements'];

      expect(entitlement['plan'], 'premium');
      expect(entitlement['verifiedBadge'], isTrue);
      expect(entitlement['sharedAcrossRoles'], isTrue);
      expect(entitlement['rolesApplied'], ['createur', 'boutique']);
      expect(entitlement['startedAt'], startsAt);
      expect(entitlement['expiresAt'], expiresAt);
    });

    test('active un boost partagé avec période', () {
      final startsAt = Timestamp.fromDate(DateTime(2026));
      final endsAt = Timestamp.fromDate(DateTime(2026, 1, 8));
      final patch = AdminWorkflowDecision.boostEntitlementPatch(
        campaignId: 'boost_1',
        rolesApplied: const ['createur', 'boutique'],
        startsAt: startsAt,
        endsAt: endsAt,
        now: now,
      );
      final boost = patch['businessEntitlements']['boost'];

      expect(boost['status'], 'active');
      expect(boost['campaignId'], 'boost_1');
      expect(boost['startsAt'], startsAt);
      expect(boost['endsAt'], endsAt);
      expect(boost['sharedAcrossRoles'], isTrue);
    });
  });
}
