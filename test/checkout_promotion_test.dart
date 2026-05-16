import 'package:elegantfaso/models/commerce/checkout_promotion.dart';
import 'package:elegantfaso/services/commerce/checkout_promotion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcule une remise coupon pilotable par règle', () {
    const coupon = CheckoutCouponRule(
      code: 'VIP15',
      type: CheckoutCouponType.percent,
      value: 15,
      minSubtotal: 10000,
      maxDiscount: 2500,
    );

    final discount = coupon.discountFor(subtotal: 20000, deliveryFee: 1000);

    expect(discount, 2500);
  });

  test('garde les points client hors des réductions checkout', () {
    final config = CheckoutPromotionService.fallbackConfig(
      availablePoints: 700,
    );

    expect(config.availablePoints, 700);
    expect(config.coupons, isNotEmpty);
  });

  test('un coupon livraison gratuite suit le frais dynamique', () {
    const coupon = CheckoutCouponRule(
      code: 'SHIP',
      type: CheckoutCouponType.freeShipping,
      value: 0,
    );

    expect(coupon.discountFor(subtotal: 20000, deliveryFee: 1000), 1000);
    expect(coupon.discountFor(subtotal: 20000, deliveryFee: 2500), 2500);
  });
}
