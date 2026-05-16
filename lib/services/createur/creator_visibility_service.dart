import 'package:cloud_firestore/cloud_firestore.dart';

class CreatorVisibilityService {
  CreatorVisibilityService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> updateOnlineStatus({
    required String creatorId,
    required bool isOnline,
  }) {
    return _firestore.collection('users').doc(creatorId).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
