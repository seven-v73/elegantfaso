import 'package:cloud_firestore/cloud_firestore.dart';

class CreationModel {
  final String id;
  final String createurId;
  final String title;
  final String description;
  final String category;
  final double price;
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final int ordersCount;
  final Timestamp createdAt;
  final bool isAvailable;
  final List<String> tags;
  final List<String> materials;
  final List<String> sizes;
  final List<String> colors;

  CreationModel({
    required this.id,
    required this.createurId,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.ordersCount = 0,
    required this.createdAt,
    this.isAvailable = true,
    this.tags = const [],
    this.materials = const [],
    this.sizes = const [],
    this.colors = const [],
  });

  // Convert Firestore Document to CreationModel
  factory CreationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CreationModel(
      id: doc.id,
      createurId: data['createurId'] ?? '',
      title: data['title'] ?? 'Sans titre',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Autre',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewsCount: data['reviewsCount'] ?? 0,
      ordersCount: data['ordersCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isAvailable: data['isAvailable'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      materials: List<String>.from(data['materials'] ?? []),
      sizes: List<String>.from(data['sizes'] ?? []),
      colors: List<String>.from(data['colors'] ?? []),
    );
  }

  // Convert CreationModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'createurId': createurId,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'ordersCount': ordersCount,
      'createdAt': createdAt,
      'isAvailable': isAvailable,
      'tags': tags,
      'materials': materials,
      'sizes': sizes,
      'colors': colors,
    };
  }

  // Helper method to get formatted price
  String get formattedPrice {
    return '${price.toStringAsFixed(0)} XOF';
  }

  // Helper method to get creation age
  String get creationAge {
    final now = DateTime.now();
    final difference = now.difference(createdAt.toDate());

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years an${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months mois';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    }
    return 'À l\'instant';
  }

  // Copy with method for updates
  CreationModel copyWith({
    String? id,
    String? createurId,
    String? title,
    String? description,
    String? category,
    double? price,
    String? imageUrl,
    double? rating,
    int? reviewsCount,
    int? ordersCount,
    Timestamp? createdAt,
    bool? isAvailable,
    List<String>? tags,
    List<String>? materials,
    List<String>? sizes,
    List<String>? colors,
  }) {
    return CreationModel(
      id: id ?? this.id,
      createurId: createurId ?? this.createurId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      ordersCount: ordersCount ?? this.ordersCount,
      createdAt: createdAt ?? this.createdAt,
      isAvailable: isAvailable ?? this.isAvailable,
      tags: tags ?? this.tags,
      materials: materials ?? this.materials,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
    );
  }
}