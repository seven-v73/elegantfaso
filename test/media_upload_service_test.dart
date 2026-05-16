import 'dart:io';

import 'package:elegantfaso/services/media/media_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaUploadService transformations', () {
    const url =
        'https://res.cloudinary.com/demo/image/upload/v123/elegantstyle/products/item.jpg';

    test('insère une transformation Cloudinary après /upload/', () {
      final transformed = MediaUploadService.transformUrl(
        url,
        'f_auto,q_auto,w_600',
      );

      expect(
        transformed,
        'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,w_600/v123/elegantstyle/products/item.jpg',
      );
    });

    test('produit une miniature mobile', () {
      final thumbnail = MediaUploadService.thumbnailUrl(url);

      expect(thumbnail, contains('f_auto,q_auto:eco'));
      expect(thumbnail, contains('w_360,h_480'));
    });

    test('ignore les urls non Cloudinary', () {
      const external = 'https://example.com/image.jpg';

      expect(
        MediaUploadService.transformUrl(external, 'f_auto,q_auto'),
        external,
      );
    });
  });

  group('MediaUploadService file safety', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('media_upload_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<File> writeFile(String name, List<int> bytes) async {
      final file = File('${tempDir.path}/$name');
      return file.writeAsBytes(bytes, flush: true);
    }

    test('accepts safe image files for image uploads', () async {
      final file = await writeFile('preuve.jpg', [
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0x00,
        0x10,
        0x4A,
        0x46,
        0x49,
        0x46,
      ]);

      final validation = await MediaUploadService.validateFile(file);

      expect(validation.isValid, isTrue);
      expect(validation.kind, 'image');
    });

    test('blocks archives even when uploadFile is used', () async {
      final file = await writeFile('archive.zip', [
        0x50,
        0x4B,
        0x03,
        0x04,
        0x14,
        0x00,
      ]);

      final validation = await MediaUploadService.validateFile(
        file,
        resourceType: 'auto',
      );

      expect(validation.isValid, isFalse);
      expect(validation.message, contains('bloqué'));
    });

    test('blocks code disguised as an image extension', () async {
      final file = await writeFile(
        'avatar.png',
        '<script>alert(1)</script>'.codeUnits,
      );

      final validation = await MediaUploadService.validateFile(file);

      expect(validation.isValid, isFalse);
      expect(validation.message, contains('image sûre'));
    });

    test('accepts pdf documents through auto uploads only', () async {
      final file = await writeFile('facture.pdf', '%PDF-1.7'.codeUnits);

      final documentValidation = await MediaUploadService.validateFile(
        file,
        resourceType: 'auto',
      );
      final imageValidation = await MediaUploadService.validateFile(file);

      expect(documentValidation.isValid, isTrue);
      expect(documentValidation.kind, 'document');
      expect(imageValidation.isValid, isFalse);
    });
  });
}
