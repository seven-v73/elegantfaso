import 'package:cloud_firestore/cloud_firestore.dart';

enum ManagedPaymentStatus {
  awaitingAdminPayment,
  clientMarkedPaid,
  paymentConfirmedByAdmin,
  preparing,
  readyOrShipped,
  deliveredBySeller,
  receivedByCustomer,
  withdrawalAvailable,
  withdrawalRequested,
  completed,
  disputed,
  refundedOrCancelled,
}

enum SellerBalanceStatus {
  notFunded,
  pendingDelivery,
  partiallyAdvanced,
  available,
  withdrawalRequested,
  withdrawn,
  disputed,
}

enum SellerTrustTier { newSeller, verified, signatureReliable, customOrder }

enum DeliveryQuoteStatus { notRequired, estimated, confirmed, disputed }

enum InventoryFlowStatus {
  awaitingPayment,
  deductionPending,
  reserved,
  deducted,
  released,
  disputed,
}

class ManagedPaymentValues {
  const ManagedPaymentValues._();

  static const paymentFlow = 'admin_managed_payment';
  static const paymentRecipient = 'platform_admin';
  static const deliveryModePickup = 'Retrait';
  static const deliveryModeDelivery = 'Livraison';

  static const awaitingAdminPaymentConfirmation =
      'awaiting_admin_payment_confirmation';
  static const paymentConfirmedByAdmin = 'payment_confirmed_by_admin';
  static const clientMarkedPaid = 'client_marked_paid';
  static const ready = 'ready';
  static const delivered = 'delivered';
  static const receivedByCustomer = 'received_by_customer';

  static String statusId(ManagedPaymentStatus status) {
    return switch (status) {
      ManagedPaymentStatus.awaitingAdminPayment => 'awaiting_admin_payment',
      ManagedPaymentStatus.clientMarkedPaid => 'client_marked_paid',
      ManagedPaymentStatus.paymentConfirmedByAdmin =>
        'payment_confirmed_by_admin',
      ManagedPaymentStatus.preparing => 'preparing',
      ManagedPaymentStatus.readyOrShipped => 'ready_or_shipped',
      ManagedPaymentStatus.deliveredBySeller => 'delivered_by_seller',
      ManagedPaymentStatus.receivedByCustomer => 'received_by_customer',
      ManagedPaymentStatus.withdrawalAvailable => 'withdrawal_available',
      ManagedPaymentStatus.withdrawalRequested => 'withdrawal_requested',
      ManagedPaymentStatus.completed => 'completed',
      ManagedPaymentStatus.disputed => 'disputed',
      ManagedPaymentStatus.refundedOrCancelled => 'refunded_or_cancelled',
    };
  }

  static String balanceStatusId(SellerBalanceStatus status) {
    return switch (status) {
      SellerBalanceStatus.notFunded => 'not_funded',
      SellerBalanceStatus.pendingDelivery => 'pending_delivery',
      SellerBalanceStatus.partiallyAdvanced => 'partially_advanced',
      SellerBalanceStatus.available => 'available',
      SellerBalanceStatus.withdrawalRequested => 'withdrawal_requested',
      SellerBalanceStatus.withdrawn => 'withdrawn',
      SellerBalanceStatus.disputed => 'disputed',
    };
  }

  static String deliveryQuoteStatusId(DeliveryQuoteStatus status) {
    return switch (status) {
      DeliveryQuoteStatus.notRequired => 'not_required',
      DeliveryQuoteStatus.estimated => 'estimated',
      DeliveryQuoteStatus.confirmed => 'confirmed',
      DeliveryQuoteStatus.disputed => 'disputed',
    };
  }

  static String inventoryFlowStatusId(InventoryFlowStatus status) {
    return switch (status) {
      InventoryFlowStatus.awaitingPayment => 'awaiting_payment',
      InventoryFlowStatus.deductionPending => 'deduction_pending',
      InventoryFlowStatus.reserved => 'reserved',
      InventoryFlowStatus.deducted => 'deducted',
      InventoryFlowStatus.released => 'released',
      InventoryFlowStatus.disputed => 'disputed',
    };
  }

  static bool isPickupMode(String deliveryMode) {
    final value = deliveryMode.trim().toLowerCase();
    return value == deliveryModePickup.toLowerCase() ||
        value.contains('retrait') ||
        value.contains('sur place');
  }

  static bool paymentIsConfirmed(String paymentStatus) {
    final value = paymentStatus.trim();
    return value == 'paid' || value == paymentConfirmedByAdmin;
  }

  static bool sellerCanProgressOrder(String status) {
    return const {
      'confirmed',
      'processing',
      'preparing',
      ready,
      delivered,
    }.contains(status);
  }

  static bool clientCanConfirmReceipt(String status) {
    return const {
      ready,
      delivered,
      'ready_or_shipped',
      'delivered_by_seller',
      receivedByCustomer,
      'withdrawal_available',
    }.contains(status);
  }
}

class ManagedPaymentCopy {
  const ManagedPaymentCopy._();

  static String orderStatusLabel(String status) {
    return switch (status) {
      'awaiting_admin_payment_confirmation' ||
      'awaiting_admin_payment' ||
      'client_marked_paid' => 'Paiement en vérification',
      'pending_seller_confirmation' || 'pending' => 'Nouvelle commande',
      'payment_confirmed_by_admin' || 'confirmed' => 'Paiement validé',
      'processing' || 'preparing' => 'Préparation',
      'ready' || 'ready_or_shipped' => 'Prête ou envoyée',
      'delivered' || 'delivered_by_seller' => 'Livraison déclarée',
      'received_by_customer' => 'Réception confirmée',
      'withdrawal_available' => 'Retrait disponible',
      'withdrawal_requested' => 'Retrait demandé',
      'completed' => 'Terminée',
      'payment_rejected' => 'Paiement refusé',
      'cancelled' || 'refunded_or_cancelled' => 'Annulée',
      'dispute' || 'disputed' => 'Litige ouvert',
      _ => status.isEmpty ? 'Suivi en cours' : status,
    };
  }

  static String paymentStatusLabel(String status) {
    return switch (status) {
      'pending' || 'pending_payment' => 'Paiement attendu',
      'proof_submitted' || 'client_marked_paid' => 'Preuve envoyée',
      'paid' || 'payment_confirmed_by_admin' => 'Paiement validé',
      'payment_rejected' || 'rejected' => 'Paiement refusé',
      'dispute' || 'disputed' => 'Paiement en litige',
      _ => status.isEmpty ? 'Paiement à suivre' : status,
    };
  }

  static String sellerBalanceLabel(String status) {
    return switch (status) {
      'not_funded' => 'Paiement admin attendu',
      'pending_delivery' => 'Solde en attente livraison',
      'partially_advanced' => 'Avance versée',
      'available' => 'Retrait disponible',
      'withdrawal_requested' => 'Retrait demandé',
      'withdrawn' => 'Retrait payé',
      'disputed' => 'Solde bloqué',
      _ => status.isEmpty ? 'Solde à suivre' : status,
    };
  }

  static String clientActionHint(String status) {
    return switch (status) {
      'client_marked_paid' ||
      'awaiting_admin_payment_confirmation' ||
      'awaiting_admin_payment' =>
        'L’admin vérifie la preuve de paiement avant de libérer la commande.',
      'payment_confirmed_by_admin' ||
      'confirmed' => 'Le vendeur peut préparer la commande.',
      'preparing' || 'processing' => 'Le vendeur prépare votre article.',
      'ready' || 'ready_or_shipped' =>
        'Votre commande est prête ou en cours de livraison.',
      'delivered_by_seller' =>
        'Confirmez seulement après réception réelle du produit.',
      'received_by_customer' || 'withdrawal_available' =>
        'Réception confirmée. Vous pouvez laisser un avis après usage.',
      'withdrawal_requested' ||
      'completed' => 'La transaction est finalisée côté suivi.',
      'payment_rejected' =>
        'La preuve n’a pas été validée. Contactez le support si besoin.',
      'dispute' ||
      'disputed' => 'Un litige bloque la transaction pendant vérification.',
      _ => 'Le suivi se met à jour à chaque étape.',
    };
  }

  static String sellerActionHint({
    required String orderStatus,
    required String balanceStatus,
  }) {
    if (balanceStatus == 'available') {
      return 'Le client a confirmé la réception. Vous pouvez demander le retrait.';
    }
    if (balanceStatus == 'withdrawal_requested') {
      return 'Votre demande de retrait est en vérification admin.';
    }
    if (balanceStatus == 'withdrawn') {
      return 'Le retrait a été marqué comme payé par l’admin.';
    }
    if (balanceStatus == 'disputed') {
      return 'Le solde est bloqué pendant le traitement du litige.';
    }
    if (balanceStatus == 'pending_delivery') {
      return 'Disponible après réception client.';
    }
    return switch (orderStatus) {
      'awaiting_admin_payment_confirmation' =>
        'Attendez la validation admin avant de préparer.',
      'confirmed' || 'payment_confirmed_by_admin' =>
        'Paiement validé. Confirmez la préparation quand vous commencez.',
      'processing' ||
      'preparing' => 'Préparez la commande puis marquez-la prête.',
      'ready' || 'ready_or_shipped' =>
        'Marquez livrée uniquement après remise ou expédition.',
      'delivered' || 'delivered_by_seller' =>
        'En attente de confirmation de réception par le client.',
      _ => 'Suivez la prochaine action affichée sur la commande.',
    };
  }
}

class ManagedPaymentTimelineEntry {
  const ManagedPaymentTimelineEntry({
    required this.status,
    required this.label,
    this.at,
  });

  final String status;
  final String label;
  final DateTime? at;

  factory ManagedPaymentTimelineEntry.fromMap(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? '';
    final rawAt = data['at'];
    return ManagedPaymentTimelineEntry(
      status: status,
      label:
          data['label']?.toString().trim().isNotEmpty == true
              ? data['label'].toString().trim()
              : ManagedPaymentCopy.orderStatusLabel(status),
      at:
          rawAt is Timestamp
              ? rawAt.toDate()
              : rawAt is DateTime
              ? rawAt
              : null,
    );
  }

  static List<ManagedPaymentTimelineEntry> listFrom(Object? value) {
    if (value is! Iterable) return const [];
    final entries =
        value
            .whereType<Map>()
            .map(
              (entry) => ManagedPaymentTimelineEntry.fromMap(
                Map<String, dynamic>.from(entry),
              ),
            )
            .toList();
    entries.sort((a, b) {
      final aDate = a.at ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.at ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });
    return entries;
  }
}

class DeliveryQuoteLedger {
  const DeliveryQuoteLedger._();

  static Map<String, dynamic> initial({
    required String deliveryMode,
    required double amount,
    required String currency,
    required String addressOrInstruction,
    required String note,
    Object? now,
  }) {
    final pickup = ManagedPaymentValues.isPickupMode(deliveryMode);
    final status =
        pickup
            ? DeliveryQuoteStatus.notRequired
            : DeliveryQuoteStatus.estimated;
    final source = pickup ? 'pickup' : 'checkout_dynamic_estimate';
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'deliveryFee': pickup ? 0.0 : amount,
      'deliveryFeeSource': source,
      'deliveryQuoteStatus': ManagedPaymentValues.deliveryQuoteStatusId(status),
      'deliveryQuote': {
        'mode': pickup ? ManagedPaymentValues.deliveryModePickup : deliveryMode,
        'amount': pickup ? 0.0 : amount,
        'currency': currency,
        'source': source,
        'status': ManagedPaymentValues.deliveryQuoteStatusId(status),
        'addressOrInstruction': addressOrInstruction,
        'note': note,
        'requiresSellerOrAdminConfirmation': !pickup,
        'confirmedAtCheckout': pickup,
        'updatedAt': timestamp,
      },
    };
  }

  static String statusLabel(String status) {
    return switch (status) {
      'not_required' => 'Retrait sur place',
      'estimated' => 'Frais estimés',
      'confirmed' => 'Frais confirmés',
      'disputed' => 'Frais à vérifier',
      _ => status.isEmpty ? 'Livraison à suivre' : status,
    };
  }

  static String clientHint(String status) {
    return switch (status) {
      'estimated' =>
        'Les frais sont une estimation. L’admin vérifie le total avec votre preuve.',
      'confirmed' => 'Le total de livraison a été confirmé.',
      'not_required' => 'Aucun frais de livraison pour un retrait sur place.',
      'disputed' => 'Le montant de livraison doit être vérifié.',
      _ => 'La livraison sera suivie avec la commande.',
    };
  }
}

class InventoryFlowLedger {
  const InventoryFlowLedger._();

  static Map<String, dynamic> awaitingPayment() {
    return {
      'inventoryFlowStatus': ManagedPaymentValues.inventoryFlowStatusId(
        InventoryFlowStatus.awaitingPayment,
      ),
      'inventoryPolicy': 'deduct_after_delivery_or_receipt',
      'inventoryReserved': false,
      'inventoryDeducted': false,
    };
  }

  static Map<String, dynamic> deductionPending({Object? now}) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'inventoryFlowStatus': ManagedPaymentValues.inventoryFlowStatusId(
        InventoryFlowStatus.deductionPending,
      ),
      'inventoryReserved': false,
      'inventoryDeducted': false,
      'inventoryPolicy': 'deduct_after_delivery_or_receipt',
      'inventoryFlowUpdatedAt': timestamp,
    };
  }

  static Map<String, dynamic> reserved({
    required List<Map<String, dynamic>> items,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'inventoryFlowStatus': ManagedPaymentValues.inventoryFlowStatusId(
        InventoryFlowStatus.reserved,
      ),
      'inventoryReserved': true,
      'inventoryReservedAt': timestamp,
      'inventoryReservedItems': items,
      'inventoryDeducted': false,
      'inventoryPolicy': 'reserved_after_admin_payment',
      'inventoryFlowUpdatedAt': timestamp,
    };
  }

  static Map<String, dynamic> deducted({
    required List<Map<String, dynamic>> items,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'inventoryFlowStatus': ManagedPaymentValues.inventoryFlowStatusId(
        InventoryFlowStatus.deducted,
      ),
      'inventoryReserved': false,
      'inventoryDeducted': true,
      'inventoryDeductedAt': timestamp,
      'inventoryDeductedItems': items,
      'inventoryFlowUpdatedAt': timestamp,
    };
  }

  static Map<String, dynamic> released({Object? now}) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'inventoryFlowStatus': ManagedPaymentValues.inventoryFlowStatusId(
        InventoryFlowStatus.released,
      ),
      'inventoryReserved': false,
      'inventoryReleasedAt': timestamp,
      'inventoryFlowUpdatedAt': timestamp,
    };
  }

  static String statusLabel(String status) {
    return switch (status) {
      'awaiting_payment' => 'Stock non engagé',
      'deduction_pending' => 'Stock à décrémenter',
      'reserved' => 'Stock réservé',
      'deducted' => 'Stock décrémenté',
      'released' => 'Stock libéré',
      'disputed' => 'Stock bloqué',
      _ => status.isEmpty ? 'Stock à suivre' : status,
    };
  }
}

class SellerAdvancePolicy {
  const SellerAdvancePolicy._();

  static double maxAdvancePercent(SellerTrustTier tier) {
    return switch (tier) {
      SellerTrustTier.newSeller => 0,
      SellerTrustTier.verified => 30,
      SellerTrustTier.signatureReliable => 50,
      SellerTrustTier.customOrder => 50,
    };
  }

  static double maxAdvanceAmount({
    required double sellerAmount,
    required SellerTrustTier tier,
  }) {
    final safeAmount = sellerAmount.clamp(0, double.infinity).toDouble();
    return (safeAmount * maxAdvancePercent(tier) / 100).roundToDouble();
  }
}

class SellerBalanceLedger {
  const SellerBalanceLedger._();

  static Map<String, dynamic> initial({
    required double sellerAmount,
    required String currency,
  }) {
    return {
      'pendingBalance': 0.0,
      'availableBalance': 0.0,
      'withdrawnBalance': 0.0,
      'disputedBalance': 0.0,
      'expectedSellerAmount': sellerAmount,
      'currency': currency,
      'status': ManagedPaymentValues.balanceStatusId(
        SellerBalanceStatus.notFunded,
      ),
    };
  }

  static Map<String, dynamic> afterAdminPaymentConfirmed({
    required double sellerAmount,
    required String currency,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'sellerBalance': {
        'pendingBalance': sellerAmount,
        'availableBalance': 0.0,
        'withdrawnBalance': 0.0,
        'disputedBalance': 0.0,
        'expectedSellerAmount': sellerAmount,
        'currency': currency,
        'status': ManagedPaymentValues.balanceStatusId(
          SellerBalanceStatus.pendingDelivery,
        ),
        'updatedAt': timestamp,
      },
      'sellerBalanceStatus': ManagedPaymentValues.balanceStatusId(
        SellerBalanceStatus.pendingDelivery,
      ),
      'managedPaymentStatus': ManagedPaymentValues.statusId(
        ManagedPaymentStatus.paymentConfirmedByAdmin,
      ),
      'paymentFlow': ManagedPaymentValues.paymentFlow,
    };
  }

  static Map<String, dynamic> afterCustomerReceived({
    required double sellerAmount,
    required String currency,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'sellerBalance': {
        'pendingBalance': 0.0,
        'availableBalance': sellerAmount,
        'withdrawnBalance': 0.0,
        'disputedBalance': 0.0,
        'expectedSellerAmount': sellerAmount,
        'currency': currency,
        'status': ManagedPaymentValues.balanceStatusId(
          SellerBalanceStatus.available,
        ),
        'updatedAt': timestamp,
      },
      'sellerBalanceStatus': ManagedPaymentValues.balanceStatusId(
        SellerBalanceStatus.available,
      ),
      'managedPaymentStatus': ManagedPaymentValues.statusId(
        ManagedPaymentStatus.withdrawalAvailable,
      ),
      'receivedByCustomerAt': timestamp,
      'updatedAt': timestamp,
    };
  }

  static Map<String, dynamic> withdrawalRequested({
    required double sellerAmount,
    required String currency,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'sellerBalance': {
        'pendingBalance': 0.0,
        'availableBalance': sellerAmount,
        'withdrawnBalance': 0.0,
        'disputedBalance': 0.0,
        'expectedSellerAmount': sellerAmount,
        'currency': currency,
        'status': ManagedPaymentValues.balanceStatusId(
          SellerBalanceStatus.withdrawalRequested,
        ),
        'withdrawalRequestedAt': timestamp,
        'updatedAt': timestamp,
      },
      'sellerBalanceStatus': ManagedPaymentValues.balanceStatusId(
        SellerBalanceStatus.withdrawalRequested,
      ),
      'managedPaymentStatus': ManagedPaymentValues.statusId(
        ManagedPaymentStatus.withdrawalRequested,
      ),
      'payoutStatus': 'withdrawal_requested',
      'withdrawalRequestedAt': timestamp,
      'updatedAt': timestamp,
    };
  }

  static Map<String, dynamic> afterWithdrawalSettled({
    required double sellerAmount,
    required String currency,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'sellerBalance': {
        'pendingBalance': 0.0,
        'availableBalance': 0.0,
        'withdrawnBalance': sellerAmount,
        'disputedBalance': 0.0,
        'expectedSellerAmount': sellerAmount,
        'currency': currency,
        'status': ManagedPaymentValues.balanceStatusId(
          SellerBalanceStatus.withdrawn,
        ),
        'withdrawnAt': timestamp,
        'updatedAt': timestamp,
      },
      'sellerBalanceStatus': ManagedPaymentValues.balanceStatusId(
        SellerBalanceStatus.withdrawn,
      ),
      'managedPaymentStatus': ManagedPaymentValues.statusId(
        ManagedPaymentStatus.completed,
      ),
      'payoutStatus': 'settled',
      'completedAt': timestamp,
      'updatedAt': timestamp,
    };
  }

  static Map<String, dynamic> afterWithdrawalBlocked({
    required double sellerAmount,
    required String currency,
    Object? now,
  }) {
    final timestamp = now ?? FieldValue.serverTimestamp();
    return {
      'sellerBalance': {
        'pendingBalance': 0.0,
        'availableBalance': 0.0,
        'withdrawnBalance': 0.0,
        'disputedBalance': sellerAmount,
        'expectedSellerAmount': sellerAmount,
        'currency': currency,
        'status': ManagedPaymentValues.balanceStatusId(
          SellerBalanceStatus.disputed,
        ),
        'blockedAt': timestamp,
        'updatedAt': timestamp,
      },
      'sellerBalanceStatus': ManagedPaymentValues.balanceStatusId(
        SellerBalanceStatus.disputed,
      ),
      'managedPaymentStatus': ManagedPaymentValues.statusId(
        ManagedPaymentStatus.disputed,
      ),
      'payoutStatus': 'blocked',
      'updatedAt': timestamp,
    };
  }
}
