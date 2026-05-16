import 'package:elegantfaso/models/wardrobe/wardrobe_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalise les métadonnées d’un essayage sauvegardé', () {
    final item = WardrobeItem.fromMap('try_on_123', const {
      'userId': 'client',
      'name': 'Essayage - Lunettes',
      'category': 'Essayages',
      'tryOnExperience': 'faceAccessory',
      'tryOnExperienceLabel': 'Accessoire visage',
      'tryOnKind': 'faceAccessory',
      'sourceType': 'product',
      'sourceId': 'lunettes_1',
      'sourceImageUrl': 'https://example.com/lunettes.jpg',
      'sourceOwnerId': 'seller_1',
      'sourceRaw': {
        'tryOnModes': ['preview', 'face'],
        'sellerName': 'Maison Style',
      },
      'images': ['https://example.com/result.jpg'],
    });

    expect(item.isTryOnResult, isTrue);
    expect(item.tryOnDisplayLabel, 'Accessoire visage');
    expect(item.tryOnKind, 'faceAccessory');
    expect(item.canRetryTryOn, isTrue);
    expect(item.sourceImageUrl, 'https://example.com/lunettes.jpg');
    expect(item.sourceOwnerId, 'seller_1');
    expect(item.sourceRaw['sellerName'], 'Maison Style');
  });

  test('déduit un libellé pour les anciens looks essayés', () {
    final item = WardrobeItem.fromMap('try_on_legacy', const {
      'userId': 'client',
      'name': 'Essayage - Robe',
      'category': 'Essayages',
      'images': ['https://example.com/result.jpg'],
    });

    expect(item.isTryOnResult, isTrue);
    expect(item.tryOnDisplayLabel, 'Essayage');
    expect(item.canRetryTryOn, isFalse);
  });
}
