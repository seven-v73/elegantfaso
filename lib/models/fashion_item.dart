import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/preferences/currency_service.dart';

class FashionItem {
  final String id;
  final String title;
  final String imageUrl;
  final int likes;
  final String designer;
  final String designerImageUrl;
  final String category;
  final bool isHot;
  final bool isNew;
  final List<String> styles;
  final List<String> occasions;
  final String description;
  final double price;
  final String currency;
  final List<String>? availableSizes;
  final List<String>? availableColors;
  final double? matchingScore;
  final List<String>? materialComposition;
  final String? origin;
  final DateTime? createdAt;
  final int? viewCount;
  final bool isFavorite;
  final double? rating;
  final int? reviewCount;
  final bool inStock;

  FashionItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.likes,
    required this.designer,
    this.designerImageUrl = '',
    required this.category,
    this.isHot = false,
    this.isNew = false,
    required this.styles,
    required this.occasions,
    required this.description,
    required this.price,
    this.currency = CurrencyService.defaultCode,
    this.availableSizes,
    this.availableColors,
    this.matchingScore,
    this.materialComposition,
    this.origin,
    this.createdAt,
    this.viewCount = 0,
    this.isFavorite = false,
    this.rating,
    this.reviewCount = 0,
    this.inStock = true,
  });

  factory FashionItem.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return FashionItem(
      id: doc.id,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      likes: data['likes'] ?? 0,
      designer: data['designer'] ?? '',
      designerImageUrl: data['designerImageUrl'] ?? '',
      category: data['category'] ?? '',
      isHot: data['isHot'] ?? false,
      isNew: data['isNew'] ?? false,
      styles: List<String>.from(data['styles'] ?? []),
      occasions: List<String>.from(data['occasions'] ?? []),
      description: data['description'] ?? '',
      price: data['price']?.toDouble() ?? 0.0,
      currency: data['currency']?.toString() ?? CurrencyService.defaultCode,
      availableSizes:
          data['availableSizes'] != null
              ? List<String>.from(data['availableSizes'])
              : null,
      availableColors:
          data['availableColors'] != null
              ? List<String>.from(data['availableColors'])
              : null,
      matchingScore: data['matchingScore']?.toDouble(),
      materialComposition:
          data['materialComposition'] != null
              ? List<String>.from(data['materialComposition'])
              : null,
      origin: data['origin'],
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
      viewCount: data['viewCount'] ?? 0,
      isFavorite: data['isFavorite'] ?? false,
      rating: data['rating']?.toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      inStock: data['inStock'] ?? true,
    );
  }

  String formattedPrice() => CurrencyService.format(price, code: currency);
}
