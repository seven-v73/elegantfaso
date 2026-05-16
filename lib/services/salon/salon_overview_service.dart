import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/salon/salon_highlight.dart';
import '../../models/salon/salon_overview.dart';
import 'salon_boost_service.dart';

class SalonOverviewService {
  SalonOverviewService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SalonBoostService? boostService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _boostService = boostService ?? SalonBoostService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SalonBoostService _boostService;
  static const Duration _overviewCacheTtl = Duration(minutes: 3);
  static final Map<String, _OverviewCacheEntry> _overviewCache = {};
  static final Map<String, _ProOwnerCacheEntry> _proOwnerCache = {};

  Future<SalonOverview> loadOverview() async {
    final user = _auth.currentUser;
    final cacheKey = user?.uid ?? 'guest';
    final cached = _overviewCache[cacheKey];
    if (cached != null && cached.isFresh) return cached.value;

    final userDocFuture =
        user == null
            ? null
            : _firestore.collection('users').doc(user.uid).get();

    final productsFuture =
        _firestore
            .collection('products')
            .orderBy('createdAt', descending: true)
            .limit(18)
            .get();
    final creationsFuture =
        _firestore
            .collection('creations')
            .orderBy('createdAt', descending: true)
            .limit(18)
            .get();
    final talentsFuture = _firestore.collection('users').limit(80).get();
    final eventsFuture =
        _firestore
            .collection('events')
            .orderBy('startAt', descending: false)
            .limit(12)
            .get();
    final wishlistFuture =
        user == null
            ? null
            : _firestore
                .collection('users')
                .doc(user.uid)
                .collection('wardrobe')
                .where('type', whereIn: ['wishlist', 'inspiration'])
                .limit(12)
                .get();
    final ordersFuture =
        user == null
            ? null
            : _firestore
                .collection('orders')
                .where('userId', isEqualTo: user.uid)
                .limit(12)
                .get();

    final results = await Future.wait([
      productsFuture,
      creationsFuture,
      talentsFuture,
      eventsFuture,
      if (userDocFuture != null) userDocFuture,
      if (wishlistFuture != null) wishlistFuture,
      if (ordersFuture != null) ordersFuture,
      _boostService.loadActiveBoostIndex(),
    ]);

    final products = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final creations = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final users = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final events = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final userDoc =
        userDocFuture == null
            ? null
            : results[4] as DocumentSnapshot<Map<String, dynamic>>;
    final wishlist =
        wishlistFuture == null
            ? null
            : results[userDocFuture == null ? 4 : 5]
                as QuerySnapshot<Map<String, dynamic>>;
    final orders =
        ordersFuture == null
            ? null
            : results[userDocFuture == null ? 5 : 6]
                as QuerySnapshot<Map<String, dynamic>>;
    final boosts = results.last as SalonBoostIndex;

    final userData = userDoc?.data() ?? const <String, dynamic>{};
    final userId = user?.uid ?? '';
    final userCity = _first(userData, const ['city', 'ville', 'location'], '');
    final activeRole = _activeRole(userData);

    final productHighlights =
        products.docs
            .where((doc) => doc.id != userId)
            .where((doc) => _isPublicListing(doc.data()))
            .map(SalonHighlight.product)
            .toList();
    final creationHighlights =
        creations.docs
            .where((doc) => _ownerId(doc.data()) != userId)
            .where((doc) => _isPublicListing(doc.data()))
            .map(SalonHighlight.creation)
            .toList();
    final talentHighlights =
        users.docs
            .where((doc) => doc.id != userId)
            .where((doc) => !_isAdminUser(doc.data()))
            .map(SalonHighlight.talent)
            .where(_isPublicTalent)
            .toList()
          ..sort((a, b) => _talentSort(a, b, boosts));
    final eventHighlights = events.docs.map(SalonHighlight.event).toList();

    final combined = <SalonHighlight>[
      ...productHighlights,
      ...creationHighlights,
    ]..sort((a, b) => _rank(a, b, boosts));
    final proOwnerIds = await _loadProOwnerIds(combined);

    final nearby =
        userCity.isEmpty
            ? combined.take(8).toList()
            : combined
                .where(
                  (item) =>
                      item.searchText.contains(userCity.toLowerCase()) ||
                      item.city.toLowerCase().contains(userCity.toLowerCase()),
                )
                .take(8)
                .toList();

    final overview = SalonOverview(
      isSignedIn: user != null,
      userId: userId,
      displayName:
          user?.displayName ??
          _first(userData, const ['displayName', 'name'], ''),
      activeRole: activeRole,
      city: userCity,
      productCount: products.size,
      creationCount: creations.size,
      talentCount: talentHighlights.length,
      eventCount: eventHighlights.length,
      wishlistCount: wishlist?.size ?? 0,
      orderCount: orders?.size ?? 0,
      myCreationCount:
          creations.docs.where((doc) => _ownerId(doc.data()) == userId).length,
      myProductCount:
          products.docs.where((doc) => _ownerId(doc.data()) == userId).length,
      today: combined.take(10).toList(),
      nearby: nearby.isEmpty ? combined.take(6).toList() : nearby,
      activeTalents: talentHighlights.take(8).toList(),
      trending: _trending(combined, talentHighlights, boosts).take(10).toList(),
      events: eventHighlights.take(6).toList(),
      featuredSignature:
          _featuredSignature(
            combined,
            talentHighlights,
            eventHighlights,
            boosts,
          ).take(10).toList(),
      marketplaceCarousel:
          _marketplaceCarousel(combined, proOwnerIds, boosts).take(12).toList(),
    );
    _overviewCache[cacheKey] = _OverviewCacheEntry(overview);
    return overview;
  }

  void clearCache() {
    _overviewCache.remove(_auth.currentUser?.uid ?? 'guest');
  }

  List<SalonHighlight> _marketplaceCarousel(
    List<SalonHighlight> listings,
    Set<String> proOwnerIds,
    SalonBoostIndex boosts,
  ) {
    final items =
        listings
            .where((item) => item.isProduct || item.isCreation)
            .where((item) => item.hasImage || item.price != null)
            .map(
              (item) => item.copyWith(
                proPriority: proOwnerIds.contains(_ownerId(item.data)),
              ),
            )
            .toList();
    items.sort((a, b) {
      final aScore = _marketplaceScore(a, proOwnerIds, boosts);
      final bScore = _marketplaceScore(b, proOwnerIds, boosts);
      if (aScore != bScore) return bScore.compareTo(aScore);
      return _recentSort(a, b);
    });
    return items;
  }

  int _marketplaceScore(
    SalonHighlight item,
    Set<String> proOwnerIds,
    SalonBoostIndex boosts,
  ) {
    final ownerId = _ownerId(item.data);
    var score = _score(item) + _boostScore(item, boosts);
    if (item.isProduct) score += 70;
    if (item.isCreation) score += 20;
    if (proOwnerIds.contains(ownerId) || item.isProListing) score += 120;
    if (item.isSignature) score += 50;
    if (item.hasImage) score += 20;
    return score;
  }

  Future<Set<String>> _loadProOwnerIds(List<SalonHighlight> listings) async {
    final ownerIds =
        listings
            .map((item) => _ownerId(item.data))
            .where((id) => id.isNotEmpty)
            .toSet()
            .take(30)
            .toList();
    if (ownerIds.isEmpty) return const {};

    final proIds = <String>{};
    final missingIds = <String>[];
    for (final ownerId in ownerIds) {
      final cached = _proOwnerCache[ownerId];
      if (cached != null && cached.isFresh) {
        if (cached.isPro) proIds.add(ownerId);
      } else {
        missingIds.add(ownerId);
      }
    }
    if (missingIds.isEmpty) return proIds;

    final userDocs = await _loadDocsByIds('users', missingIds);
    final subscriptionDocs = await _loadDocsByIds(
      'seller_subscriptions',
      missingIds,
    );

    for (final ownerId in missingIds) {
      final userData = userDocs[ownerId] ?? const <String, dynamic>{};
      final subscriptionData =
          subscriptionDocs[ownerId] ?? const <String, dynamic>{};
      if (_hasActiveProAccess(userData, subscriptionData)) {
        proIds.add(ownerId);
        _proOwnerCache[ownerId] = _ProOwnerCacheEntry(true);
      } else {
        _proOwnerCache[ownerId] = _ProOwnerCacheEntry(false);
      }
    }
    return proIds;
  }

  Future<Map<String, Map<String, dynamic>>> _loadDocsByIds(
    String collection,
    List<String> ids,
  ) async {
    final result = <String, Map<String, dynamic>>{};
    for (var start = 0; start < ids.length; start += 10) {
      final end = start + 10 > ids.length ? ids.length : start + 10;
      final chunk = ids.sublist(start, end);
      final snapshot =
          await _firestore
              .collection(collection)
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
      for (final doc in snapshot.docs) {
        result[doc.id] = doc.data();
      }
    }
    return result;
  }

  bool _hasActiveProAccess(
    Map<String, dynamic> userData,
    Map<String, dynamic> subscriptionData,
  ) {
    final entitlement = _mapFrom(userData['businessEntitlements']);
    final plan =
        _firstObjectString([
          subscriptionData['plan'],
          entitlement['plan'],
          userData['plan'],
          userData['visibilityTier'],
        ], '').toLowerCase();
    final status =
        _firstObjectString([
          subscriptionData['status'],
          entitlement['status'],
          userData['subscriptionStatus'],
        ], '').toLowerCase();
    final expiresAt =
        _dateFrom(subscriptionData['expiresAt']) ??
        _dateFrom(entitlement['expiresAt']);
    final active = status == 'active' || status.isEmpty && plan.isNotEmpty;
    final valid = expiresAt != null && expiresAt.isAfter(DateTime.now());
    return active &&
        valid &&
        (plan == 'pro' || plan == 'premium' || plan == 'signature');
  }

  List<SalonHighlight> _featuredSignature(
    List<SalonHighlight> listings,
    List<SalonHighlight> talents,
    List<SalonHighlight> events,
    SalonBoostIndex boosts,
  ) {
    final items =
        [...listings, ...talents, ...events]
            .where(
              (item) =>
                  item.isFeatured ||
                  boosts.isBoosted(
                    id: item.id,
                    ownerId: _ownerId(item.data),
                    data: item.data,
                  ),
            )
            .toList();
    items.sort((a, b) => _rank(a, b, boosts));
    return items;
  }

  List<SalonHighlight> _trending(
    List<SalonHighlight> listings,
    List<SalonHighlight> talents,
    SalonBoostIndex boosts,
  ) {
    final scored = [...listings, ...talents];
    scored.sort((a, b) {
      final aScore = _score(a) + _boostScore(a, boosts);
      final bScore = _score(b) + _boostScore(b, boosts);
      if (aScore != bScore) return bScore.compareTo(aScore);
      return _recentSort(a, b);
    });
    return scored;
  }

  int _score(SalonHighlight item) {
    var score = 0;
    if (item.hasImage) score += 20;
    if (item.price != null && item.price! > 0) score += 8;
    if (item.data['isVerified'] == true || item.data['verified'] == true) {
      score += 25;
    }
    score +=
        ((item.data['likesCount'] ?? item.data['followersCount'] ?? 0) as num?)
            ?.toInt() ??
        0;
    return score;
  }

  bool _isPublicTalent(SalonHighlight item) {
    final text = item.searchText;
    return text.contains('mode') ||
        text.contains('boutique') ||
        text.contains('createur') ||
        text.contains('creator') ||
        text.contains('coiff') ||
        text.contains('couture') ||
        text.contains('tailleur') ||
        text.contains('chauss') ||
        text.contains('styliste') ||
        text.contains('maquill');
  }

  bool _isAdminUser(Map<String, dynamic> data) {
    final roleFlags = data['roleFlags'];
    final text =
        '${data['role']} ${data['activeRole']} ${data['publicRole']} ${data['roles']}'
            .toLowerCase();
    return data['admin'] == true ||
        data['isAdmin'] == true ||
        text.split(RegExp(r'\s+')).contains('admin') ||
        (roleFlags is Map && roleFlags['isAdmin'] == true);
  }

  bool _isPublicListing(Map<String, dynamic> data) {
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

  int _recentSort(SalonHighlight a, SalonHighlight b) {
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }

  int _talentSort(SalonHighlight a, SalonHighlight b, SalonBoostIndex boosts) {
    final aScore = _score(a) + _boostScore(a, boosts);
    final bScore = _score(b) + _boostScore(b, boosts);
    return bScore.compareTo(aScore);
  }

  int _rank(SalonHighlight a, SalonHighlight b, SalonBoostIndex boosts) {
    final aScore = _score(a) + _boostScore(a, boosts);
    final bScore = _score(b) + _boostScore(b, boosts);
    if (aScore != bScore) return bScore.compareTo(aScore);
    return _recentSort(a, b);
  }

  int _boostScore(SalonHighlight item, SalonBoostIndex boosts) {
    return boosts.boostScore(
      id: item.id,
      ownerId: _ownerId(item.data),
      data: item.data,
    );
  }

  String _ownerId(Map<String, dynamic> data) {
    return _first(data, const [
      'sellerId',
      'boutiqueId',
      'createurId',
      'userId',
    ], '');
  }

  DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> _mapFrom(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  String _firstObjectString(List<Object?> values, String fallback) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return fallback;
  }

  String _activeRole(Map<String, dynamic> data) {
    final active = data['activeRole']?.toString().trim();
    if (active != null && active.isNotEmpty) return active;
    final role = data['role']?.toString().trim();
    if (role != null && role.isNotEmpty) return role;
    final roles = data['roles'];
    if (roles is Map) {
      if (roles['boutique'] == true) return 'boutique';
      if (roles['createur'] == true || roles['creator'] == true) {
        return 'createur';
      }
    }
    return 'client';
  }

  String _first(Map<String, dynamic> data, List<String> keys, String fallback) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }
}

class _OverviewCacheEntry {
  _OverviewCacheEntry(this.value) : createdAt = DateTime.now();

  final SalonOverview value;
  final DateTime createdAt;

  bool get isFresh =>
      DateTime.now().difference(createdAt) <
      SalonOverviewService._overviewCacheTtl;
}

class _ProOwnerCacheEntry {
  _ProOwnerCacheEntry(this.isPro) : createdAt = DateTime.now();

  final bool isPro;
  final DateTime createdAt;

  bool get isFresh =>
      DateTime.now().difference(createdAt) <
      SalonOverviewService._overviewCacheTtl;
}
