import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/preferences/currency_service.dart';

enum SalonHighlightType { product, creation, talent, event, inspiration }

class SalonHighlight {
  const SalonHighlight({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.actionLabel,
    required this.searchText,
    required this.data,
    this.price,
    this.city = '',
    this.createdAt,
    this.proPriority = false,
  });

  final String id;
  final SalonHighlightType type;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String actionLabel;
  final String searchText;
  final Map<String, dynamic> data;
  final double? price;
  final String city;
  final DateTime? createdAt;
  final bool proPriority;

  bool get hasImage => imageUrl.trim().isNotEmpty;
  bool get isSignature {
    final tier = data['visibilityTier']?.toString().toLowerCase() ?? '';
    final badge = data['certificationBadge']?.toString().toLowerCase() ?? '';
    final entitlements = data['businessEntitlements'];
    final plan =
        entitlements is Map
            ? entitlements['plan']?.toString().toLowerCase() ?? ''
            : '';
    return activeBusinessPlan &&
        (tier == 'signature' ||
            badge == 'signature' ||
            plan == 'premium' ||
            plan == 'signature');
  }

  bool get isFeatured => data['isFeatured'] == true || isSignature;
  bool get isProduct => type == SalonHighlightType.product;
  bool get isCreation => type == SalonHighlightType.creation;
  String get priceLabel {
    final value = price;
    if (value == null || value <= 0) return '';
    return CurrencyService.format(value, code: data['currency']?.toString());
  }

  bool get isProListing {
    final tier =
        data['sellerPlan']?.toString().toLowerCase() ??
        data['plan']?.toString().toLowerCase() ??
        data['visibilityTier']?.toString().toLowerCase() ??
        '';
    return proPriority ||
        activeBusinessPlan ||
        (activeBusinessPlan &&
            (tier == 'pro' || tier == 'premium' || tier == 'signature'));
  }

  bool get activeBusinessPlan {
    final entitlements = data['businessEntitlements'];
    if (entitlements is! Map) return false;
    final status = entitlements['status']?.toString().toLowerCase() ?? '';
    final plan = entitlements['plan']?.toString().toLowerCase() ?? '';
    final expiresAt = _date(entitlements['expiresAt']);
    final valid = expiresAt != null && expiresAt.isAfter(DateTime.now());
    return status == 'active' &&
        valid &&
        (plan == 'pro' || plan == 'premium' || plan == 'signature');
  }

  SalonHighlight copyWith({bool? proPriority}) {
    return SalonHighlight(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      actionLabel: actionLabel,
      searchText: searchText,
      data: data,
      price: price,
      city: city,
      createdAt: createdAt,
      proPriority: proPriority ?? this.proPriority,
    );
  }

  String get typeLabel {
    return switch (type) {
      SalonHighlightType.product => 'Produit',
      SalonHighlightType.creation => 'Création',
      SalonHighlightType.talent => 'Talent',
      SalonHighlightType.event => 'Événement',
      SalonHighlightType.inspiration => 'Inspiration',
    };
  }

  factory SalonHighlight.product(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return SalonHighlight(
      id: doc.id,
      type: SalonHighlightType.product,
      title: _first(data, const ['name', 'title'], 'Produit'),
      subtitle: _first(data, const ['category', 'description'], 'Boutique'),
      imageUrl: _first(data, const ['imageUrl', 'coverImage'], ''),
      actionLabel: 'Voir produit',
      price: (data['price'] as num?)?.toDouble(),
      city: _first(data, const ['city', 'location', 'ville'], ''),
      createdAt: _date(data['createdAt']),
      searchText: _search(data, doc.id),
      data: data,
    );
  }

  factory SalonHighlight.creation(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final images = data['images'];
    return SalonHighlight(
      id: doc.id,
      type: SalonHighlightType.creation,
      title: _first(data, const ['title', 'name'], 'Création'),
      subtitle: _first(data, const ['category', 'style'], 'Créateur'),
      imageUrl:
          images is List && images.isNotEmpty
              ? images.first.toString()
              : _first(data, const ['imageUrl', 'coverImage'], ''),
      actionLabel: 'Voir création',
      price: (data['price'] as num?)?.toDouble(),
      city: _first(data, const ['city', 'location', 'ville'], ''),
      createdAt: _date(data['createdAt']),
      searchText: _search(data, doc.id),
      data: data,
    );
  }

  factory SalonHighlight.talent(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return SalonHighlight(
      id: doc.id,
      type: SalonHighlightType.talent,
      title: _first(data, const [
        'displayName',
        'name',
        'boutiqueName',
        'creatorName',
      ], 'Talent mode'),
      subtitle: _first(data, const [
        'speciality',
        'profession',
        'category',
        'bio',
      ], 'Création & style'),
      imageUrl: _first(data, const [
        'photoUrl',
        'photoURL',
        'profileImage',
        'imageUrl',
        'logoUrl',
      ], ''),
      actionLabel: 'Voir profil',
      city: _first(data, const ['city', 'ville', 'country', 'pays'], ''),
      createdAt: _date(data['createdAt']),
      searchText: _search(data, doc.id),
      data: data,
    );
  }

  factory SalonHighlight.event(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return SalonHighlight(
      id: doc.id,
      type: SalonHighlightType.event,
      title: _first(data, const ['title', 'name'], 'Événement mode'),
      subtitle: _first(data, const [
        'type',
        'category',
        'description',
      ], 'Agenda'),
      imageUrl: _first(data, const ['imageUrl', 'coverImage', 'posterUrl'], ''),
      actionLabel: 'Voir agenda',
      city: _first(data, const ['city', 'location', 'venue'], ''),
      createdAt: _date(data['startAt'] ?? data['createdAt']),
      searchText: _search(data, doc.id),
      data: data,
    );
  }

  static String _first(
    Map<String, dynamic> data,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _search(Map<String, dynamic> data, String id) {
    return [
      id,
      ...data.values.whereType<Object>().map((value) => value.toString()),
    ].join(' ').toLowerCase();
  }
}
