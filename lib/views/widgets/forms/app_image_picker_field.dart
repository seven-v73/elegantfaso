import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../design/modern_design_system.dart';

class AppImagePickerField extends StatelessWidget {
  const AppImagePickerField({
    super.key,
    required this.title,
    required this.subtitle,
    required this.files,
    required this.onAdd,
    required this.onRemove,
    this.maxImages = 1,
    this.existingUrls = const [],
  });

  final String title;
  final String subtitle;
  final List<File> files;
  final List<String> existingUrls;
  final int maxImages;
  final Future<void> Function(ImageSource source) onAdd;
  final ValueChanged<int> onRemove;

  bool get _hasImages => files.isNotEmpty || existingUrls.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Text(
              '${files.length + existingUrls.length}/$maxImages',
              style: const TextStyle(
                color: ModernColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: ModernSpacing.md),
        if (_hasImages) _buildPreviewGrid() else _buildEmptyState(context),
        const SizedBox(height: ModernSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    files.length + existingUrls.length >= maxImages
                        ? null
                        : () => onAdd(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Galerie'),
              ),
            ),
            const SizedBox(width: ModernSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    files.length + existingUrls.length >= maxImages
                        ? null
                        : () => onAdd(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Caméra'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(ModernRadius.lg),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: ModernColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              color: ModernColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: ModernSpacing.md),
          Text(
            'Ajoutez une image claire',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Fond simple, bonne lumière, vêtement visible.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewGrid() {
    final count = files.length + existingUrls.length;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: ModernSpacing.sm,
        mainAxisSpacing: ModernSpacing.sm,
      ),
      itemBuilder: (context, index) {
        final isFile = index < files.length;
        final child =
            isFile
                ? Image.file(files[index], fit: BoxFit.cover)
                : Image.network(
                  existingUrls[index - files.length],
                  fit: BoxFit.cover,
                );
        return ClipRRect(
          borderRadius: BorderRadius.circular(ModernRadius.md),
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: () => onRemove(index),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: ModernColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              if (index == 0)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ModernColors.ink.withValues(alpha: 0.74),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Principale',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
