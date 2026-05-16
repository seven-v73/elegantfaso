import 'package:cloud_firestore/cloud_firestore.dart';

class ProductReview {
  const ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.productName,
    required this.productImageUrl,
    required this.sellerId,
    required this.sellerName,
    this.orderId = '',
    this.createdAt,
  });

  final String id;
  final String productId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final String productName;
  final String productImageUrl;
  final String sellerId;
  final String sellerName;
  final String orderId;
  final DateTime? createdAt;

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating.clamp(1, 5),
      'comment': comment.trim(),
      'productName': productName,
      'productImageUrl': productImageUrl,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'orderId': orderId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ProductReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return ProductReview(
      id: doc.id,
      productId: data['productId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? 'Client',
      rating: (data['rating'] as num?)?.toInt().clamp(1, 5) ?? 5,
      comment: data['comment']?.toString() ?? '',
      productName: data['productName']?.toString() ?? '',
      productImageUrl: data['productImageUrl']?.toString() ?? '',
      sellerId: data['sellerId']?.toString() ?? '',
      sellerName: data['sellerName']?.toString() ?? '',
      orderId: data['orderId']?.toString() ?? '',
      createdAt:
          data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
    );
  }
}

class ProductReviewSummary {
  const ProductReviewSummary({
    required this.average,
    required this.count,
    required this.recent,
  });

  final double average;
  final int count;
  final List<ProductReview> recent;

  static const empty = ProductReviewSummary(average: 0, count: 0, recent: []);
}
