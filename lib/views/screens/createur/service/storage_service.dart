import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../services/media/media_asset_service.dart';
import '../../../../services/media/media_upload_service.dart';

class StorageService {
  static final _mediaUploadService = MediaUploadService();
  static final _mediaAssetService = MediaAssetService();

  static Future<void> deleteImages(List<String> urls) async {
    debugPrint(
      'Suppression média distante non gérée côté client (${urls.length} fichier(s)).',
    );
  }

  static Future<List<String>> uploadImages(
    List<File> images, {
    required void Function(double) onProgress,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Utilisateur non connecté');
      }
      final imageUrls = <String>[];
      final total = images.length;

      for (int i = 0; i < total; i++) {
        final file = images[i];
        final upload = await _mediaUploadService.uploadImage(
          file: file,
          folder: 'creations/${user.uid}',
          publicId: 'creation_${DateTime.now().millisecondsSinceEpoch}_$i',
        );
        await _mediaAssetService.recordUpload(
          upload: upload,
          ownerId: user.uid,
          ownerRole: 'createur',
          usage: 'creation',
          status: 'public',
          linkedCollection: 'creations',
        );

        imageUrls.add(upload.optimizedUrl);
        onProgress((i + 1) / total);
      }

      return imageUrls;
    } catch (e) {
      debugPrint('Erreur upload images création: $e');
      if (e is StateError) rethrow;
      throw StateError('Images impossibles à envoyer pour le moment.');
    }
  }
}
