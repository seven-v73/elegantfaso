import 'package:cloud_firestore/cloud_firestore.dart';

import 'media_upload_service.dart';

class MediaAssetService {
  MediaAssetService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<String> recordUpload({
    required MediaUploadResult upload,
    required String ownerId,
    required String ownerRole,
    required String usage,
    String status = 'active',
    String? linkedCollection,
    String? linkedDocumentId,
    Map<String, dynamic> extra = const {},
  }) async {
    final doc = _firestore.collection('media_assets').doc();
    await doc.set({
      ...upload.toAssetMap(
        ownerId: ownerId,
        ownerRole: ownerRole,
        usage: usage,
        linkedCollection: linkedCollection,
        linkedDocumentId: linkedDocumentId,
        status: status,
      ),
      ...extra,
    });
    return doc.id;
  }

  Future<void> linkAsset({
    required String mediaId,
    required String linkedCollection,
    required String linkedDocumentId,
  }) {
    return _firestore.collection('media_assets').doc(mediaId).set({
      'linkedCollection': linkedCollection,
      'linkedDocumentId': linkedDocumentId,
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
