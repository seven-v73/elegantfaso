import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreationModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double price;
  final String category;
  final double rating;
  final int ratingCount;
  final bool isNew;
  final String createurId;
  final List<String> tags;
  final List<String> colors;
  final String size;
  final String material;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final bool isFeatured;
  final int stockQuantity;
  final List<String> additionalImages;

  CreationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.category = '',
    this.rating = 0.0,
    this.ratingCount = 0,
    this.isNew = false,
    this.createurId = '',
    this.tags = const [],
    this.colors = const [],
    this.size = 'Unique',
    this.material = 'Non spécifié',
    required this.createdAt,
    required this.updatedAt,
    this.isFeatured = false,
    this.stockQuantity = 1,
    this.additionalImages = const [],
  });

  factory CreationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CreationModel(
      id: doc.id,
      title: data['title'] ?? 'Sans titre',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (data['ratingCount'] as int?) ?? 0,
      isNew: data['isNew'] as bool? ?? false,
      createurId: data['createurId'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      colors: List<String>.from(data['colors'] ?? []),
      size: data['size'] ?? 'Unique',
      material: data['material'] ?? 'Non spécifié',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
      isFeatured: data['isFeatured'] as bool? ?? false,
      stockQuantity: (data['stockQuantity'] as int?) ?? 1,
      additionalImages: List<String>.from(data['additionalImages'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'category': category,
      'rating': rating,
      'ratingCount': ratingCount,
      'isNew': isNew,
      'CreateurId': createurId,
      'tags': tags,
      'colors': colors,
      'size': size,
      'material': material,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isFeatured': isFeatured,
      'stockQuantity': stockQuantity,
      'additionalImages': additionalImages,
    };
  }

  Color? get primaryColor {
    if (colors.isEmpty) return null;
    try {
      return Color(int.parse('0xFF${colors.first.replaceAll('#', '')}'));
    } catch (e) {
      return null;
    }
  }

  String get formattedPrice {
    return NumberFormat.currency(
      symbol: 'XOF',
      decimalDigits: 0,
    ).format(price);
  }

  String get formattedRating {
    return ratingCount > 0
        ? '${rating.toStringAsFixed(1)} ⭐ ($ratingCount avis)'
        : 'Pas encore noté';
  }

  String get stockStatus {
    if (stockQuantity <= 0) return 'Rupture de stock';
    if (stockQuantity < 5) return 'Stock limité';
    return 'En stock';
  }

  CreationModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    double? price,
    String? category,
    double? rating,
    int? ratingCount,
    bool? isNew,
    String? stylistId,
    List<String>? tags,
    List<String>? colors,
    String? size,
    String? material,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isFeatured,
    int? stockQuantity,
    List<String>? additionalImages,
  }) {
    return CreationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      isNew: isNew ?? this.isNew,
      createurId: createurId ?? this.createurId,
      tags: tags ?? this.tags,
      colors: colors ?? this.colors,
      size: size ?? this.size,
      material: material ?? this.material,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFeatured: isFeatured ?? this.isFeatured,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      additionalImages: additionalImages ?? this.additionalImages,
    );
  }

  bool matchesSearch(String query) {
    final searchLower = query.toLowerCase();
    return title.toLowerCase().contains(searchLower) ||
        description.toLowerCase().contains(searchLower) ||
        category.toLowerCase().contains(searchLower) ||
        tags.any((tag) => tag.toLowerCase().contains(searchLower)) ||
        material.toLowerCase().contains(searchLower);
  }
}

