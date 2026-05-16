import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/secondhand/secondhand_listing.dart';
import '../client/client_gamification_service.dart';
import '../media/media_asset_service.dart';
import '../media/media_upload_service.dart';
import '../notifications/app_notification_service.dart';
import '../preferences/currency_service.dart';
import '../profile/public_profile_service.dart';

class SecondhandListingService {
  SecondhandListingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    MediaUploadService? mediaUploadService,
    AppNotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _mediaUploadService = mediaUploadService ?? MediaUploadService(),
       _mediaAssetService = MediaAssetService(firestore: firestore),
       _gamificationService = ClientGamificationService(firestore: firestore),
       _publicProfileService = PublicProfileService(
         firestore: firestore,
         auth: auth,
       ),
       _notificationService =
           notificationService ??
           AppNotificationService(firestore: firestore, auth: auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final MediaUploadService _mediaUploadService;
  final MediaAssetService _mediaAssetService;
  final ClientGamificationService _gamificationService;
  final PublicProfileService _publicProfileService;
  final AppNotificationService _notificationService;
  final CurrencyService _currencyService = CurrencyService();
  static const Duration _trustCacheTtl = Duration(minutes: 8);
  static final Map<String, _SellerTrustCacheEntry> _sellerTrustCache = {};

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('secondhand_listings');

  String? get currentUserId => _auth.currentUser?.uid;

  Future<Map<String, String>> loadCurrentUserWithdrawalPaymentMethods() async {
    final userId = currentUserId;
    if (userId == null) return const {};
    final userSnapshot = await _firestore.collection('users').doc(userId).get();
    return _paymentMethodsFromUser(userSnapshot.data() ?? const {});
  }

  Stream<List<SecondhandListing>> watchListings({
    String category = 'Tout',
    String status = 'available',
    String query = '',
    int limit = 24,
  }) {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit.clamp(12, 120))
        .snapshots()
        .map((snapshot) {
          final normalizedQuery = query.trim().toLowerCase();
          final listings =
              snapshot.docs.map(SecondhandListing.fromFirestore).where((
                listing,
              ) {
                if (status != 'all' && listing.status != status) return false;
                if (category != 'Tout' && listing.category != category) {
                  return false;
                }
                if (normalizedQuery.isEmpty) return true;
                final searchText =
                    [
                      listing.title,
                      listing.description,
                      listing.category,
                      listing.condition,
                      listing.city,
                      listing.sellerName,
                    ].join(' ').toLowerCase();
                return searchText.contains(normalizedQuery);
              }).toList();
          listings.sort(_recommendationSort);
          return listings;
        });
  }

  int _recommendationSort(SecondhandListing a, SecondhandListing b) {
    final weightCompare = b.recommendationWeight.compareTo(
      a.recommendationWeight,
    );
    if (weightCompare != 0) return weightCompare;
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }

  Future<SecondhandSnapshot> loadSnapshot() async {
    final snapshot =
        await _collection
            .orderBy('createdAt', descending: true)
            .limit(80)
            .get();
    final listings =
        snapshot.docs.map(SecondhandListing.fromFirestore).toList();
    final available = listings.where((item) => item.isAvailable).length;
    final reserved = listings.where((item) => item.isReserved).length;
    final sold = listings.where((item) => item.isSold).length;
    return SecondhandSnapshot(
      total: listings.length,
      available: available,
      reserved: reserved,
      sold: sold,
    );
  }

  Future<String> publishListing({
    required SecondhandDraft draft,
    required List<File> images,
    required void Function(String stage) onStage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Connectez-vous pour publier.');
    if (images.isEmpty) {
      throw StateError('Ajoutez au moins une photo réelle de la pièce.');
    }

    final imageUrls = <String>[];
    final mediaIds = <String>[];
    for (var i = 0; i < images.length; i++) {
      onStage('Préparation photo ${i + 1}/${images.length}');
      final upload = await _mediaUploadService.uploadImage(
        file: images[i],
        folder: 'secondhand/${user.uid}',
        publicId: 'listing_${DateTime.now().millisecondsSinceEpoch}_$i',
      );
      final mediaId = await _mediaAssetService.recordUpload(
        upload: upload,
        ownerId: user.uid,
        ownerRole: 'client',
        usage: 'secondhand_listing',
        status: 'public',
        linkedCollection: 'secondhand_listings',
      );
      imageUrls.add(upload.optimizedUrl);
      mediaIds.add(mediaId);
    }

    onStage('Publication de l’annonce');
    final tier = await _gamificationService.loadVisibilityTier(user.uid);
    final currency =
        draft.currency.trim().isEmpty
            ? await _currencyService.currentUserCurrency()
            : CurrencyService.normalize(draft.currency);
    final doc = _collection.doc();
    final listing = SecondhandListing(
      id: doc.id,
      title: draft.title,
      description: draft.description,
      category: draft.category,
      condition: draft.condition,
      price: draft.price,
      currency: currency,
      city: draft.city,
      size: draft.size,
      color: draft.color,
      sellerId: user.uid,
      sellerName:
          user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Client ElegantFaso',
      sellerPhotoUrl: user.photoURL ?? '',
      imageUrls: imageUrls,
      status: 'available',
      likedBy: const [],
      visibilityTierId: tier.id,
      visibilityLabel: tier.label,
      visibilityCategory: tier.category,
      visibilityBoost: tier.visibilityBoost,
      recommendationWeight: tier.recommendationWeight,
    );

    await doc.set({
      ...listing.toFirestore(includeCreatedAt: true),
      'mediaIds': mediaIds,
      'trust': {
        'photoRequired': true,
        'communitySeller': true,
        'moderationEnabled': true,
        'visibilityEarnedByPoints': true,
      },
    });
    await _publicProfileService.syncCurrentUser();
    await _publicProfileService.incrementSecondhandPublished(user.uid);
    for (final mediaId in mediaIds) {
      await _mediaAssetService.linkAsset(
        mediaId: mediaId,
        linkedCollection: 'secondhand_listings',
        linkedDocumentId: doc.id,
      );
    }
    return doc.id;
  }

  Future<void> reserve(SecondhandListing listing) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Connectez-vous pour réserver.');
    if (listing.sellerId == userId) {
      throw StateError('Vous ne pouvez pas réserver votre propre annonce.');
    }
    await _collection.doc(listing.id).set({
      'status': 'reserved',
      'reservedBy': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _notifySecondhand(
      () => _notificationService.notifySecondhandEvent(
        recipientId: listing.sellerId,
        listingId: listing.id,
        title: 'Votre pièce est réservée',
        body:
            '${_auth.currentUser?.displayName ?? 'Un client'} souhaite réserver "${listing.title}".',
        event: 'secondhand_reserved',
        priority: 'high',
      ),
    );
  }

  Future<void> markSold(SecondhandListing listing) async {
    final userId = currentUserId;
    if (userId == null || listing.sellerId != userId) {
      throw StateError('Seul le vendeur peut marquer la pièce comme vendue.');
    }
    final reference = 'VD-${DateTime.now().millisecondsSinceEpoch}';
    await _collection.doc(listing.id).set({
      'status': 'sold',
      'paymentReference': reference,
      'paymentFlow': 'secondhand_client_sale',
      'secondhandBalanceStatus': 'available',
      'secondhandBalance': {
        'availableBalance': listing.price,
        'withdrawnBalance': 0.0,
        'convertedBalance': 0.0,
        'expectedSellerAmount': listing.price,
        'stylePointsAwarded': 0,
        'currency': listing.currency,
        'status': 'available',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'paymentTimeline': FieldValue.arrayUnion([
        {
          'status': 'sold',
          'label': 'Vente vide-dressing marquée comme finalisée',
          'at': Timestamp.now(),
        },
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _publicProfileService.incrementSecondhandSold(userId);
    await _notifySecondhand(
      () => _notificationService.notifySecondhandEvent(
        recipientId: userId,
        listingId: listing.id,
        title: 'Solde Vide-dressing disponible',
        body:
            'La vente de "${listing.title}" est finalisée. Vous pouvez retirer ${CurrencyService.format(listing.price, code: listing.currency)} ou convertir en points Style.',
        event: 'secondhand_withdrawal_available',
        priority: 'high',
      ),
    );
    if (listing.reservedBy.isNotEmpty && listing.reservedBy != userId) {
      await _notifySecondhand(
        () => _notificationService.notifySecondhandEvent(
          recipientId: listing.reservedBy,
          listingId: listing.id,
          title: 'Vente Vide-dressing finalisée',
          body: 'La vente de "${listing.title}" a été marquée comme finalisée.',
          event: 'secondhand_sold',
          priority: 'normal',
        ),
      );
    }
  }

  Future<void> requestWithdrawal(SecondhandListing listing) async {
    final userId = currentUserId;
    if (userId == null || listing.sellerId != userId) {
      throw StateError('Seul le vendeur peut demander le retrait.');
    }
    if (!listing.hasSettlementAvailable) {
      throw StateError('Aucun solde vide-dressing disponible pour retrait.');
    }

    final requestRef = _firestore
        .collection('seller_withdrawal_requests')
        .doc('secondhand_${listing.id}');
    final listingRef = _collection.doc(listing.id);
    final userRef = _firestore.collection('users').doc(userId);
    late double withdrawalAmount;
    late String withdrawalCurrency;
    late String withdrawalReference;
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(listingRef);
      final userSnapshot = await transaction.get(userRef);
      final data = snapshot.data() ?? const <String, dynamic>{};
      final userData = userSnapshot.data() ?? const <String, dynamic>{};
      final sellerPaymentMethods = _paymentMethodsFromUser(userData);
      if (sellerPaymentMethods.isEmpty) {
        throw StateError(
          'Ajoutez au moins un moyen de retrait dans votre profil client.',
        );
      }
      final balance = _map(data['secondhandBalance']);
      final balanceStatus =
          data['secondhandBalanceStatus']?.toString() ??
          balance['status']?.toString() ??
          '';
      if (balanceStatus == 'withdrawal_requested') {
        throw StateError('Une demande de retrait est déjà en cours.');
      }
      if (balanceStatus != 'available') {
        throw StateError('Ce solde n’est plus disponible.');
      }
      final amount =
          (balance['availableBalance'] as num?)?.toDouble() ?? listing.price;
      final currency =
          balance['currency']?.toString().trim().isNotEmpty == true
              ? balance['currency'].toString()
              : listing.currency;
      final reference =
          data['paymentReference']?.toString().trim().isNotEmpty == true
              ? data['paymentReference'].toString()
              : 'VD-${listing.id}';
      withdrawalAmount = amount;
      withdrawalCurrency = currency;
      withdrawalReference = reference;

      transaction.set(requestRef, {
        'orderId': '',
        'listingId': listing.id,
        'sellerId': userId,
        'sellerName': listing.sellerName,
        'sellerRole': 'client',
        'clientId': data['reservedBy']?.toString() ?? '',
        'amount': amount,
        'currency': currency,
        'paymentReference': reference,
        'sellerPaymentMethods': sellerPaymentMethods,
        'preferredPayoutMethod':
            sellerPaymentMethods.isEmpty ? '' : sellerPaymentMethods.keys.first,
        'preferredPayoutAccount':
            sellerPaymentMethods.isEmpty
                ? ''
                : sellerPaymentMethods.values.first,
        'status': 'pending_admin_transfer',
        'requestType': 'secondhand_client_withdrawal',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.set(listingRef, {
        'secondhandBalanceStatus': 'withdrawal_requested',
        'settlementChoice': 'withdrawal',
        'secondhandBalance.status': 'withdrawal_requested',
        'secondhandBalance.withdrawalRequestedAt': FieldValue.serverTimestamp(),
        'paymentTimeline': FieldValue.arrayUnion([
          {
            'status': 'withdrawal_requested',
            'label': 'Retrait vide-dressing demandé',
            'at': Timestamp.now(),
          },
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    await _notifySecondhand(
      () => _notificationService.notifyWithdrawalStatus(
        recipientId: userId,
        withdrawalId: requestRef.id,
        title: 'Retrait Vide-dressing demandé',
        body:
            'Votre demande de retrait ${CurrencyService.format(withdrawalAmount, code: withdrawalCurrency)} est en vérification admin.',
        status: 'requested',
        priority: 'high',
      ),
    );
    await _notifyAdminsOfSecondhandWithdrawal(
      listing: listing,
      requestId: requestRef.id,
      amount: withdrawalAmount,
      currency: withdrawalCurrency,
      reference: withdrawalReference,
    );
  }

  Future<int> convertSaleToStylePoints(SecondhandListing listing) async {
    final userId = currentUserId;
    if (userId == null || listing.sellerId != userId) {
      throw StateError('Seul le vendeur peut convertir cette vente.');
    }
    if (!listing.hasSettlementAvailable) {
      throw StateError('Aucun solde vide-dressing disponible à convertir.');
    }
    final listingRef = _collection.doc(listing.id);
    final userRef = _firestore.collection('users').doc(userId);
    late int awardedPoints;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(listingRef);
      final data = snapshot.data() ?? const <String, dynamic>{};
      final balance = _map(data['secondhandBalance']);
      final balanceStatus =
          data['secondhandBalanceStatus']?.toString() ??
          balance['status']?.toString() ??
          '';
      if (balanceStatus != 'available') {
        throw StateError('Ce solde n’est plus disponible.');
      }
      final amount =
          (balance['availableBalance'] as num?)?.toDouble() ?? listing.price;
      final currency =
          balance['currency']?.toString().trim().isNotEmpty == true
              ? balance['currency'].toString()
              : listing.currency;
      awardedPoints = SecondhandSettlementPolicy.stylePointsFor(
        amount: amount,
        currency: currency,
      );

      transaction.set(listingRef, {
        'secondhandBalanceStatus': 'converted_to_style_points',
        'settlementChoice': 'style_points',
        'stylePointsAwarded': awardedPoints,
        'secondhandBalance': {
          'availableBalance': 0.0,
          'withdrawnBalance': 0.0,
          'convertedBalance': amount,
          'expectedSellerAmount': amount,
          'stylePointsAwarded': awardedPoints,
          'currency': currency,
          'status': 'converted_to_style_points',
          'convertedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'paymentTimeline': FieldValue.arrayUnion([
          {
            'status': 'converted_to_style_points',
            'label': '$awardedPoints points Style reçus à la place du retrait',
            'at': Timestamp.now(),
          },
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.set(userRef, {
        'gamification.points': FieldValue.increment(awardedPoints),
        'gamification.lifetimePoints': FieldValue.increment(awardedPoints),
        'gamification.pointBuckets.community': FieldValue.increment(
          awardedPoints,
        ),
        'gamification.lastActivityDate': _todayKey(),
        'gamification.completedChallengesToday': FieldValue.arrayUnion([
          'secondhand_conversion',
        ]),
        'gamification.updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.set(
        userRef
            .collection('visibility_activity')
            .doc('secondhand_${listing.id}'),
        {
          'type': 'secondhand_conversion',
          'listingId': listing.id,
          'pointCategory': 'community',
          'title': 'Vente convertie en points Style',
          'points': awardedPoints,
          'amount': amount,
          'currency': currency,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
    await _notifySecondhand(
      () => _notificationService.notifySecondhandEvent(
        recipientId: userId,
        listingId: listing.id,
        title: 'Points Style ajoutés',
        body:
            '$awardedPoints points Style ont été ajoutés après la vente de "${listing.title}".',
        event: 'secondhand_points_converted',
        priority: 'normal',
      ),
    );
    return awardedPoints;
  }

  Future<SecondhandSellerTrust> loadSellerTrust(String sellerId) async {
    if (sellerId.trim().isEmpty) return SecondhandSellerTrust.empty;
    final cached = _sellerTrustCache[sellerId];
    if (cached != null && cached.isFresh) return cached.value;

    final profile = await _publicProfileService.load(sellerId);
    final listings =
        await _collection
            .where('sellerId', isEqualTo: sellerId)
            .limit(80)
            .get();
    var available = 0;
    var sold = 0;
    for (final doc in listings.docs) {
      final status = doc.data()['status']?.toString() ?? '';
      if (status == 'available') available++;
      if (status == 'sold') sold++;
    }
    final trust = SecondhandSellerTrust(
      sellerName: profile?.displayName ?? 'Client ElegantStyle',
      photoUrl: profile?.photoUrl ?? '',
      roleLabel: profile?.roleLabel ?? 'Client de la communauté',
      city: profile?.city ?? '',
      isVerified: profile?.isVerified ?? false,
      rating: profile?.rating ?? 0,
      reviewCount: profile?.reviewCount ?? 0,
      activeListings: available,
      soldListings: sold,
    );
    _sellerTrustCache[sellerId] = _SellerTrustCacheEntry(trust);
    return trust;
  }

  Future<void> toggleLike(SecondhandListing listing) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Connectez-vous pour aimer.');
    final ref = _collection.doc(listing.id);
    final liked = listing.likedBy.contains(userId);
    await ref.set({
      'likedBy':
          liked
              ? FieldValue.arrayRemove([userId])
              : FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> report(SecondhandListing listing, String reason) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Connectez-vous pour signaler.');
    await _firestore.collection('secondhand_reports').add({
      'listingId': listing.id,
      'sellerId': listing.sellerId,
      'reporterId': userId,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _notifyAdminsOfSecondhandWithdrawal({
    required SecondhandListing listing,
    required String requestId,
    required double amount,
    required String currency,
    required String reference,
  }) async {
    try {
      final adminDocs =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .limit(10)
              .get();
      for (final admin in adminDocs.docs) {
        await _notificationService.notifyWithdrawalStatus(
          recipientId: admin.id,
          withdrawalId: requestId,
          title: 'Retrait Vide-dressing à traiter',
          body:
              '${listing.sellerName} demande ${CurrencyService.format(amount, code: currency)} • $reference.',
          status: 'pending_admin_transfer',
          priority: 'high',
        );
      }
    } catch (_) {
      // Une notification ne doit jamais bloquer une transaction financière.
    }
  }

  Future<void> _notifySecondhand(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // L’action principale reste prioritaire si la notification échoue.
    }
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    return value.map(
      (key, entry) => MapEntry(key.toString(), entry?.toString() ?? ''),
    )..removeWhere((key, entry) => key.trim().isEmpty || entry.trim().isEmpty);
  }

  static Map<String, String> _paymentMethodsFromUser(
    Map<String, dynamic> data,
  ) {
    final methods = <String, String>{..._stringMap(data['paymentMethods'])};
    final method = data['paymentMethod']?.toString() ?? '';
    final number = data['paymentNumber']?.toString() ?? '';
    if (method.trim().isNotEmpty && number.trim().isNotEmpty) {
      methods[_paymentMethodLabel(method)] = number.trim();
    }
    return methods;
  }

  static String _paymentMethodLabel(String value) {
    return switch (value.trim().toLowerCase()) {
      'orange_money' => 'Orange Money',
      'moov_money' => 'Moov Money',
      'wave' => 'Wave',
      'mobile_money' => 'Mobile Money',
      _ => value.trim().isEmpty ? 'Paiement mobile' : value.trim(),
    };
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class _SellerTrustCacheEntry {
  _SellerTrustCacheEntry(this.value) : createdAt = DateTime.now();

  final SecondhandSellerTrust value;
  final DateTime createdAt;

  bool get isFresh =>
      DateTime.now().difference(createdAt) <
      SecondhandListingService._trustCacheTtl;
}

class SecondhandSnapshot {
  const SecondhandSnapshot({
    required this.total,
    required this.available,
    required this.reserved,
    required this.sold,
  });

  final int total;
  final int available;
  final int reserved;
  final int sold;
}

class SecondhandSellerTrust {
  const SecondhandSellerTrust({
    required this.sellerName,
    required this.photoUrl,
    required this.roleLabel,
    required this.city,
    required this.isVerified,
    required this.rating,
    required this.reviewCount,
    required this.activeListings,
    required this.soldListings,
  });

  static const empty = SecondhandSellerTrust(
    sellerName: 'Client ElegantStyle',
    photoUrl: '',
    roleLabel: 'Client de la communauté',
    city: '',
    isVerified: false,
    rating: 0,
    reviewCount: 0,
    activeListings: 0,
    soldListings: 0,
  );

  final String sellerName;
  final String photoUrl;
  final String roleLabel;
  final String city;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final int activeListings;
  final int soldListings;
}
