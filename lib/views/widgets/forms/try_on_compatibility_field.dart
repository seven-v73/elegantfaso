import 'package:flutter/material.dart';

import '../../../models/try_on/try_on_compatibility.dart';
import 'app_select_field.dart';

class TryOnCompatibilityField extends StatelessWidget {
  const TryOnCompatibilityField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const autoPreset = 'Automatique selon la catégorie';
  static const facePreset = 'Accessoire visage';
  static const garmentPreset = 'Vêtement IA';
  static const previewPreset = 'Aperçu libre';

  static const presets = [autoPreset, facePreset, garmentPreset, previewPreset];

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSelectField<String>(
          value: presets.contains(value) ? value : autoPreset,
          items: presets,
          label: 'Essayage conseillé',
          icon: Icons.checkroom_rounded,
          onChanged: (next) => onChanged(next ?? autoPreset),
        ),
        const SizedBox(height: 8),
        Text(
          helperTextFor(value),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF64748B),
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  static String helperTextFor(String preset) {
    return switch (preset) {
      facePreset =>
        'Pour lunettes, chapeaux, foulards ou bijoux proches du visage.',
      garmentPreset =>
        'Pour robes, hauts, vestes, boubous, ensembles et pièces portées.',
      previewPreset =>
        'Pour sacs, chaussures ou pièces à tester rapidement sans IA.',
      _ => 'L’app choisira le meilleur mode selon le titre et la catégorie.',
    };
  }

  static Map<String, dynamic> catalogFields({
    required String preset,
    required String title,
    required String category,
    String subtitle = '',
  }) {
    final compatibility =
        preset == autoPreset
            ? TryOnCompatibility.fromSource(
              title: title,
              subtitle: [
                category,
                subtitle,
              ].where((v) => v.isNotEmpty).join(' '),
            )
            : _compatibilityForPreset(preset);

    final modes = _modesFor(compatibility);
    return {
      'tryOnPreset': preset,
      'tryOnKind': compatibility.kind.name,
      'tryOnModes': modes,
      'tryOnEnabled': modes.isNotEmpty,
    };
  }

  static TryOnCompatibility _compatibilityForPreset(String preset) {
    return switch (preset) {
      facePreset => const TryOnCompatibility(
        kind: TryOnPieceKind.faceAccessory,
        allowedExperiences: {
          TryOnExperience.freePreview,
          TryOnExperience.faceAccessory,
        },
      ),
      garmentPreset => const TryOnCompatibility(
        kind: TryOnPieceKind.garment,
        allowedExperiences: {
          TryOnExperience.freePreview,
          TryOnExperience.aiGarment,
        },
      ),
      previewPreset => const TryOnCompatibility(
        kind: TryOnPieceKind.supportAccessory,
        allowedExperiences: {TryOnExperience.freePreview},
      ),
      _ => const TryOnCompatibility(kind: TryOnPieceKind.unknown),
    };
  }

  static List<String> _modesFor(TryOnCompatibility compatibility) {
    final modes = <String>['preview'];
    if (compatibility.supports(TryOnExperience.faceAccessory)) {
      modes.add('face');
    }
    if (compatibility.supports(TryOnExperience.aiGarment)) {
      modes.add('ai');
    }
    return modes;
  }
}
