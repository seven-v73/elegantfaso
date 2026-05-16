import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/client/client_saved_item.dart';
import '../../models/try_on/try_on_source.dart';
import '../../models/wardrobe/wardrobe_item.dart';

class TryOnSourceService {
  TryOnSourceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<TryOnSource>> loadWardrobe(String userId) async {
    final byKey = <String, TryOnSource>{};

    Future<void> addSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) async {
      for (final doc in snapshot.docs) {
        final item = WardrobeItem.fromFirestore(doc);
        if (item.isArchived || item.coverImage.trim().isEmpty) continue;
        final source = TryOnSource(
          id: item.id,
          type: TryOnSourceType.wardrobe,
          title: item.name,
          subtitle: [
            item.category,
            item.color,
            item.occasion,
          ].where((value) => value.trim().isNotEmpty).join(' • '),
          imageUrl: item.coverImage,
          ownerId: item.userId,
          raw: {'collection': 'wardrobe', ...item.toFirestore()},
        );
        byKey['wardrobe:${item.id}:${item.coverImage}'] = source;
      }
    }

    try {
      await addSnapshot(
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('wardrobe')
            .get(),
      );
    } catch (_) {}

    for (final collection in const ['wardrobe_items', 'wardrobe']) {
      for (final field in const ['userId', 'ownerId', 'clientId', 'uid']) {
        try {
          await addSnapshot(
            await _firestore
                .collection(collection)
                .where(field, isEqualTo: userId)
                .get(),
          );
        } catch (_) {}
      }
    }

    return byKey.values.toList();
  }

  Future<List<TryOnSource>> loadWishlist(String userId) async {
    final byKey = <String, TryOnSource>{};

    void addSaved(ClientSavedItem item) {
      if (item.imageUrl.trim().isEmpty) return;
      byKey['${item.sourceType}:${item.sourceId}:${item.id}:${item.imageUrl}'] =
          TryOnSource(
            id: item.id,
            type: TryOnSourceType.wishlist,
            title: item.title,
            subtitle:
                item.subtitle.isNotEmpty ? item.subtitle : _label(item.type),
            imageUrl: item.imageUrl,
            ownerId: userId,
            raw: item.raw,
          );
    }

    for (final collection in const ['saved_items', 'wishlist', 'souhaits']) {
      try {
        final snapshot =
            await _firestore
                .collection('users')
                .doc(userId)
                .collection(collection)
                .get();
        for (final doc in snapshot.docs) {
          addSaved(ClientSavedItem.fromFirestore(doc));
        }
      } catch (_) {}

      for (final field in const ['userId', 'ownerId', 'clientId', 'uid']) {
        try {
          final snapshot =
              await _firestore
                  .collection(collection)
                  .where(field, isEqualTo: userId)
                  .get();
          for (final doc in snapshot.docs) {
            addSaved(ClientSavedItem.fromFirestore(doc));
          }
        } catch (_) {}
      }
    }

    final wardrobe = await loadWardrobe(userId);
    for (final item in wardrobe.where(_looksLikeWishlist)) {
      byKey['wardrobe-wish:${item.id}:${item.imageUrl}'] = TryOnSource(
        id: item.id,
        type: TryOnSourceType.wishlist,
        title: item.title,
        subtitle: item.subtitle.isNotEmpty ? item.subtitle : 'Souhait',
        imageUrl: item.imageUrl,
        ownerId: userId,
        raw: item.raw,
      );
    }

    return byKey.values.toList();
  }

  Future<List<TryOnSource>> loadSalonProducts(String userId) async {
    final snapshot = await _firestore.collection('products').limit(80).get();
    return snapshot.docs
        .map((doc) => _sourceFromProduct(doc, userId))
        .whereType<TryOnSource>()
        .toList();
  }

  Future<List<TryOnSource>> loadSalonCreations(String userId) async {
    final snapshot = await _firestore.collection('creations').limit(80).get();
    return snapshot.docs
        .map((doc) => _sourceFromCreation(doc, userId))
        .whereType<TryOnSource>()
        .toList();
  }

  TryOnSource? _sourceFromProduct(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String userId,
  ) {
    final data = doc.data();
    if (!_isVisible(data)) return null;
    if (_ownerId(data) == userId) return null;
    final imageUrl = _firstImage(data);
    if (imageUrl.isEmpty) return null;
    return TryOnSource(
      id: doc.id,
      type: TryOnSourceType.product,
      title: _firstText(data, const [
        'name',
        'title',
        'productName',
      ], 'Produit'),
      subtitle: _firstText(data, const ['category', 'sellerName'], 'Salon'),
      imageUrl: imageUrl,
      ownerId: _ownerId(data),
      raw: data,
    );
  }

  TryOnSource? _sourceFromCreation(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String userId,
  ) {
    final data = doc.data();
    if (!_isVisible(data)) return null;
    if (_ownerId(data) == userId) return null;
    final imageUrl = _firstImage(data);
    if (imageUrl.isEmpty) return null;
    return TryOnSource(
      id: doc.id,
      type: TryOnSourceType.creation,
      title: _firstText(data, const [
        'title',
        'name',
        'description',
      ], 'Création'),
      subtitle: _firstText(data, const ['category', 'creatorName'], 'Salon'),
      imageUrl: imageUrl,
      ownerId: _ownerId(data),
      raw: data,
    );
  }

  bool _isVisible(Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? '';
    final moderation = data['moderationStatus']?.toString().toLowerCase() ?? '';
    if (status == 'deleted' ||
        status == 'hidden' ||
        status == 'archived' ||
        moderation == 'rejected') {
      return false;
    }
    if (data['isDeleted'] == true || data['deleted'] == true) return false;
    if (data['isPublic'] == false || data['visibleInSalon'] == false) {
      return false;
    }
    return true;
  }

  bool _looksLikeWishlist(TryOnSource item) {
    final searchable =
        '${item.id} ${item.title} ${item.subtitle}'.toLowerCase();
    return searchable.contains('souhait') ||
        searchable.contains('wishlist') ||
        searchable.contains('inspiration') ||
        item.id.startsWith('wish_');
  }

  String _label(ClientSavedType type) {
    return switch (type) {
      ClientSavedType.owned => 'Garde-robe',
      ClientSavedType.wishlist => 'Souhait',
      ClientSavedType.inspiration => 'Inspiration',
      ClientSavedType.tryOn => 'Essayage',
      ClientSavedType.project => 'Projet',
      ClientSavedType.favorite => 'Favori',
    };
  }

  String _ownerId(Map<String, dynamic> data) {
    return _firstText(data, const [
      'ownerId',
      'sellerId',
      'boutiqueId',
      'creatorId',
      'createurId',
      'userId',
    ], '');
  }

  String _firstImage(Map<String, dynamic> data) {
    final direct = _firstText(data, const [
      'imageUrl',
      'image',
      'photoUrl',
      'coverImage',
      'thumbnailUrl',
    ], '');
    if (direct.isNotEmpty) return direct;

    final images = data['images'];
    if (images is List) {
      for (final item in images) {
        final value = item?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }

    final media = data['media'];
    if (media is List) {
      for (final item in media.whereType<Map>()) {
        final value =
            item['optimizedUrl']?.toString().trim() ??
            item['url']?.toString().trim() ??
            item['secureUrl']?.toString().trim() ??
            item['imageUrl']?.toString().trim() ??
            '';
        if (value.isNotEmpty) return value;
      }
    }
    return '';
  }

  String _firstText(
    Map<String, dynamic> data,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }
}
