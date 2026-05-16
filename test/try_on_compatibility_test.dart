import 'package:elegantfaso/models/try_on/try_on_compatibility.dart';
import 'package:elegantfaso/models/shop/public_listing.dart';
import 'package:elegantfaso/views/widgets/forms/try_on_compatibility_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classe les accessoires visage et autorise le mode visage', () {
    final compatibility = TryOnCompatibility.fromSource(
      title: 'Lunettes solaires artisanales',
      subtitle: 'Accessoires',
      sourceType: 'product',
    );

    expect(compatibility.kind, TryOnPieceKind.faceAccessory);
    expect(compatibility.supports(TryOnExperience.faceAccessory), isTrue);
    expect(compatibility.supports(TryOnExperience.aiGarment), isFalse);
  });

  test('classe les vêtements et autorise le mode IA vêtement', () {
    final compatibility = TryOnCompatibility.fromSource(
      title: 'Robe wax cérémonie',
      subtitle: 'Tenue femme',
      sourceType: 'creation',
    );

    expect(compatibility.kind, TryOnPieceKind.garment);
    expect(compatibility.supports(TryOnExperience.aiGarment), isTrue);
    expect(compatibility.supports(TryOnExperience.faceAccessory), isFalse);
  });

  test('garde les chaussures en aperçu libre plutôt que visage ou IA', () {
    final compatibility = TryOnCompatibility.fromSource(
      title: 'Sandales cuir',
      subtitle: 'Chaussures',
      sourceType: 'product',
    );

    expect(compatibility.kind, TryOnPieceKind.supportAccessory);
    expect(compatibility.supports(TryOnExperience.freePreview), isTrue);
    expect(compatibility.supports(TryOnExperience.faceAccessory), isFalse);
    expect(compatibility.supports(TryOnExperience.aiGarment), isFalse);
  });

  test('respecte une compatibilité explicite fournie par le catalogue', () {
    final compatibility = TryOnCompatibility.fromSource(
      title: 'Pièce concept',
      subtitle: 'Edition spéciale',
      sourceType: 'product',
      raw: const {
        'tryOnKind': 'support',
        'tryOnModes': ['preview', 'ai'],
      },
    );

    expect(compatibility.kind, TryOnPieceKind.supportAccessory);
    expect(compatibility.supports(TryOnExperience.freePreview), isTrue);
    expect(compatibility.supports(TryOnExperience.aiGarment), isTrue);
  });

  test('prépare les champs Firestore depuis le choix pro du formulaire', () {
    final data = TryOnCompatibilityField.catalogFields(
      preset: TryOnCompatibilityField.facePreset,
      title: 'Lunettes modernes',
      category: 'Accessoires',
    );

    expect(data['tryOnPreset'], TryOnCompatibilityField.facePreset);
    expect(data['tryOnKind'], TryOnPieceKind.faceAccessory.name);
    expect(data['tryOnModes'], containsAll(['preview', 'face']));
    expect(data['tryOnEnabled'], isTrue);
  });

  test('le choix automatique classe une robe comme vêtement IA', () {
    final data = TryOnCompatibilityField.catalogFields(
      preset: TryOnCompatibilityField.autoPreset,
      title: 'Robe fluide',
      category: 'Vêtements',
    );

    expect(data['tryOnKind'], TryOnPieceKind.garment.name);
    expect(data['tryOnModes'], containsAll(['preview', 'ai']));
  });

  test(
    'PublicListing expose le bouton essayer avec les champs pro explicites',
    () {
      const listing = PublicListing(
        id: 'p1',
        type: 'product',
        title: 'Sac perlé',
        imageUrl: 'https://example.com/sac.jpg',
        price: 15000,
        sellerId: 'seller',
        category: 'Accessoires',
        data: {
          'tryOnEnabled': true,
          'tryOnKind': 'supportAccessory',
          'tryOnModes': ['preview'],
        },
      );

      expect(listing.canTryOn, isTrue);
    },
  );

  test('PublicListing respecte une désactivation explicite essayage', () {
    const listing = PublicListing(
      id: 'p2',
      type: 'product',
      title: 'Produit non essayable',
      imageUrl: 'https://example.com/item.jpg',
      price: 10000,
      sellerId: 'seller',
      category: 'Décoration',
      data: {'tryOnEnabled': false},
    );

    expect(listing.canTryOn, isFalse);
  });

  test(
    'PublicListing conserve les pièces anciennes essayables par inférence',
    () {
      const listing = PublicListing(
        id: 'p3',
        type: 'product',
        title: 'Robe droite',
        imageUrl: 'https://example.com/robe.jpg',
        price: 25000,
        sellerId: 'seller',
        category: 'Vêtements',
        data: {},
      );

      expect(listing.canTryOn, isTrue);
    },
  );
}
