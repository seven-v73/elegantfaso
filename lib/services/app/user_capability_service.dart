import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/account_roles.dart';
import '../../models/app/app_user_capabilities.dart';

class UserCapabilityService {
  UserCapabilityService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<AppUserCapabilities> current() async {
    final user = _auth.currentUser;
    if (user == null) return AppUserCapabilities.guest();

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    return AppUserCapabilities(
      userId: user.uid,
      activeRole: AccountRoles.activeRole(data),
      roles: AccountRoles.normalize(data),
      isAuthenticated: true,
    );
  }

  Future<bool> can(AppActionIntent action, {String? ownerId}) async {
    final capabilities = await current();
    return capabilities.can(action, ownerId: ownerId);
  }

  Future<String> blockedReason(
    AppActionIntent action, {
    String? ownerId,
  }) async {
    final capabilities = await current();
    return capabilities.blockedReason(action, ownerId: ownerId);
  }
}
