import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/client/client_saved_item.dart';
import '../../models/wardrobe/wardrobe_item.dart';
import '../wardrobe/wardrobe_service.dart';

class ClientSavedService {
  ClientSavedService({
    FirebaseFirestore? firestore,
    WardrobeService? wardrobeService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _wardrobeService = wardrobeService ?? WardrobeService();

  final FirebaseFirestore _firestore;
  final WardrobeService _wardrobeService;

  Stream<List<ClientSavedItem>> watchSavedItems(String userId) {
    return _wardrobeService.watchItems(userId).asyncMap((wardrobeItems) async {
      final saved = <ClientSavedItem>[
        ...wardrobeItems
            .where((item) => item.favorite)
            .map(_fromWardrobeFavorite),
      ];

      for (final collection in const ['saved_items', 'wishlist', 'souhaits']) {
        try {
          final snapshot =
              await _firestore
                  .collection('users')
                  .doc(userId)
                  .collection(collection)
                  .orderBy('createdAt', descending: true)
                  .limit(12)
                  .get();
          saved.addAll(snapshot.docs.map(ClientSavedItem.fromFirestore));
        } catch (_) {
          // Optional legacy collections are not guaranteed to exist or be indexed.
        }
      }

      final byId = <String, ClientSavedItem>{};
      for (final item in saved) {
        byId['${item.sourceType}:${item.sourceId}:${item.id}'] = item;
      }

      final items = byId.values.toList();
      items.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return items.take(16).toList();
    });
  }

  Future<void> removeSavedItem({
    required String userId,
    required ClientSavedItem item,
  }) async {
    if (item.sourceType == 'wardrobe') {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wardrobe')
          .doc(item.sourceId)
          .set({
            'favorite': false,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      return;
    }

    for (final collection in const ['saved_items', 'wishlist', 'souhaits']) {
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection(collection)
            .doc(item.id)
            .delete();
        return;
      } catch (_) {
        // Try the next known collection name.
      }
    }
  }

  ClientSavedItem _fromWardrobeFavorite(WardrobeItem item) {
    return ClientSavedItem(
      id: 'wardrobe_${item.id}',
      title: item.name,
      subtitle:
          item.category.isNotEmpty
              ? item.category
              : item.occasion.isNotEmpty
              ? item.occasion
              : 'Garde-robe',
      imageUrl: item.coverImage,
      type: ClientSavedType.favorite,
      sourceId: item.id,
      sourceType: 'wardrobe',
      createdAt: item.updatedAt ?? item.createdAt,
    );
  }
}
