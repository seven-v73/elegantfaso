import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/salon/salon_item.dart';

class SalonAnalyticsService {
  SalonAnalyticsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  static final Set<String> _trackedSessionViews = <String>{};

  Future<void> track({
    required SalonItem item,
    required String eventType,
  }) async {
    try {
      await _firestore.collection('salon_analytics').add({
        'eventType': eventType,
        'itemId': item.id,
        'itemType': item.type.name,
        'ownerId': item.ownerId,
        'viewerId': _auth.currentUser?.uid,
        'title': item.title,
        'city': item.city,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _incrementCountersForItem(item: item, eventType: eventType);
    } catch (_) {
      // Analytics must never block the user journey.
    }
  }

  Future<void> trackView({required SalonItem item}) {
    final eventType = switch (item.type) {
      SalonItemType.product => 'product_view',
      SalonItemType.creation => 'creation_view',
      SalonItemType.talent => 'profile_view',
      SalonItemType.event => 'event_view',
      SalonItemType.inspiration => 'inspiration_view',
      SalonItemType.video => 'video_view',
      SalonItemType.article => 'article_view',
    };
    return track(item: item, eventType: eventType);
  }

  Future<void> trackListingView({
    required String itemId,
    required String itemType,
    required String ownerId,
    required String title,
    String city = '',
  }) async {
    if (itemId.trim().isEmpty) return;
    final normalizedType = itemType.toLowerCase().trim();
    final eventType =
        normalizedType == 'creation' ? 'creation_view' : 'product_view';
    final viewerId = _auth.currentUser?.uid;
    if (viewerId != null && ownerId.isNotEmpty && viewerId == ownerId) return;
    if (!_markViewOnce('$eventType:$itemId:${viewerId ?? 'anon'}')) return;

    try {
      await _firestore.collection('salon_analytics').add({
        'eventType': eventType,
        'itemId': itemId,
        'itemType': normalizedType == 'creation' ? 'creation' : 'product',
        'ownerId': ownerId,
        'viewerId': viewerId,
        'title': title,
        'city': city,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _incrementListingCounters(
        collection: normalizedType == 'creation' ? 'creations' : 'products',
        itemId: itemId,
        ownerId: ownerId,
      );
    } catch (_) {
      // Analytics must never block the user journey.
    }
  }

  Future<void> trackProfileView({
    required String profileId,
    String title = '',
    String role = 'createur',
  }) async {
    final viewerId = _auth.currentUser?.uid;
    if (viewerId != null && viewerId == profileId) return;
    if (!_markViewOnce('profile_view:$profileId:${viewerId ?? 'anon'}')) {
      return;
    }

    try {
      await _firestore.collection('salon_analytics').add({
        'eventType': 'profile_view',
        'itemId': profileId,
        'itemType': 'profile',
        'ownerId': profileId,
        'viewerId': viewerId,
        'title': title,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('users').doc(profileId).update({
        'profileViewsCount': FieldValue.increment(1),
        'viewsCount': FieldValue.increment(1),
        'stats.profileViews': FieldValue.increment(1),
        'stats.views': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Analytics must never block the user journey.
    }
  }

  Future<void> _incrementCountersForItem({
    required SalonItem item,
    required String eventType,
  }) async {
    if (!eventType.endsWith('_view') && eventType != 'view') return;
    final viewerId = _auth.currentUser?.uid;
    if (viewerId != null &&
        item.ownerId.isNotEmpty &&
        viewerId == item.ownerId) {
      return;
    }
    if (!_markViewOnce('${item.type.name}:${item.id}:${viewerId ?? 'anon'}')) {
      return;
    }

    switch (item.type) {
      case SalonItemType.product:
        await _incrementListingCounters(
          collection: 'products',
          itemId: item.id,
          ownerId: item.ownerId,
        );
      case SalonItemType.creation:
        await _incrementListingCounters(
          collection: 'creations',
          itemId: item.id,
          ownerId: item.ownerId,
        );
      case SalonItemType.talent:
        await trackProfileView(
          profileId: item.ownerId.isEmpty ? item.id : item.ownerId,
          title: item.title,
        );
      case SalonItemType.event:
      case SalonItemType.inspiration:
      case SalonItemType.video:
      case SalonItemType.article:
        break;
    }
  }

  Future<void> _incrementListingCounters({
    required String collection,
    required String itemId,
    required String ownerId,
  }) async {
    if (itemId.trim().isEmpty) return;
    await _firestore.collection(collection).doc(itemId).update({
      'viewsCount': FieldValue.increment(1),
      'viewCount': FieldValue.increment(1),
      'stats.views': FieldValue.increment(1),
      'lastViewedAt': FieldValue.serverTimestamp(),
    });

    if (ownerId.trim().isEmpty) return;
    final ownerField =
        collection == 'creations'
            ? 'stats.creationViews'
            : 'stats.productViews';
    await _firestore.collection('users').doc(ownerId).update({
      ownerField: FieldValue.increment(1),
      'stats.salonViews': FieldValue.increment(1),
      'lastContentViewedAt': FieldValue.serverTimestamp(),
    });
  }

  bool _markViewOnce(String key) {
    if (_trackedSessionViews.contains(key)) return false;
    _trackedSessionViews.add(key);
    return true;
  }
}
