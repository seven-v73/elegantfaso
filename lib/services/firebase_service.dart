import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ClothingItem {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final List<String> occasions;
  final List<String> seasons;
  final List<String> styles;
  final DateTime addedDate;

  ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.occasions,
    required this.seasons,
    required this.styles,
    required this.addedDate,
  });
}

class GeneratedOutfit {
  final String id;
  final String imageUrl;
  final String description;
  final String styleTips;
  final DateTime createdAt;
  bool isFavorite;
  List<String>? usedItemIds;

  GeneratedOutfit({
    required this.id,
    required this.imageUrl,
    required this.description,
    required this.styleTips,
    required this.createdAt,
    this.isFavorite = false,
    this.usedItemIds,
  });
}

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  Future<String> uploadImage(File image, String path) async {
    final ref = _storage.ref().child('$path/${DateTime.now().millisecondsSinceEpoch}');
    final uploadTask = ref.putFile(image);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> addClothingItem({
    required String name,
    required String category,
    required File image,
    required List<String> occasions,
    required List<String> seasons,
    required List<String> styles,
  }) async {
    final imageUrl = await uploadImage(image, 'wardrobe/${_user!.uid}');

    await _firestore.collection('users').doc(_user!.uid).collection('wardrobe').add({
      'name': name,
      'category': category,
      'imageUrl': imageUrl,
      'occasions': occasions,
      'seasons': seasons,
      'styles': styles,
      'addedDate': Timestamp.now(),
    });
  }

  List<ClothingItem> _wardrobeItems = [];

  Future<List<ClothingItem>> getWardrobeItems() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('wardrobe')
        .orderBy('addedDate', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ClothingItem(
        id: doc.id,
        name: data['name'] ?? '',
        category: data['category'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        occasions: List<String>.from(data['occasions'] ?? []),
        seasons: List<String>.from(data['seasons'] ?? []),
        styles: List<String>.from(data['styles'] ?? []),
        addedDate: (data['addedDate'] as Timestamp).toDate(),
      );
    }).toList();
  }

  Future<Map<String, dynamic>> generateOutfit({
    required String occasion,
    required String weather,
    String? style,
    List<String>? selectedItems,
  }) async {
    final data = {
      'occasion': occasion,
      'weather': weather,
      'style': style,
      'selectedItems': selectedItems,
    };

    // Appel de la fonction Cloud
    // Implémentation à compléter avec vos fonctions Cloud
    await Future.delayed(const Duration(seconds: 2)); // Simulation

    return {
      'outfitId': 'generated-id',
      'description': 'Tenue traditionnelle moderne',
      'styleTips': 'Accessoirisez avec des bijoux traditionnels',
      'imageUrl': 'https://via.placeholder.com/500x750/6C4AB6/FFFFFF?text=Tenue+Générée',
      'timestamp': Timestamp.now(),
      'usedItemIds': selectedItems,
    };
  }
}