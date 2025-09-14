import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> toggleFollow({
    required String followerId,
    required String followedId,
  }) async {
    try {
      // Validation des IDs
      if (followerId.isEmpty || followedId.isEmpty) {
        throw Exception('IDs invalides: follower:$followerId, followed:$followedId');
      }

      final batch = _firestore.batch();
      final usersRef = _firestore.collection('users');

      final followerRef = usersRef.doc(followerId);
      final followedRef = usersRef.doc(followedId);

      // Récupération des documents
      final futures = await Future.wait([followerRef.get(), followedRef.get()]);
      final followerDoc = futures[0];
      final followedDoc = futures[1];

      // Vérification existence
      if (!followerDoc.exists) {
        throw Exception('Utilisateur follower non trouvé: $followerId');
      }

      if (!followedDoc.exists) {
        throw Exception('Utilisateur followed non trouvé: $followedId');
      }

      // Initialisation des champs si nécessaire
      final followerData = followerDoc.data()!;
      if (!followerData.containsKey('following')) {
        await followerRef.update({'following': [], 'followingCount': 0});
      }

      final followedData = followedDoc.data()!;
      if (!followedData.containsKey('followers')) {
        await followedRef.update({'followers': [], 'followersCount': 0});
      }

      // Rechargement des données
      final updatedFollower = await followerRef.get();
      final updatedFollowed = await followedRef.get();

      // Extraction des listes
      final followingList = List<String>.from(
          updatedFollower['following'] ?? []
      );

      final followersList = List<String>.from(
          updatedFollowed['followers'] ?? []
      );

      final isFollowing = followingList.contains(followedId);

      // Opérations batch
      if (isFollowing) {
        // Désabonnement
        batch.update(followerRef, {
          'following': FieldValue.arrayRemove([followedId]),
          'followingCount': FieldValue.increment(-1),
        });

        batch.update(followedRef, {
          'followers': FieldValue.arrayRemove([followerId]),
          'followersCount': FieldValue.increment(-1),
        });
      } else {
        // Abonnement
        batch.update(followerRef, {
          'following': FieldValue.arrayUnion([followedId]),
          'followingCount': FieldValue.increment(1),
        });

        batch.update(followedRef, {
          'followers': FieldValue.arrayUnion([followerId]),
          'followersCount': FieldValue.increment(1),
        });
      }

      await batch.commit();
      debugPrint('Follow operation successful');
    } catch (e) {
      debugPrint('Erreur FollowService: $e');
      rethrow;
    }
  }
}