import 'package:cloud_firestore/cloud_firestore.dart';

enum CheckoutCouponType { percent, fixedAmount, freeShipping }

class CheckoutCouponRule {
  const CheckoutCouponRule({
    required this.code,
    required this.type,
    required this.value,
    this.active = true,
    this.minSubtotal = 0,
    this.maxDiscount,
    this.description = '',
    this.startsAt,
    this.endsAt,
  });

  final String code;
  final CheckoutCouponType type;
  final double value;
  final bool active;
  final double minSubtotal;
  final double? maxDiscount;
  final String description;
  final DateTime? startsAt;
  final DateTime? endsAt;

  factory CheckoutCouponRule.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return CheckoutCouponRule(
      code: (data['code'] ?? doc.id).toString().trim().toUpperCase(),
      type: _couponTypeFrom(data['type']?.toString()),
      value: (data['value'] as num?)?.toDouble() ?? 0,
      active: data['active'] != false,
      minSubtotal: (data['minSubtotal'] as num?)?.toDouble() ?? 0,
      maxDiscount: (data['maxDiscount'] as num?)?.toDouble(),
      description: data['description']?.toString() ?? '',
      startsAt: _date(data['startsAt']),
      endsAt: _date(data['endsAt']),
    );
  }

  bool isAvailableFor(double subtotal, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (!active || subtotal < minSubtotal) return false;
    if (startsAt != null && current.isBefore(startsAt!)) return false;
    if (endsAt != null && current.isAfter(endsAt!)) return false;
    return true;
  }

  double discountFor({required double subtotal, required double deliveryFee}) {
    if (!isAvailableFor(subtotal)) return 0;
    final raw = switch (type) {
      CheckoutCouponType.percent => subtotal * value / 100,
      CheckoutCouponType.fixedAmount => value,
      CheckoutCouponType.freeShipping => deliveryFee,
    };
    final capped = maxDiscount == null ? raw : raw.clamp(0, maxDiscount!);
    return capped.clamp(0, subtotal).toDouble();
  }

  static CheckoutCouponType _couponTypeFrom(String? raw) {
    final value = raw?.toLowerCase().trim() ?? '';
    if (value.contains('fixed') || value.contains('amount')) {
      return CheckoutCouponType.fixedAmount;
    }
    if (value.contains('ship') || value.contains('livraison')) {
      return CheckoutCouponType.freeShipping;
    }
    return CheckoutCouponType.percent;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }
}

class CheckoutPromotionConfig {
  const CheckoutPromotionConfig({
    required this.coupons,
    required this.availablePoints,
    this.loadedFromFirestore = false,
  });

  final List<CheckoutCouponRule> coupons;
  final int availablePoints;
  final bool loadedFromFirestore;
}
