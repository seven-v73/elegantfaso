import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../design/app_icons.dart';
import '../../services/preferences/currency_service.dart';

import 'salon_action.dart';

enum SalonItemType {
  product,
  creation,
  talent,
  event,
  inspiration,
  video,
  article,
}

class SalonItem {
  const SalonItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.ownerId,
    required this.city,
    required this.price,
    required this.tags,
    required this.actions,
    required this.data,
    this.source = '',
    this.url = '',
    this.createdAt,
  });

  final String id;
  final SalonItemType type;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String ownerId;
  final String city;
  final double? price;
  final List<String> tags;
  final List<SalonAction> actions;
  final Map<String, dynamic> data;
  final String source;
  final String url;
  final DateTime? createdAt;

  bool get hasImage => imageUrl.trim().isNotEmpty;
  bool get isLocal => city.trim().isNotEmpty;
  String get country =>
      (data['country'] ?? data['pays'] ?? data['region'] ?? '').toString();
  bool get isOnline =>
      type == SalonItemType.video ||
      data['isOnline'] == true ||
      url.trim().isNotEmpty;
  bool get verified =>
      data['verified'] == true ||
      data['isVerified'] == true ||
      data['verifiedBadge'] == true ||
      activeBusinessPlan ||
      isSignature;
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
  String get certificationLabel => isSignature ? 'Signature' : 'Certifié';
  String get ownerName => _first(data, const [
    'sellerName',
    'creatorName',
    'boutiqueName',
    'ownerName',
    'displayName',
  ], '');

  String get locationLabel {
    final parts = [city, country].where((part) => part.trim().isNotEmpty);
    return parts.isEmpty ? '' : parts.join(', ');
  }

  String get editorialLine {
    return switch (type) {
      SalonItemType.product =>
        priceLabel.isEmpty
            ? 'Pièce repérée dans le Salon'
            : 'Pièce disponible dans le Salon',
      SalonItemType.creation => 'Création d’atelier à explorer',
      SalonItemType.talent => 'Profil public du Salon',
      SalonItemType.event => 'Temps fort à suivre',
      SalonItemType.inspiration => 'Idée à garder pour ton style',
      SalonItemType.video => 'Inspiration à explorer',
      SalonItemType.article => 'Lecture mode sélectionnée',
    };
  }

  String get typeLabel {
    final role = data['salonRole']?.toString().toLowerCase() ?? '';
    return switch (type) {
      SalonItemType.product => 'Produit',
      SalonItemType.creation => 'Création',
      SalonItemType.talent =>
        role.contains('boutique') || role.contains('shop')
            ? 'Boutique'
            : role.contains('createur') || role.contains('creator')
            ? 'Atelier'
            : 'Talent',
      SalonItemType.event => 'Événement',
      SalonItemType.inspiration => 'Inspiration',
      SalonItemType.video => 'Vidéo',
      SalonItemType.article => 'Article',
    };
  }

  String get badgeLabel {
    if (isOnline) return 'En ligne';
    if (isLocal) return 'Local';
    return source.isEmpty ? 'Salon' : source;
  }

  String get priceLabel {
    final value = price;
    if (value == null || value <= 0) return '';
    return CurrencyService.format(value, code: data['currency']?.toString());
  }

  String get searchableText =>
      '$title $subtitle $city $country $source ${tags.join(' ')} ${data.values.join(' ')}'
          .toLowerCase();

  Color get color {
    return switch (type) {
      SalonItemType.product => const Color(0xFFB45309),
      SalonItemType.creation => const Color(0xFF7C3AED),
      SalonItemType.talent => const Color(0xFF0F766E),
      SalonItemType.event => const Color(0xFFDB2777),
      SalonItemType.inspiration => const Color(0xFF2563EB),
      SalonItemType.video => const Color(0xFFDC2626),
      SalonItemType.article => const Color(0xFF475569),
    };
  }

  IconData get icon {
    return switch (type) {
      SalonItemType.product => Icons.local_mall_rounded,
      SalonItemType.creation => Icons.palette_rounded,
      SalonItemType.talent => Icons.groups_2_rounded,
      SalonItemType.event => Icons.event_available_rounded,
      SalonItemType.inspiration => AppIcons.inspiration,
      SalonItemType.video => AppIcons.video,
      SalonItemType.article => AppIcons.article,
    };
  }

  factory SalonItem.product(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SalonItem(
      id: doc.id,
      type: SalonItemType.product,
      title: _first(data, const ['name', 'title'], 'Produit'),
      subtitle: _first(data, const ['category', 'description'], 'Boutique'),
      imageUrl: _first(data, const ['imageUrl', 'coverImage'], ''),
      ownerId: _first(data, const ['sellerId', 'boutiqueId', 'userId'], ''),
      city: _first(data, const ['city', 'ville', 'location'], ''),
      price: (data['price'] as num?)?.toDouble(),
      tags: _list(data['tags'] ?? data['categories']),
      actions: const [
        SalonAction(
          type: SalonActionType.save,
          label: 'Sauvegarder',
          icon: Icons.bookmark_border_rounded,
        ),
        SalonAction(
          type: SalonActionType.buy,
          label: 'Acheter',
          icon: Icons.shopping_bag_rounded,
        ),
        SalonAction(
          type: SalonActionType.creator,
          label: 'Vendeur',
          icon: AppIcons.shop,
        ),
        SalonAction(
          type: SalonActionType.similar,
          label: 'Similaires',
          icon: AppIcons.salon,
        ),
      ],
      createdAt: _date(data['createdAt']),
      data: data,
    );
  }

  factory SalonItem.creation(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final images = data['images'];
    return SalonItem(
      id: doc.id,
      type: SalonItemType.creation,
      title: _first(data, const ['title', 'name'], 'Création'),
      subtitle: _first(data, const [
        'category',
        'style',
        'description',
      ], 'Créateur'),
      imageUrl:
          images is List && images.isNotEmpty
              ? images.first.toString()
              : _first(data, const ['imageUrl', 'coverImage'], ''),
      ownerId: _first(data, const ['createurId', 'sellerId', 'userId'], ''),
      city: _first(data, const ['city', 'ville', 'location'], ''),
      price: (data['price'] as num?)?.toDouble(),
      tags: _list(data['tags'] ?? data['styles']),
      actions: const [
        SalonAction(
          type: SalonActionType.save,
          label: 'Sauvegarder',
          icon: Icons.bookmark_border_rounded,
        ),
        SalonAction(
          type: SalonActionType.tryOn,
          label: 'Essayer',
          icon: Icons.checkroom_rounded,
        ),
        SalonAction(
          type: SalonActionType.creator,
          label: 'Créateur',
          icon: AppIcons.creator,
        ),
        SalonAction(
          type: SalonActionType.similar,
          label: 'Inspirations',
          icon: AppIcons.inspiration,
        ),
      ],
      createdAt: _date(data['createdAt']),
      data: data,
    );
  }

  factory SalonItem.talent(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SalonItem(
      id: doc.id,
      type: SalonItemType.talent,
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
      ownerId: doc.id,
      city: _first(data, const ['city', 'ville', 'country', 'pays'], ''),
      price: null,
      tags: _list(data['tags'] ?? data['skills']),
      actions: const [
        SalonAction(
          type: SalonActionType.save,
          label: 'Suivre',
          icon: Icons.person_add_alt_rounded,
        ),
        SalonAction(
          type: SalonActionType.contact,
          label: 'Contacter',
          icon: Icons.chat_rounded,
        ),
        SalonAction(
          type: SalonActionType.book,
          label: 'Rendez-vous',
          icon: Icons.event_available_rounded,
        ),
        SalonAction(
          type: SalonActionType.similar,
          label: 'Similaires',
          icon: AppIcons.salon,
        ),
      ],
      createdAt: _date(data['createdAt']),
      data: data,
    );
  }

  factory SalonItem.talentRole(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String role,
  }) {
    final data = doc.data() ?? {};
    final isShop =
        role.toLowerCase().contains('boutique') ||
        role.toLowerCase().contains('shop');
    final source = isShop ? 'Boutique' : 'Atelier';
    final roleData = {
      ...data,
      'salonRole': isShop ? 'boutique' : 'createur',
      'publicRole': isShop ? 'boutique' : 'createur',
      'sourceLabel': source,
    };
    return SalonItem(
      id: '${doc.id}:${isShop ? 'boutique' : 'createur'}',
      type: SalonItemType.talent,
      title:
          isShop
              ? _firstPath(data, const [
                'boutiqueName',
                'shopName',
                'shopProfile.name',
                'displayName',
                'name',
              ], 'Boutique')
              : _firstPath(data, const [
                'creatorName',
                'atelierName',
                'creatorProfile.name',
                'displayName',
                'name',
              ], 'Créateur'),
      subtitle:
          isShop
              ? _firstPath(data, const [
                'shopCategory',
                'shopProfile.category',
                'category',
                'speciality',
                'shopProfile.description',
                'bio',
              ], 'Produits & sélection')
              : _firstPath(data, const [
                'speciality',
                'specialty',
                'creatorProfile.specialty',
                'profession',
                'creatorBio',
                'creatorProfile.description',
                'creatorProfile.bio',
                'bio',
              ], 'Créations & sur mesure'),
      imageUrl: _roleImageUrl(data, isShop: isShop),
      ownerId: doc.id,
      city: _first(data, const ['city', 'ville', 'country', 'pays'], ''),
      price: null,
      tags: [
        ..._list(data['tags'] ?? data['skills']),
        if (isShop) ...const [
          'boutique',
          'shop',
          'produits',
          'talent',
          'pro',
        ] else ...const [
          'createur',
          'créateur',
          'atelier',
          'créations',
          'talent',
          'pro',
        ],
      ],
      actions:
          isShop
              ? const [
                SalonAction(
                  type: SalonActionType.save,
                  label: 'Suivre',
                  icon: Icons.person_add_alt_rounded,
                ),
                SalonAction(
                  type: SalonActionType.contact,
                  label: 'Message',
                  icon: Icons.chat_rounded,
                ),
                SalonAction(
                  type: SalonActionType.similar,
                  label: 'Produits',
                  icon: AppIcons.shop,
                ),
              ]
              : const [
                SalonAction(
                  type: SalonActionType.save,
                  label: 'Suivre',
                  icon: Icons.person_add_alt_rounded,
                ),
                SalonAction(
                  type: SalonActionType.contact,
                  label: 'Message',
                  icon: Icons.chat_rounded,
                ),
                SalonAction(
                  type: SalonActionType.book,
                  label: 'RDV',
                  icon: Icons.event_available_rounded,
                ),
                SalonAction(
                  type: SalonActionType.similar,
                  label: 'Créations',
                  icon: AppIcons.creator,
                ),
              ],
      source: source,
      createdAt: _date(data['createdAt']),
      data: roleData,
    );
  }

  factory SalonItem.event(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SalonItem(
      id: doc.id,
      type: SalonItemType.event,
      title: _first(data, const ['title', 'name'], 'Événement mode'),
      subtitle: _first(data, const [
        'description',
        'summary',
        'type',
      ], 'Agenda'),
      imageUrl: _first(data, const ['imageUrl', 'coverImage', 'posterUrl'], ''),
      ownerId: _first(data, const ['organizerId', 'creatorId', 'userId'], ''),
      city: _first(data, const ['city', 'ville', 'venue', 'location'], ''),
      price: (data['price'] as num?)?.toDouble(),
      tags: _list(data['tags'] ?? data['audience']),
      actions: const [
        SalonAction(
          type: SalonActionType.book,
          label: 'Réserver',
          icon: Icons.confirmation_number_rounded,
        ),
        SalonAction(
          type: SalonActionType.save,
          label: 'Rappel',
          icon: Icons.notifications_none_rounded,
        ),
        SalonAction(
          type: SalonActionType.share,
          label: 'Partager',
          icon: Icons.ios_share_rounded,
        ),
        SalonAction(
          type: SalonActionType.similar,
          label: 'Liés',
          icon: Icons.travel_explore_rounded,
        ),
      ],
      url: _first(data, const ['onlineUrl', 'liveUrl', 'url', 'link'], ''),
      createdAt: _date(data['startAt'] ?? data['createdAt']),
      data: data,
    );
  }

  factory SalonItem.inspiration(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SalonItem(
      id: doc.id,
      type: SalonItemType.inspiration,
      title: _first(data, const ['title', 'name'], 'Inspiration'),
      subtitle: _first(data, const [
        'subtitle',
        'description',
        'source',
      ], 'Idée style'),
      imageUrl: _first(data, const [
        'imageUrl',
        'coverImage',
        'thumbnailUrl',
      ], ''),
      ownerId: _first(data, const ['userId', 'creatorId', 'ownerId'], ''),
      city: _first(data, const ['city', 'ville'], ''),
      price: null,
      tags: _list(data['tags']),
      actions: const [
        SalonAction(
          type: SalonActionType.save,
          label: 'Souhaits',
          icon: Icons.bookmark_border_rounded,
        ),
        SalonAction(
          type: SalonActionType.tryOn,
          label: 'Essayer',
          icon: Icons.checkroom_rounded,
        ),
        SalonAction(
          type: SalonActionType.similar,
          label: 'Inspirations',
          icon: AppIcons.inspiration,
        ),
        SalonAction(
          type: SalonActionType.similar,
          label: 'Similaires',
          icon: Icons.travel_explore_rounded,
        ),
      ],
      source: _first(data, const ['source'], 'Inspiration'),
      url: _first(data, const ['url', 'link'], ''),
      createdAt: _date(data['createdAt']),
      data: data,
    );
  }

  factory SalonItem.video({
    required String id,
    required String title,
    required String subtitle,
    required String thumbnailUrl,
    required String url,
    Map<String, dynamic> data = const {},
  }) {
    return SalonItem(
      id: id,
      type: SalonItemType.video,
      title: title,
      subtitle: subtitle,
      imageUrl: thumbnailUrl,
      ownerId: '',
      city: '',
      price: null,
      tags: const ['inspiration', 'style'],
      actions: const [
        SalonAction(
          type: SalonActionType.save,
          label: 'Sauvegarder',
          icon: Icons.bookmark_border_rounded,
        ),
        SalonAction(
          type: SalonActionType.similar,
          label: 'Explorer',
          icon: AppIcons.inspiration,
        ),
        SalonAction(
          type: SalonActionType.share,
          label: 'Partager',
          icon: Icons.ios_share_rounded,
        ),
      ],
      source: 'Salon',
      url: url,
      data: data,
    );
  }

  factory SalonItem.article(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SalonItem(
      id: doc.id,
      type: SalonItemType.article,
      title: _first(data, const ['title', 'name'], 'Article mode'),
      subtitle: _first(data, const [
        'summary',
        'description',
        'source',
      ], 'Lecture mode'),
      imageUrl: _first(data, const [
        'imageUrl',
        'coverImage',
        'thumbnailUrl',
      ], ''),
      ownerId: _first(data, const ['authorId', 'userId'], ''),
      city: _first(data, const ['city', 'country'], ''),
      price: null,
      tags: _list(data['tags']),
      actions: const [
        SalonAction(
          type: SalonActionType.save,
          label: 'Sauvegarder',
          icon: Icons.bookmark_border_rounded,
        ),
        SalonAction(
          type: SalonActionType.share,
          label: 'Partager',
          icon: Icons.ios_share_rounded,
        ),
        SalonAction(
          type: SalonActionType.similar,
          label: 'Liés',
          icon: Icons.travel_explore_rounded,
        ),
      ],
      source: _first(data, const ['source'], 'Article'),
      url: _first(data, const ['url', 'link'], ''),
      createdAt: _date(data['createdAt'] ?? data['publishedAt']),
      data: data,
    );
  }

  factory SalonItem.fromRecentMap(Map<String, dynamic> data) {
    final type = _typeFromString(data['type']?.toString());
    return SalonItem(
      id: data['id']?.toString() ?? '',
      type: type,
      title: data['title']?.toString() ?? 'Contenu Salon',
      subtitle: data['subtitle']?.toString() ?? type.name,
      imageUrl: data['imageUrl']?.toString() ?? '',
      ownerId: data['ownerId']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      price: (data['price'] as num?)?.toDouble(),
      tags: _list(data['tags']),
      actions: _defaultActionsFor(type),
      data: Map<String, dynamic>.from(data['data'] as Map? ?? const {}),
      source: data['source']?.toString() ?? 'Vu récemment',
      url: data['url']?.toString() ?? '',
      createdAt: _date(data['createdAt']),
    );
  }

  Map<String, dynamic> toRecentMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'city': city,
      'price': price,
      'tags': tags,
      'source': source,
      'url': url,
      'createdAt': createdAt?.toIso8601String(),
      'data': {'country': country, 'verified': verified, 'isOnline': isOnline},
    };
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

  static String _firstPath(
    Map<String, dynamic> data,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = _valueAt(data, key)?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  static String _roleImageUrl(
    Map<String, dynamic> data, {
    required bool isShop,
  }) {
    if (isShop) {
      return _firstPath(data, const [
        'boutiqueLogoUrl',
        'boutiquePhotoUrl',
        'boutiqueLogo',
        'shopImage',
        'shopProfile.logoUrl',
        'shopProfile.photoUrl',
        'shopProfile.imageUrl',
        'shopProfile.coverImage',
        'media.shopLogo.url',
        'media.shopLogo.optimizedUrl',
      ], '');
    }
    return _firstPath(data, const [
      'creatorPhotoUrl',
      'creatorImage',
      'atelierImage',
      'creatorProfile.photoUrl',
      'creatorProfile.imageUrl',
      'creatorProfile.coverImage',
      'media.creatorPhoto.url',
      'media.creatorPhoto.optimizedUrl',
    ], '');
  }

  static Object? _valueAt(Map<String, dynamic> data, String path) {
    Object? current = data;
    for (final part in path.split('.')) {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  static List<String> _list(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  static SalonItemType _typeFromString(String? value) {
    return SalonItemType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => SalonItemType.inspiration,
    );
  }

  static List<SalonAction> _defaultActionsFor(SalonItemType type) {
    return switch (type) {
      SalonItemType.product => const [
        SalonAction(
          type: SalonActionType.save,
          label: 'Sauvegarder',
          icon: Icons.bookmark_border_rounded,
        ),
        SalonAction(
          type: SalonActionType.buy,
          label: 'Acheter',
          icon: Icons.shopping_bag_rounded,
        ),
        SalonAction(
          type: SalonActionType.similar,
          label: 'Similaires',
          icon: Icons.travel_explore_rounded,
        ),
      ],
      SalonItemType.talent => const [
        SalonAction(
          type: SalonActionType.save,
          label: 'Suivre',
          icon: Icons.person_add_alt_rounded,
        ),
        SalonAction(
          type: SalonActionType.contact,
          label: 'Contacter',
          icon: Icons.chat_rounded,
        ),
        SalonAction(
          type: SalonActionType.book,
          label: 'Rendez-vous',
          icon: Icons.event_available_rounded,
        ),
      ],
      SalonItemType.event => const [
        SalonAction(
          type: SalonActionType.book,
          label: 'Réserver',
          icon: Icons.confirmation_number_rounded,
        ),
        SalonAction(
          type: SalonActionType.share,
          label: 'Partager',
          icon: Icons.ios_share_rounded,
        ),
      ],
      SalonItemType.video => const [
        SalonAction(
          type: SalonActionType.save,
          label: 'Sauvegarder',
          icon: Icons.bookmark_border_rounded,
        ),
        SalonAction(
          type: SalonActionType.similar,
          label: 'Explorer',
          icon: AppIcons.inspiration,
        ),
      ],
      SalonItemType.creation ||
      SalonItemType.inspiration ||
      SalonItemType.article => const [
        SalonAction(
          type: SalonActionType.save,
          label: 'Sauvegarder',
          icon: Icons.bookmark_border_rounded,
        ),
        SalonAction(
          type: SalonActionType.similar,
          label: 'Similaires',
          icon: Icons.travel_explore_rounded,
        ),
      ],
    };
  }
}
