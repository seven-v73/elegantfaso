import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

class StorageService {
  static Future<List<String>> uploadImages(
      List<File> images, {
        required void Function(double) onProgress,
      }) async {
    try {
      final storage = FirebaseStorage.instance;
      final imageUrls = <String>[];
      final total = images.length;

      for (int i = 0; i < total; i++) {
        final file = images[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = storage.ref().child('creations/$fileName');

        await ref.putFile(file);
        final url = await ref.getDownloadURL();

        imageUrls.add(url);
        onProgress((i + 1) / total);
      }

      return imageUrls;
    } catch (e) {
      debugPrint("Error uploading images: $e");
      throw Exception("Failed to upload images");
    }
  }
}