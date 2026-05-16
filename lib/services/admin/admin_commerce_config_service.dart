import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/commerce/checkout_promotion.dart';
import '../../models/commerce/platform_revenue.dart';
import '../commerce/commerce_revenue_service.dart';

class AdminCommerceConfigService {
  AdminCommerceConfigService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> seedDefaultCheckoutRules() async {
    final batch = _firestore.batch();

    batch.set(
      _firestore.collection('platform_settings').doc('commerce'),
      CommerceRevenueService.fallbackConfig.toMap(),
      SetOptions(merge: true),
    );

    for (final coupon in CheckoutPromotionServiceDefaults.coupons) {
      final ref = _firestore.collection('checkout_coupons').doc(coupon.code);
      batch.set(ref, _couponToMap(coupon), SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> upsertCoupon(CheckoutCouponRule coupon) {
    return _firestore
        .collection('checkout_coupons')
        .doc(coupon.code)
        .set(_couponToMap(coupon), SetOptions(merge: true));
  }

  Future<void> saveRevenueConfig(CommerceRevenueConfig config) {
    return _firestore
        .collection('platform_settings')
        .doc('commerce')
        .set(config.toMap(), SetOptions(merge: true));
  }

  Future<void> createSellerSubscription(SellerSubscription subscription) {
    return _firestore
        .collection('seller_subscriptions')
        .doc(subscription.sellerId)
        .set(subscription.toMap(), SetOptions(merge: true));
  }

  Future<void> createBoostCampaign({
    required String ownerId,
    required String targetId,
    required String targetType,
    required String placement,
    required double budget,
    required DateTime startsAt,
    required DateTime endsAt,
  }) {
    return _firestore.collection('boost_campaigns').add({
      'ownerId': ownerId,
      'targetId': targetId,
      'targetType': targetType,
      'placement': placement,
      'budget': budget,
      'status': 'active',
      'startsAt': Timestamp.fromDate(startsAt),
      'endsAt': Timestamp.fromDate(endsAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<BusinessAccessMaintenanceResult> expireOverdueBusinessAccess({
    int limit = 80,
  }) async {
    final now = DateTime.now();
    final nowTimestamp = Timestamp.fromDate(now);
    var expiredPlans = 0;
    var expiredBoosts = 0;

    final subscriptions =
        await _firestore
            .collection('seller_subscriptions')
            .where('status', isEqualTo: 'active')
            .where('expiresAt', isLessThanOrEqualTo: nowTimestamp)
            .limit(limit)
            .get();

    for (final doc in subscriptions.docs) {
      final data = doc.data();
      final sellerId =
          data['sellerId']?.toString().trim().isNotEmpty == true
              ? data['sellerId'].toString().trim()
              : doc.id;
      final batch = _firestore.batch();
      batch.set(doc.reference, {
        'status': 'expired',
        'expiredAt': nowTimestamp,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(_firestore.collection('users').doc(sellerId), {
        'businessEntitlements.status': 'expired',
        'businessEntitlements.expiredAt': nowTimestamp,
        'businessEntitlements.updatedAt': FieldValue.serverTimestamp(),
        'certifiedProfessional': false,
        'certificationBadge': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
      expiredPlans++;
    }

    final boosts =
        await _firestore
            .collection('boost_campaigns')
            .where('status', isEqualTo: 'active')
            .where('endsAt', isLessThanOrEqualTo: nowTimestamp)
            .limit(limit)
            .get();

    for (final doc in boosts.docs) {
      final data = doc.data();
      final ownerId =
          data['ownerId']?.toString().trim().isNotEmpty == true
              ? data['ownerId'].toString().trim()
              : data['accountId']?.toString().trim() ?? '';
      final batch = _firestore.batch();
      batch.set(doc.reference, {
        'status': 'expired',
        'expiredAt': nowTimestamp,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (ownerId.isNotEmpty) {
        batch.set(_firestore.collection('users').doc(ownerId), {
          'businessEntitlements.boost.status': 'expired',
          'businessEntitlements.boost.expiredAt': nowTimestamp,
          'businessEntitlements.boost.updatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
      expiredBoosts++;
    }

    return BusinessAccessMaintenanceResult(
      expiredPlans: expiredPlans,
      expiredBoosts: expiredBoosts,
    );
  }

  Map<String, dynamic> _couponToMap(CheckoutCouponRule coupon) {
    return {
      'code': coupon.code,
      'type': coupon.type.name,
      'value': coupon.value,
      'active': coupon.active,
      'minSubtotal': coupon.minSubtotal,
      if (coupon.maxDiscount != null) 'maxDiscount': coupon.maxDiscount,
      'description': coupon.description,
      if (coupon.startsAt != null)
        'startsAt': Timestamp.fromDate(coupon.startsAt!),
      if (coupon.endsAt != null) 'endsAt': Timestamp.fromDate(coupon.endsAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class BusinessAccessMaintenanceResult {
  const BusinessAccessMaintenanceResult({
    required this.expiredPlans,
    required this.expiredBoosts,
  });

  final int expiredPlans;
  final int expiredBoosts;

  int get total => expiredPlans + expiredBoosts;
}

class CheckoutPromotionServiceDefaults {
  static const coupons = [
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
      description: '10% dès 20 000 FCFA',
    ),
    CheckoutCouponRule(
      code: 'FREESHIP',
      type: CheckoutCouponType.freeShipping,
      value: 100,
      description: 'Livraison offerte',
    ),
  ];
}
