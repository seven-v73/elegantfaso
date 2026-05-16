import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/account_roles.dart';
import '../../models/talent/talent_filter.dart';
import '../../models/talent/talent_portfolio_item.dart';
import '../../models/talent/talent_profile.dart';
import '../salon/salon_boost_service.dart';

class TalentService {
  TalentService({FirebaseFirestore? firestore, SalonBoostService? boostService})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _boostService = boostService ?? SalonBoostService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final SalonBoostService _boostService;

  Stream<List<TalentProfile>> watchPublicTalents({
    String query = '',
    TalentFilter filter = const TalentFilter(),
  }) {
    return _firestore
        .collection('salon_places')
        .where('isPublic', isEqualTo: true)
        .limit(160)
        .snapshots()
        .asyncMap((snapshot) async {
          final boosts = await _boostService.loadActiveBoostIndex();
          final portfolioIndex = await _loadPortfolioIndex();
          final talentsById = <String, TalentProfile>{};
          final placeDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            if (_isAdminUser(data)) continue;
            final type = data['type']?.toString().toLowerCase() ?? '';
            final publicRole =
                data['publicRole']?.toString().toLowerCase() ?? '';
            final isTalentPlace =
                type.contains('boutique') ||
                type.contains('createur') ||
                type.contains('creator') ||
                type.contains('coiff') ||
                type.contains('cordonn') ||
                publicRole.contains('boutique') ||
                publicRole.contains('createur') ||
                publicRole.contains('creator');
            if (!isTalentPlace) continue;
            placeDocs.add(doc);
          }

          final ownerDataById = await _loadUserDataByIds(
            placeDocs
                .map((doc) => _ownerIdFromPlace(doc.data()))
                .where((id) => id.isNotEmpty)
                .toSet(),
          );

          for (final doc in placeDocs) {
            final data = doc.data();
            final ownerId = _ownerIdFromPlace(data);
            final ownerData = ownerDataById[ownerId] ?? const {};
            final mergedData = {...ownerData, ...data};
            final role =
                (data['type']?.toString().toLowerCase() ?? '').contains(
                          'boutique',
                        ) ||
                        (data['type']?.toString().toLowerCase() ?? '').contains(
                          'shop',
                        )
                    ? AccountRoles.boutique
                    : AccountRoles.createur;
            final enriched = TalentProfile.fromSalonPlaceDoc(
              doc,
              creationsCount:
                  role == AccountRoles.createur
                      ? _creationCountFromData(mergedData) +
                          (portfolioIndex[ownerId]?.creationsCount ?? 0)
                      : 0,
              productsCount:
                  role == AccountRoles.boutique
                      ? _productCountFromData(mergedData) +
                          (portfolioIndex[ownerId]?.productsCount ?? 0)
                      : 0,
              portfolioImages: _mergedPortfolioImages(
                portfolioIndex[ownerId]?.imagesForRole(role) ?? const [],
                _portfolioImagesFromData(mergedData, role),
              ),
              ownerData: ownerData,
            );
            if (_matches(enriched, query, filter)) {
              talentsById[enriched.id] = enriched;
            }
          }

          final userTalents = await _loadUserTalentsFallback(
            query,
            filter,
            portfolioIndex,
          );
          for (final talent in userTalents) {
            talentsById[talent.id] = talent;
          }
          final creationTalents = await _loadCreationTalentsSource(
            query,
            filter,
            portfolioIndex,
          );
          for (final talent in creationTalents) {
            talentsById[talent.id] = talent;
          }

          final talents = talentsById.values.toList();
          talents.sort((a, b) {
            final aScore =
                a.relevanceScore +
                boosts.boostScore(id: a.id, ownerId: a.accountId, data: a.raw);
            final bScore =
                b.relevanceScore +
                boosts.boostScore(id: b.id, ownerId: b.accountId, data: b.raw);
            return bScore.compareTo(aScore);
          });
          return talents;
        });
  }

  String _ownerIdFromPlace(Map<String, dynamic> placeData) {
    return placeData['ownerId']?.toString() ??
        placeData['userId']?.toString() ??
        placeData['accountId']?.toString() ??
        '';
  }

  Future<List<TalentProfile>> _loadUserTalentsFallback(
    String query,
    TalentFilter filter,
    Map<String, _PortfolioSummary> portfolioIndex,
  ) async {
    final docsById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    final queries = [
      _firestore.collection('users').limit(300),
      _firestore
          .collection('users')
          .where('roleFlags.isCreator', isEqualTo: true)
          .limit(300),
      _firestore
          .collection('users')
          .where('roleFlags.isShop', isEqualTo: true)
          .limit(300),
      _firestore
          .collection('users')
          .where('publicRole', isEqualTo: AccountRoles.createur)
          .limit(160),
      _firestore
          .collection('users')
          .where('roles', arrayContains: AccountRoles.createur)
          .limit(160),
      _firestore
          .collection('users')
          .where('roles', arrayContains: 'creator')
          .limit(160),
    ];
    for (final queryRef in queries) {
      try {
        final snapshot = await queryRef.get();
        for (final doc in snapshot.docs) {
          docsById[doc.id] = doc;
        }
      } catch (_) {
        // Some projects restrict a query or miss an index. Keep the other sources.
      }
    }
    final talents = <TalentProfile>[];
    for (final doc in docsById.values) {
      final data = doc.data();
      if (_isAdminUser(data)) continue;
      final roles = _publicBusinessRoles(data);
      for (final role in roles) {
        final base = TalentProfile.fromDoc(
          doc,
          roleOverride: role,
          creationsCount:
              role == AccountRoles.createur
                  ? _creationCountFromData(data) +
                      (portfolioIndex[doc.id]?.creationsCount ?? 0)
                  : 0,
          productsCount:
              role == AccountRoles.boutique
                  ? _productCountFromData(data) +
                      (portfolioIndex[doc.id]?.productsCount ?? 0)
                  : 0,
          portfolioImages: _mergedPortfolioImages(
            portfolioIndex[doc.id]?.imagesForRole(role) ?? const [],
            _portfolioImagesFromData(data, role),
          ),
        );
        if (!_isPublicTalent(base)) continue;
        if (_matches(base, query, filter)) talents.add(base);
      }
    }
    return talents;
  }

  Future<List<TalentProfile>> _loadCreationTalentsSource(
    String query,
    TalentFilter filter,
    Map<String, _PortfolioSummary> portfolioIndex,
  ) async {
    try {
      final snapshot =
          await _firestore.collection('creations').limit(240).get();
      final creationDocs =
          snapshot.docs.where((doc) => _isPublicContent(doc.data())).toList();
      final creatorIds =
          creationDocs
              .map((doc) => _creatorIdFromCreation(doc.data()))
              .where((id) => id.isNotEmpty)
              .toSet();
      if (creatorIds.isEmpty) return const [];

      final users = await _loadUserDataByIds(creatorIds);
      final creationsByCreator =
          <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
      for (final doc in creationDocs) {
        final creatorId = _creatorIdFromCreation(doc.data());
        if (creatorId.isEmpty) continue;
        creationsByCreator.putIfAbsent(creatorId, () => []).add(doc);
      }

      final talents = <TalentProfile>[];
      for (final entry in creationsByCreator.entries) {
        final userData = users[entry.key];
        if (userData == null || _isAdminUser(userData)) continue;
        final fallbackImages =
            entry.value
                .map((doc) => _imageFromCreation(doc.data()))
                .where((url) => url.isNotEmpty)
                .take(3)
                .toList();
        final profileImages = _portfolioImagesFromData(
          userData,
          AccountRoles.createur,
        );
        final enriched = TalentProfile.fromUserData(
          uid: entry.key,
          data: userData,
          roleOverride: AccountRoles.createur,
          creationsCount: _creationCountFromData(userData) + entry.value.length,
          productsCount: 0,
          portfolioImages: _mergedPortfolioImages([
            ...fallbackImages,
            ...?portfolioIndex[entry.key]?.creationImages,
          ], profileImages),
        );
        if (_matches(enriched, query, filter)) talents.add(enriched);
      }
      return talents;
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, Map<String, dynamic>>> _loadUserDataByIds(
    Set<String> ids,
  ) async {
    final cleaned = ids.where((id) => id.trim().isNotEmpty).toList();
    final result = <String, Map<String, dynamic>>{};
    for (final collection in const ['users', 'createurs']) {
      for (var start = 0; start < cleaned.length; start += 10) {
        final end = start + 10 > cleaned.length ? cleaned.length : start + 10;
        final chunk = cleaned.sublist(start, end);
        try {
          final snapshot =
              await _firestore
                  .collection(collection)
                  .where(FieldPath.documentId, whereIn: chunk)
                  .get();
          for (final doc in snapshot.docs) {
            result.putIfAbsent(doc.id, () => doc.data());
          }
        } catch (_) {
          for (final id in chunk) {
            try {
              final doc = await _firestore.collection(collection).doc(id).get();
              final data = doc.data();
              if (data != null) result.putIfAbsent(id, () => data);
            } catch (_) {
              // Keep the rest of the creators visible when one profile is blocked.
            }
          }
        }
      }
    }
    return result;
  }

  Future<Map<String, _PortfolioSummary>> _loadPortfolioIndex() async {
    final index = <String, _PortfolioSummary>{};

    void addItem({
      required String ownerId,
      required String type,
      required String imageUrl,
    }) {
      if (ownerId.trim().isEmpty) return;
      final current = index[ownerId] ?? const _PortfolioSummary();
      index[ownerId] = current.add(type: type, imageUrl: imageUrl);
    }

    try {
      final products = await _firestore.collection('products').limit(360).get();
      for (final doc in products.docs) {
        final data = doc.data();
        if (!_isPublicContent(data)) continue;
        addItem(
          ownerId: _firstString([
            data['boutiqueId'],
            data['sellerId'],
            data['ownerId'],
            data['userId'],
          ]),
          type: 'product',
          imageUrl: _imageFromProduct(data),
        );
      }
    } catch (_) {
      // Keep talents visible even when products cannot be indexed.
    }

    try {
      final creations =
          await _firestore.collection('creations').limit(360).get();
      for (final doc in creations.docs) {
        final data = doc.data();
        if (!_isPublicContent(data)) continue;
        addItem(
          ownerId: _creatorIdFromCreation(data),
          type: 'creation',
          imageUrl: _imageFromCreation(data),
        );
      }
    } catch (_) {
      // Keep products and profile data visible.
    }

    return index;
  }

  int _creationCountFromData(Map<String, dynamic> data) {
    return _intFromPath(data, 'stats.creationsCount') ??
        _intFromPath(data, 'creationsCount') ??
        _intFromPath(data, 'creationCount') ??
        0;
  }

  int _productCountFromData(Map<String, dynamic> data) {
    return _intFromPath(data, 'stats.productsCount') ??
        _intFromPath(data, 'productsCount') ??
        _intFromPath(data, 'productCount') ??
        0;
  }

  List<String> _portfolioImagesFromData(
    Map<String, dynamic> data,
    String role,
  ) {
    final urls = <String>[];

    void add(Object? value) {
      if (value == null) return;
      if (value is Iterable) {
        for (final item in value) {
          add(item);
        }
        return;
      }
      if (value is Map) {
        for (final key in const [
          'portfolioImages',
          'portfolio',
          'gallery',
          'workImages',
          'productImages',
          'creationImages',
          'imageUrls',
          'images',
          'coverUrl',
          'coverImage',
          'thumbnailUrl',
          'optimizedUrl',
          'secureUrl',
          'url',
        ]) {
          add(value[key]);
        }
        return;
      }
      final url = value.toString().trim();
      if (_isNetworkImage(url) &&
          !_looksLikeProfileImage(url) &&
          !urls.contains(url)) {
        urls.add(url);
      }
    }

    // Only fields that can represent a portfolio, product, creation, or gallery.
    // Avatar/logo/profile fields are intentionally excluded so talent cards do
    // not show a creator photo in place of their products or creations.
    if (role == AccountRoles.boutique) {
      add(data['productImages']);
      add(data['products']);
      add(data['shopGallery']);
      add(data['shopPortfolio']);
    } else {
      add(data['creationImages']);
      add(data['creations']);
      add(data['workImages']);
      add(data['lookbook']);
      add(data['creatorGallery']);
      add(data['creatorPortfolio']);
    }

    final media = data['media'];
    if (media is Map) {
      if (role == AccountRoles.boutique) {
        add(media['products']);
        add(media['productImages']);
        add(media['shopGallery']);
        add(media['shopPortfolio']);
      } else {
        add(media['creations']);
        add(media['creationImages']);
        add(media['workImages']);
        add(media['lookbook']);
        add(media['creatorGallery']);
        add(media['creatorPortfolio']);
      }
    }

    final businessProfile =
        role == AccountRoles.boutique
            ? data['shopProfile']
            : data['creatorProfile'];
    if (businessProfile is Map) {
      if (role == AccountRoles.boutique) {
        add(businessProfile['productImages']);
        add(businessProfile['products']);
        add(businessProfile['gallery']);
        add(businessProfile['portfolio']);
      } else {
        add(businessProfile['creationImages']);
        add(businessProfile['creations']);
        add(businessProfile['workImages']);
        add(businessProfile['lookbook']);
        add(businessProfile['gallery']);
        add(businessProfile['portfolio']);
      }
    }

    return urls.take(3).toList();
  }

  List<String> _mergedPortfolioImages(
    List<String> primary,
    List<String> extra,
  ) {
    final urls = <String>[];
    for (final url in [...primary, ...extra]) {
      final value = url.trim();
      if (_isNetworkImage(value) &&
          !_looksLikeProfileImage(value) &&
          !urls.contains(value)) {
        urls.add(value);
      }
      if (urls.length >= 3) break;
    }
    return urls;
  }

  String _imageFromProduct(Map<String, dynamic> data) {
    return _firstImageUrl([
      _itemMedia(data['media']),
      data['imageUrls'],
      data['images'],
      data['coverImage'],
      data['thumbnailUrl'],
      data['imageUrl'],
    ]);
  }

  String _firstString(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  int? _intFromPath(Map<String, dynamic> data, String path) {
    Object? current = data;
    for (final part in path.split('.')) {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }
    if (current is num) return current.toInt();
    return int.tryParse(current?.toString() ?? '');
  }

  Future<List<TalentPortfolioItem>> loadPortfolio(
    String talentId, {
    int limit = 8,
  }) async {
    final creationDocs = await _loadDocsByOwnerFields(
      'creations',
      const ['createurId', 'creatorId', 'sellerId', 'ownerId', 'userId'],
      talentId,
      limit,
    );
    final productDocs = await _loadDocsByOwnerFields(
      'products',
      const ['boutiqueId', 'sellerId', 'ownerId', 'userId'],
      talentId,
      limit,
    );

    final items = <TalentPortfolioItem>[
      ...creationDocs.map((doc) {
        final data = doc.data();
        return TalentPortfolioItem(
          id: doc.id,
          title: data['title']?.toString() ?? 'Création',
          imageUrl: _imageFromCreation(data),
          type: 'creation',
          price: (data['price'] as num?)?.toDouble() ?? 0,
        );
      }),
      ...productDocs.map(_productItem),
    ];

    final unique = <String, TalentPortfolioItem>{};
    for (final item in items) {
      if (item.imageUrl.isNotEmpty) unique[item.id] = item;
    }
    return unique.values.take(limit).toList();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadDocsByOwnerFields(
    String collection,
    List<String> fields,
    String ownerId,
    int limit,
  ) async {
    if (ownerId.trim().isEmpty) return const [];
    final docsById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final field in fields) {
      try {
        final snapshot =
            await _firestore
                .collection(collection)
                .where(field, isEqualTo: ownerId)
                .limit(limit)
                .get();
        for (final doc in snapshot.docs) {
          docsById[doc.id] = doc;
        }
      } catch (_) {
        // Keep the other legacy owner fields available.
      }
    }
    return docsById.values.take(limit).toList();
  }

  TalentPortfolioItem _productItem(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return TalentPortfolioItem(
      id: doc.id,
      title: data['name']?.toString() ?? 'Produit',
      imageUrl: _imageFromProduct(data),
      type: 'product',
      price: (data['price'] as num?)?.toDouble() ?? 0,
    );
  }

  String _creatorIdFromCreation(Map<String, dynamic> data) {
    return data['createurId']?.toString() ??
        data['creatorId']?.toString() ??
        data['sellerId']?.toString() ??
        data['ownerId']?.toString() ??
        data['userId']?.toString() ??
        data['uid']?.toString() ??
        '';
  }

  String _imageFromCreation(Map<String, dynamic> data) {
    return _firstImageUrl([
      _itemMedia(data['media']),
      data['images'],
      data['imageUrls'],
      data['coverUrl'],
      data['coverImage'],
      data['thumbnailUrl'],
      data['imageUrl'],
    ]);
  }

  String _firstImageUrl(List<Object?> values) {
    for (final value in values) {
      final url = _cleanImageUrl(value);
      if (url.isNotEmpty) return url;
    }
    return '';
  }

  Object? _itemMedia(Object? media) {
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

  String _cleanImageUrl(Object? value) {
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
    return _isNetworkImage(url) && !_looksLikeProfileImage(url) ? url : '';
  }

  bool _isNetworkImage(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  bool _looksLikeProfileImage(String url) {
    final value = url.toLowerCase();
    return value.contains('/profiles/') ||
        value.contains('/profile_') ||
        value.contains('/profile/') ||
        value.contains('/avatar_') ||
        value.contains('/avatars/') ||
        value.contains('/logo_') ||
        value.contains('/logos/') ||
        value.contains('/shops/') && value.contains('/logo_') ||
        value.contains('/createur/') && value.contains('/profile_') ||
        value.contains('/users/') && value.contains('/avatar_');
  }

  bool _isPublicContent(Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? '';
    final visibility = data['visibility']?.toString().toLowerCase() ?? '';
    final moderation = data['moderationStatus']?.toString().toLowerCase() ?? '';
    if (data['deleted'] == true || data['isDeleted'] == true) return false;
    if (data['isPublic'] == false || data['public'] == false) return false;
    if (status == 'draft' || status == 'hidden' || status == 'archived') {
      return false;
    }
    if (visibility == 'private' || visibility == 'hidden') return false;
    if (moderation == 'rejected' || moderation == 'blocked') return false;
    return true;
  }

  bool _isPublicTalent(TalentProfile talent) {
    return talent.raw['isPublic'] == true ||
        talent.raw['publicProfile'] == true ||
        talent.raw['publicRole'] != null ||
        talent.roleLabels.isNotEmpty ||
        talent.searchText.contains('mode') ||
        talent.searchText.contains('coiff') ||
        talent.searchText.contains('couture') ||
        talent.searchText.contains('tailleur') ||
        talent.searchText.contains('boutique') ||
        talent.searchText.contains('chauss');
  }

  bool _isAdminUser(Map<String, dynamic> data) {
    final roleValues = <String>[
      data['role']?.toString() ?? '',
      data['activeRole']?.toString() ?? '',
      data['publicRole']?.toString() ?? '',
    ];
    final rawRoles = data['roles'];
    if (rawRoles is Iterable) {
      roleValues.addAll(rawRoles.map((role) => role.toString()));
    }
    if (rawRoles is Map) {
      for (final entry in rawRoles.entries) {
        if (entry.value == true) roleValues.add(entry.key.toString());
      }
    }
    final roleText = roleValues.join(' ').toLowerCase();
    final roleFlags = data['roleFlags'];
    return data['admin'] == true ||
        data['isAdmin'] == true ||
        roleText.split(RegExp(r'\s+')).contains('admin') ||
        (roleFlags is Map && roleFlags['isAdmin'] == true);
  }

  List<String> _publicBusinessRoles(Map<String, dynamic> data) {
    final roles = <String>{...AccountRoles.normalize(data)};

    void addRole(dynamic value) {
      final canonical = AccountRoles.canonical(value?.toString());
      if (canonical != null) roles.add(canonical);
    }

    addRole(data['publicRole']);
    addRole(data['role']);
    addRole(data['activeRole']);

    final rawRoles = data['roles'];
    if (rawRoles is Iterable) {
      for (final role in rawRoles) {
        addRole(role);
      }
    }
    if (rawRoles is Map) {
      if (rawRoles['boutique'] == true) roles.add('boutique');
      if (rawRoles['createur'] == true || rawRoles['creator'] == true) {
        roles.add('createur');
      }
    }

    final flags = data['roleFlags'];
    if (flags is Map) {
      if (flags['isShop'] == true) roles.add('boutique');
      if (flags['isCreator'] == true) roles.add('createur');
    }

    final onboarding = data['businessOnboarding'];
    if (onboarding is Map) {
      final shop = onboarding['boutique'] ?? onboarding['shop'];
      final creator = onboarding['createur'] ?? onboarding['creator'];
      if (shop is Map && _businessRoleEnabled(shop)) {
        roles.add(AccountRoles.boutique);
      }
      if (creator is Map && _businessRoleEnabled(creator)) {
        roles.add(AccountRoles.createur);
      }
    }

    if (roles.isEmpty &&
        (data['isPublic'] == true || data['publicProfile'] == true)) {
      final text =
          '${data['boutiqueName']} ${data['creatorName']} ${data['speciality']} ${data['specialty']} ${data['category']}'
              .toLowerCase();
      if (text.contains('boutique')) roles.add(AccountRoles.boutique);
      if (text.contains('createur') ||
          text.contains('creator') ||
          text.contains('créateur') ||
          text.contains('mode') ||
          text.contains('couture') ||
          text.contains('styliste')) {
        roles.add(AccountRoles.createur);
      }
    }

    return roles
        .where((role) => AccountRoles.businessRoles.contains(role))
        .toList();
  }

  bool _businessRoleEnabled(Map<dynamic, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? '';
    return status == 'active' ||
        status == 'approved' ||
        status == 'enabled' ||
        data['enabled'] == true;
  }

  bool _matches(TalentProfile talent, String query, TalentFilter filter) {
    final q = query.trim().toLowerCase();
    final queryOk = q.isEmpty || talent.searchText.contains(q);
    final roleOk =
        filter.role == 'Tous' ||
        talent.primaryRole.toLowerCase().contains(filter.role.toLowerCase()) ||
        talent.searchText.contains(filter.role.toLowerCase());
    final locationOk =
        filter.location.trim().isEmpty ||
        talent.searchText.contains(filter.location.trim().toLowerCase());
    final languageOk =
        filter.language.trim().isEmpty ||
        talent.languages
            .join(' ')
            .toLowerCase()
            .contains(filter.language.trim().toLowerCase());
    return queryOk &&
        roleOk &&
        locationOk &&
        languageOk &&
        (!filter.availableOnly || talent.isAvailable) &&
        (!filter.verifiedOnly || talent.verified) &&
        (!filter.withCreationsOnly || talent.hasCreations) &&
        (!filter.withProductsOnly || talent.hasProducts) &&
        (!filter.madeToMeasureOnly || talent.madeToMeasure) &&
        (!filter.appointmentOnly || talent.acceptsAppointments);
  }
}

class _PortfolioSummary {
  const _PortfolioSummary({
    this.creationsCount = 0,
    this.productsCount = 0,
    this.creationImages = const [],
    this.productImages = const [],
  });

  final int creationsCount;
  final int productsCount;
  final List<String> creationImages;
  final List<String> productImages;

  List<String> imagesForRole(String role) {
    return role == AccountRoles.boutique ? productImages : creationImages;
  }

  _PortfolioSummary add({required String type, required String imageUrl}) {
    final nextCreationImages = [...creationImages];
    final nextProductImages = [...productImages];
    final cleanUrl = imageUrl.trim();
    final isValid =
        (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) &&
        !cleanUrl.toLowerCase().contains('/profiles/') &&
        !cleanUrl.toLowerCase().contains('/avatars/') &&
        !cleanUrl.toLowerCase().contains('/logos/');
    if (isValid && type == 'creation') {
      if (!nextCreationImages.contains(cleanUrl) &&
          nextCreationImages.length < 3) {
        nextCreationImages.add(cleanUrl);
      }
    }
    if (isValid && type == 'product') {
      if (!nextProductImages.contains(cleanUrl) &&
          nextProductImages.length < 3) {
        nextProductImages.add(cleanUrl);
      }
    }
    return _PortfolioSummary(
      creationsCount: creationsCount + (type == 'creation' ? 1 : 0),
      productsCount: productsCount + (type == 'product' ? 1 : 0),
      creationImages: nextCreationImages,
      productImages: nextProductImages,
    );
  }
}
