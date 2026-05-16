import 'package:cloud_firestore/cloud_firestore.dart';

class TalentProfile {
  const TalentProfile({
    required this.id,
    required this.displayName,
    required this.roleLabels,
    required this.photoUrl,
    required this.city,
    required this.country,
    required this.speciality,
    required this.description,
    required this.verified,
    required this.followersCount,
    required this.rating,
    required this.responseTime,
    required this.availabilityStatus,
    required this.creationsCount,
    required this.productsCount,
    required this.phone,
    required this.whatsapp,
    required this.tags,
    required this.languages,
    required this.portfolioImages,
    required this.raw,
  });

  final String id;
  final String displayName;
  final List<String> roleLabels;
  final String photoUrl;
  final String city;
  final String country;
  final String speciality;
  final String description;
  final bool verified;
  final int followersCount;
  final double rating;
  final String responseTime;
  final String availabilityStatus;
  final int creationsCount;
  final int productsCount;
  final String phone;
  final String whatsapp;
  final List<String> tags;
  final List<String> languages;
  final List<String> portfolioImages;
  final Map<String, dynamic> raw;

  bool get isAvailable =>
      availabilityStatus.toLowerCase().contains('disponible') ||
      availabilityStatus.toLowerCase().contains('online') ||
      raw['isOnline'] == true ||
      raw['available'] == true;

  bool get hasPortfolio => portfolioImages.isNotEmpty;
  bool get hasProducts => productsCount > 0;
  bool get hasCreations => creationsCount > 0;
  String get accountId {
    final rawAccountId = raw['accountId']?.toString().trim() ?? '';
    if (rawAccountId.isNotEmpty) return rawAccountId;
    final separator = id.indexOf('__');
    if (separator > 0) return id.substring(0, separator);
    return id;
  }

  String get professionalRole {
    final override =
        raw['displayRoleOverride']?.toString().trim().toLowerCase();
    if (override == 'boutique' || override == 'createur') return override!;
    return primaryRole == 'Boutique' ? 'boutique' : 'createur';
  }

  bool get acceptsAppointments =>
      raw['acceptsAppointments'] == true ||
      raw['appointmentsEnabled'] == true ||
      searchText.contains('rendez');
  bool get madeToMeasure =>
      raw['madeToMeasure'] == true ||
      searchText.contains('sur mesure') ||
      searchText.contains('mesure');

  String get place {
    if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
    if (city.isNotEmpty) return city;
    if (country.isNotEmpty) return country;
    return 'En ligne';
  }

  String get primaryRole {
    final forcedRole = raw['displayRoleOverride']?.toString();
    if (forcedRole == 'boutique') return 'Boutique';
    if (forcedRole == 'createur') return 'Créateur';
    if (roleLabels.contains('Boutique')) return 'Boutique';
    if (searchText.contains('coiff') || searchText.contains('hair')) {
      return 'Coiffure';
    }
    if (searchText.contains('chauss') || searchText.contains('cordonn')) {
      return 'Chaussures';
    }
    if (searchText.contains('maquill')) return 'Maquillage';
    if (roleLabels.contains('Créateur')) return 'Créateur';
    return roleLabels.isEmpty ? 'Talent' : roleLabels.first;
  }

  String get searchText =>
      '$id $displayName ${_rawSearchText(raw)} ${roleLabels.join(' ')} $speciality $description $city $country ${tags.join(' ')} ${languages.join(' ')}'
          .toLowerCase();

  int get relevanceScore {
    var score = followersCount;
    if (verified) score += 80;
    if (hasPortfolio) score += 60;
    if (hasCreations) score += 35;
    if (hasProducts) score += 35;
    if (photoUrl.isNotEmpty) score += 20;
    if (city.isNotEmpty) score += 15;
    if (isAvailable) score += 20;
    if (responseTime.isNotEmpty) score += 12;
    score += (rating * 10).round();
    return score;
  }

  factory TalentProfile.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    int creationsCount = 0,
    int productsCount = 0,
    List<String> portfolioImages = const [],
    String? roleOverride,
  }) {
    final data = doc.data();
    final roleData = {
      ...data,
      if (roleOverride != null) 'displayRoleOverride': roleOverride,
      'accountId': doc.id,
    };
    final isShop = roleOverride == 'boutique';
    return TalentProfile(
      id: roleOverride == null ? doc.id : '${doc.id}__$roleOverride',
      displayName:
          isShop
              ? _first(data, const [
                'boutiqueName',
                'shopProfile.name',
                'displayName',
                'name',
              ], 'Boutique mode')
              : _first(data, const [
                'creatorName',
                'creatorProfile.name',
                'displayName',
                'name',
              ], 'Talent mode'),
      roleLabels:
          roleOverride == null
              ? _roles(data)
              : [isShop ? 'Boutique' : 'Créateur'],
      photoUrl:
          isShop
              ? _first(data, const [
                'boutiquePhotoUrl',
                'boutiqueLogoUrl',
                'shopProfile.logoUrl',
                'photoUrl',
                'photoURL',
                'profileImage',
                'imageUrl',
                'logoUrl',
              ], '')
              : _first(data, const [
                'creatorPhotoUrl',
                'creatorProfile.photoUrl',
                'photoUrl',
                'photoURL',
                'profileImage',
                'imageUrl',
              ], ''),
      city: _first(data, const [
        'city',
        'ville',
        'locationCity',
        'location',
        'boutiqueAddress',
        'shopProfile.address',
        'creatorProfile.location',
      ], ''),
      country: _first(data, const ['country', 'pays', 'region'], ''),
      speciality: _first(data, const [
        'speciality',
        'specialty',
        'category',
        'profession',
        'shopProfile.category',
        'creatorProfile.specialty',
      ], 'Création & style'),
      description: _first(data, const [
        'bio',
        'description',
        'boutiqueDescription',
        'shopProfile.description',
        'creatorProfile.bio',
      ], 'Profil mode disponible dans le Salon.'),
      verified: _verified(data),
      followersCount:
          (data['followersCount'] as num?)?.toInt() ??
          ((data['followers'] is List)
              ? (data['followers'] as List).length
              : 0),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      responseTime: _first(data, const ['responseTime', 'replyDelay'], ''),
      availabilityStatus: _first(data, const [
        'availabilityStatus',
        'status',
        'businessOnboarding.createur.status',
        'businessOnboarding.boutique.status',
      ], data['isOnline'] == true ? 'Disponible' : 'Sur demande'),
      creationsCount: creationsCount,
      productsCount: productsCount,
      phone: _first(data, const ['phone', 'phoneNumber'], ''),
      whatsapp: _first(data, const ['whatsapp', 'whatsApp'], ''),
      tags: _stringList(data['tags'] ?? data['skills']),
      languages: _stringList(data['languages']),
      portfolioImages: portfolioImages,
      raw: roleData,
    );
  }

  factory TalentProfile.fromUserData({
    required String uid,
    required Map<String, dynamic> data,
    int creationsCount = 0,
    int productsCount = 0,
    List<String> portfolioImages = const [],
    String? roleOverride,
  }) {
    final roleData = {
      ...data,
      if (roleOverride != null) 'displayRoleOverride': roleOverride,
      'accountId': uid,
    };
    final isShop = roleOverride == 'boutique';
    return TalentProfile(
      id: roleOverride == null ? uid : '${uid}__$roleOverride',
      displayName:
          isShop
              ? _first(data, const [
                'boutiqueName',
                'shopProfile.name',
                'displayName',
                'name',
              ], 'Boutique mode')
              : _first(data, const [
                'creatorName',
                'creatorProfile.name',
                'displayName',
                'name',
              ], 'Talent mode'),
      roleLabels:
          roleOverride == null
              ? _roles(data)
              : [isShop ? 'Boutique' : 'Créateur'],
      photoUrl:
          isShop
              ? _first(data, const [
                'boutiquePhotoUrl',
                'boutiqueLogoUrl',
                'shopProfile.logoUrl',
                'photoUrl',
                'photoURL',
                'profileImage',
                'imageUrl',
                'logoUrl',
              ], '')
              : _first(data, const [
                'creatorPhotoUrl',
                'creatorProfile.photoUrl',
                'photoUrl',
                'photoURL',
                'profileImage',
                'imageUrl',
              ], ''),
      city: _first(data, const [
        'city',
        'ville',
        'locationCity',
        'location',
        'boutiqueAddress',
        'shopProfile.address',
        'creatorProfile.location',
      ], ''),
      country: _first(data, const ['country', 'pays', 'region'], ''),
      speciality: _first(data, const [
        'speciality',
        'specialty',
        'category',
        'profession',
        'shopProfile.category',
        'creatorProfile.specialty',
      ], 'Création & style'),
      description: _first(data, const [
        'bio',
        'description',
        'boutiqueDescription',
        'shopProfile.description',
        'creatorProfile.bio',
      ], 'Profil mode disponible dans le Salon.'),
      verified: _verified(data),
      followersCount:
          (data['followersCount'] as num?)?.toInt() ??
          ((data['followers'] is List)
              ? (data['followers'] as List).length
              : 0),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      responseTime: _first(data, const ['responseTime', 'replyDelay'], ''),
      availabilityStatus: _first(data, const [
        'availabilityStatus',
        'status',
        'businessOnboarding.createur.status',
        'businessOnboarding.boutique.status',
      ], data['isOnline'] == true ? 'Disponible' : 'Sur demande'),
      creationsCount: creationsCount,
      productsCount: productsCount,
      phone: _first(data, const ['phone', 'phoneNumber'], ''),
      whatsapp: _first(data, const ['whatsapp', 'whatsApp'], ''),
      tags: _stringList(data['tags'] ?? data['skills']),
      languages: _stringList(data['languages']),
      portfolioImages: portfolioImages,
      raw: roleData,
    );
  }

  factory TalentProfile.fromSalonPlaceDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    int creationsCount = 0,
    int productsCount = 0,
    List<String> portfolioImages = const [],
    Map<String, dynamic> ownerData = const {},
  }) {
    final data = doc.data();
    final enrichedData = {...ownerData, ...data};
    final verificationData = {...ownerData, ...data};
    final ownerId =
        data['ownerId']?.toString() ??
        data['userId']?.toString() ??
        data['accountId']?.toString() ??
        '';
    final type = data['type']?.toString().toLowerCase() ?? '';
    final roleOverride =
        type.contains('boutique') || type.contains('shop')
            ? 'boutique'
            : 'createur';
    final isShop = roleOverride == 'boutique';
    final roleData = {
      ...data,
      'accountId': ownerId,
      'displayRoleOverride': roleOverride,
      'isPublic': true,
      'publicProfile': true,
      'publicRole': roleOverride,
      if (ownerData['roles'] != null) 'roles': ownerData['roles'],
      if (ownerData['roleFlags'] != null) 'roleFlags': ownerData['roleFlags'],
      if (ownerData['businessOnboarding'] != null)
        'businessOnboarding': ownerData['businessOnboarding'],
      if (ownerData['businessEntitlements'] != null)
        'businessEntitlements': ownerData['businessEntitlements'],
      if (ownerData['certificationBadge'] != null)
        'certificationBadge': ownerData['certificationBadge'],
      if (ownerData['certifiedProfessional'] != null)
        'certifiedProfessional': ownerData['certifiedProfessional'],
      if (ownerData['verifiedBadge'] != null)
        'verifiedBadge': ownerData['verifiedBadge'],
    };

    return TalentProfile(
      id: doc.id,
      displayName:
          isShop
              ? _first(enrichedData, const [
                'boutiqueName',
                'shopProfile.name',
                'name',
                'title',
              ], 'Boutique mode')
              : _first(enrichedData, const [
                'creatorName',
                'creatorProfile.name',
                'name',
                'title',
              ], 'Créateur mode'),
      roleLabels: [isShop ? 'Boutique' : 'Créateur'],
      photoUrl:
          isShop
              ? _first(enrichedData, const [
                'imageUrl',
                'boutiqueLogoUrl',
                'boutiquePhotoUrl',
                'shopProfile.logoUrl',
                'photoUrl',
                'logoUrl',
              ], '')
              : _first(enrichedData, const [
                'imageUrl',
                'creatorPhotoUrl',
                'creatorProfile.photoUrl',
                'photoUrl',
              ], ''),
      city: _first(enrichedData, const [
        'city',
        'creatorProfile.city',
        'shopProfile.city',
        'address',
        'locationLabel',
      ], ''),
      country: _first(enrichedData, const [
        'country',
        'creatorProfile.country',
        'shopProfile.country',
        'pays',
      ], ''),
      speciality:
          isShop
              ? _first(enrichedData, const [
                'subtitle',
                'boutiqueDescription',
                'shopProfile.description',
                'shopProfile.category',
                'speciality',
                'category',
              ], 'Boutique mode')
              : _first(enrichedData, const [
                'subtitle',
                'specialty',
                'creatorProfile.specialty',
                'creatorProfile.description',
                'creatorProfile.bio',
                'speciality',
              ], 'Création & style'),
      description:
          isShop
              ? _first(enrichedData, const [
                'description',
                'boutiqueDescription',
                'shopProfile.description',
                'bio',
                'subtitle',
              ], 'Profil boutique disponible dans le Salon.')
              : _first(enrichedData, const [
                'description',
                'creatorProfile.description',
                'creatorProfile.bio',
                'bio',
                'subtitle',
              ], 'Profil créateur disponible dans le Salon.'),
      verified: _verified(verificationData),
      followersCount: (data['followersCount'] as num?)?.toInt() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      responseTime: _first(data, const ['responseTime', 'replyDelay'], ''),
      availabilityStatus:
          data['openNow'] == true || data['availableNow'] == true
              ? 'Disponible'
              : 'Sur demande',
      creationsCount: creationsCount,
      productsCount: productsCount,
      phone: _first(data, const ['phone', 'phoneNumber'], ''),
      whatsapp: _first(enrichedData, const ['whatsapp', 'whatsApp'], ''),
      tags: [
        ..._stringList(enrichedData['tags']),
        ..._stringList(enrichedData['competences']),
        ..._stringList(enrichedData['specialities']),
      ],
      languages: _stringList(enrichedData['languages']),
      portfolioImages: portfolioImages,
      raw: roleData,
    );
  }

  static String _first(
    Map<String, dynamic> data,
    List<String> fields,
    String fallback,
  ) {
    for (final field in fields) {
      final value = _valueAt(data, field)?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  static dynamic _valueAt(Map<String, dynamic> data, String path) {
    if (!path.contains('.')) return data[path];
    dynamic current = data;
    for (final segment in path.split('.')) {
      if (current is! Map) return null;
      current = current[segment];
    }
    return current;
  }

  static List<String> _roles(Map<String, dynamic> data) {
    final result = <String>{};
    void add(String value) {
      final normalized = value.trim().toLowerCase();
      if (normalized.contains('boutique')) result.add('Boutique');
      if (normalized.contains('createur') || normalized.contains('creator')) {
        result.add('Créateur');
      }
      if (normalized.contains('client')) return;
    }

    final role = data['role'];
    final activeRole = data['activeRole'];
    final publicRole = data['publicRole'];
    final roles = data['roles'];
    if (role != null) add(role.toString());
    if (activeRole != null) add(activeRole.toString());
    if (publicRole != null) add(publicRole.toString());
    if (roles is Iterable) {
      for (final item in roles) {
        add(item.toString());
      }
    }
    if (roles is Map) {
      if (roles['createur'] == true || roles['creator'] == true) {
        result.add('Créateur');
      }
      if (roles['boutique'] == true) result.add('Boutique');
    }
    final roleFlags = data['roleFlags'];
    if (roleFlags is Map) {
      if (roleFlags['isCreator'] == true) result.add('Créateur');
      if (roleFlags['isShop'] == true) result.add('Boutique');
    }
    final onboarding = data['businessOnboarding'];
    if (onboarding is Map) {
      final creator = onboarding['createur'];
      final boutique = onboarding['boutique'];
      if (creator is Map && creator['status'] == 'active') {
        result.add('Créateur');
      }
      if (boutique is Map && boutique['status'] == 'active') {
        result.add('Boutique');
      }
    }
    final text =
        '${data['speciality']} ${data['specialty']} ${data['profession']} ${data['category']} ${_valueAt(data, 'shopProfile.category')} ${_valueAt(data, 'creatorProfile.specialty')}'
            .toLowerCase();
    if (text.contains('coiff')) result.add('Coiffure');
    if (text.contains('chauss') || text.contains('cordonn')) {
      result.add('Chaussures');
    }
    if (text.contains('maquill')) result.add('Maquillage');
    if (result.isEmpty && text.contains('mode')) result.add('Créateur');
    return result.toList();
  }

  static List<String> _stringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static String _rawSearchText(Map<String, dynamic> data) {
    final values = [
      data['creatorName'],
      data['boutiqueName'],
      data['publicRole'],
      data['location'],
      data['boutiqueAddress'],
      data['shopProfile'],
      data['creatorProfile'],
      data['businessOnboarding'],
      data['businessEntitlements'],
      data['certificationBadge'],
      data['certifiedProfessional'],
      data['verifiedBadge'],
      data['roleFlags'],
    ];
    return values
        .where((value) => value != null)
        .map((value) => value.toString())
        .join(' ');
  }

  static bool _verified(Map<String, dynamic> data) {
    if (data['isVerified'] == true ||
        data['verified'] == true ||
        data['verifiedBadge'] == true) {
      return true;
    }

    final entitlements = _valueAt(data, 'businessEntitlements');
    if (entitlements is Map) {
      final status = entitlements['status']?.toString().toLowerCase() ?? '';
      final plan = entitlements['plan']?.toString().toLowerCase() ?? '';
      final expiresAt = _dateFrom(entitlements['expiresAt']);
      final valid = expiresAt != null && expiresAt.isAfter(DateTime.now());
      final entitlementBadge =
          entitlements['certificationBadge']?.toString().trim() ?? '';
      final activePlan =
          status == 'active' &&
          valid &&
          (plan == 'pro' || plan == 'premium' || plan == 'signature');
      return activePlan &&
          (entitlements['verifiedBadge'] == true ||
              entitlementBadge.isNotEmpty && entitlementBadge != 'none' ||
              data['certifiedProfessional'] == true);
    }

    return false;
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
