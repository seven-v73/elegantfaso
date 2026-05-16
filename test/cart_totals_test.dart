import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegantfaso/models/commerce/platform_revenue.dart';
import 'package:elegantfaso/models/global/cart_item.dart';
import 'package:elegantfaso/services/global/cart_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applique un coupon aux totaux panier', () {
    final totals = CartService.calculateTotals(
      [_cartItem(price: 20000, quantity: 1)],
      couponCode: 'STYLE10',
      couponDiscountAmount: 2000,
    );

    expect(totals.subtotal, 20000);
    expect(totals.couponCode, 'STYLE10');
    expect(totals.discount, 2000);
    expect(totals.grandTotal, 19200);
  });

  test('ne laisse jamais le total devenir négatif', () {
    final totals = CartService.calculateTotals(
      [_cartItem(price: 1000, quantity: 1)],
      couponCode: 'STYLE10',
      couponDiscountAmount: 10000,
    );

    expect(totals.grandTotal, greaterThanOrEqualTo(0));
  });

  test('applique les frais checkout pilotés par configuration commerce', () {
    final totals = CartService.calculateTotals(
      [_cartItem(price: 12000, quantity: 1)],
      revenueConfig: const CommerceRevenueConfig(
        freeDeliveryThreshold: 15000,
        baseDeliveryFee: 750,
        serviceFeeRatePercent: 2,
      ),
    );

    expect(totals.deliveryFee, 750);
    expect(totals.serviceFee, 240);
    expect(totals.grandTotal, 12990);
  });

  test('autorise des frais de livraison dynamiques au checkout', () {
    final totals = CartService.calculateTotals(
      [_cartItem(price: 12000, quantity: 1)],
      revenueConfig: const CommerceRevenueConfig(
        freeDeliveryThreshold: 15000,
        baseDeliveryFee: 750,
        serviceFeeRatePercent: 2,
      ),
      deliveryFeeOverride: 2200,
    );

    expect(totals.deliveryFee, 2200);
    expect(totals.serviceFee, 240);
    expect(totals.grandTotal, 14440);
    expect(totals.sellerPayout, 13240);
  });
}

CartItem _cartItem({required double price, required int quantity}) {
  return CartItem(
    id: 'cart',
    productId: 'product',
    name: 'Produit test',
    imageUrl: '',
    price: price,
    quantity: quantity,
    sellerId: 'seller',
    sellerName: 'Vendeur',
    sellerImage: '',
    metadata: const {},
    addedAt: Timestamp.now(),
  );
}
