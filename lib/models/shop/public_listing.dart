import 'package:cloud_firestore/cloud_firestore.dart';

import '../try_on/try_on_compatibility.dart';
import 'product_variant.dart';

class PublicListing {
  const PublicListing({
    required this.id,
    required this.type,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.sellerId,
    required this.data,
    this.description = '',
    this.category = '',
    this.stock,
    this.variants = const [],
  });

  final String id;
  final String type;
  final String title;
  final String imageUrl;
  final double price;
  final String sellerId;
  final Map<String, dynamic> data;
  final String description;
  final String category;
  final int? stock;
  final List<ProductVariant> variants;

  bool get isProduct => type == 'product';
  bool get isCreation => type == 'creation';
  bool get isSecondhand => type == 'secondhand';
  bool get hasStock => stock == null || stock! > 0;
  bool get needsVariant =>
      variants.isNotEmpty || sizes.isNotEmpty || colors.isNotEmpty;
  bool get canTryOn {
    if (data['tryOnEnabled'] == true) return true;
    if (data['tryOnEnabled'] == false) return false;
    final compatibility = TryOnCompatibility.fromSource(
      title: title,
      subtitle: [category, description].where((v) => v.isNotEmpty).join(' '),
      sourceType: type,
      raw: data,
    );
    return compatibility.kind != TryOnPieceKind.unknown;
  }

  List<String> get sizes => _stringList(data['sizes'] ?? data['tailles']);
  List<String> get colors => _stringList(data['colors'] ?? data['couleurs']);
  String get currency => data['currency']?.toString() ?? 'XOF';

  String get badgeLabel {
    switch (type) {
      case 'hairstyle':
      case 'coiffure':
        return 'Coiffure';
      case 'shoe':
      case 'chaussure':
        return 'Chaussure';
      case 'accessory':
      case 'accessoire':
        return 'Accessoire';
      case 'creation':
        return 'Créateur';
      case 'secondhand':
        return 'Vide-dressing';
      default:
        return 'Boutique';
    }
  }

  String get searchableText =>
      [
        title,
        category,
        description,
        data['name'],
        data['category'],
        data['description'],
        data['fabric'],
        data['style'],
        data['occasion'],
        data['creatorName'],
        data['createurName'],
        data['sellerName'],
        data['condition'],
        data['size'],
        data['color'],
        data['city'],
        data['location'],
      ].whereType<Object>().join(' ').toLowerCase();

  factory PublicListing.product(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final itemType = data['type']?.toString().trim();
    return PublicListing(
      id: doc.id,
      type: itemType == null || itemType.isEmpty ? 'product' : itemType,
      title: data['name']?.toString() ?? 'Produit sans nom',
      imageUrl: _firstImage([
        _itemMedia(data['media']),
        data['imageUrls'],
        data['images'],
        data['coverImage'],
        data['thumbnailUrl'],
        data['imageUrl'],
      ]),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      sellerId:
          data['boutiqueId']?.toString() ?? data['sellerId']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      stock: _int(data['stock'] ?? data['quantity']),
      variants: _variants(data),
      data: data,
    );
  }

  factory PublicListing.creation(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PublicListing(
      id: doc.id,
      type: 'creation',
      title: data['title']?.toString() ?? 'Création sans titre',
      imageUrl: _firstImage([
        _itemMedia(data['media']),
        data['images'],
        data['imageUrls'],
        data['coverImage'],
        data['coverUrl'],
        data['thumbnailUrl'],
        data['imageUrl'],
      ]),
      price:
          (data['price'] as num?)?.toDouble() ??
          (data['startingPrice'] as num?)?.toDouble() ??
          (data['priceFrom'] as num?)?.toDouble() ??
          0,
      sellerId:
          data['createurId']?.toString() ??
          data['creatorId']?.toString() ??
          data['sellerId']?.toString() ??
          data['ownerId']?.toString() ??
          '',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      stock: _int(data['stock'] ?? data['quantity']),
      variants: _variants(data),
      data: data,
    );
  }

  factory PublicListing.secondhand(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final status = data['status']?.toString() ?? 'available';
    return PublicListing(
      id: doc.id,
      type: 'secondhand',
      title: data['title']?.toString() ?? 'Pièce vide-dressing',
      imageUrl: _firstImage([
        data['imageUrls'],
        data['images'],
        data['coverImage'],
        data['thumbnailUrl'],
        data['imageUrl'],
      ]),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      sellerId: data['sellerId']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      stock: status == 'available' ? 1 : 0,
      data: {
        ...data,
        'type': 'secondhand',
        'role': 'client',
        'collection': 'secondhand_listings',
        'source': 'vide_dressing',
      },
    );
  }

  static int? _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _firstImage(List<Object?> values) {
    for (final value in values) {
      final url = _cleanImageUrl(value);
      if (url.isNotEmpty) return url;
    }
    return '';
  }

  static Object? _itemMedia(Object? media) {
    if (media is! Map) return media;
    return [
      media['cover'],
      media['main'],
      media['primary'],
      media['product'],
      media['creation'],
      media['gallery'],
      media['images'],
      media['imageUrls'],
      media['coverUrl'],
      media['imageUrl'],
      media['coverImage'],
      media['thumbnailUrl'],
      media['optimizedUrl'],
      media['secureUrl'],
    ];
  }

  static String _cleanImageUrl(Object? value) {
    if (value == null) return '';
    if (value is Iterable) {
      for (final item in value) {
        final url = _cleanImageUrl(item);
        if (url.isNotEmpty) return url;
      }
      return '';
    }
    if (value is Map) {
      for (final key in const [
        'optimizedUrl',
        'thumbnailUrl',
        'secureUrl',
        'coverUrl',
        'imageUrl',
        'url',
        'coverImage',
      ]) {
        final url = _cleanImageUrl(value[key]);
        if (url.isNotEmpty) return url;
      }
      return '';
    }
    final url = value.toString().trim();
    if ((url.startsWith('http://') || url.startsWith('https://')) &&
        !_looksLikeProfileImage(url)) {
      return url;
    }
    return '';
  }

  static bool _looksLikeProfileImage(String url) {
    final value = url.toLowerCase();
    return value.contains('/profiles/') ||
        value.contains('/profile_') ||
        value.contains('/avatar_') ||
        value.contains('/shops/') && value.contains('/logo_') ||
        value.contains('/createur/') && value.contains('/profile_') ||
        value.contains('/users/') && value.contains('/avatar_');
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<ProductVariant> _variants(Map<String, dynamic> data) {
    final raw = data['variants'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map(
            (item) => ProductVariant.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
    return const [];
  }
}
