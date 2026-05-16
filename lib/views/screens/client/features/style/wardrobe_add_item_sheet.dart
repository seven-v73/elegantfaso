part of 'garde_robe.dart';

class AddWardrobeItemSheet extends StatefulWidget {
  final String userId;
  final WardrobeItem? item;
  final ImageSource? initialSource;
  final WardrobeService service;

  const AddWardrobeItemSheet({
    super.key,
    required this.userId,
    required this.service,
    this.item,
    this.initialSource,
  });

  @override
  State<AddWardrobeItemSheet> createState() => _AddWardrobeItemSheetState();
}

class _AddWardrobeItemSheetState extends State<AddWardrobeItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _colorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _category = 'Haut';
  String _occasion = 'Décontracté';
  String _season = 'Toute saison';
  bool _favorite = false;
  bool _isLoading = false;
  String _stage = '';
  final List<File> _selectedImages = [];
  final List<String> _existingImages = [];
  final List<Map<String, dynamic>> _existingMedia = [];

  static const Color _primaryColor = _WardrobeScreenState._primaryColor;
  static const Color _cardColor = Colors.white;
  static const Color _errorRed = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _nameController.text = item.name;
      _brandController.text = item.brand;
      _colorController.text = item.color;
      _descriptionController.text = item.description;
      _category = item.category;
      _occasion = item.occasion.isEmpty ? 'Décontracté' : item.occasion;
      _season = item.season.isEmpty ? 'Toute saison' : item.season;
      _favorite = item.favorite;
      _existingImages.addAll(item.images);
      _existingMedia.addAll(item.media);
    }
    if (widget.initialSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImage(widget.initialSource!);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder:
          (context, controller) => Container(
            decoration: const BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: ListView(
              controller: controller,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: ModernColors.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ModernColors.client.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.checkroom_rounded,
                        color: ModernColors.client,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item == null
                                ? 'Ajouter une pièce'
                                : 'Modifier la pièce',
                            style: const TextStyle(
                              color: ModernColors.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Organisez votre style pour mieux essayer et associer.',
                            style: TextStyle(
                              color: ModernColors.inkSoft,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AppFormSection(
                  title: 'Photos',
                  subtitle:
                      'Ajoutez une image nette. La première photo sera utilisée dans la garde-robe.',
                  icon: Icons.photo_library_rounded,
                  children: [
                    AppImagePickerField(
                      title: 'Images de la pièce',
                      subtitle: 'Galerie ou caméra, jusqu’à 5 images.',
                      files: _selectedImages,
                      existingUrls: _existingImages,
                      maxImages: 5,
                      onAdd: _pickImage,
                      onRemove: _removeImageAt,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppFormSection(
                        title: 'Informations',
                        subtitle:
                            'Un nom clair permet de mieux retrouver la pièce dans votre garde-robe.',
                        icon: Icons.info_outline_rounded,
                        children: [
                          AppTextField(
                            controller: _nameController,
                            label: 'Nom de la pièce *',
                            hint: 'Ex: chemise blanche, robe cérémonie...',
                            icon: Icons.label_rounded,
                            textInputAction: TextInputAction.next,
                            validator:
                                (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Ajoutez un nom pour reconnaître cette pièce.'
                                        : null,
                          ),
                          AppSelectField<String>(
                            value: _category,
                            label: 'Catégorie',
                            icon: Icons.category_rounded,
                            items:
                                _WardrobeScreenState._categories
                                    .where((e) => e != 'Tous')
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _category = value);
                              }
                            },
                          ),
                          AppTextField(
                            controller: _brandController,
                            label: 'Marque ou créateur',
                            hint: 'Facultatif',
                            icon: Icons.business_rounded,
                            textInputAction: TextInputAction.next,
                          ),
                          AppTextField(
                            controller: _colorController,
                            label: 'Couleur dominante',
                            hint: 'Ex: bleu, noir, imprimé...',
                            icon: Icons.palette_rounded,
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppFormSection(
                        title: 'Usage',
                        subtitle:
                            'Ces détails aideront à organiser vos tenues et vos sélections.',
                        icon: AppIcons.style,
                        children: [
                          AppSelectField<String>(
                            value: _occasion,
                            label: 'Occasion',
                            icon: Icons.event_available_rounded,
                            items:
                                _WardrobeScreenState._occasions
                                    .where((e) => e != 'Toutes')
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _occasion = value);
                              }
                            },
                          ),
                          AppSelectField<String>(
                            value: _season,
                            label: 'Saison',
                            icon: Icons.wb_sunny_rounded,
                            items:
                                _WardrobeScreenState._seasons
                                    .where((e) => e != 'Toutes')
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _season = value);
                              }
                            },
                          ),
                          AppTextField(
                            controller: _descriptionController,
                            label: 'Notes',
                            hint:
                                'Ex: à porter avec talons, à montrer au tailleur...',
                            icon: Icons.notes_rounded,
                            maxLines: 3,
                          ),
                          SwitchListTile.adaptive(
                            value: _favorite,
                            onChanged:
                                (value) => setState(() => _favorite = value),
                            title: const Text(
                              'Marquer comme favori',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: const Text(
                              'La pièce remontera plus facilement dans vos looks.',
                            ),
                            activeThumbColor: _primaryColor,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoading) ...[
                  LinearProgressIndicator(
                    color: _primaryColor,
                    backgroundColor: _primaryColor.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stage,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                AppStickyFormBar(
                  primaryLabel: widget.item == null ? 'Ajouter' : 'Enregistrer',
                  onPrimary: _save,
                  secondaryLabel: 'Annuler',
                  onSecondary: () => Navigator.pop(context),
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 84,
      maxWidth: 1400,
    );
    if (image == null) return;
    setState(() {
      if (_selectedImages.length + _existingImages.length < 5) {
        _selectedImages.add(File(image.path));
      }
    });
  }

  void _removeImageAt(int index) {
    setState(() {
      if (index < _selectedImages.length) {
        _selectedImages.removeAt(index);
        return;
      }
      final existingIndex = index - _selectedImages.length;
      if (existingIndex >= 0 && existingIndex < _existingImages.length) {
        _existingImages.removeAt(existingIndex);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _stage = 'Préparation des images';
    });

    try {
      final media = [..._existingMedia];
      final imageUrls = [..._existingImages];
      if (_selectedImages.isNotEmpty) {
        final uploads = await widget.service.uploadImages(
          userId: widget.userId,
          files: _selectedImages,
          onStage: (stage) => setState(() => _stage = stage),
        );
        imageUrls.addAll(uploads.map((upload) => upload.optimizedUrl));
        media.addAll(uploads.map((upload) => upload.toMap()));
      }

      setState(() => _stage = 'Sauvegarde dans la garde-robe');

      final item = WardrobeItem(
        id: widget.item?.id ?? '',
        userId: widget.userId,
        name: _nameController.text.trim(),
        category: _category,
        brand: _brandController.text.trim(),
        color: _colorController.text.trim().toLowerCase(),
        occasion: _occasion,
        season: _season,
        description: _descriptionController.text.trim(),
        images: imageUrls,
        media: media,
        favorite: _favorite,
        wearCount: widget.item?.wearCount ?? 0,
        lastWornAt: widget.item?.lastWornAt,
      );

      if (widget.item == null) {
        final id = await widget.service.addItem(item);
        if (mounted) Navigator.pop(context, item.copyWith(id: id));
      } else {
        await widget.service.updateItem(item);
        if (mounted) Navigator.pop(context, item);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload impossible: $e'),
          backgroundColor: _errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _stage = '';
        });
      }
    }
  }
}
