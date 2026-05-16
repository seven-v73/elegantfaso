import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/account_roles.dart';
import '../../models/profile/public_profile.dart';

class SalonPlacePublisherService {
  SalonPlacePublisherService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> publishCurrentUserPlaces() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final data = userDoc.data();
    if (data == null || _isAdmin(data)) return;

    final roles = _businessRoles(data);
    if (roles.isEmpty) return;

    final batch = _firestore.batch();
    for (final role in roles) {
      final profile = PublicProfile.fromUserData(
        uid: user.uid,
        role: role,
        data: data,
      );
      if (!profile.canPublish) continue;
      final placeData = {
        ...profile.toSalonPlaceMap(),
        'type': role,
        'role': role,
        'publicRole': role,
        'primaryRole': role,
        'activeRole': role,
        'isPublic': true,
      };
      batch.set(
        _firestore.collection('salon_places').doc('${user.uid}_$role'),
        placeData,
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Set<String> _businessRoles(Map<String, dynamic> data) {
    final roles = <String>{};
    final normalized = AccountRoles.normalize(data);
    if (normalized.contains(AccountRoles.createur)) {
      roles.add(AccountRoles.createur);
    }
    if (normalized.contains(AccountRoles.boutique)) {
      roles.add(AccountRoles.boutique);
    }

    final flags = data['roleFlags'];
    if (flags is Map) {
      if (flags['isCreator'] == true) roles.add(AccountRoles.createur);
      if (flags['isShop'] == true) roles.add(AccountRoles.boutique);
    }

    final onboarding = data['businessOnboarding'];
    if (onboarding is Map) {
      final creator = onboarding['createur'] ?? onboarding['creator'];
      final boutique = onboarding['boutique'] ?? onboarding['shop'];
      if (creator is Map && _businessRoleEnabled(creator)) {
        roles.add(AccountRoles.createur);
      }
      if (boutique is Map && _businessRoleEnabled(boutique)) {
        roles.add(AccountRoles.boutique);
      }
    }

    return roles;
  }

  bool _businessRoleEnabled(Map<dynamic, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? '';
    return status == 'active' ||
        status == 'approved' ||
        status == 'enabled' ||
        data['enabled'] == true;
  }

  bool _isAdmin(Map<String, dynamic> data) {
    final flags = data['roleFlags'];
    final text =
        '${data['role']} ${data['activeRole']} ${data['roles']} ${data['publicRole']}'
            .toLowerCase();
    return data['admin'] == true ||
        data['isAdmin'] == true ||
        text.split(RegExp(r'\s+')).contains('admin') ||
        (flags is Map && flags['isAdmin'] == true);
  }
}
