import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/account_roles.dart';

enum AccountClosureTarget {
  account,
  createur,
  boutique;

  String get firestoreValue {
    switch (this) {
      case AccountClosureTarget.account:
        return 'account';
      case AccountClosureTarget.createur:
        return 'createur_space';
      case AccountClosureTarget.boutique:
        return 'boutique_space';
    }
  }

  String get label {
    switch (this) {
      case AccountClosureTarget.account:
        return 'compte client';
      case AccountClosureTarget.createur:
        return 'espace créateur';
      case AccountClosureTarget.boutique:
        return 'espace boutique';
    }
  }
}

class AccountClosureReason {
  const AccountClosureReason({required this.id, required this.label});

  final String id;
  final String label;
}

class AccountClosureService {
  AccountClosureService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const reasons = <AccountClosureReason>[
    AccountClosureReason(id: 'pause', label: 'Je veux faire une pause'),
    AccountClosureReason(
      id: 'not_using',
      label: 'Je n’utilise plus cet espace',
    ),
    AccountClosureReason(
      id: 'privacy',
      label: 'Confidentialité ou données personnelles',
    ),
    AccountClosureReason(
      id: 'reorganize',
      label: 'Je veux réorganiser mon profil',
    ),
    AccountClosureReason(id: 'issue', label: 'J’ai rencontré un problème'),
    AccountClosureReason(id: 'other', label: 'Autre raison'),
  ];

  Future<void> submitClosureRequest({
    required AccountClosureTarget target,
    required String reasonId,
    required String reasonLabel,
    String details = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non connecté');
    }

    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();
    final data = userDoc.data() ?? const <String, dynamic>{};
    final now = FieldValue.serverTimestamp();
    final requestId = '${user.uid}_${target.firestoreValue}';

    final displayName = _displayNameForTarget(data, target, user);
    final email = data['email']?.toString() ?? user.email ?? '';

    final batch = _firestore.batch();
    final closesImmediately = target != AccountClosureTarget.account;
    final roleKey =
        target == AccountClosureTarget.createur
            ? AccountRoles.createur
            : AccountRoles.boutique;
    final currentRoles = AccountRoles.normalize(data);
    final nextRoles =
        closesImmediately
            ? currentRoles.where((role) => role != roleKey).toSet().toList()
            : currentRoles;
    final safeRoles =
        nextRoles.contains(AccountRoles.client)
            ? nextRoles
            : [AccountRoles.client, ...nextRoles];

    batch.set(
      _firestore.collection('account_closure_requests').doc(requestId),
      {
        'id': requestId,
        'userId': user.uid,
        'accountId': user.uid,
        'email': email,
        'displayName': displayName,
        'target': target.firestoreValue,
        'targetLabel': target.label,
        'reasonId': reasonId,
        'reasonLabel': reasonLabel,
        'details': details.trim(),
        'status': closesImmediately ? 'closed' : 'pending',
        'adminDecision': closesImmediately ? 'auto_closed' : null,
        'adminNote': '',
        'createdAt': now,
        if (closesImmediately) 'resolvedAt': now,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );

    batch.set(userRef, {
      if (target == AccountClosureTarget.account) ...{
        'accountStatus': 'closure_requested',
        'closure': {
          'status': 'requested',
          'requestId': requestId,
          'reasonId': reasonId,
          'requestedAt': now,
        },
      } else ...{
        'role': AccountRoles.client,
        'activeRole': AccountRoles.client,
        'roles': safeRoles,
        'roleFlags': AccountRoleService.roleFlags(safeRoles),
        'businessOnboarding.$roleKey.status': 'closed',
        'businessOnboarding.$roleKey.closedAt': now,
        'roleClosures.$roleKey': {
          'status': 'closed',
          'requestId': requestId,
          'reasonId': reasonId,
          'closedAt': now,
        },
      },
      'updatedAt': now,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  String _displayNameForTarget(
    Map<String, dynamic> data,
    AccountClosureTarget target,
    User user,
  ) {
    final creatorProfile = Map<String, dynamic>.from(
      data['creatorProfile'] ?? const {},
    );
    final shopProfile = Map<String, dynamic>.from(
      data['shopProfile'] ?? const {},
    );
    final candidates = switch (target) {
      AccountClosureTarget.createur => [
        data['creatorName'],
        creatorProfile['name'],
        data['name'],
        user.displayName,
      ],
      AccountClosureTarget.boutique => [
        data['boutiqueName'],
        shopProfile['name'],
        data['name'],
        user.displayName,
      ],
      AccountClosureTarget.account => [
        data['clientName'],
        data['displayName'],
        data['name'],
        user.displayName,
      ],
    };

    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return 'Utilisateur ElegantStyle';
  }
}
