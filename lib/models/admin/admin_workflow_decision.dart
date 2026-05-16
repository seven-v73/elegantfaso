import 'package:cloud_firestore/cloud_firestore.dart';

import '../commerce/managed_payment.dart';

class AdminWorkflowDecision {
  const AdminWorkflowDecision._();

  static Map<String, dynamic> moderationPatch({
    required Map<String, dynamic> fields,
    required String action,
    required String note,
    required String? adminId,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      ...fields,
      'moderation': {
        'status': fields['status'] ?? action,
        'action': action,
        'note': note,
        'reviewedBy': adminId,
        'reviewedAt': timestamp,
      },
      'moderationStatus': fields['status'] ?? action,
      'updatedAt': timestamp,
    };
  }

  static Map<String, dynamic> orderPaymentPatch({
    required String decision,
    required String orderStatus,
    required String note,
    required String? adminId,
    double? sellerAmount,
    String currency = 'XOF',
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    final timelineLabel = switch (decision) {
      'paid' => 'Paiement validé par l’admin',
      'payment_rejected' => 'Paiement refusé par l’admin',
      'dispute' => 'Litige ouvert par l’admin',
      _ => 'Décision paiement admin',
    };
    final timelineStatus = switch (decision) {
      'paid' => ManagedPaymentValues.statusId(
        ManagedPaymentStatus.paymentConfirmedByAdmin,
      ),
      'payment_rejected' => ManagedPaymentValues.statusId(
        ManagedPaymentStatus.refundedOrCancelled,
      ),
      'dispute' => ManagedPaymentValues.statusId(ManagedPaymentStatus.disputed),
      _ => decision,
    };
    return {
      'paymentStatus': decision,
      'status': orderStatus,
      'orderStatus': orderStatus,
      if (decision == 'paid')
        ...SellerBalanceLedger.afterAdminPaymentConfirmed(
          sellerAmount: sellerAmount ?? 0,
          currency: currency,
          now: timestamp,
        ),
      if (decision == 'paid')
        ...InventoryFlowLedger.deductionPending(now: timestamp),
      if (decision == 'payment_rejected')
        'managedPaymentStatus': ManagedPaymentValues.statusId(
          ManagedPaymentStatus.refundedOrCancelled,
        ),
      if (decision == 'payment_rejected')
        'inventoryFlowStatus': ManagedPaymentValues.inventoryFlowStatusId(
          InventoryFlowStatus.released,
        ),
      if (decision == 'dispute')
        'managedPaymentStatus': ManagedPaymentValues.statusId(
          ManagedPaymentStatus.disputed,
        ),
      if (decision == 'dispute')
        'inventoryFlowStatus': ManagedPaymentValues.inventoryFlowStatusId(
          InventoryFlowStatus.disputed,
        ),
      if (decision == 'dispute')
        'sellerBalanceStatus': ManagedPaymentValues.balanceStatusId(
          SellerBalanceStatus.disputed,
        ),
      'paymentReview': {
        'decision': decision,
        'note': note,
        'reviewedBy': adminId,
        'reviewedAt': timestamp,
      },
      if (decision == 'paid') 'paidAt': timestamp,
      'paymentTimeline': FieldValue.arrayUnion([
        {
          'status': timelineStatus,
          'label': timelineLabel,
          'at': Timestamp.now(),
        },
      ]),
      'updatedAt': timestamp,
    };
  }

  static Map<String, dynamic> commissionPaymentPatch({
    required String decision,
    required String orderStatus,
    required String note,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'paymentStatus': decision,
      'orderStatus': orderStatus,
      if (decision == 'paid') 'status': 'pending_settlement',
      if (decision == 'payment_rejected') 'status': 'payment_rejected',
      if (decision == 'dispute') 'status': 'dispute',
      'paymentReviewNote': note,
      'updatedAt': timestamp,
    };
  }

  static Map<String, dynamic> payoutCommissionPatch({
    required String decision,
    required String note,
    required String? adminId,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'status': decision,
      'payoutStatus': decision,
      'payoutReview': {
        'decision': decision,
        'note': note,
        'reviewedBy': adminId,
        'reviewedAt': timestamp,
      },
      if (decision == 'settled') 'settledAt': timestamp,
      if (decision == 'blocked') 'blockedAt': timestamp,
      'updatedAt': timestamp,
    };
  }

  static Map<String, dynamic> sellerPayoutPatch({
    required String commissionId,
    required String orderId,
    required String sellerId,
    required double amount,
    required String decision,
    required String note,
    required String? adminId,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'commissionId': commissionId,
      'orderId': orderId,
      'sellerId': sellerId,
      'amount': amount,
      'status': decision,
      'note': note,
      'reviewedBy': adminId,
      if (decision == 'settled') 'paidAt': timestamp,
      if (decision == 'blocked') 'blockedAt': timestamp,
      'updatedAt': timestamp,
      'createdAt': timestamp,
    };
  }

  static Map<String, dynamic> withdrawalRequestPatch({
    required String decision,
    required String note,
    required String? adminId,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'status': decision,
      'review': {
        'decision': decision,
        'note': note,
        'reviewedBy': adminId,
        'reviewedAt': timestamp,
      },
      if (decision == 'settled') 'settledAt': timestamp,
      if (decision == 'blocked') 'blockedAt': timestamp,
      'updatedAt': timestamp,
    };
  }

  static Map<String, dynamic> orderWithdrawalPatch({
    required String decision,
    required double sellerAmount,
    required String currency,
    required String note,
    required String? adminId,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    final balancePatch =
        decision == 'settled'
            ? SellerBalanceLedger.afterWithdrawalSettled(
              sellerAmount: sellerAmount,
              currency: currency,
              now: timestamp,
            )
            : SellerBalanceLedger.afterWithdrawalBlocked(
              sellerAmount: sellerAmount,
              currency: currency,
              now: timestamp,
            );
    return {
      ...balancePatch,
      'withdrawalReview': {
        'decision': decision,
        'note': note,
        'reviewedBy': adminId,
        'reviewedAt': timestamp,
      },
      'paymentTimeline': FieldValue.arrayUnion([
        {
          'status': decision == 'settled' ? 'withdrawn' : 'withdrawal_blocked',
          'label':
              decision == 'settled'
                  ? 'Retrait payé par l’admin'
                  : 'Retrait bloqué par l’admin',
          'at': Timestamp.now(),
        },
      ]),
      'status': decision == 'settled' ? 'completed' : 'disputed',
      'orderStatus': decision == 'settled' ? 'completed' : 'disputed',
      'updatedAt': timestamp,
    };
  }

  static Map<String, dynamic> planEntitlementPatch({
    required String plan,
    required List<String> rolesApplied,
    required Timestamp startsAt,
    required Timestamp expiresAt,
    int durationDays = 30,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'businessEntitlements': {
        'plan': plan,
        'status': 'active',
        'rolesApplied': rolesApplied,
        'sharedAcrossRoles': true,
        'verifiedBadge': true,
        'certificationBadge': plan == 'premium' ? 'signature' : 'pro',
        'startedAt': startsAt,
        'expiresAt': expiresAt,
        'durationDays': durationDays,
        'updatedAt': timestamp,
      },
      'certifiedProfessional': true,
      'certificationBadge': plan == 'premium' ? 'signature' : 'pro',
      'professionalPlan': plan,
      'professionalPlanStartedAt': startsAt,
      'professionalPlanExpiresAt': expiresAt,
      'updatedAt': timestamp,
    };
  }

  static Map<String, dynamic> boostEntitlementPatch({
    required String campaignId,
    required List<String> rolesApplied,
    required Timestamp startsAt,
    required Timestamp endsAt,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'businessEntitlements': {
        'boost': {
          'status': 'active',
          'campaignId': campaignId,
          'rolesApplied': rolesApplied,
          'sharedAcrossRoles': true,
          'startsAt': startsAt,
          'endsAt': endsAt,
          'updatedAt': timestamp,
        },
      },
      'updatedAt': timestamp,
    };
  }
}
