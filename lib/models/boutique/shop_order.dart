import 'package:cloud_firestore/cloud_firestore.dart';

import '../commerce/managed_payment.dart';

class ShopOrderItem {
  const ShopOrderItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.currency,
    required this.quantity,
    this.size = '',
    this.color = '',
  });

  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final String currency;
  final int quantity;
  final String size;
  final String color;

  double get total => price * quantity;

  factory ShopOrderItem.fromMap(Map<String, dynamic> data) {
    return ShopOrderItem(
      productId: data['productId']?.toString() ?? data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Article',
      imageUrl: data['imageUrl']?.toString() ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: data['currency']?.toString() ?? 'XOF',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      size: data['size']?.toString() ?? '',
      color: data['color']?.toString() ?? '',
    );
  }
}

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.boutiqueId,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.proofImageUrl,
    required this.deliveryAddress,
    required this.deliveryMode,
    required this.deliveryFee,
    required this.sellerNote,
    required this.items,
    required this.total,
    required this.currency,
    required this.sellerBalanceStatus,
    required this.sellerExpectedBalance,
    required this.sellerAvailableBalance,
    required this.sellerPendingBalance,
    required this.sellerWithdrawnBalance,
    required this.sellerDisputedBalance,
    required this.paymentReference,
    required this.timeline,
    required this.createdAt,
    required this.updatedAt,
    required this.raw,
  });

  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String boutiqueId;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String proofImageUrl;
  final String deliveryAddress;
  final String deliveryMode;
  final double deliveryFee;
  final String sellerNote;
  final List<ShopOrderItem> items;
  final double total;
  final String currency;
  final String sellerBalanceStatus;
  final double sellerExpectedBalance;
  final double sellerAvailableBalance;
  final double sellerPendingBalance;
  final double sellerWithdrawnBalance;
  final double sellerDisputedBalance;
  final String paymentReference;
  final List<ManagedPaymentTimelineEntry> timeline;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  bool get hasProof => proofImageUrl.isNotEmpty;
  bool get needsPaymentReview =>
      paymentStatus == 'proof_submitted' ||
      paymentStatus == 'client_marked_paid' ||
      paymentStatus == 'pending';
  bool get isPending =>
      status == 'pending' || status == 'pending_seller_confirmation';
  bool get isAwaitingAdminPayment =>
      status == 'awaiting_admin_payment_confirmation';
  bool get isConfirmed => status == 'confirmed';
  bool get isPreparing => status == 'processing' || status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isDelivered =>
      status == 'delivered' ||
      status == 'delivered_by_seller' ||
      status == 'received_by_customer' ||
      status == 'withdrawal_available' ||
      status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get canRequestWithdrawal =>
      sellerBalanceStatus == 'available' && sellerAvailableBalance > 0;
  bool get hasWithdrawalRequest =>
      sellerBalanceStatus == 'withdrawal_requested';
  bool get isPayoutSettled => sellerBalanceStatus == 'withdrawn';
  bool get hasSellerBalanceInfo =>
      sellerExpectedBalance > 0 ||
      sellerPendingBalance > 0 ||
      sellerAvailableBalance > 0 ||
      sellerWithdrawnBalance > 0 ||
      sellerDisputedBalance > 0;

  double get visibleSellerBalance {
    if (sellerAvailableBalance > 0) return sellerAvailableBalance;
    if (sellerPendingBalance > 0) return sellerPendingBalance;
    if (sellerDisputedBalance > 0) return sellerDisputedBalance;
    if (sellerWithdrawnBalance > 0) return sellerWithdrawnBalance;
    return sellerExpectedBalance;
  }

  String get visibleSellerBalanceLabel {
    if (sellerBalanceStatus == 'available' && sellerAvailableBalance > 0) {
      return 'Disponible au retrait';
    }
    if (sellerBalanceStatus == 'pending_delivery' && sellerPendingBalance > 0) {
      return 'Disponible après réception client';
    }
    if (sellerBalanceStatus == 'withdrawal_requested') {
      return 'Retrait demandé';
    }
    if (sellerBalanceStatus == 'withdrawn') return 'Déjà retiré';
    if (sellerBalanceStatus == 'disputed') return 'Bloqué en litige';
    if (sellerExpectedBalance > 0) return 'Solde attendu';
    return 'Solde vendeur';
  }

  String get sellerBalanceLabel {
    return ManagedPaymentCopy.sellerBalanceLabel(sellerBalanceStatus);
  }

  String get statusLabel {
    return ManagedPaymentCopy.orderStatusLabel(status);
  }

  String get paymentStatusLabel =>
      ManagedPaymentCopy.paymentStatusLabel(paymentStatus);

  String get sellerActionHint => ManagedPaymentCopy.sellerActionHint(
    orderStatus: status,
    balanceStatus: sellerBalanceStatus,
  );

  String get nextActionLabel {
    if (isAwaitingAdminPayment) return 'Paiement admin';
    if (isPending) return 'Confirmer';
    if (isConfirmed) return 'Préparer';
    if (isPreparing) return 'Marquer prête';
    if (isReady) return 'Marquer livrée';
    return 'Voir détail';
  }

  String get nextStatus {
    if (isAwaitingAdminPayment) return status;
    if (isPending) return 'confirmed';
    if (isConfirmed) return 'processing';
    if (isPreparing) return 'ready';
    if (isReady) return 'delivered';
    return status;
  }

  factory ShopOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ShopOrder.fromMap(id: doc.id, data: doc.data() ?? {});
  }

  factory ShopOrder.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final rawItems = data['items'];
    final items =
        rawItems is Iterable
            ? rawItems
                .whereType<Map>()
                .map(
                  (item) =>
                      ShopOrderItem.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
            : <ShopOrderItem>[];
    final totals = data['totals'];
    final sellerBalance =
        data['sellerBalance'] is Map
            ? Map<String, dynamic>.from(data['sellerBalance'] as Map)
            : const <String, dynamic>{};
    final sellerExpectedBalance =
        (sellerBalance['expectedSellerAmount'] as num?)?.toDouble() ??
        (data['sellerPayout'] as num?)?.toDouble() ??
        0;
    final sellerBalanceStatus =
        data['sellerBalanceStatus']?.toString() ??
        sellerBalance['status']?.toString() ??
        '';
    final rawAvailableBalance =
        (sellerBalance['availableBalance'] as num?)?.toDouble() ?? 0;
    final rawPendingBalance =
        (sellerBalance['pendingBalance'] as num?)?.toDouble() ?? 0;
    final rawWithdrawnBalance =
        (sellerBalance['withdrawnBalance'] as num?)?.toDouble() ?? 0;
    final rawDisputedBalance =
        (sellerBalance['disputedBalance'] as num?)?.toDouble() ?? 0;
    return ShopOrder(
      id: id,
      clientId:
          data['clientId']?.toString() ?? data['userId']?.toString() ?? '',
      clientName:
          data['clientName']?.toString() ??
          data['customerName']?.toString() ??
          'Client',
      clientPhone:
          data['clientPhone']?.toString() ??
          data['customerPhone']?.toString() ??
          '',
      boutiqueId:
          data['boutiqueId']?.toString() ?? data['sellerId']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      paymentStatus: data['paymentStatus']?.toString() ?? 'pending',
      paymentMethod: data['paymentMethod']?.toString() ?? '',
      proofImageUrl: data['proofImageUrl']?.toString() ?? '',
      deliveryAddress: data['deliveryAddress']?.toString() ?? '',
      deliveryMode: data['deliveryMode']?.toString() ?? '',
      deliveryFee:
          (data['deliveryFee'] as num?)?.toDouble() ??
          (totals is Map
              ? (totals['deliveryFee'] as num?)?.toDouble()
              : null) ??
          0,
      sellerNote:
          data['sellerNote']?.toString() ??
          data['deliveryNotes']?.toString() ??
          '',
      items: items,
      total:
          (data['total'] as num?)?.toDouble() ??
          (totals is Map ? (totals['grandTotal'] as num?)?.toDouble() : null) ??
          items.fold<double>(0, (total, item) => total + item.total),
      currency:
          data['currency']?.toString() ??
          (items.isEmpty ? 'XOF' : items.first.currency),
      sellerBalanceStatus: sellerBalanceStatus,
      sellerExpectedBalance: sellerExpectedBalance,
      sellerAvailableBalance:
          rawAvailableBalance > 0
              ? rawAvailableBalance
              : sellerBalanceStatus == 'available'
              ? sellerExpectedBalance
              : 0,
      sellerPendingBalance:
          rawPendingBalance > 0
              ? rawPendingBalance
              : sellerBalanceStatus == 'pending_delivery'
              ? sellerExpectedBalance
              : 0,
      sellerWithdrawnBalance:
          rawWithdrawnBalance > 0
              ? rawWithdrawnBalance
              : sellerBalanceStatus == 'withdrawn'
              ? sellerExpectedBalance
              : 0,
      sellerDisputedBalance:
          rawDisputedBalance > 0
              ? rawDisputedBalance
              : sellerBalanceStatus == 'disputed'
              ? sellerExpectedBalance
              : 0,
      paymentReference: data['paymentReference']?.toString() ?? '',
      timeline: ManagedPaymentTimelineEntry.listFrom(data['paymentTimeline']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      raw: data,
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
