import 'package:cloud_firestore/cloud_firestore.dart';

class BoutiqueProduct {
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final int stock;
  final String boutiqueId;
  final String imageUrl;
  final DateTime createdAt;

  BoutiqueProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.stock,
    required this.boutiqueId,
    required this.imageUrl,
    required this.createdAt,
  });

  factory BoutiqueProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BoutiqueProduct(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      stock: (data['stock'] ?? 0).toInt(),
      boutiqueId: data['boutiqueId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] ?? Timestamp.now()).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'stock': stock,
      'boutiqueId': boutiqueId,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}