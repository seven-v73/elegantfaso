import 'package:cloud_firestore/cloud_firestore.dart';

class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.boutiqueId,
    required this.name,
    required this.description,
    required this.images,
    required this.price,
    required this.currency,
    required this.stock,
    required this.category,
    required this.status,
    required this.visibility,
    required this.viewsCount,
    required this.salesCount,
    required this.createdAt,
    required this.updatedAt,
    required this.raw,
  });

  final String id;
  final String boutiqueId;
  final String name;
  final String description;
  final List<String> images;
  final double price;
  final String currency;
  final int stock;
  final String category;
  final String status;
  final String visibility;
  final int viewsCount;
  final int salesCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  String get coverImage => images.isEmpty ? '' : images.first;
  bool get isPublished => status == 'published' || visibility == 'salon';
  bool get isDraft => status == 'draft';
  bool get isHidden => status == 'hidden' || visibility == 'private';
  bool get isOutOfStock => stock <= 0 || status == 'outOfStock';
  bool get isLowStock => stock > 0 && stock <= 3;
  bool get hasPromotion =>
      raw['promotionActive'] == true ||
      raw['discountPercentage'] != null ||
      raw['promoId'] != null;

  String get statusLabel {
    if (isOutOfStock) return 'Rupture';
    if (isDraft) return 'Brouillon';
    if (isHidden) return 'Masqué';
    if (isPublished) return 'Visible Salon';
    return 'Produit';
  }

  factory ShopProduct.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawImages = data['images'];
    final images =
        <String>[
          if (data['imageUrl']?.toString().trim().isNotEmpty == true)
            data['imageUrl'].toString(),
          if (rawImages is Iterable)
            ...rawImages.map((item) => item.toString()),
        ].where((item) => item.trim().isNotEmpty).toSet().toList();

    return ShopProduct(
      id: doc.id,
      boutiqueId:
          data['boutiqueId']?.toString() ?? data['sellerId']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Produit',
      description: data['description']?.toString() ?? '',
      images: images,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: data['currency']?.toString() ?? 'XOF',
      stock:
          (data['stock'] as num?)?.toInt() ??
          (data['quantity'] as num?)?.toInt() ??
          0,
      category: data['category']?.toString() ?? 'Autre',
      status: data['status']?.toString() ?? 'published',
      visibility: data['visibility']?.toString() ?? 'salon',
      viewsCount: (data['viewsCount'] as num?)?.toInt() ?? 0,
      salesCount: (data['salesCount'] as num?)?.toInt() ?? 0,
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
