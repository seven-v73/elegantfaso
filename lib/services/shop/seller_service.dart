import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/shop/public_listing.dart';
import '../../models/shop/seller_info.dart';

class SellerService {
  SellerService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const Duration _sellerCacheTtl = Duration(minutes: 10);
  static const Duration _sellerLookupTimeout = Duration(seconds: 4);
  static const Duration _sellerDocTimeout = Duration(seconds: 3);
  static final Map<String, _SellerCacheEntry> _resolvedCache = {};
  static final Map<String, Future<SellerInfo>> _pendingCache = {};

  final FirebaseFirestore _firestore;

  String sellerKey(PublicListing listing) {
    return '${_roleFor(listing)}:${listing.sellerId}';
  }

  SellerInfo? cachedSeller(PublicListing listing) {
    final cached = _resolvedCache[sellerKey(listing)];
    return cached != null && cached.isFresh ? cached.value : null;
  }

  Map<String, SellerInfo> cachedSellers(Iterable<PublicListing> listings) {
    final sellers = <String, SellerInfo>{};
    for (final listing in listings) {
      final cached = cachedSeller(listing);
      if (cached != null) sellers[sellerKey(listing)] = cached;
    }
    return sellers;
  }

  Future<Map<String, SellerInfo>> getSellers(
    Iterable<PublicListing> listings,
  ) async {
    final uniqueListings = <String, PublicListing>{};
    for (final listing in listings) {
      uniqueListings.putIfAbsent(sellerKey(listing), () => listing);
    }

    final sellers = cachedSellers(uniqueListings.values);
    final missing =
        uniqueListings.entries
            .where((entry) => !sellers.containsKey(entry.key))
            .map((entry) => entry.value)
            .where((listing) => listing.sellerId.trim().isNotEmpty)
            .toList();
    if (missing.isEmpty) return sellers;

    final boutiqueIds =
        missing
            .where((listing) => listing.isProduct)
            .map((listing) => listing.sellerId)
            .toSet();
    final creatorIds =
        missing
            .where((listing) => listing.isCreation)
            .map((listing) => listing.sellerId)
            .toSet();
    final secondhandIds =
        missing
            .where((listing) => listing.isSecondhand)
            .map((listing) => listing.sellerId)
            .toSet();
    final userIds = {...boutiqueIds, ...creatorIds, ...secondhandIds};

    final snapshots = await Future.wait([
      _loadDocsByIds('boutiques', boutiqueIds),
      _loadDocsByIds('createurs', creatorIds),
      _loadDocsByIds('users', userIds),
    ]).timeout(_sellerLookupTimeout, onTimeout: () => const []);

    final boutiqueDocs =
        snapshots.isNotEmpty
            ? snapshots[0]
            : const <String, Map<String, dynamic>>{};
    final creatorDocs =
        snapshots.length > 1
            ? snapshots[1]
            : const <String, Map<String, dynamic>>{};
    final userDocs =
        snapshots.length > 2
            ? snapshots[2]
            : const <String, Map<String, dynamic>>{};

    for (final listing in missing) {
      final role = _roleFor(listing);
      final key = sellerKey(listing);
      final data =
          listing.isSecondhand
              ? userDocs[listing.sellerId]
              : listing.isProduct
              ? boutiqueDocs[listing.sellerId] ?? userDocs[listing.sellerId]
              : userDocs[listing.sellerId] ?? creatorDocs[listing.sellerId];
      if (data == null && !listing.isSecondhand) continue;

      final seller = _sellerFromData(
        listing: listing,
        role: role,
        data: data ?? const {},
      );
      _resolvedCache[key] = _SellerCacheEntry(seller);
      sellers[key] = seller;
    }

    final stillMissing = missing.where(
      (listing) => !sellers.containsKey(sellerKey(listing)),
    );
    final fallbackResults = await Future.wait(
      stillMissing.map((listing) async {
        final seller = await getSeller(listing);
        return MapEntry(sellerKey(listing), seller);
      }),
    );
    sellers.addEntries(fallbackResults);
    return sellers;
  }

  Future<SellerInfo> getSeller(PublicListing listing) {
    final role = _roleFor(listing);
    final key = sellerKey(listing);
    final cached = _resolvedCache[key];
    if (cached != null && cached.isFresh) return Future.value(cached.value);

    return _pendingCache.putIfAbsent(key, () async {
      if (listing.sellerId.isEmpty) {
        return SellerInfo.fallback(id: listing.sellerId, role: role);
      }
      final fallback = SellerInfo.fallback(id: listing.sellerId, role: role);
      try {
        final data = await _loadSellerData(
          listing,
        ).timeout(_sellerLookupTimeout, onTimeout: () => null);
        if (data == null) {
          if (!listing.isSecondhand) return fallback;
          final seller = _sellerFromData(
            listing: listing,
            role: role,
            data: const {},
          );
          _resolvedCache[key] = _SellerCacheEntry(seller);
          return seller;
        }
        final seller = _sellerFromData(
          listing: listing,
          role: role,
          data: data,
        );
        _resolvedCache[key] = _SellerCacheEntry(seller);
        return seller;
      } finally {
        _pendingCache.remove(key);
      }
    });
  }

  Future<Map<String, dynamic>?> _loadSellerData(PublicListing listing) async {
    final collections =
        listing.isSecondhand
            ? const ['users']
            : listing.isProduct
            ? const ['boutiques', 'users']
            : const ['users', 'createurs'];
    for (final collection in collections) {
      try {
        final doc = await _firestore
            .collection(collection)
            .doc(listing.sellerId)
            .get()
            .timeout(_sellerDocTimeout);
        final data = doc.data();
        if (data != null) return data;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<Map<String, Map<String, dynamic>>> _loadDocsByIds(
    String collection,
    Set<String> ids,
  ) async {
    final cleanedIds =
        ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toList();
    if (cleanedIds.isEmpty) return const {};

    final result = <String, Map<String, dynamic>>{};
    for (var start = 0; start < cleanedIds.length; start += 10) {
      final end =
          start + 10 > cleanedIds.length ? cleanedIds.length : start + 10;
      final chunk = cleanedIds.sublist(start, end);
      final snapshot = await _firestore
          .collection(collection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get()
          .timeout(_sellerDocTimeout);
      for (final doc in snapshot.docs) {
        result[doc.id] = doc.data();
      }
    }
    return result;
  }

  SellerInfo _sellerFromData({
    required PublicListing listing,
    required String role,
    required Map<String, dynamic> data,
  }) {
    final sourceData = listing.isSecondhand ? {...listing.data, ...data} : data;
    return SellerInfo(
      id: listing.sellerId,
      role: role,
      name: _firstString(
        sourceData,
        listing.isSecondhand
            ? const ['sellerName', 'displayName', 'name', 'clientProfile.name']
            : listing.isProduct
            ? const ['boutiqueName', 'shopProfile.name', 'name', 'displayName']
            : const [
              'creatorName',
              'creatorProfile.name',
              'displayName',
              'name',
            ],
        role == 'boutique'
            ? 'Boutique'
            : role == 'client'
            ? 'Client'
            : 'Créateur',
      ),
      imageUrl: _firstString(
        sourceData,
        listing.isSecondhand
            ? const [
              'sellerPhotoUrl',
              'photoUrl',
              'photoURL',
              'avatarUrl',
              'clientProfile.photoUrl',
            ]
            : listing.isProduct
            ? const [
              'boutiquePhotoUrl',
              'boutiqueLogoUrl',
              'shopProfile.logoUrl',
              'photoUrl',
              'photoURL',
              'imageUrl',
              'logoUrl',
            ]
            : const [
              'creatorPhotoUrl',
              'creatorProfile.photoUrl',
              'photoUrl',
              'photoURL',
              'imageUrl',
            ],
        '',
      ),
      city: _firstString(sourceData, const [
        'city',
        'ville',
        'location',
        'address',
        'shopProfile.city',
        'creatorProfile.city',
      ], ''),
      phone: _firstString(sourceData, const [
        'phone',
        'phoneNumber',
        'whatsapp',
        'shopProfile.phone',
        'creatorProfile.phone',
      ], ''),
      speciality: _firstString(sourceData, const [
        'speciality',
        'specialty',
        'category',
        'shopProfile.category',
        'creatorProfile.specialty',
      ], ''),
      followersCount: (sourceData['followersCount'] as num?)?.toInt() ?? 0,
      rating: (sourceData['rating'] as num?)?.toDouble() ?? 0,
      verified:
          sourceData['verified'] == true || sourceData['isVerified'] == true,
      responseTime: _firstString(sourceData, const ['responseTime'], ''),
      paymentMethods: _paymentMethodsFrom(sourceData),
    );
  }

  Map<String, String> _paymentMethodsFrom(Map<String, dynamic> data) {
    final paymentMethods =
        data['paymentMethods'] ??
        _valueForPath(data, 'shopProfile.paymentMethods') ??
        _valueForPath(data, 'creatorProfile.paymentMethods');
    if (paymentMethods is Map) {
      return paymentMethods.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
    return const {};
  }

  String _roleFor(PublicListing listing) {
    if (listing.isSecondhand) return 'client';
    return listing.isProduct ? 'boutique' : 'createur';
  }

  String _firstString(
    Map<String, dynamic> data,
    List<String> fields,
    String fallback,
  ) {
    for (final field in fields) {
      final value = _valueForPath(data, field)?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  Object? _valueForPath(Map<String, dynamic> data, String path) {
    Object? current = data;
    for (final part in path.split('.')) {
      if (current is! Map) return null;
      current = current[part];
    }
    return current;
  }
}

class _SellerCacheEntry {
  _SellerCacheEntry(this.value) : createdAt = DateTime.now();

  final SellerInfo value;
  final DateTime createdAt;

  bool get isFresh =>
      DateTime.now().difference(createdAt) < SellerService._sellerCacheTtl;
}
