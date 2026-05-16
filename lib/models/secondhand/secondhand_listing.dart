import 'package:cloud_firestore/cloud_firestore.dart';

import '../commerce/managed_payment.dart';

class SecondhandListing {
  const SecondhandListing({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.price,
    required this.currency,
    required this.city,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhotoUrl,
    required this.imageUrls,
    required this.status,
    required this.likedBy,
    this.visibilityTierId = 'explorer',
    this.visibilityLabel = 'Explorateur style',
    this.visibilityCategory = 'Visibilité douce',
    this.visibilityBoost = 1,
    this.recommendationWeight = 10,
    this.size = '',
    this.color = '',
    this.reservedBy = '',
    this.secondhandBalanceStatus = '',
    this.secondhandAvailableBalance = 0,
    this.secondhandWithdrawnBalance = 0,
    this.secondhandConvertedBalance = 0,
    this.stylePointsAwarded = 0,
    this.settlementChoice = '',
    this.paymentReference = '',
    this.timeline = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String condition;
  final double price;
  final String currency;
  final String city;
  final String size;
  final String color;
  final String sellerId;
  final String sellerName;
  final String sellerPhotoUrl;
  final List<String> imageUrls;
  final String status;
  final String reservedBy;
  final String secondhandBalanceStatus;
  final double secondhandAvailableBalance;
  final double secondhandWithdrawnBalance;
  final double secondhandConvertedBalance;
  final int stylePointsAwarded;
  final String settlementChoice;
  final String paymentReference;
  final List<ManagedPaymentTimelineEntry> timeline;
  final List<String> likedBy;
  final String visibilityTierId;
  final String visibilityLabel;
  final String visibilityCategory;
  final double visibilityBoost;
  final int recommendationWeight;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAvailable => status == 'available';
  bool get isReserved => status == 'reserved';
  bool get isSold => status == 'sold';
  bool get hasSettlementAvailable =>
      isSold &&
      secondhandBalanceStatus == 'available' &&
      secondhandAvailableBalance > 0;
  bool get hasWithdrawalRequest =>
      secondhandBalanceStatus == 'withdrawal_requested';
  bool get isConvertedToStylePoints =>
      secondhandBalanceStatus == 'converted_to_style_points';
  bool get isWithdrawn => secondhandBalanceStatus == 'withdrawn';
  bool get isDisputed =>
      secondhandBalanceStatus == 'disputed' ||
      secondhandBalanceStatus == 'withdrawal_blocked';
  bool get hasSettlementHistory =>
      timeline.isNotEmpty ||
      hasWithdrawalRequest ||
      isConvertedToStylePoints ||
      isWithdrawn ||
      isDisputed;

  String get coverUrl => imageUrls.isEmpty ? '' : imageUrls.first;

  String get statusLabel {
    return switch (status) {
      'reserved' => 'Réservé',
      'sold' => 'Vendu',
      _ => 'Disponible',
    };
  }

  Map<String, dynamic> toFirestore({bool includeCreatedAt = false}) {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'condition': condition,
      'price': price,
      'currency': currency,
      'city': city.trim(),
      'size': size.trim(),
      'color': color.trim(),
      'sellerId': sellerId,
      'sellerName': sellerName.trim(),
      'sellerPhotoUrl': sellerPhotoUrl,
      'imageUrls': imageUrls,
      'status': status,
      'reservedBy': reservedBy,
      'likedBy': likedBy,
      'visibilityTierId': visibilityTierId,
      'visibilityLabel': visibilityLabel,
      'visibilityCategory': visibilityCategory,
      'visibilityBoost': visibilityBoost,
      'recommendationWeight': recommendationWeight,
      'searchText': _searchText,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get _searchText {
    return [
      title,
      description,
      category,
      condition,
      city,
      size,
      color,
      sellerName,
    ].join(' ').toLowerCase();
  }

  SecondhandListing copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? condition,
    double? price,
    String? currency,
    String? city,
    String? size,
    String? color,
    String? sellerId,
    String? sellerName,
    String? sellerPhotoUrl,
    List<String>? imageUrls,
    String? status,
    String? reservedBy,
    String? secondhandBalanceStatus,
    double? secondhandAvailableBalance,
    double? secondhandWithdrawnBalance,
    double? secondhandConvertedBalance,
    int? stylePointsAwarded,
    String? settlementChoice,
    String? paymentReference,
    List<ManagedPaymentTimelineEntry>? timeline,
    List<String>? likedBy,
    String? visibilityTierId,
    String? visibilityLabel,
    String? visibilityCategory,
    double? visibilityBoost,
    int? recommendationWeight,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SecondhandListing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      city: city ?? this.city,
      size: size ?? this.size,
      color: color ?? this.color,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhotoUrl: sellerPhotoUrl ?? this.sellerPhotoUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      reservedBy: reservedBy ?? this.reservedBy,
      secondhandBalanceStatus:
          secondhandBalanceStatus ?? this.secondhandBalanceStatus,
      secondhandAvailableBalance:
          secondhandAvailableBalance ?? this.secondhandAvailableBalance,
      secondhandWithdrawnBalance:
          secondhandWithdrawnBalance ?? this.secondhandWithdrawnBalance,
      secondhandConvertedBalance:
          secondhandConvertedBalance ?? this.secondhandConvertedBalance,
      stylePointsAwarded: stylePointsAwarded ?? this.stylePointsAwarded,
      settlementChoice: settlementChoice ?? this.settlementChoice,
      paymentReference: paymentReference ?? this.paymentReference,
      timeline: timeline ?? this.timeline,
      likedBy: likedBy ?? this.likedBy,
      visibilityTierId: visibilityTierId ?? this.visibilityTierId,
      visibilityLabel: visibilityLabel ?? this.visibilityLabel,
      visibilityCategory: visibilityCategory ?? this.visibilityCategory,
      visibilityBoost: visibilityBoost ?? this.visibilityBoost,
      recommendationWeight: recommendationWeight ?? this.recommendationWeight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SecondhandListing.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return SecondhandListing(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Accessoires',
      condition: data['condition']?.toString() ?? 'Très bon état',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: data['currency']?.toString() ?? 'XOF',
      city: data['city']?.toString() ?? '',
      size: data['size']?.toString() ?? '',
      color: data['color']?.toString() ?? '',
      sellerId: data['sellerId']?.toString() ?? '',
      sellerName: data['sellerName']?.toString() ?? 'Client ElegantFaso',
      sellerPhotoUrl: data['sellerPhotoUrl']?.toString() ?? '',
      imageUrls:
          (data['imageUrls'] as List<dynamic>? ?? [])
              .map((url) => url.toString())
              .where((url) => url.isNotEmpty)
              .toList(),
      status: data['status']?.toString() ?? 'available',
      reservedBy: data['reservedBy']?.toString() ?? '',
      secondhandBalanceStatus:
          data['secondhandBalanceStatus']?.toString() ??
          _map(data['secondhandBalance'])['status']?.toString() ??
          '',
      secondhandAvailableBalance:
          (_map(data['secondhandBalance'])['availableBalance'] as num?)
              ?.toDouble() ??
          0,
      secondhandWithdrawnBalance:
          (_map(data['secondhandBalance'])['withdrawnBalance'] as num?)
              ?.toDouble() ??
          0,
      secondhandConvertedBalance:
          (_map(data['secondhandBalance'])['convertedBalance'] as num?)
              ?.toDouble() ??
          0,
      stylePointsAwarded:
          (_map(data['secondhandBalance'])['stylePointsAwarded'] as num?)
              ?.toInt() ??
          (data['stylePointsAwarded'] as num?)?.toInt() ??
          0,
      settlementChoice: data['settlementChoice']?.toString() ?? '',
      paymentReference: data['paymentReference']?.toString() ?? '',
      timeline: ManagedPaymentTimelineEntry.listFrom(data['paymentTimeline']),
      likedBy:
          (data['likedBy'] as List<dynamic>? ?? [])
              .map((id) => id.toString())
              .toList(),
      visibilityTierId: data['visibilityTierId']?.toString() ?? 'explorer',
      visibilityLabel:
          data['visibilityLabel']?.toString() ?? 'Explorateur style',
      visibilityCategory:
          data['visibilityCategory']?.toString() ?? 'Visibilité douce',
      visibilityBoost: (data['visibilityBoost'] as num?)?.toDouble() ?? 1,
      recommendationWeight:
          (data['recommendationWeight'] as num?)?.toInt() ?? 10,
      createdAt: _dateFrom(data['createdAt']),
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}

class SecondhandSettlementPolicy {
  const SecondhandSettlementPolicy._();

  static const int xofPerStylePoint = 100;
  static const int maxPointsPerSale = 800;

  static int stylePointsFor({
    required double amount,
    required String currency,
  }) {
    if (amount <= 0) return 0;
    final normalized = currency.trim().toUpperCase();
    final base =
        normalized == 'XOF' || normalized == 'FCFA'
            ? (amount / xofPerStylePoint).floor()
            : (amount / 2).floor();
    return base.clamp(10, maxPointsPerSale);
  }
}

class SecondhandDraft {
  const SecondhandDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.price,
    required this.currency,
    required this.city,
    required this.size,
    required this.color,
  });

  final String title;
  final String description;
  final String category;
  final String condition;
  final double price;
  final String currency;
  final String city;
  final String size;
  final String color;
}
