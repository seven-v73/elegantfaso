import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/wardrobe/wardrobe_item.dart';
import '../media/media_asset_service.dart';
import '../media/media_upload_service.dart';

class WardrobeService {
  WardrobeService({
    FirebaseFirestore? firestore,
    MediaUploadService? mediaUploadService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _mediaUploadService = mediaUploadService ?? MediaUploadService(),
       _mediaAssetService = MediaAssetService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final MediaUploadService _mediaUploadService;
  final MediaAssetService _mediaAssetService;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('wardrobe');
  }

  Stream<List<WardrobeItem>> watchItems(String userId, {int limit = 60}) {
    return _collection(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit.clamp(24, 160))
        .snapshots()
        .map((snapshot) {
          final items =
              snapshot.docs
                  .map(WardrobeItem.fromFirestore)
                  .where((item) => !item.isArchived)
                  .toList();
          items.sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          return items;
        });
  }

  Future<List<MediaUploadResult>> uploadImages({
    required String userId,
    required List<File> files,
    required void Function(String stage) onStage,
  }) async {
    final uploads = <MediaUploadResult>[];
    for (var i = 0; i < files.length; i++) {
      onStage('Compression ${i + 1}/${files.length}');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      onStage('Upload Cloudinary ${i + 1}/${files.length}');
      final upload = await _mediaUploadService.uploadImage(
        file: files[i],
        folder: 'wardrobe/$userId',
        publicId: 'item_${DateTime.now().millisecondsSinceEpoch}_$i',
      );
      final mediaId = await _mediaAssetService.recordUpload(
        upload: upload,
        ownerId: userId,
        ownerRole: 'client',
        usage: 'wardrobe',
        status: 'pending',
        linkedCollection: 'users/$userId/wardrobe',
      );
      uploads.add(upload.copyWithAssetId(mediaId));
    }
    return uploads;
  }

  Future<String> addItem(WardrobeItem item) async {
    final doc = await _collection(
      item.userId,
    ).add(item.toFirestore(includeCreatedAt: true));
    for (final media in item.media) {
      final mediaId = media['mediaId']?.toString();
      if (mediaId != null && mediaId.isNotEmpty) {
        await _mediaAssetService.linkAsset(
          mediaId: mediaId,
          linkedCollection: 'users/${item.userId}/wardrobe',
          linkedDocumentId: doc.id,
        );
      }
    }
    return doc.id;
  }

  Future<void> updateItem(WardrobeItem item) {
    return _collection(
      item.userId,
    ).doc(item.id).set(item.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteItem(String userId, String itemId) {
    return _collection(userId).doc(itemId).delete();
  }

  Future<void> deleteItems(String userId, Iterable<String> itemIds) async {
    final batch = _firestore.batch();
    for (final itemId in itemIds) {
      batch.delete(_collection(userId).doc(itemId));
    }
    await batch.commit();
  }

  Future<void> updateItemsFields(
    String userId,
    Iterable<String> itemIds,
    Map<String, dynamic> fields,
  ) async {
    final batch = _firestore.batch();
    for (final itemId in itemIds) {
      batch.set(_collection(userId).doc(itemId), {
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> toggleFavorite(WardrobeItem item) {
    return _collection(item.userId).doc(item.id).set({
      'favorite': !item.favorite,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markWorn(WardrobeItem item) {
    return _collection(item.userId).doc(item.id).set({
      'wearCount': FieldValue.increment(1),
      'lastWornAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
