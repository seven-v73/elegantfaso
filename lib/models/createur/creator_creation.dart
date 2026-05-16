import 'package:cloud_firestore/cloud_firestore.dart';

class CreatorCreation {
  const CreatorCreation({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.category,
    required this.images,
    required this.price,
    required this.currency,
    required this.stock,
    required this.status,
    required this.visibility,
    required this.viewsCount,
    required this.savesCount,
    required this.requestsCount,
    required this.createdAt,
    required this.updatedAt,
    required this.raw,
  });

  final String id;
  final String creatorId;
  final String title;
  final String description;
  final String category;
  final List<String> images;
  final double price;
  final String currency;
  final int? stock;
  final String status;
  final String visibility;
  final int viewsCount;
  final int savesCount;
  final int requestsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  String get coverImage => images.isEmpty ? '' : images.first;
  bool get isPublished => status == 'published' || visibility == 'salon';
  bool get isDraft => status == 'draft';
  bool get isHidden => status == 'hidden' || visibility == 'private';
  bool get hasManagedStock => stock != null;
  bool get isOutOfStock => hasManagedStock && stock! <= 0;
  bool get isLowStock => hasManagedStock && stock! > 0 && stock! <= 3;
  bool get isVisibleInSalon => isPublished && !isHidden;

  String get statusLabel {
    if (isOutOfStock) return 'Rupture';
    if (isDraft) return 'Brouillon';
    if (isHidden) return 'Masquée';
    if (isVisibleInSalon) return 'Visible Salon';
    return 'Création';
  }

  factory CreatorCreation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawImages = data['images'];
    final images =
        <String>[
          if (data['imageUrl']?.toString().trim().isNotEmpty == true)
            data['imageUrl'].toString(),
          if (rawImages is Iterable)
            ...rawImages.map((item) => item.toString()),
        ].where((item) => item.trim().isNotEmpty).toSet().toList();

    return CreatorCreation(
      id: doc.id,
      creatorId:
          data['createurId']?.toString() ??
          data['creatorId']?.toString() ??
          data['ownerId']?.toString() ??
          '',
      title:
          data['title']?.toString() ?? data['name']?.toString() ?? 'Création',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Autre',
      images: images,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: data['currency']?.toString() ?? 'XOF',
      stock:
          (data['stock'] as num?)?.toInt() ??
          (data['quantity'] as num?)?.toInt(),
      status: data['status']?.toString() ?? 'published',
      visibility: data['visibility']?.toString() ?? 'salon',
      viewsCount: (data['viewsCount'] as num?)?.toInt() ?? 0,
      savesCount:
          (data['savesCount'] as num?)?.toInt() ??
          (data['wishlistCount'] as num?)?.toInt() ??
          0,
      requestsCount: (data['requestsCount'] as num?)?.toInt() ?? 0,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      raw: data,
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
