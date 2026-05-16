import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/try_on/try_on_source.dart';
import '../../models/try_on/try_on_compatibility.dart';
import '../media/media_asset_service.dart';
import '../media/media_upload_service.dart';

class TryOnResultService {
  TryOnResultService({
    FirebaseFirestore? firestore,
    MediaUploadService? mediaUploadService,
    MediaAssetService? mediaAssetService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _mediaUploadService = mediaUploadService ?? MediaUploadService(),
       _mediaAssetService =
           mediaAssetService ??
           MediaAssetService(
             firestore: firestore ?? FirebaseFirestore.instance,
           );

  final FirebaseFirestore _firestore;
  final MediaUploadService _mediaUploadService;
  final MediaAssetService _mediaAssetService;

  Future<String> saveResult({
    required String userId,
    required Uint8List bytes,
    required TryOnSource source,
    String personImagePath = '',
    String garmentImageUrl = '',
    TryOnExperience experience = TryOnExperience.freePreview,
    TryOnPieceKind pieceKind = TryOnPieceKind.unknown,
    String experienceLabel = 'Aperçu libre',
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/try_on_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);

    final upload = await _mediaUploadService.uploadImage(
      file: file,
      folder: 'try_on/$userId',
      publicId: 'result_${DateTime.now().millisecondsSinceEpoch}',
    );
    final mediaId = await _mediaAssetService.recordUpload(
      upload: upload,
      ownerId: userId,
      ownerRole: 'client',
      usage: 'try_on',
      status: 'active',
      linkedCollection: 'users/$userId/try_on_sessions',
      extra: {
        'sourceType': source.type.name,
        'sourceId': source.id,
        'experience': experience.name,
        'pieceKind': pieceKind.name,
      },
    );

    final session =
        _firestore
            .collection('users')
            .doc(userId)
            .collection('try_on_sessions')
            .doc();
    await session.set({
      'userId': userId,
      'personImagePath': personImagePath,
      'garmentImageUrl':
          garmentImageUrl.isNotEmpty ? garmentImageUrl : source.imageUrl,
      'resultImageUrl': upload.optimizedUrl,
      'resultOriginalUrl': upload.url,
      'garmentSourceType': source.type.name,
      'garmentSourceId': source.id,
      'garmentTitle': source.title,
      'tryOnExperience': experience.name,
      'tryOnExperienceLabel': experienceLabel,
      'tryOnKind': pieceKind.name,
      'sourceOwnerId': source.ownerId,
      'sourceRaw': source.raw,
      'status': 'completed',
      'mediaId': mediaId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wardrobe')
        .doc('try_on_${session.id}')
        .set({
          'userId': userId,
          'name': 'Essayage - ${source.title}',
          'category': 'Essayages',
          'brand': source.typeLabel,
          'occasion': 'Essayage virtuel',
          'description': 'Look essayé depuis ${source.typeLabel}.',
          'tryOnExperience': experience.name,
          'tryOnExperienceLabel': experienceLabel,
          'tryOnKind': pieceKind.name,
          'images': [upload.optimizedUrl],
          'media': [
            {...upload.toMap(), 'type': 'try_on_result', 'mediaId': mediaId},
          ],
          'sourceType': source.type.name,
          'sourceId': source.id,
          'sourceImageUrl': source.imageUrl,
          'sourceOwnerId': source.ownerId,
          'sourceRaw': source.raw,
          'favorite': true,
          'isArchived': false,
          'wearCount': 0,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    return upload.optimizedUrl;
  }
}
