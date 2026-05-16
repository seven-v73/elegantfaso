import 'package:flutter/material.dart';

import '../../../design/modern_design_system.dart';
import 'app_text_field.dart';

class AppLocationField extends StatelessWidget {
  const AppLocationField({
    super.key,
    required this.cityController,
    required this.countryController,
    this.addressController,
    this.onUseCurrentLocation,
    this.status,
  });

  final TextEditingController cityController;
  final TextEditingController countryController;
  final TextEditingController? addressController;
  final VoidCallback? onUseCurrentLocation;
  final String? status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: cityController,
                label: 'Ville',
                hint: 'Paris, Abidjan, Ouagadougou...',
                icon: Icons.location_city_rounded,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: ModernSpacing.md),
            Expanded(
              child: AppTextField(
                controller: countryController,
                label: 'Pays',
                hint: 'Pays',
                icon: Icons.public_rounded,
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        if (addressController != null) ...[
          const SizedBox(height: ModernSpacing.md),
          AppTextField(
            controller: addressController!,
            label: 'Adresse courte',
            hint: 'Quartier, rue ou repère',
            icon: Icons.place_rounded,
            textInputAction: TextInputAction.next,
          ),
        ],
        const SizedBox(height: ModernSpacing.md),
        Container(
          padding: const EdgeInsets.all(ModernSpacing.md),
          decoration: ModernDecorations.softPanel(),
          child: Row(
            children: [
              const Icon(Icons.map_rounded, color: ModernColors.primary),
              const SizedBox(width: ModernSpacing.md),
              Expanded(
                child: Text(
                  status?.trim().isNotEmpty == true
                      ? status!
                      : 'Cette localisation peut rendre le profil visible dans “Près de moi”.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (onUseCurrentLocation != null)
                TextButton(
                  onPressed: onUseCurrentLocation,
                  child: const Text('Utiliser'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
