import 'package:elegantfaso/models/commerce/platform_revenue.dart';
import 'package:elegantfaso/services/commerce/commerce_revenue_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcule commission plateforme et reversement vendeur', () {
    final breakdown = CommerceRevenueService.calculateBreakdown(
      subtotal: 20000,
      deliveryFee: 1000,
      serviceFee: 200,
      discount: 2000,
      config: const CommerceRevenueConfig(commissionRatePercent: 8),
    );

    expect(breakdown.grandTotal, 19200);
    expect(breakdown.platformCommission, 1640);
    expect(breakdown.sellerPayout, 17560);
  });

  test('normalise la configuration revenue depuis Firestore', () {
    final config = CommerceRevenueConfig.fromMap({
      'commissionRatePercent': 50,
      'appointmentCommissionRatePercent': '7.5',
      'appointmentFixedFee': '300',
      'boostBasePrice': 1500,
      'freeDeliveryThreshold': '30000',
      'baseDeliveryFee': '1500',
      'serviceFeeRatePercent': '3',
      'currency': 'EUR',
    });

    expect(config.commissionRatePercent, 30);
    expect(config.appointmentCommissionRatePercent, 7.5);
    expect(config.appointmentFixedFee, 300);
    expect(config.boostBasePrice, 1500);
    expect(config.freeDeliveryThreshold, 30000);
    expect(config.baseDeliveryFee, 1500);
    expect(config.serviceFeeRatePercent, 3);
    expect(config.currency, 'EUR');
  });
}
