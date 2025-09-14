import 'package:cloud_firestore/cloud_firestore.dart';

class Creation {
  final String? id;
  final String createurId;
  final String title;
  final String description;
  final String category;
  final List<String> images;
  final double price;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Creation({
    this.id,
    required this.createurId,
    required this.title,
    required this.description,
    required this.category,
    required this.images,
    this.price = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Firestore-compatible Map
  Map<String, dynamic> toJson() {
    return {
      'createurId': createurId,
      'title': title,
      'description': description,
      'category': category,
      'images': images,
      'price': price,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  // Create from Firestore DocumentSnapshot
  factory Creation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Creation(
      id: doc.id,
      createurId: data['createurId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'Autre',
      images: (data['images'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  // Create from JSON (alternative for non-Firestore sources)
  factory Creation.fromJson(Map<String, dynamic> json, {String? id}) {
    return Creation(
      id: id,
      createurId: json['createurId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Autre',
      images: (json['images'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  // Helper for creating copies with modified values
  Creation copyWith({
    String? id,
    String? createurId,
    String? title,
    String? description,
    String? category,
    List<String>? images,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Creation(
      id: id ?? this.id,
      createurId: createurId ?? this.createurId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      images: images ?? this.images,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Creation{id: $id, title: $title, category: $category, images: ${images.length}}';
  }
}