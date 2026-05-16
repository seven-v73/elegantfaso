import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/shop/public_listing.dart';

class SalonProductService {
  SalonProductService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<PublicListing>> watchListings({int limit = 32}) {
    final products = _firestore.collection('products').limit(limit).snapshots();
    final creations =
        _firestore.collection('creations').limit(limit).snapshots();
    final secondhand =
        _firestore.collection('secondhand_listings').limit(limit).snapshots();

    return Rx.combineLatest3(products, creations, secondhand, (
      QuerySnapshot<Map<String, dynamic>> productSnapshot,
      QuerySnapshot<Map<String, dynamic>> creationSnapshot,
      QuerySnapshot<Map<String, dynamic>> secondhandSnapshot,
    ) {
      final items = [
        ...productSnapshot.docs
            .where((doc) => _isPublicDoc(doc.data()))
            .map(PublicListing.product),
        ...creationSnapshot.docs
            .where((doc) => _isPublicDoc(doc.data()))
            .map(PublicListing.creation),
        ...secondhandSnapshot.docs
            .where((doc) => _isPublicSecondhandDoc(doc.data()))
            .map(PublicListing.secondhand),
      ];
      items.sort((a, b) {
        final aDate = _dateFrom(a.data);
        final bDate = _dateFrom(b.data);
        return bDate.compareTo(aDate);
      });
      return items;
    });
  }

  Future<PublicListing?> refreshListing(PublicListing listing) async {
    final collection =
        listing.isSecondhand
            ? 'secondhand_listings'
            : listing.isProduct
            ? 'products'
            : 'creations';
    final doc = await _firestore.collection(collection).doc(listing.id).get();
    if (!doc.exists || doc.data() == null) return null;
    if (listing.isSecondhand) {
      if (!_isPublicSecondhandDoc(doc.data()!)) return null;
      return PublicListing.secondhand(doc);
    }
    if (!_isPublicDoc(doc.data()!)) return null;
    return listing.isProduct
        ? PublicListing.product(doc)
        : PublicListing.creation(doc);
  }

  bool _isPublicSecondhandDoc(Map<String, dynamic> data) {
    if (!_isPublicDoc(data)) return false;
    final status = data['status']?.toString().toLowerCase() ?? 'available';
    return status == 'available';
  }

  bool _isPublicDoc(Map<String, dynamic> data) {
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

  DateTime _dateFrom(Map<String, dynamic> data) {
    for (final key in const ['createdAt', 'created_at', 'updatedAt']) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
