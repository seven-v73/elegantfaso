import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../model/creation.dart';

class FirestoreService {
  static final CollectionReference creationsCollection = FirebaseFirestore
      .instance
      .collection('creations');

  static Future<DocumentReference> addCreation(
    Creation creation, {
    Map<String, dynamic> extraData = const {},
  }) async {
    try {
      return await creationsCollection.add({
        ...creation.toJson(),
        ...extraData,
      });
    } catch (e) {
      debugPrint('Erreur création Firestore: $e');
      throw StateError('Création impossible à enregistrer pour le moment.');
    }
  }
}
