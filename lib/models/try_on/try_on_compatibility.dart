enum TryOnExperience { freePreview, faceAccessory, aiGarment }

enum TryOnPieceKind { faceAccessory, garment, supportAccessory, unknown }

class TryOnCompatibility {
  const TryOnCompatibility({
    required this.kind,
    this.allowedExperiences = const {},
  });

  final TryOnPieceKind kind;
  final Set<TryOnExperience> allowedExperiences;

  bool supports(TryOnExperience experience) {
    if (experience == TryOnExperience.freePreview) return true;
    if (allowedExperiences.contains(experience)) return true;
    if (kind == TryOnPieceKind.unknown) return true;
    return switch (experience) {
      TryOnExperience.faceAccessory => kind == TryOnPieceKind.faceAccessory,
      TryOnExperience.aiGarment => kind == TryOnPieceKind.garment,
      TryOnExperience.freePreview => true,
    };
  }

  String get label {
    return switch (kind) {
      TryOnPieceKind.faceAccessory => 'Visage',
      TryOnPieceKind.garment => 'Vêtement',
      TryOnPieceKind.supportAccessory => 'Aperçu',
      TryOnPieceKind.unknown => 'À ajuster',
    };
  }

  factory TryOnCompatibility.fromSource({
    required String title,
    String subtitle = '',
    String sourceType = '',
    Map<String, dynamic> raw = const {},
  }) {
    final explicitKind = _kindFromValue(
      _firstText(raw, const [
        'tryOnKind',
        'tryOnType',
        'tryOnCategory',
        'vtoKind',
        'vtoType',
      ]),
    );
    final explicitExperiences = _experiencesFromRaw(raw);
    if (explicitKind != null) {
      return TryOnCompatibility(
        kind: explicitKind,
        allowedExperiences: explicitExperiences,
      );
    }

    final text =
        [
          title,
          subtitle,
          sourceType,
          raw['category'],
          raw['type'],
          raw['style'],
          raw['tags'],
        ].whereType<Object>().join(' ').toLowerCase();

    if (text.trim().isEmpty || sourceType.toLowerCase() == 'gallery') {
      return TryOnCompatibility(
        kind: TryOnPieceKind.unknown,
        allowedExperiences: explicitExperiences,
      );
    }

    if (_containsAny(text, const [
      'lunette',
      'glasses',
      'eyewear',
      'chapeau',
      'hat',
      'casquette',
      'foulard',
      'turban',
      'scarf',
      'bijou',
      'bijoux',
      'collier',
      'boucle',
      'earring',
      'necklace',
    ])) {
      return TryOnCompatibility(
        kind: TryOnPieceKind.faceAccessory,
        allowedExperiences: explicitExperiences,
      );
    }

    if (_containsAny(text, const ['sac', 'bag', 'chauss', 'shoe', 'sandale'])) {
      return TryOnCompatibility(
        kind: TryOnPieceKind.supportAccessory,
        allowedExperiences: explicitExperiences,
      );
    }

    if (_containsAny(text, const [
      'robe',
      'boubou',
      'tenue',
      'haut',
      'shirt',
      'chemise',
      'veste',
      'pantalon',
      'jupe',
      'ensemble',
      'habit',
      'look',
      'outfit',
    ])) {
      return TryOnCompatibility(
        kind: TryOnPieceKind.garment,
        allowedExperiences: explicitExperiences,
      );
    }

    return TryOnCompatibility(
      kind: TryOnPieceKind.unknown,
      allowedExperiences: explicitExperiences,
    );
  }

  static Set<TryOnExperience> _experiencesFromRaw(Map<String, dynamic> raw) {
    final values = <Object?>[
      raw['tryOnMode'],
      raw['tryOnModes'],
      raw['tryOnExperiences'],
      raw['vtoMode'],
      raw['vtoModes'],
    ];
    final normalized = <String>{};
    for (final value in values) {
      if (value is Iterable) {
        normalized.addAll(value.map((item) => item.toString().toLowerCase()));
      } else if (value != null) {
        normalized.add(value.toString().toLowerCase());
      }
    }
    return {
      if (_matchesAny(normalized, const ['face', 'visage', 'accessory_face']))
        TryOnExperience.faceAccessory,
      if (_matchesAny(normalized, const ['ai', 'ia', 'garment', 'vton']))
        TryOnExperience.aiGarment,
      if (_matchesAny(normalized, const ['free', 'preview', 'apercu']))
        TryOnExperience.freePreview,
    };
  }

  static TryOnPieceKind? _kindFromValue(String value) {
    final normalized = value.toLowerCase();
    if (normalized.isEmpty) return null;
    if (_containsAny(normalized, const ['face', 'visage', 'accessoire'])) {
      return TryOnPieceKind.faceAccessory;
    }
    if (_containsAny(normalized, const ['garment', 'vetement', 'vêtement'])) {
      return TryOnPieceKind.garment;
    }
    if (_containsAny(normalized, const ['support', 'shoe', 'chauss', 'bag'])) {
      return TryOnPieceKind.supportAccessory;
    }
    return null;
  }

  static String _firstText(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static bool _containsAny(String text, List<String> tokens) {
    return tokens.any(text.contains);
  }

  static bool _matchesAny(Set<String> values, List<String> tokens) {
    return values.any((value) => tokens.any(value.contains));
  }
}
