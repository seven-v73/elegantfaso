import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/commerce/platform_revenue.dart';
import '../../models/global/cart_item.dart';

class CommerceRevenueService {
  CommerceRevenueService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const CommerceRevenueConfig fallbackConfig = CommerceRevenueConfig();

  Future<CommerceRevenueConfig> loadConfig() async {
    try {
      final doc =
          await _firestore
              .collection('platform_settings')
              .doc('commerce')
              .get();
      if (!doc.exists) return fallbackConfig;
      return CommerceRevenueConfig.fromMap(
        doc.data() ?? const {},
        loadedFromFirestore: true,
      );
    } catch (_) {
      return fallbackConfig;
    }
  }

  Stream<CommerceRevenueConfig> watchConfig() {
    return _firestore
        .collection('platform_settings')
        .doc('commerce')
        .snapshots()
        .map((doc) {
          if (!doc.exists) return fallbackConfig;
          return CommerceRevenueConfig.fromMap(
            doc.data() ?? const {},
            loadedFromFirestore: true,
          );
        });
  }

  Future<void> saveConfig(CommerceRevenueConfig config) {
    return _firestore
        .collection('platform_settings')
        .doc('commerce')
        .set(config.toMap(), SetOptions(merge: true));
  }

  static PlatformCommissionBreakdown calculateBreakdown({
    required double subtotal,
    required double deliveryFee,
    required double serviceFee,
    required double discount,
    required CommerceRevenueConfig config,
  }) {
    final netMerchandise = (subtotal - discount).clamp(0, double.infinity);
    final commission =
        (netMerchandise * config.commissionRatePercent / 100).roundToDouble();
    final platformCommission = (commission + serviceFee).roundToDouble();
    final grandTotal =
        (subtotal + deliveryFee + serviceFee - discount)
            .clamp(0, double.infinity)
            .toDouble();
    final sellerPayout =
        (grandTotal - platformCommission).clamp(0, double.infinity).toDouble();

    return PlatformCommissionBreakdown(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      discount: discount,
      commissionRatePercent: config.commissionRatePercent,
      platformCommission: platformCommission,
      sellerPayout: sellerPayout,
      grandTotal: grandTotal,
    );
  }

  Future<void> recordPlatformCommission({
    required String orderId,
    required String sellerId,
    required String userId,
    required CartTotals totals,
  }) {
    return _firestore.collection('platform_commissions').doc(orderId).set({
      'orderId': orderId,
      'sellerId': sellerId,
      'userId': userId,
      'subtotal': totals.subtotal,
      'deliveryFee': totals.deliveryFee,
      'serviceFee': totals.serviceFee,
      'discount': totals.discount,
      'commissionRatePercent': totals.commissionRatePercent,
      'platformCommission': totals.platformCommission,
      'sellerPayout': totals.sellerPayout,
      'grandTotal': totals.grandTotal,
      'status': 'pending_settlement',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<BoostCampaign>> watchActiveBoosts({String? placement}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('boost_campaigns')
        .where('status', isEqualTo: 'active')
        .limit(30);
    if (placement != null && placement.trim().isNotEmpty) {
      query = query.where('placement', isEqualTo: placement.trim());
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(BoostCampaign.fromFirestore)
          .where((campaign) => campaign.isActive)
          .toList(growable: false);
    });
  }

  Stream<SellerSubscription?> watchSellerSubscription(String sellerId) {
    return _firestore
        .collection('seller_subscriptions')
        .doc(sellerId)
        .snapshots()
        .map(
          (doc) => doc.exists ? SellerSubscription.fromFirestore(doc) : null,
        );
  }
}
