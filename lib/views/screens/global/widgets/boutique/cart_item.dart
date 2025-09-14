import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String type; // 'product' ou 'creation'
  final String sellerId;
  final String sellerName;
  final String sellerImage;
  final Map<String, dynamic> metadata;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.type,
    required this.sellerId,
    required this.sellerName,
    required this.sellerImage,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'type': type,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerImage': sellerImage,
      'metadata': metadata,
      'addedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CartItem.fromMap(String id, Map<String, dynamic> map) {
    return CartItem(
      id: id,
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      type: map['type'] ?? 'product',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerImage: map['sellerImage'] ?? '',
      metadata: map['metadata'] ?? {},
    );
  }

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
    String? type,
    String? sellerId,
    String? sellerName,
    String? sellerImage,
    Map<String, dynamic>? metadata,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      type: type ?? this.type,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerImage: sellerImage ?? this.sellerImage,
      metadata: metadata ?? this.metadata,
    );
  }
}