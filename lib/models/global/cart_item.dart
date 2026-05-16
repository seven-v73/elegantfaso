import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.sellerId,
    required this.sellerName,
    required this.sellerImage,
    required this.metadata,
    required this.addedAt,
  });

  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String sellerId;
  final String sellerName;
  final String sellerImage;
  final Map<String, dynamic> metadata;
  final Timestamp addedAt;

  String get sellerRole {
    final rawRole = metadata['role']?.toString().trim().toLowerCase() ?? '';
    if (rawRole == 'createur' || rawRole == 'créateur') return 'createur';
    if (rawRole == 'boutique') return 'boutique';

    final rawType = metadata['type']?.toString().trim().toLowerCase() ?? '';
    if (rawType == 'creation' || rawType == 'création') return 'createur';
    return 'boutique';
  }

  String get vendorKey {
    final normalizedSellerId =
        sellerId.trim().isNotEmpty ? sellerId.trim() : 'unknown-$productId';
    return '${_sanitizeIdPart(sellerRole)}_${_sanitizeIdPart(normalizedSellerId)}';
  }

  String get variantKey {
    final size = metadata['size']?.toString() ?? '';
    final color = metadata['color']?.toString() ?? '';
    return CartItem.buildId(
      sellerId: vendorKey,
      productId: productId,
      size: size,
      color: color,
    );
  }

  int get stockLimit {
    final rawStock =
        metadata['stock'] ?? metadata['quantity'] ?? metadata['maxQuantity'];
    final stock =
        rawStock is num ? rawStock.toInt() : int.tryParse('$rawStock');
    if (stock == null || stock <= 0) return 99;
    return stock.clamp(1, 99);
  }

  String get currency => metadata['currency']?.toString() ?? 'XOF';

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerImage': sellerImage,
      'sellerRole': sellerRole,
      'metadata': metadata,
      'currency': currency,
      'addedAt': addedAt,
    };
  }

  Map<String, dynamic> toOrderMap() {
    return {
      'cartItemId': id,
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'subtotal': price * quantity,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerRole': sellerRole,
      'metadata': metadata,
      'currency': currency,
    };
  }

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
    String? sellerId,
    String? sellerName,
    String? sellerImage,
    Map<String, dynamic>? metadata,
    Timestamp? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerImage: sellerImage ?? this.sellerImage,
      metadata: metadata ?? this.metadata,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  factory CartItem.fromMap(String id, Map<String, dynamic> map) {
    final metadata = Map<String, dynamic>.from(map['metadata'] ?? {});
    final sellerRole = map['sellerRole']?.toString();
    final currency = map['currency']?.toString();
    if ((metadata['currency'] == null ||
            metadata['currency'].toString().isEmpty) &&
        currency != null &&
        currency.isNotEmpty) {
      metadata['currency'] = currency;
    }
    if ((metadata['role'] == null || metadata['role'].toString().isEmpty) &&
        sellerRole != null &&
        sellerRole.isNotEmpty) {
      metadata['role'] = sellerRole;
    }

    return CartItem(
      id: id,
      productId: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      sellerId: map['sellerId']?.toString() ?? '',
      sellerName: map['sellerName']?.toString() ?? '',
      sellerImage: map['sellerImage']?.toString() ?? '',
      metadata: metadata,
      addedAt:
          map['addedAt'] is Timestamp
              ? map['addedAt'] as Timestamp
              : Timestamp.now(),
    );
  }

  static String buildId({
    required String sellerId,
    required String productId,
    String? size,
    String? color,
  }) {
    return [
      sellerId,
      productId,
      size ?? '',
      color ?? '',
    ].map(_sanitizeIdPart).join('_');
  }

  static String _sanitizeIdPart(String value) {
    final sanitized = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    return sanitized.isEmpty ? 'default' : sanitized;
  }
}

class Vendor {
  const Vendor({
    required this.id,
    required this.name,
    required this.role,
    required this.paymentMethods,
    required this.phone,
    required this.photoUrl,
    this.speciality = '',
    this.followersCount = 0,
  });

  final String id;
  final String name;
  final String role;
  final Map<String, String> paymentMethods;
  final String phone;
  final String photoUrl;
  final String speciality;
  final int followersCount;

  factory Vendor.fromCartItem(CartItem item) {
    return Vendor(
      id: item.sellerId,
      name: item.sellerName,
      role: item.sellerRole,
      paymentMethods: Map<String, String>.from(
        item.metadata['paymentMethods'] ?? {},
      ),
      phone: item.metadata['phone']?.toString() ?? '',
      photoUrl: item.sellerImage,
      speciality: item.metadata['speciality']?.toString() ?? '',
      followersCount: (item.metadata['followersCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class CartTotals {
  const CartTotals({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    this.couponCode = '',
    this.couponDiscount = 0,
    this.commissionRatePercent = 8,
    this.platformCommission = 0,
    this.sellerPayout = 0,
  });

  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final String couponCode;
  final double couponDiscount;
  final double commissionRatePercent;
  final double platformCommission;
  final double sellerPayout;

  double get grandTotal =>
      (subtotal + deliveryFee + serviceFee - discount)
          .clamp(0, double.infinity)
          .toDouble();

  Map<String, dynamic> toMap() {
    return {
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'serviceFee': serviceFee,
      'discount': discount,
      'couponCode': couponCode,
      'couponDiscount': couponDiscount,
      'commissionRatePercent': commissionRatePercent,
      'platformCommission': platformCommission,
      'sellerPayout': sellerPayout,
      'grandTotal': grandTotal,
    };
  }
}
