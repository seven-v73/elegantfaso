import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Méthode pour récupérer tous les utilisateurs
  Stream<QuerySnapshot> getUsersByType(String userType) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: userType)
        .snapshots();
  }

  // Méthode pour mettre à jour un utilisateur
  Future<void> updateUserStatus(String userId, bool isActive) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }
}
