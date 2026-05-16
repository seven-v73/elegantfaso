import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/account_roles.dart';
import '../../models/commerce/platform_revenue.dart';
import 'commerce_revenue_service.dart';

class ProGrowthService {
  ProGrowthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      _revenueService = CommerceRevenueService(firestore: firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final CommerceRevenueService _revenueService;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<ProGrowthState> watchCurrentState() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(ProGrowthState.guest());

    return _firestore.collection('users').doc(uid).snapshots().asyncMap((
      userDoc,
    ) async {
      final userData = userDoc.data() ?? const <String, dynamic>{};
      final roles = AccountRoles.normalize(userData);
      final subscriptionDoc =
          await _firestore.collection('seller_subscriptions').doc(uid).get();
      final planRequests =
          await _firestore
              .collection('pro_upgrade_requests')
              .where('userId', isEqualTo: uid)
              .limit(5)
              .get();
      final pendingPlanDocs =
          planRequests.docs
              .where((doc) => _isPendingStatus(doc.data()['status']))
              .toList();
      final boosts =
          await _firestore
              .collection('boost_campaigns')
              .where('ownerId', isEqualTo: uid)
              .limit(10)
              .get();

      return ProGrowthState(
        userId: uid,
        roles: roles,
        subscription:
            subscriptionDoc.exists
                ? SellerSubscription.fromFirestore(subscriptionDoc)
                : null,
        pendingPlan:
            pendingPlanDocs.isEmpty
                ? null
                : pendingPlanDocs.first.data()['plan']?.toString(),
        pendingPlanCount: pendingPlanDocs.length,
        boostCount: boosts.docs.length,
        hasActiveBoost: boosts.docs
            .map(BoostCampaign.fromFirestore)
            .any((boost) => boost.isActive),
        pendingBoostCount:
            boosts.docs
                .where((doc) => _isPendingStatus(doc.data()['status']))
                .length,
      );
    });
  }

  Stream<CommerceRevenueConfig> watchRevenueConfig() {
    return _revenueService.watchConfig();
  }

  Future<String> requestPlanUpgrade({
    required String plan,
    required double monthlyPrice,
    required String paymentMethod,
    required String proofImageUrl,
    Map<String, dynamic>? proofMedia,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Utilisateur non connecté');
    final normalizedPlan = normalizePlanForStorage(plan);

    final userRef = _firestore.collection('users').doc(uid);
    final requestRef = _firestore.collection('pro_upgrade_requests').doc();
    final userDoc = await userRef.get();
    final userData = userDoc.data() ?? const <String, dynamic>{};
    final roles = AccountRoles.normalize(userDoc.data());
    final businessRoles = _businessRoles(roles);
    final activeSubscription =
        await _firestore.collection('seller_subscriptions').doc(uid).get();
    if (activeSubscription.exists) {
      final current = SellerSubscription.fromFirestore(activeSubscription);
      if (current.isActive &&
          normalizePlanForStorage(current.plan) == normalizedPlan) {
        throw StateError('Ce plan est déjà actif.');
      }
    }
    final existing =
        await _firestore
            .collection('pro_upgrade_requests')
            .where('userId', isEqualTo: uid)
            .limit(5)
            .get();
    if (existing.docs.any((doc) => _isPendingStatus(doc.data()['status']))) {
      throw StateError('Une demande de plan est déjà en attente.');
    }

    final batch = _firestore.batch();
    final reference = _reference('PLAN');
    final config = await _revenueService.loadConfig();
    batch.set(requestRef, {
      'userId': uid,
      'accountId': uid,
      'reference': reference,
      'requestLabel': 'Plan ${planDisplayLabel(normalizedPlan)}',
      'plan': normalizedPlan,
      'monthlyPrice': monthlyPrice,
      'amount': monthlyPrice,
      'currency': config.currency,
      'durationDays': 30,
      'status': 'pending_payment',
      'paymentStatus': 'pending',
      'paymentReference': reference,
      'paymentMethod': paymentMethod,
      if (proofImageUrl.isNotEmpty) 'proofImageUrl': proofImageUrl,
      if (proofMedia != null) 'paymentProofMedia': proofMedia,
      'paymentInstructions':
          'Effectuez le paiement avec cette référence, puis contactez l’administration pour validation.',
      'userName':
          userData['displayName']?.toString() ??
          userData['name']?.toString() ??
          _auth.currentUser?.displayName ??
          '',
      'userEmail': userData['email']?.toString() ?? _auth.currentUser?.email,
      'rolesApplied': businessRoles,
      'sharedAcrossRoles': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (proofImageUrl.isNotEmpty) {
      batch.set(requestRef, {
        'status': 'pending_review',
        'paymentStatus': 'client_marked_paid',
        'paidMarkedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    batch.set(userRef, {
      'businessEntitlements': {
        'plan': normalizedPlan,
        'status': proofImageUrl.isEmpty ? 'pending_payment' : 'pending_review',
        'reference': reference,
        'amount': monthlyPrice,
        'durationDays': 30,
        'paymentMethod': paymentMethod,
        'rolesApplied': businessRoles,
        'sharedAcrossRoles': true,
        'requestedAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
    return reference;
  }

  Future<String> requestAccountBoost({
    required String sourceRole,
    required double budget,
    required String paymentMethod,
    required String proofImageUrl,
    Map<String, dynamic>? proofMedia,
    int days = 7,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Utilisateur non connecté');

    final userRef = _firestore.collection('users').doc(uid);
    final userDoc = await userRef.get();
    final userData = userDoc.data() ?? const <String, dynamic>{};
    final roles = AccountRoles.normalize(userDoc.data());
    final businessRoles = _businessRoles(roles);
    final subscriptionDoc =
        await _firestore.collection('seller_subscriptions').doc(uid).get();
    final subscription =
        subscriptionDoc.exists
            ? SellerSubscription.fromFirestore(subscriptionDoc)
            : null;
    if (!hasActiveSignatureAccess(
      subscription: subscription,
      entitlements: _mapFrom(userData['businessEntitlements']),
    )) {
      throw StateError(
        'La mise en avant est réservée aux comptes Signature actifs.',
      );
    }
    final existing =
        await _firestore
            .collection('boost_campaigns')
            .where('ownerId', isEqualTo: uid)
            .limit(10)
            .get();
    if (existing.docs.any((doc) => _isPendingStatus(doc.data()['status']))) {
      throw StateError('Une mise en avant est déjà en attente.');
    }
    final active =
        await _firestore
            .collection('boost_campaigns')
            .where('ownerId', isEqualTo: uid)
            .where('status', isEqualTo: 'active')
            .limit(5)
            .get();
    final hasActive = active.docs
        .map(BoostCampaign.fromFirestore)
        .any((boost) => boost.isActive);
    if (hasActive) {
      throw StateError('Une mise en avant est déjà active.');
    }
    final now = DateTime.now();
    final endsAt = now.add(Duration(days: days));

    final boostRef = _firestore.collection('boost_campaigns').doc();
    final reference = _reference('BOOST');
    final batch = _firestore.batch();
    final config = await _revenueService.loadConfig();
    batch.set(boostRef, {
      'ownerId': uid,
      'accountId': uid,
      'reference': reference,
      'requestLabel': 'Mise en avant compte',
      'targetId': uid,
      'targetType': 'account',
      'placement': 'salon_all',
      'sourceRole': sourceRole,
      'rolesApplied': businessRoles,
      'sharedAcrossRoles': true,
      'budget': budget,
      'amount': budget,
      'currency': config.currency,
      'status': 'pending_payment',
      'paymentStatus': 'pending',
      'paymentReference': reference,
      'paymentMethod': paymentMethod,
      if (proofImageUrl.isNotEmpty) 'proofImageUrl': proofImageUrl,
      if (proofMedia != null) 'paymentProofMedia': proofMedia,
      'paymentInstructions':
          'Effectuez le paiement avec cette référence pour lancer la mise en avant.',
      'userName':
          userData['displayName']?.toString() ??
          userData['name']?.toString() ??
          _auth.currentUser?.displayName ??
          '',
      'userEmail': userData['email']?.toString() ?? _auth.currentUser?.email,
      'startsAt': Timestamp.fromDate(now),
      'endsAt': Timestamp.fromDate(endsAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (proofImageUrl.isNotEmpty) {
      batch.set(boostRef, {
        'status': 'pending_review',
        'paymentStatus': 'client_marked_paid',
        'paidMarkedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    batch.set(userRef, {
      'businessEntitlements': {
        'boost': {
          'status':
              proofImageUrl.isEmpty ? 'pending_payment' : 'pending_review',
          'campaignId': boostRef.id,
          'reference': reference,
          'amount': budget,
          'paymentMethod': paymentMethod,
          'sourceRole': sourceRole,
          'rolesApplied': businessRoles,
          'sharedAcrossRoles': true,
          'requestedAt': FieldValue.serverTimestamp(),
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
    return reference;
  }

  static List<String> _businessRoles(List<String> roles) {
    final result =
        roles
            .where((role) => AccountRoles.businessRoles.contains(role))
            .toSet();
    if (result.isEmpty) result.add(AccountRoles.createur);
    return result.toList();
  }

  static bool _isPendingStatus(dynamic value) {
    final status = value?.toString() ?? '';
    return status == 'pending_payment' || status == 'pending_review';
  }

  static String normalizePlanForStorage(String plan) {
    final normalized = plan.toLowerCase().trim();
    if (normalized == 'premium' || normalized == 'signature') {
      return 'premium';
    }
    if (normalized == 'pro') return 'pro';
    return 'starter';
  }

  static String planDisplayLabel(String plan) {
    return switch (normalizePlanForStorage(plan)) {
      'premium' => 'Signature',
      'pro' => 'Pro',
      _ => 'Starter',
    };
  }

  static bool hasActiveSignatureAccess({
    SellerSubscription? subscription,
    Map<String, dynamic> entitlements = const {},
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    if (subscription != null &&
        normalizePlanForStorage(subscription.plan) == 'premium' &&
        subscription.status.toLowerCase().trim() == 'active' &&
        subscription.expiresAt != null &&
        subscription.expiresAt!.isAfter(current)) {
      return true;
    }

    final plan = normalizePlanForStorage(
      entitlements['plan']?.toString() ?? '',
    );
    final status = entitlements['status']?.toString().toLowerCase().trim();
    final expiresAt = _dateFrom(entitlements['expiresAt']);
    return plan == 'premium' &&
        status == 'active' &&
        expiresAt != null &&
        expiresAt.isAfter(current);
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

  static String _reference(String prefix) {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return '$prefix-$stamp-${now.millisecond.toString().padLeft(3, '0')}';
  }
}

class ProGrowthState {
  const ProGrowthState({
    required this.userId,
    required this.roles,
    required this.subscription,
    required this.pendingPlan,
    required this.pendingPlanCount,
    required this.boostCount,
    required this.hasActiveBoost,
    required this.pendingBoostCount,
  });

  final String? userId;
  final List<String> roles;
  final SellerSubscription? subscription;
  final String? pendingPlan;
  final int pendingPlanCount;
  final int boostCount;
  final bool hasActiveBoost;
  final int pendingBoostCount;

  bool get isGuest => userId == null;
  bool get hasBusinessRole =>
      roles.any((role) => AccountRoles.businessRoles.contains(role));
  bool get hasSharedRoles =>
      roles.contains(AccountRoles.createur) &&
      roles.contains(AccountRoles.boutique);
  bool get hasActivePlan => subscription?.isActive ?? false;
  bool get hasExpiredPlan => subscription?.isExpired ?? false;
  bool get hasSignaturePlan =>
      hasActivePlan &&
      ProGrowthService.normalizePlanForStorage(subscription?.plan ?? '') ==
          'premium';
  bool get hasPremiumPlan => hasSignaturePlan;
  bool get hasPendingPlan => pendingPlanCount > 0;
  String get planLabel {
    return ProGrowthService.planDisplayLabel(subscription?.plan ?? 'starter');
  }

  static ProGrowthState guest() {
    return const ProGrowthState(
      userId: null,
      roles: [],
      subscription: null,
      pendingPlan: null,
      pendingPlanCount: 0,
      boostCount: 0,
      hasActiveBoost: false,
      pendingBoostCount: 0,
    );
  }
}
