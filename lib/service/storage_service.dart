// File: storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; // Import for XFile
import 'package:flutter/foundation.dart'; // Import for debugPrint

class StorageService {
  /// Uploads multiple images to Firebase Storage and returns their download URLs.
  static Future<List<String>> uploadImages(List<XFile> images) async {
    final List<String> downloadUrls = [];
    try {
      for (final image in images) {
        // Generate a unique file name using timestamp and original file name
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final ref = FirebaseStorage.instance.ref('creations/$fileName');

        // Upload the file to Firebase Storage
        await ref.putFile(File(image.path));

        // Get the download URL for the uploaded file
        final downloadUrl = await ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }
      return downloadUrls;
    } catch (e) {
      debugPrint('Error uploading images: $e');
      throw Exception('Failed to upload images: $e');
    }
  }
}