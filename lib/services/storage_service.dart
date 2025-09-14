import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  /// Upload multiple images et retourne la liste des URLs
  static Future<List<String>> uploadImages(List<XFile> images) async {
    List<String> urls = [];
    for (final image in images) {
      final file = File(image.path);
      final ref = _storage.ref().child('creations/${DateTime.now().millisecondsSinceEpoch}_${image.name}');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }
}
