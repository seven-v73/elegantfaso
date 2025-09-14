import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static Stream<QuerySnapshot> getStylistCreations() {
    return FirebaseFirestore.instance
        .collection('creations')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}