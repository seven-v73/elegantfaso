import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _creationsCollection = FirebaseFirestore.instance.collection('creations');

  /// Ajoute une création dans Firestore
  static Future<void> addCreation({
    required String description,
    required String category,
    required List<String> images,
    required List<String> tags,
  }) async {
    final doc = _creationsCollection.doc();
    await doc.set({
      'description': description,
      'category': category,
      'images': images,
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Récupère un stream des créations, trié par date décroissante
  static Stream<QuerySnapshot> getCreationsStream() {
    return _creationsCollection.orderBy('createdAt', descending: true).snapshots();
  }
}
