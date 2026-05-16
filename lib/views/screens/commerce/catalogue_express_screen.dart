import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/account_roles.dart';
import '../../../design/app_icons.dart';
import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';
import '../../../services/commerce/catalogue_express_service.dart';

class CatalogueExpressScreen extends StatefulWidget {
  const CatalogueExpressScreen({super.key, required this.role});

  final String role;

  @override
  State<CatalogueExpressScreen> createState() => _CatalogueExpressScreenState();
}

class _CatalogueExpressScreenState extends State<CatalogueExpressScreen> {
  final _picker = ImagePicker();
  final _service = CatalogueExpressService();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  final List<XFile> _images = [];
  String _category = 'Tenues';
  String _mode = 'Disponible';
  String _status = 'draft';
  bool _saving = false;
  String _stage = '';
  double _progress = 0;

  bool get _isCreator => widget.role == AccountRoles.createur;

  List<String> get _categories =>
      _isCreator
          ? const ['Tenues', 'Mariage', 'Cérémonie', 'Coiffures', 'Accessoires']
          : const ['Tenues', 'Chaussures', 'Sacs', 'Bijoux', 'Accessoires'];

  List<String> get _modes =>
      _isCreator
          ? const [
            'Portfolio seulement',
            'Commandable sur mesure',
            'Disponible maintenant',
            'Prix sur devis',
          ]
          : const [
            'Disponible',
            'Pièce unique',
            'Sur commande',
            'Vitrine - discuter',
          ];

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 86);
    if (images.isEmpty || !mounted) return;
    setState(() => _images.addAll(images.take(50 - _images.length)));
  }

  Future<void> _saveDrafts() async {
    if (_images.isEmpty) {
      _snack('Ajoutez des photos pour créer votre catalogue.', danger: true);
      return;
    }

    setState(() {
      _saving = true;
      _stage = 'Préparation des brouillons';
      _progress = 0;
    });
    try {
      final price = double.tryParse(_priceController.text.trim()) ?? 0;
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
      final drafts =
          _images.indexed.map((entry) {
            final index = entry.$1 + 1;
            final file = entry.$2;
            return CatalogueExpressDraft(
              file: file,
              title: _suggestTitle(file.name, index),
              category: _category,
              price: price,
              quantity: quantity.clamp(1, 999),
              mode: _mode,
              status: _status,
              description:
                  _descriptionController.text.trim().isEmpty
                      ? _defaultDescription
                      : _descriptionController.text.trim(),
            );
          }).toList();
      final result = await _service.publishDrafts(
        role: widget.role,
        drafts: drafts,
        onProgress: (stage, progress) {
          if (!mounted) return;
          setState(() {
            _stage = stage;
            _progress = progress.clamp(0, 1);
          });
        },
      );
      if (!mounted) return;
      _snack('${result.created} brouillon(s) créés. Vous pouvez les enrichir.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack('Catalogue Express indisponible: $e', danger: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _defaultDescription {
    if (_isCreator) {
      return 'Création ajoutée via Catalogue Express. Détails à enrichir avant publication finale.';
    }
    return 'Produit ajouté via Catalogue Express. Détails à enrichir avant publication finale.';
  }

  String _suggestTitle(String fileName, int index) {
    final text = fileName.toLowerCase();
    final prefix =
        _category == 'Chaussures'
            ? 'Chaussures'
            : _category == 'Sacs'
            ? 'Sac'
            : _category == 'Bijoux'
            ? 'Bijou'
            : _category == 'Coiffures'
            ? 'Coiffure'
            : 'Pièce mode';
    final color =
        text.contains('noir')
            ? ' noir'
            : text.contains('blanc')
            ? ' blanc'
            : text.contains('rouge')
            ? ' rouge'
            : '';
    return '$prefix$color #$index';
  }

  void _snack(String message, {bool danger = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: danger ? ModernColors.danger : ModernColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isCreator ? 'Créations Express' : 'Catalogue Express';
    final subtitle =
        _isCreator
            ? 'Transformez vos photos en brouillons de créations.'
            : 'Importez plusieurs photos et préparez un rayon en quelques minutes.';

    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: ModernColors.canvas,
        foregroundColor: ModernColors.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
          children: [
            _HeroCard(
              title: title,
              subtitle: subtitle,
              accent: _isCreator ? ModernColors.creator : ModernColors.shop,
              count: _images.length,
              onPick: _saving ? null : _pickImages,
            ),
            const SizedBox(height: 14),
            _ImageStrip(
              images: _images,
              onRemove:
                  _saving
                      ? null
                      : (image) => setState(() => _images.remove(image)),
            ),
            const SizedBox(height: 14),
            _BatchSettings(
              categories: _categories,
              modes: _modes,
              category: _category,
              mode: _mode,
              status: _status,
              priceController: _priceController,
              quantityController: _quantityController,
              descriptionController: _descriptionController,
              showQuantity: !_isCreator,
              onCategoryChanged: (value) => setState(() => _category = value),
              onModeChanged: (value) => setState(() => _mode = value),
              onStatusChanged: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: 14),
            const _ExpressPrinciples(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            border: Border(top: BorderSide(color: ModernColors.line)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_saving) ...[
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
                Text(
                  _stage,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              AppButton(
                label: _status == 'published' ? 'Publier' : 'Créer',
                icon: Icons.auto_awesome_rounded,
                onPressed: _saveDrafts,
                loading: _saving,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.count,
    required this.onPick,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final int count;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: ModernColors.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(AppIcons.add, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(
                    count == 0 ? 'Importer des photos' : '$count photo(s)',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.images, required this.onRemove});

  final List<XFile> images;
  final ValueChanged<XFile>? onRemove;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const AppCard(
        elevated: false,
        child: Text(
          'Les photos deviennent des brouillons. Vous pourrez corriger les titres, prix et détails après création.',
          style: TextStyle(
            color: ModernColors.inkSoft,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final image = images[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(image.path),
                  width: 94,
                  height: 112,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, _, _) => Container(
                        width: 94,
                        height: 112,
                        color: ModernColors.line,
                        child: const Icon(Icons.image_rounded),
                      ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: onRemove == null ? null : () => onRemove!(image),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: ModernColors.ink.withValues(alpha: 0.76),
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
            ],
          );
        },
      ),
    );
  }
}

class _BatchSettings extends StatelessWidget {
  const _BatchSettings({
    required this.categories,
    required this.modes,
    required this.category,
    required this.mode,
    required this.status,
    required this.priceController,
    required this.quantityController,
    required this.descriptionController,
    required this.showQuantity,
    required this.onCategoryChanged,
    required this.onModeChanged,
    required this.onStatusChanged,
  });

  final List<String> categories;
  final List<String> modes;
  final String category;
  final String mode;
  final String status;
  final TextEditingController priceController;
  final TextEditingController quantityController;
  final TextEditingController descriptionController;
  final bool showQuantity;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Réglages en lot',
            style: TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _ChoiceWrap(
            label: 'Catégorie',
            values: categories,
            selected: category,
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 12),
          _ChoiceWrap(
            label: 'Mode',
            values: modes,
            selected: mode,
            onChanged: onModeChanged,
          ),
          const SizedBox(height: 12),
          _ChoiceWrap(
            label: 'Publication',
            values: const ['draft', 'published'],
            labels: const {'draft': 'Brouillon', 'published': 'Publier'},
            selected: status,
            onChanged: onStatusChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prix commun',
                    hintText: '0 = devis',
                  ),
                ),
              ),
              if (showQuantity) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 104,
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description commune',
              hintText: 'Optionnel, vous pourrez enrichir après.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.label,
    required this.values,
    required this.selected,
    required this.onChanged,
    this.labels = const {},
  });

  final String label;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ModernColors.inkSoft,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              values.map((value) {
                return ChoiceChip(
                  label: Text(labels[value] ?? value),
                  selected: value == selected,
                  onSelected: (_) => onChanged(value),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class _ExpressPrinciples extends StatelessWidget {
  const _ExpressPrinciples();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pensé pour les journées chargées',
            style: TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Publiez vite en brouillon, puis enrichissez seulement les pièces importantes. Votre vitrine avance même quand vous êtes en boutique ou à l’atelier.',
            style: TextStyle(
              color: ModernColors.inkSoft,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
