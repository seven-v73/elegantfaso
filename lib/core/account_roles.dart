import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountRoles {
  static const client = 'client';
  static const createur = 'createur';
  static const boutique = 'boutique';
  static const admin = 'admin';

  static const all = [client, createur, boutique, admin];
  static const businessRoles = [createur, boutique];

  static String? canonical(String? role) {
    final value = role?.trim().toLowerCase();
    return switch (value) {
      client => client,
      createur ||
      'creator' ||
      'créateur' ||
      'creatrice' ||
      'créatrice' => createur,
      boutique || 'shop' || 'store' || 'seller' || 'vendeur' => boutique,
      admin || 'administrator' || 'superadmin' => admin,
      _ => null,
    };
  }

  static bool isValid(String role) => canonical(role) != null;

  static List<String> normalize(Map<String, dynamic>? data) {
    final roles = <String>{client};
    final legacyRole = data?['role']?.toString();
    final activeRole = data?['activeRole']?.toString();
    final rawRoles = data?['roles'];

    final canonicalLegacy = canonical(legacyRole);
    final canonicalActive = canonical(activeRole);
    if (canonicalLegacy != null) roles.add(canonicalLegacy);
    if (canonicalActive != null) roles.add(canonicalActive);
    if (rawRoles is Iterable) {
      for (final role in rawRoles) {
        final value = canonical(role.toString());
        if (value != null) roles.add(value);
      }
    }
    if (rawRoles is Map) {
      for (final entry in rawRoles.entries) {
        if (entry.value == true) {
          final value = canonical(entry.key.toString());
          if (value != null) roles.add(value);
        }
      }
    }

    final roleFlags = data?['roleFlags'];
    if (roleFlags is Map) {
      if (roleFlags['isCreator'] == true) roles.add(createur);
      if (roleFlags['isShop'] == true) roles.add(boutique);
      if (roleFlags['isAdmin'] == true) roles.add(admin);
    }

    final onboarding = data?['businessOnboarding'];
    if (onboarding is Map) {
      final creator = onboarding['createur'] ?? onboarding['creator'];
      final shop = onboarding['boutique'] ?? onboarding['shop'];
      if (creator is Map && _businessRoleEnabled(creator)) {
        roles.add(createur);
      }
      if (shop is Map && _businessRoleEnabled(shop)) {
        roles.add(boutique);
      }
    }

    return roles.toList();
  }

  static bool _businessRoleEnabled(Map<dynamic, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? '';
    return status == 'active' ||
        status == 'approved' ||
        status == 'enabled' ||
        data['enabled'] == true;
  }

  static String activeRole(Map<String, dynamic>? data) {
    final activeRole = canonical(data?['activeRole']?.toString());
    final legacyRole = canonical(data?['role']?.toString());
    if (activeRole != null) return activeRole;
    if (legacyRole != null) return legacyRole;
    return client;
  }
}

class AccountRoleState {
  final String uid;
  final String activeRole;
  final List<String> roles;

  const AccountRoleState({
    required this.uid,
    required this.activeRole,
    required this.roles,
  });

  bool hasRole(String role) => roles.contains(role);
  bool get canCreate => hasRole(AccountRoles.createur);
  bool get canSell => hasRole(AccountRoles.boutique);
}

class AccountRoleService {
  AccountRoleService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Future<AccountRoleState?> getCurrentState() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _userRef(user.uid).get();
    final data = snapshot.data();
    final roles = AccountRoles.normalize(data);
    final activeRole = AccountRoles.activeRole(data);

    return AccountRoleState(
      uid: user.uid,
      activeRole: activeRole,
      roles: roles,
    );
  }

  Future<void> ensureRoleSchema({
    required String uid,
    String preferredRole = AccountRoles.client,
  }) async {
    final snapshot = await _userRef(uid).get();
    final data = snapshot.data();
    final roles = AccountRoles.normalize(data);
    final activeRole =
        AccountRoles.isValid(preferredRole)
            ? preferredRole
            : AccountRoles.client;
    final nextRoles =
        roles.contains(activeRole) ? roles : [...roles, activeRole];

    await _userRef(uid).set({
      'role': activeRole,
      'activeRole': activeRole,
      'roles': nextRoles,
      'roleFlags': roleFlags(nextRoles),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<AccountRoleState> grantRole(
    String role, {
    Map<String, dynamic> profileData = const {},
    bool makeActive = true,
  }) async {
    if (!AccountRoles.businessRoles.contains(role)) {
      throw ArgumentError('Rôle évolutif invalide: $role');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non connecté');
    }

    final state = await getCurrentState();
    final roles =
        <String>{...?state?.roles, AccountRoles.client, role}.toList();
    final activeRole =
        makeActive ? role : state?.activeRole ?? AccountRoles.client;

    await _userRef(user.uid).set({
      ...profileData,
      'role': activeRole,
      'activeRole': activeRole,
      'roles': roles,
      'roleFlags': roleFlags(roles),
      'businessOnboarding': {
        role: {
          'enabled': true,
          'enabledAt': FieldValue.serverTimestamp(),
          'status': 'active',
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _firestore.collection('public_profiles').doc(user.uid).set({
      'id': user.uid,
      if (profileData['displayName'] != null)
        'displayName': profileData['displayName'],
      if (profileData['name'] != null) 'displayName': profileData['name'],
      if (profileData['photoUrl'] != null) 'photoUrl': profileData['photoUrl'],
      if (profileData['boutiqueName'] != null)
        'specialty': profileData['boutiqueName'],
      if (profileData['specialty'] != null)
        'specialty': profileData['specialty'],
      'role': activeRole,
      'activeRole': activeRole,
      'roles': roles,
      'roleFlags': roleFlags(roles),
      'primaryRole': role,
      'isVerified': role != AccountRoles.client,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return AccountRoleState(
      uid: user.uid,
      activeRole: activeRole,
      roles: roles,
    );
  }

  Future<AccountRoleState> switchActiveRole(String role) async {
    if (!AccountRoles.isValid(role)) {
      throw ArgumentError('Rôle invalide: $role');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non connecté');
    }

    final state = await getCurrentState();
    final roles = state?.roles ?? const [AccountRoles.client];
    if (!roles.contains(role)) {
      throw StateError('Ce rôle n’est pas encore activé pour ce compte');
    }

    await _userRef(user.uid).set({
      'role': role,
      'activeRole': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _firestore.collection('public_profiles').doc(user.uid).set({
      'role': role,
      'activeRole': role,
      'roles': roles,
      'primaryRole': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return AccountRoleState(uid: user.uid, activeRole: role, roles: roles);
  }

  static Map<String, bool> roleFlags(List<String> roles) {
    return {
      'isClient': roles.contains(AccountRoles.client),
      'isCreator': roles.contains(AccountRoles.createur),
      'isShop': roles.contains(AccountRoles.boutique),
      'isAdmin': roles.contains(AccountRoles.admin),
    };
  }
}
