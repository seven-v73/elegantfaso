import 'package:cloud_firestore/cloud_firestore.dart';

import 'managed_payment.dart';

class PurchaseHistoryItem {
  const PurchaseHistoryItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.category,
    required this.price,
    required this.currency,
    required this.quantity,
    required this.sellerId,
    required this.sellerName,
    required this.recipientType,
    this.recipientName = '',
    this.reviewId = '',
    this.reviewRating = 0,
    this.wardrobeItemId = '',
    this.status = 'client_marked_paid',
    this.canReview = false,
    this.paymentReference = '',
    this.createdAt,
  });

  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String productImageUrl;
  final String category;
  final double price;
  final String currency;
  final int quantity;
  final String sellerId;
  final String sellerName;
  final String recipientType;
  final String recipientName;
  final String reviewId;
  final int reviewRating;
  final String wardrobeItemId;
  final String status;
  final bool canReview;
  final String paymentReference;
  final DateTime? createdAt;

  bool get isForSelf => recipientType == 'self';
  bool get hasReview => reviewId.isNotEmpty || reviewRating > 0;
  bool get isReceived =>
      status == 'received_by_customer' ||
      status == 'withdrawal_available' ||
      status == 'withdrawal_requested' ||
      status == 'completed';
  bool get canConfirmReceipt =>
      orderId.isNotEmpty && !isReceived && status != 'disputed';
  String get statusLabel => ManagedPaymentCopy.orderStatusLabel(status);
  String get actionHint => ManagedPaymentCopy.clientActionHint(status);

  factory PurchaseHistoryItem.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return PurchaseHistoryItem(
      id: doc.id,
      orderId: data['orderId']?.toString() ?? '',
      productId: data['productId']?.toString() ?? '',
      productName: data['productName']?.toString() ?? '',
      productImageUrl: data['productImageUrl']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Autre',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: data['currency']?.toString() ?? 'XOF',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      sellerId: data['sellerId']?.toString() ?? '',
      sellerName: data['sellerName']?.toString() ?? '',
      recipientType: data['recipientType']?.toString() ?? 'self',
      recipientName: data['recipientName']?.toString() ?? '',
      reviewId: data['reviewId']?.toString() ?? '',
      reviewRating: (data['reviewRating'] as num?)?.toInt() ?? 0,
      wardrobeItemId: data['wardrobeItemId']?.toString() ?? '',
      status: data['status']?.toString() ?? 'client_marked_paid',
      canReview: data['canReview'] == true,
      paymentReference: data['paymentReference']?.toString() ?? '',
      createdAt:
          data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
    );
  }
}
