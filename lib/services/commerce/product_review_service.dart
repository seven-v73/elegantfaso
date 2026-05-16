import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/commerce/product_review.dart';

class ProductReviewService {
  ProductReviewService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<ProductReviewSummary> watchSummary(String productId) {
    if (productId.isEmpty) return Stream.value(ProductReviewSummary.empty);
    return _firestore
        .collection('product_reviews')
        .where('productId', isEqualTo: productId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs.map(ProductReview.fromDoc).toList();
          reviews.sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          if (reviews.isEmpty) return ProductReviewSummary.empty;
          final total = reviews.fold<int>(
            0,
            (total, review) => total + review.rating,
          );
          return ProductReviewSummary(
            average: total / reviews.length,
            count: reviews.length,
            recent: reviews.take(3).toList(),
          );
        });
  }
}
