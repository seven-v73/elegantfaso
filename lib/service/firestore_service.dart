import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // Ajouter une création
  static Future<void> addCreation({
    required String description,
    required String category,
    required List<String> images,
  }) async {
    await _db.collection('creations').add({
      'description': description,
      'category': category,
      'images': images,
      'timestamp': FieldValue.serverTimestamp(),
      'stylistId': FirebaseAuth.instance.currentUser!.uid, // Use FirebaseAuth here
    });
  }

  // Récupérer les créations d'un styliste
  static Stream<QuerySnapshot> getStylistCreations(String stylistId) {
    return _db
        .collection('creations')
        .where('stylistId', isEqualTo: stylistId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}