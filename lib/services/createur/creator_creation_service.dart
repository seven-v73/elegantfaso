import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/createur/creator_creation.dart';

class CreatorCreationService {
  CreatorCreationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<CreatorCreation>> watchCreations(String creatorId) {
    if (creatorId.isEmpty) return Stream.value(const []);
    final byCreateur =
        _firestore
            .collection('creations')
            .where('createurId', isEqualTo: creatorId)
            .snapshots();
    final byCreator =
        _firestore
            .collection('creations')
            .where('creatorId', isEqualTo: creatorId)
            .snapshots();

    return Rx.combineLatest2(byCreateur, byCreator, (
      QuerySnapshot<Map<String, dynamic>> createurSnapshot,
      QuerySnapshot<Map<String, dynamic>> creatorSnapshot,
    ) {
      final docs = {
        for (final doc in createurSnapshot.docs) doc.id: doc,
        for (final doc in creatorSnapshot.docs) doc.id: doc,
      }.values.where((doc) {
        final data = doc.data();
        final status = data['status']?.toString() ?? '';
        return status != 'archived' &&
            status != 'deleted' &&
            data['deletedAt'] == null;
      });
      final creations = docs.map(CreatorCreation.fromDoc).toList();
      creations.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return creations;
    });
  }

  Future<List<CreatorCreation>> loadCreations(String creatorId) async {
    final docs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final field in const ['createurId', 'creatorId']) {
      final snapshot =
          await _firestore
              .collection('creations')
              .where(field, isEqualTo: creatorId)
              .limit(80)
              .get();
      for (final doc in snapshot.docs) {
        docs[doc.id] = doc;
      }
    }
    return docs.values.map(CreatorCreation.fromDoc).toList();
  }

  Future<void> updateStatus(String creationId, String status) {
    return _firestore.collection('creations').doc(creationId).set({
      'status': status,
      'visibility': status == 'hidden' ? 'private' : 'salon',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> duplicateCreation(CreatorCreation creation) {
    return _firestore.collection('creations').add({
      ...creation.raw,
      'title': '${creation.title} copie',
      'status': 'draft',
      'visibility': 'private',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCreation(String creationId) {
    return _firestore.collection('creations').doc(creationId).set({
      'status': 'archived',
      'visibility': 'private',
      'archivedAt': FieldValue.serverTimestamp(),
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> restoreCreation(CreatorCreation creation) {
    return _firestore.collection('creations').doc(creation.id).set({
      ...creation.raw,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
