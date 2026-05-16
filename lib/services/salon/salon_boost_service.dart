import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/commerce/platform_revenue.dart';

class SalonBoostService {
  SalonBoostService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<SalonBoostIndex> loadActiveBoostIndex() async {
    final snapshot =
        await _firestore
            .collection('boost_campaigns')
            .where('status', isEqualTo: 'active')
            .limit(80)
            .get();
    return SalonBoostIndex.fromBoosts(
      snapshot.docs.map(BoostCampaign.fromFirestore),
    );
  }

  Stream<SalonBoostIndex> watchActiveBoostIndex() {
    return _firestore
        .collection('boost_campaigns')
        .where('status', isEqualTo: 'active')
        .limit(80)
        .snapshots()
        .map(
          (snapshot) => SalonBoostIndex.fromBoosts(
            snapshot.docs.map(BoostCampaign.fromFirestore),
          ),
        );
  }
}

class SalonBoostIndex {
  const SalonBoostIndex({
    this.ownerIds = const {},
    this.targetIds = const {},
    this.placements = const {},
  });

  final Set<String> ownerIds;
  final Set<String> targetIds;
  final Set<String> placements;

  bool get isEmpty => ownerIds.isEmpty && targetIds.isEmpty;

  factory SalonBoostIndex.fromBoosts(Iterable<BoostCampaign> boosts) {
    final ownerIds = <String>{};
    final targetIds = <String>{};
    final placements = <String>{};

    for (final boost in boosts) {
      if (!boost.isActive) continue;
      if (boost.ownerId.trim().isNotEmpty) ownerIds.add(boost.ownerId.trim());
      if (boost.targetId.trim().isNotEmpty) {
        targetIds.add(boost.targetId.trim());
      }
      if (boost.placement.trim().isNotEmpty) {
        placements.add(boost.placement.trim());
      }
    }

    return SalonBoostIndex(
      ownerIds: ownerIds,
      targetIds: targetIds,
      placements: placements,
    );
  }

  bool isBoosted({
    required String id,
    required String ownerId,
    Map<String, dynamic> data = const {},
  }) {
    if (targetIds.contains(id) || ownerIds.contains(ownerId)) return true;

    for (final key in const [
      'sellerId',
      'boutiqueId',
      'createurId',
      'creatorId',
      'userId',
      'ownerId',
      'organizerId',
    ]) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty && ownerIds.contains(value)) {
        return true;
      }
    }

    final entitlements = data['businessEntitlements'];
    if (entitlements is Map) {
      final boost = entitlements['boost'];
      if (boost is Map && _entitlementBoostIsActive(boost)) return true;
    }

    return false;
  }

  int boostScore({
    required String id,
    required String ownerId,
    Map<String, dynamic> data = const {},
  }) {
    return isBoosted(id: id, ownerId: ownerId, data: data) ? 100000 : 0;
  }

  static bool _entitlementBoostIsActive(Map<dynamic, dynamic> boost) {
    if (boost['status']?.toString() != 'active') return false;
    final now = DateTime.now();
    final startsAt = _dateFrom(boost['startsAt']);
    final endsAt = _dateFrom(boost['endsAt']);
    if (startsAt != null && startsAt.isAfter(now)) return false;
    if (endsAt != null && !endsAt.isAfter(now)) return false;
    return true;
  }

  static DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
