import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/commerce/checkout_promotion.dart';

class CheckoutPromotionService {
  CheckoutPromotionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<CheckoutPromotionConfig> loadConfig({
    required String? userId,
    required double subtotal,
  }) async {
    try {
      final coupons = await _loadCoupons(subtotal);
      final points = await _loadUserPoints(userId);
      if (coupons.isEmpty) {
        return fallbackConfig(availablePoints: points);
      }
      return CheckoutPromotionConfig(
        coupons: coupons,
        availablePoints: points,
        loadedFromFirestore: true,
      );
    } catch (_) {
      final points = await _loadUserPoints(userId).catchError((_) => 0);
      return fallbackConfig(availablePoints: points);
    }
  }

  Future<CheckoutCouponRule?> findCoupon({
    required String code,
    required CheckoutPromotionConfig config,
    required double subtotal,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    for (final coupon in config.coupons) {
      if (coupon.code == normalized && coupon.isAvailableFor(subtotal)) {
        return coupon;
      }
    }
    return null;
  }

  static CheckoutPromotionConfig fallbackConfig({int availablePoints = 0}) {
    return CheckoutPromotionConfig(
      availablePoints: availablePoints,
      coupons: const [
        CheckoutCouponRule(
          code: 'STYLE5',
          type: CheckoutCouponType.percent,
          value: 5,
          description: '5% sur votre commande',
        ),
        CheckoutCouponRule(
          code: 'STYLE10',
          type: CheckoutCouponType.percent,
          value: 10,
          minSubtotal: 20000,
          description: '10% dès le minimum requis',
        ),
        CheckoutCouponRule(
          code: 'FREESHIP',
          type: CheckoutCouponType.freeShipping,
          value: 100,
          description: 'Livraison offerte',
        ),
      ],
    );
  }

  Future<List<CheckoutCouponRule>> _loadCoupons(double subtotal) async {
    final snapshot =
        await _firestore
            .collection('checkout_coupons')
            .where('active', isEqualTo: true)
            .limit(40)
            .get();
    return snapshot.docs
        .map(CheckoutCouponRule.fromFirestore)
        .where((coupon) => coupon.isAvailableFor(subtotal))
        .toList(growable: false);
  }

  Future<int> _loadUserPoints(String? userId) async {
    if (userId == null) return 0;
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data() ?? const {};
    final gamification = data['gamification'];
    if (gamification is Map) {
      return (gamification['points'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }
}
