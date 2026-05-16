import 'package:cloud_firestore/cloud_firestore.dart';

class CommerceRevenueConfig {
  const CommerceRevenueConfig({
    this.commissionRatePercent = 8,
    this.appointmentCommissionRatePercent = 5,
    this.appointmentFixedFee = 500,
    this.boostBasePrice = 1000,
    this.proMonthlyPrice = 2500,
    this.premiumMonthlyPrice = 7500,
    this.freeDeliveryThreshold = 25000,
    this.baseDeliveryFee = 1000,
    this.serviceFeeRatePercent = 1,
    this.currency = 'XOF',
    this.platformPaymentMethods = const {},
    this.loadedFromFirestore = false,
  });

  final double commissionRatePercent;
  final double appointmentCommissionRatePercent;
  final double appointmentFixedFee;
  final double boostBasePrice;
  final double proMonthlyPrice;
  final double premiumMonthlyPrice;
  final double freeDeliveryThreshold;
  final double baseDeliveryFee;
  final double serviceFeeRatePercent;
  final String currency;
  final Map<String, String> platformPaymentMethods;
  final bool loadedFromFirestore;

  factory CommerceRevenueConfig.fromMap(
    Map<String, dynamic> data, {
    bool loadedFromFirestore = false,
  }) {
    return CommerceRevenueConfig(
      commissionRatePercent:
          _doubleFrom(
            data['commissionRatePercent'] ?? data['commissionRate'],
            fallback: 8,
          ).clamp(0, 30).toDouble(),
      appointmentCommissionRatePercent:
          _doubleFrom(
            data['appointmentCommissionRatePercent'],
            fallback: 5,
          ).clamp(0, 30).toDouble(),
      appointmentFixedFee: _doubleFrom(
        data['appointmentFixedFee'],
        fallback: 500,
      ),
      boostBasePrice: _doubleFrom(data['boostBasePrice'], fallback: 1000),
      proMonthlyPrice: _doubleFrom(data['proMonthlyPrice'], fallback: 2500),
      premiumMonthlyPrice: _doubleFrom(
        data['premiumMonthlyPrice'],
        fallback: 7500,
      ),
      freeDeliveryThreshold: _doubleFrom(
        data['freeDeliveryThreshold'],
        fallback: 25000,
      ),
      baseDeliveryFee: _doubleFrom(data['baseDeliveryFee'], fallback: 1000),
      serviceFeeRatePercent:
          _doubleFrom(
            data['serviceFeeRatePercent'],
            fallback: 1,
          ).clamp(0, 10).toDouble(),
      currency: data['currency']?.toString() ?? 'XOF',
      platformPaymentMethods: _stringMapFrom(data['platformPaymentMethods']),
      loadedFromFirestore: loadedFromFirestore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commissionRatePercent': commissionRatePercent,
      'appointmentCommissionRatePercent': appointmentCommissionRatePercent,
      'appointmentFixedFee': appointmentFixedFee,
      'boostBasePrice': boostBasePrice,
      'proMonthlyPrice': proMonthlyPrice,
      'premiumMonthlyPrice': premiumMonthlyPrice,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'baseDeliveryFee': baseDeliveryFee,
      'serviceFeeRatePercent': serviceFeeRatePercent,
      'currency': currency,
      'platformPaymentMethods': platformPaymentMethods,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static double _doubleFrom(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static Map<String, String> _stringMapFrom(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, entry) => MapEntry(key.toString(), entry?.toString() ?? ''),
    )..removeWhere((key, entry) => key.trim().isEmpty || entry.trim().isEmpty);
  }
}

class PlatformCommissionBreakdown {
  const PlatformCommissionBreakdown({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.commissionRatePercent,
    required this.platformCommission,
    required this.sellerPayout,
    required this.grandTotal,
  });

  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double commissionRatePercent;
  final double platformCommission;
  final double sellerPayout;
  final double grandTotal;

  Map<String, dynamic> toMap() {
    return {
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'serviceFee': serviceFee,
      'discount': discount,
      'commissionRatePercent': commissionRatePercent,
      'platformCommission': platformCommission,
      'sellerPayout': sellerPayout,
      'grandTotal': grandTotal,
    };
  }
}

class SellerSubscription {
  const SellerSubscription({
    required this.sellerId,
    required this.plan,
    this.status = 'free',
    this.startedAt,
    this.expiresAt,
    this.monthlyPrice = 0,
    this.productLimit = 10,
    this.boostCredits = 0,
    this.analyticsEnabled = false,
    this.verifiedBadge = false,
  });

  final String sellerId;
  final String plan;
  final String status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final double monthlyPrice;
  final int productLimit;
  final int boostCredits;
  final bool analyticsEnabled;
  final bool verifiedBadge;

  bool get isActive {
    if (status != 'active') return false;
    if (expiresAt == null) return false;
    return expiresAt!.isAfter(DateTime.now());
  }

  bool get isExpired {
    final end = expiresAt;
    return status == 'active' && end != null && !end.isAfter(DateTime.now());
  }

  int? get daysUntilExpiration {
    final end = expiresAt;
    if (end == null) return null;
    return end.difference(DateTime.now()).inDays;
  }

  factory SellerSubscription.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return SellerSubscription(
      sellerId: data['sellerId']?.toString() ?? doc.id,
      plan: data['plan']?.toString() ?? 'starter',
      status: data['status']?.toString() ?? 'free',
      startedAt: _dateFrom(data['startedAt']),
      expiresAt: _dateFrom(data['expiresAt']),
      monthlyPrice: CommerceRevenueConfig._doubleFrom(
        data['monthlyPrice'],
        fallback: 0,
      ),
      productLimit: (data['productLimit'] as num?)?.toInt() ?? 10,
      boostCredits: (data['boostCredits'] as num?)?.toInt() ?? 0,
      analyticsEnabled: _boolFrom(data['analyticsEnabled']),
      verifiedBadge: _boolFrom(data['verifiedBadge']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'plan': plan,
      'status': status,
      'monthlyPrice': monthlyPrice,
      'productLimit': productLimit,
      'boostCredits': boostCredits,
      'analyticsEnabled': analyticsEnabled,
      'verifiedBadge': verifiedBadge,
      if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class BoostCampaign {
  const BoostCampaign({
    required this.id,
    required this.ownerId,
    required this.targetId,
    required this.targetType,
    required this.placement,
    required this.budget,
    this.status = 'draft',
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String ownerId;
  final String targetId;
  final String targetType;
  final String placement;
  final double budget;
  final String status;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool get isActive {
    final now = DateTime.now();
    if (status != 'active') return false;
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }

  factory BoostCampaign.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return BoostCampaign(
      id: doc.id,
      ownerId: data['ownerId']?.toString() ?? '',
      targetId: data['targetId']?.toString() ?? '',
      targetType: data['targetType']?.toString() ?? 'product',
      placement: data['placement']?.toString() ?? 'salon',
      budget: CommerceRevenueConfig._doubleFrom(data['budget'], fallback: 0),
      status: data['status']?.toString() ?? 'draft',
      startsAt: _dateFrom(data['startsAt']),
      endsAt: _dateFrom(data['endsAt']),
    );
  }
}

DateTime? _dateFrom(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}

bool _boolFrom(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes' || text == 'oui';
}
