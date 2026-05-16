import 'dart:io';

enum TryOnSourceType { wardrobe, wishlist, product, creation, gallery }

class TryOnSource {
  const TryOnSource({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle = '',
    this.imageUrl = '',
    this.file,
    this.ownerId = '',
    this.raw = const {},
  });

  final String id;
  final TryOnSourceType type;
  final String title;
  final String subtitle;
  final String imageUrl;
  final File? file;
  final String ownerId;
  final Map<String, dynamic> raw;

  bool get hasImage => file != null || imageUrl.trim().isNotEmpty;

  bool get isNetworkImage {
    final value = imageUrl.trim().toLowerCase();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  File? get effectiveFile {
    if (file != null) return file;
    final value = imageUrl.trim();
    if (value.isEmpty || isNetworkImage) return null;
    return File(value);
  }

  String get typeLabel {
    return switch (type) {
      TryOnSourceType.wardrobe => 'Garde-robe',
      TryOnSourceType.wishlist => 'Souhait',
      TryOnSourceType.product => 'Produit',
      TryOnSourceType.creation => 'Création',
      TryOnSourceType.gallery => 'Galerie',
    };
  }
}
