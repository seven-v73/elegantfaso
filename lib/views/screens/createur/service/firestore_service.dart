import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../model/creation.dart';

class FirestoreService {
  static final CollectionReference creationsCollection =
  FirebaseFirestore.instance.collection('creations');

  static Future<void> addCreation(Creation creation) async {
    try {
      await creationsCollection.add(creation.toJson());
    } catch (e) {
      debugPrint("Error adding creation: $e");
      throw Exception("Failed to add creation");
    }
  }
}