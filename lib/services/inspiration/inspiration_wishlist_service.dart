import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/inspiration/external_look.dart';

class InspirationWishlistService {
  InspirationWishlistService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static const localKey = 'wardrobe_wishlist_inspirations';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<List<ExternalLook>> loadLooks() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(localKey) ?? const [];
    return values
        .map((value) {
          try {
            return ExternalLook.fromJson(
              Map<String, dynamic>.from(jsonDecode(value) as Map),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<ExternalLook>()
        .where((look) => look.imageUrl.isNotEmpty)
        .toList();
  }

  Future<Set<String>> loadSavedIds() async {
    final looks = await loadLooks();
    return looks.map((look) => look.id).toSet();
  }

  Future<void> save(ExternalLook look) async {
    final prefs = await SharedPreferences.getInstance();
    final looks = await loadLooks();
    if (!looks.any((saved) => saved.id == look.id)) {
      looks.insert(0, look);
      await prefs.setStringList(
        localKey,
        looks.map((saved) => jsonEncode(saved.toJson())).toList(),
      );
    }
    await _syncToWardrobe(look);
  }

  Future<ExternalLook?> remove(ExternalLook look) async {
    final prefs = await SharedPreferences.getInstance();
    final looks = await loadLooks();
    final removed = looks.where((saved) => saved.id == look.id).firstOrNull;
    looks.removeWhere((saved) => saved.id == look.id);
    await prefs.setStringList(
      localKey,
      looks.map((saved) => jsonEncode(saved.toJson())).toList(),
    );

    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wardrobe')
          .doc(_docId(look))
          .delete()
          .catchError((_) {});
    }
    return removed;
  }

  Future<void> addNote(ExternalLook look, String note) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wardrobe')
        .doc(_docId(look))
        .set({
          'note': note.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> markAsProject(ExternalLook look) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wardrobe')
        .doc(_docId(look))
        .set({
          'wishlistType': 'project',
          'category': 'Souhaits',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  String _docId(ExternalLook look) => 'wish_${look.id}';

  Future<void> _syncToWardrobe(ExternalLook look) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wardrobe')
        .doc(_docId(look))
        .set({
          'userId': userId,
          'name': look.title,
          'category': 'Souhaits',
          'brand': 'Inspiration',
          'color': '',
          'occasion': 'Inspiration',
          'season': 'Toute saison',
          'description': look.subtitle,
          'images': [look.imageUrl],
          'media': [
            {
              'type': 'remote_inspiration',
              'url': look.imageUrl,
              'source': look.source,
              'tags': look.tags,
            },
          ],
          'favorite': true,
          'isArchived': false,
          'wearCount': 0,
          'wishlistType': 'inspiration',
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
