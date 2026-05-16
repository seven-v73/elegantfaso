import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/account_roles.dart';
import '../../models/profile/public_profile.dart';

class PublicProfileService {
  PublicProfileService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('public_profiles');

  Future<PublicProfile?> load(String userId) async {
    if (userId.trim().isEmpty) return null;
    final doc = await _profiles.doc(userId).get();
    if (doc.exists) return PublicProfile.fromDoc(doc);

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();
    if (data == null) return null;
    final profile = PublicProfile.fromMap(data, id: userId);
    await _profiles
        .doc(userId)
        .set(profile.toFirestore(), SetOptions(merge: true));
    return profile;
  }

  Future<void> syncCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    await syncFromUserData(
      userId: user.uid,
      data: doc.data() ?? const {},
      authDisplayName: user.displayName,
      authPhotoUrl: user.photoURL,
    );
  }

  Future<void> syncFromUserData({
    required String userId,
    required Map<String, dynamic> data,
    String? authDisplayName,
    String? authPhotoUrl,
  }) async {
    final merged = <String, dynamic>{
      ...data,
      'id': userId,
      'displayName':
          data['displayName']?.toString().trim().isNotEmpty == true
              ? data['displayName']
              : (data['name']?.toString().trim().isNotEmpty == true
                  ? data['name']
                  : authDisplayName),
      'photoUrl':
          data['photoUrl']?.toString().trim().isNotEmpty == true
              ? data['photoUrl']
              : authPhotoUrl,
      'roles': AccountRoles.normalize(data),
    };
    final profile = PublicProfile.fromMap(merged, id: userId);
    await _profiles
        .doc(userId)
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<void> incrementSecondhandPublished(String userId) {
    return _profiles.doc(userId).set({
      'secondhandListings': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> incrementSecondhandSold(String userId) {
    return _profiles.doc(userId).set({
      'secondhandSold': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
