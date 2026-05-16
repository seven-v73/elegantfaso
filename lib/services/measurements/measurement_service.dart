import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/measurements/measurement_profile.dart';
import '../notifications/app_notification_service.dart';

class MeasurementCreator {
  final String id;
  final String name;
  final String email;
  final String speciality;
  final String? photoUrl;

  const MeasurementCreator({
    required this.id,
    required this.name,
    required this.email,
    this.speciality = '',
    this.photoUrl,
  });

  factory MeasurementCreator.fromMap(Map<String, dynamic> data, String id) {
    return MeasurementCreator(
      id: id,
      name:
          data['name']?.toString() ??
          data['displayName']?.toString() ??
          'Créateur',
      email: data['email']?.toString() ?? '',
      speciality:
          data['speciality']?.toString() ??
          data['specialty']?.toString() ??
          data['creatorSpecialty']?.toString() ??
          '',
      photoUrl: data['photoUrl']?.toString() ?? data['photoURL']?.toString(),
    );
  }
}

class MeasurementService {
  MeasurementService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance,
      _notificationService = AppNotificationService(
        firestore: firestore,
        auth: auth,
      );

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AppNotificationService _notificationService;

  DocumentReference<Map<String, dynamic>> profileRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .doc('profile');
  }

  CollectionReference<Map<String, dynamic>> historyRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('measurement_history');
  }

  Stream<MeasurementProfile> watchProfile(String userId) {
    return profileRef(userId).snapshots().asyncMap((snapshot) async {
      if (snapshot.exists) {
        return MeasurementProfile.fromFirestore(snapshot);
      }

      final legacy =
          await _firestore.collection('measurements').doc(userId).get();
      if (legacy.exists) {
        return MeasurementProfile.fromMap(legacy.data() ?? const {}, userId);
      }

      return MeasurementProfile.empty(userId);
    });
  }

  Stream<MeasurementBundle> watchBundle(String userId) {
    return profileRef(userId).snapshots().asyncMap((snapshot) async {
      final profile =
          snapshot.exists
              ? MeasurementProfile.fromFirestore(snapshot)
              : await getProfile(userId);
      final shares = await loadShares(userId);
      return MeasurementBundle(profile: profile, shares: shares);
    });
  }

  Future<MeasurementProfile> getProfile(String userId) async {
    final doc = await profileRef(userId).get();
    if (doc.exists) return MeasurementProfile.fromFirestore(doc);

    final legacy =
        await _firestore.collection('measurements').doc(userId).get();
    if (legacy.exists) {
      return MeasurementProfile.fromMap(legacy.data() ?? const {}, userId);
    }

    return MeasurementProfile.empty(userId);
  }

  Future<void> saveProfile(MeasurementProfile profile) async {
    final existing = await profileRef(profile.userId).get();
    final previous =
        existing.exists ? MeasurementProfile.fromFirestore(existing) : null;

    if (previous != null) {
      await historyRef(profile.userId).add({
        'profile': previous.toSnapshotMap(),
        'savedAt': FieldValue.serverTimestamp(),
      });
    }

    await profileRef(profile.userId).set(
      profile.toFirestore(includeCreatedAt: !existing.exists),
      SetOptions(merge: true),
    );
  }

  Future<List<MeasurementCreator>> loadCreators() async {
    final users = <String, MeasurementCreator>{};

    Future<void> collect(Query<Map<String, dynamic>> query) async {
      try {
        final snapshot = await query.get();
        for (final doc in snapshot.docs) {
          users[doc.id] = MeasurementCreator.fromMap(doc.data(), doc.id);
        }
      } catch (_) {
        // Some legacy fields may not exist in every project yet.
      }
    }

    final base = _firestore.collection('users');
    await Future.wait([
      collect(base.where('roles.creator', isEqualTo: true)),
      collect(base.where('isCreator', isEqualTo: true)),
      collect(base.where('role', isEqualTo: 'createur')),
      collect(base.where('role', isEqualTo: 'creator')),
    ]);

    final creators = users.values.toList();
    creators.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return creators;
  }

  Stream<List<MeasurementShare>> watchShares(String userId) {
    return _firestore
        .collection('shared_measurements')
        .where('clientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final shares =
              snapshot.docs
                  .map(MeasurementShare.fromFirestore)
                  .where((share) => share.status != 'revoked')
                  .toList();
          shares.sort((a, b) {
            final aDate = a.sharedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.sharedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          return shares;
        });
  }

  Future<List<MeasurementShare>> loadShares(String userId) async {
    final snapshot =
        await _firestore
            .collection('shared_measurements')
            .where('clientId', isEqualTo: userId)
            .limit(30)
            .get();
    final shares =
        snapshot.docs
            .map(MeasurementShare.fromFirestore)
            .where((share) => share.status != 'revoked')
            .toList();
    shares.sort((a, b) {
      final aDate = a.sharedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.sharedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return shares;
  }

  Future<String> shareWithCreator({
    required MeasurementProfile profile,
    required MeasurementCreator creator,
    required Duration duration,
    bool includeSnapshot = false,
  }) async {
    final currentUser = _auth.currentUser;
    final existing =
        await _firestore
            .collection('shared_measurements')
            .where('clientId', isEqualTo: profile.userId)
            .where('creatorId', isEqualTo: creator.id)
            .where('status', whereIn: ['active', 'pending'])
            .get();

    if (existing.docs.isNotEmpty) {
      throw StateError('Un partage avec ce créateur est déjà actif.');
    }

    final shareRef = _firestore.collection('shared_measurements').doc();
    final expiresAt = DateTime.now().add(duration);
    final shareData = {
      'id': shareRef.id,
      'clientId': profile.userId,
      'clientName': currentUser?.displayName ?? 'Client',
      'clientEmail': currentUser?.email ?? '',
      'creatorId': creator.id,
      'creatorName': creator.name,
      'creatorEmail': creator.email,
      'measurementPath': profileRef(profile.userId).path,
      'measurementSummary': profile.toShareSummary(),
      if (includeSnapshot) 'snapshot': profile.toSnapshotMap(),
      'permissions': {'read': true, 'comment': true, 'export': false},
      'status': 'active',
      'sharedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await shareRef.set(shareData);
    await profileRef(profile.userId).set({
      'sharedWith': FieldValue.arrayUnion([creator.id]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _notificationService.createNotification(
      recipientId: creator.id,
      title: 'Mensurations partagées',
      body:
          '${currentUser?.displayName ?? 'Un client'} a partagé ses mensurations avec vous.',
      type: 'measurement_shared',
      priority: 'high',
      actionLabel: 'Voir les mensurations',
      data: {
        'targetType': 'measurement_share',
        'targetId': shareRef.id,
        'shareId': shareRef.id,
        'senderId': profile.userId,
        'senderEmail': currentUser?.email ?? '',
      },
    );

    return shareRef.id;
  }

  Future<void> revokeShare(MeasurementShare share) async {
    await _firestore.collection('shared_measurements').doc(share.id).set({
      'status': 'revoked',
      'revokedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await profileRef(share.clientId).set({
      'sharedWith': FieldValue.arrayRemove([share.creatorId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class MeasurementBundle {
  const MeasurementBundle({required this.profile, required this.shares});

  final MeasurementProfile profile;
  final List<MeasurementShare> shares;
}
