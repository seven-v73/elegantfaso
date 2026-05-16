import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final String currency;
  final int quantity;
  final String? size;
  final String? color;
  final String? variantId;

  OrderItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.currency = 'XOF',
    required this.quantity,
    this.size,
    this.color,
    this.variantId,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    try {
      return OrderItem(
        productId: data['productId'] as String,
        name: data['name'] as String,
        imageUrl: data['imageUrl'] as String? ?? '',
        price:
            (data['price'] is int
                ? (data['price'] as int).toDouble()
                : data['price'] as double),
        currency: data['currency']?.toString() ?? 'XOF',
        quantity: data['quantity'] as int,
        size: data['size'] as String?,
        color: data['color'] as String?,
        variantId: data['variantId'] as String?,
      );
    } catch (e) {
      throw FormatException('Failed to parse OrderItem: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'currency': currency,
      'quantity': quantity,
      if (size != null) 'size': size,
      if (color != null) 'color': color,
      if (variantId != null) 'variantId': variantId,
    };
  }

  double get totalPrice => price * quantity;

  OrderItem copyWith({
    String? productId,
    String? name,
    String? imageUrl,
    double? price,
    String? currency,
    int? quantity,
    String? size,
    String? color,
    String? variantId,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      color: color ?? this.color,
      variantId: variantId ?? this.variantId,
    );
  }
}

class BoutiqueOrder {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String boutiqueId;
  final String status;
  final String deliveryAddress;
  final List<OrderItem> items;
  final String currency;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? deliveryNotes;
  final double? deliveryFee;
  final double? discountAmount;

  BoutiqueOrder({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.boutiqueId,
    required this.status,
    required this.deliveryAddress,
    required this.items,
    this.currency = 'XOF',
    required this.createdAt,
    this.updatedAt,
    this.paymentMethod,
    this.paymentStatus,
    this.deliveryNotes,
    this.deliveryFee,
    this.discountAmount,
  });

  factory BoutiqueOrder.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final rawItems = data['items'] as List<dynamic>? ?? const [];
      final items =
          rawItems
              .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList();
      final firstItem =
          rawItems.isNotEmpty && rawItems.first is Map
              ? Map<String, dynamic>.from(rawItems.first as Map)
              : const <String, dynamic>{};

      return BoutiqueOrder(
        id: doc.id,
        clientId: data['clientId'] as String,
        clientName: data['clientName'] as String,
        clientPhone: data['clientPhone'] as String,
        boutiqueId: data['boutiqueId'] as String,
        status: data['status'] as String? ?? 'pending',
        deliveryAddress: data['deliveryAddress'] as String,
        items: items,
        currency:
            data['currency']?.toString() ??
            firstItem['currency']?.toString() ??
            'XOF',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt:
            data['updatedAt'] != null
                ? (data['updatedAt'] as Timestamp).toDate()
                : null,
        paymentMethod: data['paymentMethod'] as String?,
        paymentStatus: data['paymentStatus'] as String?,
        deliveryNotes: data['deliveryNotes'] as String?,
        deliveryFee: (data['deliveryFee'] as num?)?.toDouble(),
        discountAmount: (data['discountAmount'] as num?)?.toDouble(),
      );
    } catch (e) {
      throw FormatException('Failed to parse BoutiqueOrder: $e');
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'boutiqueId': boutiqueId,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'items': items.map((item) => item.toMap()).toList(),
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (deliveryNotes != null) 'deliveryNotes': deliveryNotes,
      if (deliveryFee != null) 'deliveryFee': deliveryFee,
      if (discountAmount != null) 'discountAmount': discountAmount,
    };
  }

  double get subtotal =>
      items.fold(0, (total, item) => total + item.totalPrice);

  double get total {
    double total = subtotal;
    if (deliveryFee != null) total += deliveryFee!;
    if (discountAmount != null) total -= discountAmount!;
    return total;
  }

  BoutiqueOrder copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? boutiqueId,
    String? status,
    String? deliveryAddress,
    List<OrderItem>? items,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? paymentMethod,
    String? paymentStatus,
    String? deliveryNotes,
    double? deliveryFee,
    double? discountAmount,
  }) {
    return BoutiqueOrder(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      boutiqueId: boutiqueId ?? this.boutiqueId,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  static const List<String> statusOptions = [
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded',
  ];

  bool get isCancellable =>
      !['cancelled', 'refunded', 'delivered'].contains(status);
  bool get isEditable => status == 'pending';
}
