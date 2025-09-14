import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fashion_item.dart';

class FashionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final int _pageSize = 10;

  Stream<List<FashionItem>> getTrends({
    String? sortBy,
    String? filterCategory,
    List<String>? filterOccasions,
    double? minPrice,
    double? maxPrice,
    bool onlyLocalMade = false,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) {
    Query query = _db.collection('fashion_items');
    if (filterCategory != null && filterCategory.isNotEmpty) {
      query = query.where('category', isEqualTo: filterCategory);
    }
    if (filterOccasions != null && filterOccasions.isNotEmpty) {
      query = query.where('occasions', arrayContainsAny: filterOccasions);
    }
    if (onlyLocalMade) {
      query = query.where('origin', isEqualTo: 'Burkina Faso');
    }
    if (sortBy == 'popular') {
      query = query.orderBy('likes', descending: true);
    } else if (sortBy == 'recent') {
      query = query.orderBy('createdAt', descending: true);
    } else if (sortBy == 'price_low') {
      query = query.orderBy('price', descending: false);
    } else if (sortBy == 'price_high') {
      query = query.orderBy('price', descending: true);
    } else {
      query = query.orderBy('likes', descending: true);
    }
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    query = query.limit(limit);
    return query.snapshots().map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) => FashionItem.fromFirestore(doc))
            .toList();
      } catch (e) {
        print('Erreur dans la récupération des tendances: $e');
        return [];
      }
    });
  }

  Future<List<FashionItem>> getTrendsPaginated({
    String? sortBy,
    String? filterCategory,
    List<String>? filterOccasions,
    double? minPrice,
    double? maxPrice,
    bool onlyLocalMade = false,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _db.collection('fashion_items');
      if (filterCategory != null && filterCategory.isNotEmpty) {
        query = query.where('category', isEqualTo: filterCategory);
      }
      if (filterOccasions != null && filterOccasions.isNotEmpty) {
        query = query.where('occasions', arrayContainsAny: filterOccasions);
      }
      if (onlyLocalMade) {
        query = query.where('origin', isEqualTo: 'Burkina Faso');
      }
      if (sortBy == 'popular') {
        query = query.orderBy('likes', descending: true);
      } else if (sortBy == 'recent') {
        query = query.orderBy('createdAt', descending: true);
      } else if (sortBy == 'price_low') {
        query = query.orderBy('price', descending: false);
      } else if (sortBy == 'price_high') {
        query = query.orderBy('price', descending: true);
      } else {
        query = query.orderBy('likes', descending: true);
      }
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      final snapshot = await query.limit(_pageSize).get();
      List<FashionItem> items =
          snapshot.docs.map((doc) => FashionItem.fromFirestore(doc)).toList();
      if (minPrice != null || maxPrice != null) {
        items =
            items.where((item) {
              bool passesMinFilter = minPrice == null || item.price >= minPrice;
              bool passesMaxFilter = maxPrice == null || item.price <= maxPrice;
              return passesMinFilter && passesMaxFilter;
            }).toList();
      }
      return items;
    } catch (e) {
      print('Erreur dans getTrendsPaginated: $e');
      return [];
    }
  }

  Stream<FashionItem?> getFeatured() {
    return _db.collection('featured_items').doc('current').snapshots().map((
      doc,
    ) {
      try {
        if (!doc.exists) {
          return null;
        }
        return FashionItem.fromFirestore(doc);
      } catch (e) {
        print('Erreur dans la récupération de l\'article en vedette: $e');
        return null;
      }
    });
  }

  Future<List<FashionItem>> getRecommendations(String userId) async {
    try {
      final userPrefs = await _db.collection('users').doc(userId).get();
      if (!userPrefs.exists) {
        return [];
      }
      final userStyles = List<String>.from(userPrefs['preferredStyles'] ?? []);
      if (userStyles.isEmpty) {
        final snapshot =
            await _db
                .collection('fashion_items')
                .orderBy('likes', descending: true)
                .limit(5)
                .get();
        return snapshot.docs
            .map((doc) => FashionItem.fromFirestore(doc))
            .toList();
      }
      final snapshot =
          await _db
              .collection('fashion_items')
              .where('styles', arrayContainsAny: userStyles)
              .orderBy('likes', descending: true)
              .limit(5)
              .get();
      return snapshot.docs
          .map((doc) => FashionItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur dans getRecommendations: $e');
      return [];
    }
  }

  Future<bool> toggleFavorite(String userId, String itemId) async {
    try {
      final userRef = _db.collection('users').doc(userId);
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        await userRef.set({
          'favorites': [itemId],
        });
        return true;
      }
      List<String> favorites = List<String>.from(
        userDoc.data()?['favorites'] ?? [],
      );
      if (favorites.contains(itemId)) {
        favorites.remove(itemId);
      } else {
        favorites.add(itemId);
      }
      await userRef.update({'favorites': favorites});
      return true;
    } catch (e) {
      print('Erreur lors de l\'ajout aux favoris: $e');
      return false;
    }
  }

  Future<List<FashionItem>> getFavorites(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return [];
      }
      List<String> favoriteIds = List<String>.from(userDoc['favorites'] ?? []);
      if (favoriteIds.isEmpty) {
        return [];
      }
      List<FashionItem> favorites = [];
      List<List<String>> batches = [];
      for (int i = 0; i < favoriteIds.length; i += 10) {
        int end = (i + 10 < favoriteIds.length) ? i + 10 : favoriteIds.length;
        batches.add(favoriteIds.sublist(i, end));
      }
      for (List<String> batch in batches) {
        final snapshot =
            await _db
                .collection('fashion_items')
                .where(FieldPath.documentId, whereIn: batch)
                .get();
        favorites.addAll(
          snapshot.docs.map((doc) => FashionItem.fromFirestore(doc)),
        );
      }
      return favorites;
    } catch (e) {
      print('Erreur lors de la récupération des favoris: $e');
      return [];
    }
  }
}
