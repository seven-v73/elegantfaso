import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowService {
  FollowService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? get userId => _auth.currentUser?.uid;
  bool get isSignedIn => userId != null;

  Stream<bool> watchFollowing(String talentId) {
    final id = userId;
    if (id == null) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(id)
        .collection('following')
        .doc(talentId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> toggleFollow({
    required String talentId,
    required String talentName,
    String? professionalId,
    String? professionalRole,
  }) async {
    final id = userId;
    if (id == null) throw StateError('Connexion requise');
    final ownerId = _ownerIdFor(talentId, professionalId);
    final role = _roleFor(talentId, professionalRole);
    final userFollowRef = _firestore
        .collection('users')
        .doc(id)
        .collection('following')
        .doc(talentId);
    final currentUserRef = _firestore.collection('users').doc(id);
    final professionalRef = _firestore.collection('users').doc(ownerId);
    final talentFollowerRef = professionalRef.collection('followers').doc(id);

    await _firestore.runTransaction((transaction) async {
      final current = await transaction.get(userFollowRef);
      if (current.exists) {
        transaction.delete(userFollowRef);
        transaction.delete(talentFollowerRef);
        transaction.set(professionalRef, {
          'followers': FieldValue.arrayRemove([id]),
          'followersCount': FieldValue.increment(-1),
        }, SetOptions(merge: true));
        transaction.set(currentUserRef, {
          'following': FieldValue.arrayRemove([ownerId]),
          'followingTalentKeys': FieldValue.arrayRemove([talentId]),
        }, SetOptions(merge: true));
      } else {
        transaction.set(userFollowRef, {
          'talentId': talentId,
          'professionalId': ownerId,
          'professionalRole': role,
          'talentName': talentName,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.set(talentFollowerRef, {
          'followerId': id,
          'professionalRole': role,
          'talentKey': talentId,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.set(professionalRef, {
          'followers': FieldValue.arrayUnion([id]),
          'followersCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
        transaction.set(currentUserRef, {
          'following': FieldValue.arrayUnion([ownerId]),
          'followingTalentKeys': FieldValue.arrayUnion([talentId]),
        }, SetOptions(merge: true));
      }
    });
  }

  String _ownerIdFor(String talentId, String? explicit) {
    final clean = explicit?.trim();
    if (clean != null && clean.isNotEmpty) return clean;
    final separator = talentId.indexOf('__');
    if (separator > 0) return talentId.substring(0, separator);
    return talentId;
  }

  String _roleFor(String talentId, String? explicit) {
    final clean = explicit?.trim().toLowerCase();
    if (clean == 'boutique' || clean == 'createur') return clean!;
    if (talentId.endsWith('__boutique')) return 'boutique';
    if (talentId.endsWith('__createur')) return 'createur';
    return 'createur';
  }
}
