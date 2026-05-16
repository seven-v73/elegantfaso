import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/commerce/platform_revenue.dart';
import '../notifications/app_notification_service.dart';

enum ProPlanTier { free, pro, signature }

class ProFeatureLimits {
  const ProFeatureLimits({
    required this.productLimit,
    required this.creationLimit,
    required this.photosPerItem,
    required this.communityLimit,
    required this.eventLimitPerMonth,
    required this.featuredSlots,
  });

  final int productLimit;
  final int creationLimit;
  final int photosPerItem;
  final int communityLimit;
  final int eventLimitPerMonth;
  final int featuredSlots;

  static const free = ProFeatureLimits(
    productLimit: 8,
    creationLimit: 8,
    photosPerItem: 4,
    communityLimit: 0,
    eventLimitPerMonth: 0,
    featuredSlots: 0,
  );

  static const pro = ProFeatureLimits(
    productLimit: 60,
    creationLimit: 60,
    photosPerItem: 8,
    communityLimit: 2,
    eventLimitPerMonth: 4,
    featuredSlots: 1,
  );

  static const signature = ProFeatureLimits(
    productLimit: 200,
    creationLimit: 200,
    photosPerItem: 12,
    communityLimit: 5,
    eventLimitPerMonth: 12,
    featuredSlots: 3,
  );
}

class ProAccessState {
  const ProAccessState({
    required this.userId,
    required this.tier,
    required this.status,
    required this.expiresAt,
    required this.limits,
    this.certificationBadge = '',
    this.hasActiveBoost = false,
    this.boostStatus = 'none',
    this.boostEndsAt,
    this.pendingPlan = false,
    this.expiredPlanLabel = '',
  });

  final String? userId;
  final ProPlanTier tier;
  final String status;
  final DateTime? expiresAt;
  final ProFeatureLimits limits;
  final String certificationBadge;
  final bool hasActiveBoost;
  final String boostStatus;
  final DateTime? boostEndsAt;
  final bool pendingPlan;
  final String expiredPlanLabel;

  bool get isGuest => userId == null;
  bool get isActive {
    if (tier == ProPlanTier.free) return false;
    if (status != 'active') return false;
    if (expiresAt == null) return false;
    return expiresAt!.isAfter(DateTime.now());
  }

  bool get isPro => isActive && tier == ProPlanTier.pro;
  bool get isSignature => isActive && tier == ProPlanTier.signature;
  bool get hasBusinessPlan => isPro || isSignature;
  bool get canCreateCommunity => hasBusinessPlan && limits.communityLimit > 0;
  bool get canCreateAgendaEvent =>
      hasBusinessPlan && limits.eventLimitPerMonth > 0;
  bool get canBoost => isSignature;
  bool get canUseBasicAnalytics => hasBusinessPlan;
  bool get canUseAdvancedAnalytics => isSignature;
  bool get canCustomizeShowcase => isSignature;
  bool get canPinPortfolio => hasBusinessPlan;
  bool get hasCertifiedBadge => hasBusinessPlan;
  bool get hasExpiredPlan => expiredPlanLabel.isNotEmpty;
  bool get hasPendingBoost =>
      boostStatus == 'pending_payment' || boostStatus == 'pending_review';
  bool get hasExpiredBoost => boostStatus == 'expired';

  String get planLabel {
    return switch (tier) {
      ProPlanTier.signature => 'Signature',
      ProPlanTier.pro => 'Pro',
      ProPlanTier.free =>
        pendingPlan
            ? 'En attente'
            : hasExpiredPlan
            ? '$expiredPlanLabel expiré'
            : 'Gratuit',
    };
  }

  String get badgeLabel {
    return switch (tier) {
      ProPlanTier.signature => 'Certifié Signature',
      ProPlanTier.pro => 'Certifié Pro',
      ProPlanTier.free => '',
    };
  }

  static const guest = ProAccessState(
    userId: null,
    tier: ProPlanTier.free,
    status: 'guest',
    expiresAt: null,
    limits: ProFeatureLimits.free,
  );
}

class ProAccessService {
  ProAccessService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    AppNotificationService? notificationService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService =
           notificationService ??
           AppNotificationService(firestore: firestore, auth: auth);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AppNotificationService _notificationService;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<ProAccessState> watchCurrentAccess() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(ProAccessState.guest);
    return _firestore.collection('users').doc(uid).snapshots().asyncMap((
      userDoc,
    ) async {
      final userData = userDoc.data() ?? const <String, dynamic>{};
      await _syncExpiredBoost(uid: uid, userData: userData);
      final subscriptionDoc =
          await _firestore.collection('seller_subscriptions').doc(uid).get();
      final boostDocs =
          await _firestore
              .collection('boost_campaigns')
              .where('ownerId', isEqualTo: uid)
              .where('status', isEqualTo: 'active')
              .limit(5)
              .get();
      return accessFromData(
        userId: uid,
        userData: userData,
        subscriptionData: subscriptionDoc.data(),
        hasActiveBoost: boostDocs.docs
            .map(BoostCampaign.fromFirestore)
            .any((boost) => boost.isActive),
      );
    });
  }

  Future<ProAccessState> getCurrentAccess() async {
    final uid = currentUserId;
    if (uid == null) return ProAccessState.guest;
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final subscriptionDoc =
        await _firestore.collection('seller_subscriptions').doc(uid).get();
    final boostDocs =
        await _firestore
            .collection('boost_campaigns')
            .where('ownerId', isEqualTo: uid)
            .where('status', isEqualTo: 'active')
            .limit(5)
            .get();
    await _syncExpiredBoost(
      uid: uid,
      userData: userDoc.data() ?? const <String, dynamic>{},
    );
    return accessFromData(
      userId: uid,
      userData: userDoc.data() ?? const <String, dynamic>{},
      subscriptionData: subscriptionDoc.data(),
      hasActiveBoost: boostDocs.docs
          .map(BoostCampaign.fromFirestore)
          .any((boost) => boost.isActive),
    );
  }

  Future<void> syncCurrentAccessLifecycle() async {
    final uid = currentUserId;
    if (uid == null) return;

    final userRef = _firestore.collection('users').doc(uid);
    final subscriptionRef = _firestore
        .collection('seller_subscriptions')
        .doc(uid);
    final userDoc = await userRef.get();
    final subscriptionDoc = await subscriptionRef.get();
    final userData = userDoc.data() ?? const <String, dynamic>{};
    final subscriptionData =
        subscriptionDoc.data() ?? const <String, dynamic>{};
    final access = accessFromData(
      userId: uid,
      userData: userData,
      subscriptionData: subscriptionData,
    );
    await _syncExpiredBoost(uid: uid, userData: userData);
    final rawStatus =
        _firstString([
          subscriptionData['status'],
          _mapFrom(userData['businessEntitlements'])['status'],
        ])?.toLowerCase() ??
        '';
    final expiresAt = access.expiresAt;
    if (expiresAt == null || rawStatus != 'active') return;

    final now = DateTime.now();
    final planLabel = access.planLabel;
    if (!expiresAt.isAfter(now)) {
      final alreadyNotified =
          subscriptionData['expiredNotifiedAt'] != null ||
          _mapFrom(userData['businessEntitlements'])['expiredNotifiedAt'] !=
              null;
      final batch = _firestore.batch();
      batch.set(subscriptionRef, {
        'status': 'expired',
        'expiredAt': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(userRef, {
        'businessEntitlements.status': 'expired',
        'businessEntitlements.expiredAt': Timestamp.fromDate(now),
        'businessEntitlements.updatedAt': FieldValue.serverTimestamp(),
        'certifiedProfessional': false,
        'certificationBadge': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
      if (!alreadyNotified) {
        await _notificationService.notifyProPlanExpiry(
          recipientId: uid,
          planLabel: planLabel,
          expiresAt: expiresAt,
          expired: true,
        );
        await userRef.set({
          'businessEntitlements.expiredNotifiedAt':
              FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await subscriptionRef.set({
          'expiredNotifiedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return;
    }

    final daysLeft = expiresAt.difference(now).inDays;
    final warningSent =
        subscriptionData['expiryWarningSentAt'] != null ||
        _mapFrom(userData['businessEntitlements'])['expiryWarningSentAt'] !=
            null;
    if (daysLeft <= 7 && !warningSent) {
      await _notificationService.notifyProPlanExpiry(
        recipientId: uid,
        planLabel: planLabel,
        expiresAt: expiresAt,
      );
      await userRef.set({
        'businessEntitlements.expiryWarningSentAt':
            FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await subscriptionRef.set({
        'expiryWarningSentAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _syncExpiredBoost({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    final entitlements = _mapFrom(userData['businessEntitlements']);
    final boost = _mapFrom(entitlements['boost']);
    if (boost.isEmpty || boost['status']?.toString() != 'active') return;
    final endsAt = _dateFrom(boost['endsAt']);
    if (endsAt == null || endsAt.isAfter(DateTime.now())) return;

    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(uid);
    batch.set(userRef, {
      'businessEntitlements.boost.status': 'expired',
      'businessEntitlements.boost.expiredAt': Timestamp.fromDate(
        DateTime.now(),
      ),
      'businessEntitlements.boost.updatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final campaignId = boost['campaignId']?.toString().trim() ?? '';
    if (campaignId.isNotEmpty) {
      batch.set(
        _firestore.collection('boost_campaigns').doc(campaignId),
        {
          'status': 'expired',
          'expiredAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<int> countOwnedCommunities(String userId) async {
    final snapshot =
        await _firestore
            .collection('community_groups')
            .where('ownerId', isEqualTo: userId)
            .where('status', whereIn: ['approved', 'active', 'published'])
            .limit(20)
            .get();
    return snapshot.size;
  }

  Future<int> countOwnedProducts(String userId) async {
    final snapshot =
        await _firestore
            .collection('products')
            .where('ownerId', isEqualTo: userId)
            .limit(250)
            .get();
    return snapshot.size;
  }

  Future<int> countOwnedCreations(String userId) async {
    final snapshot =
        await _firestore
            .collection('creations')
            .where('ownerId', isEqualTo: userId)
            .limit(250)
            .get();
    if (snapshot.docs.isNotEmpty) return snapshot.size;
    final legacy =
        await _firestore
            .collection('creations')
            .where('createurId', isEqualTo: userId)
            .limit(250)
            .get();
    return legacy.size;
  }

  Future<bool> canCreateCommunity(String userId) async {
    final access = await getCurrentAccess();
    if (!access.canCreateCommunity || access.userId != userId) return false;
    final count = await countOwnedCommunities(userId);
    return count < access.limits.communityLimit;
  }

  ProAccessState accessFromData({
    required String userId,
    required Map<String, dynamic> userData,
    Map<String, dynamic>? subscriptionData,
    bool hasActiveBoost = false,
  }) {
    final entitlement = _mapFrom(userData['businessEntitlements']);
    final subscription = subscriptionData ?? const <String, dynamic>{};
    final subscriptionTier = _tierFrom(subscription['plan']);
    final entitlementTier = _tierFrom(entitlement['plan']);
    final tier = _strongestTier(subscriptionTier, entitlementTier);
    final status =
        _firstString([subscription['status'], entitlement['status']]) ?? 'free';
    final expiresAt =
        _dateFrom(subscription['expiresAt']) ??
        _dateFrom(entitlement['expiresAt']);
    final pendingPlan =
        status == 'pending_payment' || status == 'pending_review';
    final expiredPlan =
        status == 'active' &&
        tier != ProPlanTier.free &&
        expiresAt != null &&
        !expiresAt.isAfter(DateTime.now());
    final activeTier =
        status == 'active' &&
                expiresAt != null &&
                expiresAt.isAfter(DateTime.now())
            ? tier
            : ProPlanTier.free;

    return ProAccessState(
      userId: userId,
      tier: activeTier,
      status:
          pendingPlan
              ? status
              : (activeTier == ProPlanTier.free ? 'free' : status),
      expiresAt: expiresAt,
      limits: _limitsFor(activeTier),
      certificationBadge:
          activeTier == ProPlanTier.free
              ? ''
              : userData['certificationBadge']?.toString() ??
                  entitlement['certificationBadge']?.toString() ??
                  '',
      hasActiveBoost: hasActiveBoost,
      boostStatus: _boostStatusFromEntitlement(entitlement, hasActiveBoost),
      boostEndsAt: _dateFrom(_mapFrom(entitlement['boost'])['endsAt']),
      pendingPlan: pendingPlan,
      expiredPlanLabel: expiredPlan ? _labelForTier(tier) : '',
    );
  }

  static ProPlanTier _strongestTier(ProPlanTier a, ProPlanTier b) {
    if (a == ProPlanTier.signature || b == ProPlanTier.signature) {
      return ProPlanTier.signature;
    }
    if (a == ProPlanTier.pro || b == ProPlanTier.pro) return ProPlanTier.pro;
    return ProPlanTier.free;
  }

  static ProFeatureLimits _limitsFor(ProPlanTier tier) {
    return switch (tier) {
      ProPlanTier.signature => ProFeatureLimits.signature,
      ProPlanTier.pro => ProFeatureLimits.pro,
      ProPlanTier.free => ProFeatureLimits.free,
    };
  }

  static ProPlanTier _tierFrom(Object? value) {
    final plan = value?.toString().toLowerCase().trim();
    if (plan == 'premium' || plan == 'signature') return ProPlanTier.signature;
    if (plan == 'pro') return ProPlanTier.pro;
    return ProPlanTier.free;
  }

  static String _labelForTier(ProPlanTier tier) {
    return switch (tier) {
      ProPlanTier.signature => 'Signature',
      ProPlanTier.pro => 'Pro',
      ProPlanTier.free => '',
    };
  }

  static String _boostStatusFromEntitlement(
    Map<String, dynamic> entitlement,
    bool hasActiveBoost,
  ) {
    if (hasActiveBoost) return 'active';
    final boost = _mapFrom(entitlement['boost']);
    final status = boost['status']?.toString().toLowerCase().trim();
    final endsAt = _dateFrom(boost['endsAt']);
    if (status == 'active' &&
        endsAt != null &&
        !endsAt.isAfter(DateTime.now())) {
      return 'expired';
    }
    if (status != null && status.isNotEmpty) return status;
    return 'none';
  }

  static Map<String, dynamic> _mapFrom(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  static DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String? _firstString(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}
