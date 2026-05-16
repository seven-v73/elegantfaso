import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/forms/app_form_state.dart';
import '../../../../services/forms/form_validation_service.dart';
import '../../../../services/preferences/currency_service.dart';
import '../../../widgets/forms/app_form_scaffold.dart';
import '../../../widgets/forms/app_form_section.dart';
import '../../../widgets/forms/app_image_picker_field.dart';
import '../../../widgets/forms/app_money_field.dart';
import '../../../widgets/forms/app_select_field.dart';
import '../../../widgets/forms/app_text_field.dart';
import '../../../widgets/forms/try_on_compatibility_field.dart';
import '../model/creation.dart';
import '../service/storage_service.dart';

class EditCreationScreen extends StatefulWidget {
  final Creation creation;

  const EditCreationScreen({super.key, required this.creation});

  @override
  State<EditCreationScreen> createState() => _EditCreationScreenState();
}

class _EditCreationScreenState extends State<EditCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _tagsController = TextEditingController();
  final _currencyService = CurrencyService();

  late String _selectedCategory;
  String _currency = CurrencyService.defaultCode;
  String _selectedAvailability = 'Disponible sur demande';
  String _tryOnPreset = TryOnCompatibilityField.autoPreset;
  AppFormState _formState = const AppFormState();

  final List<String> _existingImages = [];
  final List<File> _newImages = [];
  final List<String> _deletedImages = [];

  final List<String> _categories = const [
    'Robe',
    'Boubou',
    'Accessoire',
    'Tenue traditionnelle',
    'Coiffure',
    'Chaussure',
    'Autre',
  ];

  final List<String> _availability = const [
    'Disponible sur demande',
    'Prêt à commander',
    'Sur mesure uniquement',
    'Masqué temporairement',
  ];

  bool get _isSaving => _formState.isSaving;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.creation.title;
    _descriptionController.text = widget.creation.description;
    _priceController.text =
        widget.creation.price == 0
            ? ''
            : widget.creation.price.toStringAsFixed(0);
    _selectedCategory =
        _categories.contains(widget.creation.category)
            ? widget.creation.category
            : _categories.first;
    _currency = CurrencyService.normalize(widget.creation.currency);
    _existingImages.addAll(widget.creation.images);
    _loadCurrencyFallback();
  }

  Future<void> _loadCurrencyFallback() async {
    if (_currency != CurrencyService.defaultCode) return;
    final currency = await _currencyService.currentUserCurrency();
    if (mounted) setState(() => _currency = currency);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      onChanged:
          () => setState(
            () =>
                _formState = _formState.copyWith(
                  status: AppFormStatus.dirty,
                  message: '',
                ),
          ),
      child: AppFormScaffold(
        title: 'Modifier la création',
        subtitle:
            'Actualisez votre portfolio. Vous pouvez garder la création visible ou la masquer du Salon.',
        formState: _formState,
        primaryLabel: 'Mettre à jour',
        secondaryLabel: 'Masquer',
        onPrimary: _isSaving ? null : () => _updateCreation(published: true),
        onSecondary: _isSaving ? null : () => _updateCreation(published: false),
        children: [
          AppFormSection(
            title: 'Galerie',
            subtitle: 'La première image reste la couverture publique.',
            icon: Icons.photo_library_rounded,
            children: [
              AppImagePickerField(
                title: 'Images',
                subtitle: 'Ajoutez, remplacez ou retirez les visuels.',
                files: _newImages,
                existingUrls: _existingImages,
                maxImages: 5,
                onAdd: _pickImage,
                onRemove: _removeImageAt,
              ),
            ],
          ),
          AppFormSection(
            title: 'Identité',
            subtitle:
                'Titre, catégorie et tags pour mieux ressortir dans le Salon.',
            icon: Icons.label_rounded,
            children: [
              AppTextField(
                controller: _titleController,
                label: 'Titre',
                hint: 'Nom de la création',
                icon: Icons.title_rounded,
                textInputAction: TextInputAction.next,
                validator:
                    (value) => FormValidationService.requiredText(
                      value,
                      message: 'Ajoutez un titre de création.',
                      minLength: 3,
                    ),
              ),
              AppSelectField<String>(
                value: _selectedCategory,
                items: _categories,
                label: 'Catégorie',
                icon: Icons.category_rounded,
                onChanged:
                    (value) => setState(
                      () => _selectedCategory = value ?? _selectedCategory,
                    ),
              ),
              TryOnCompatibilityField(
                value: _tryOnPreset,
                onChanged: (value) => setState(() => _tryOnPreset = value),
              ),
              AppTextField(
                controller: _tagsController,
                label: 'Tags',
                hint: 'mariage, wax, moderne...',
                icon: Icons.sell_rounded,
                textInputAction: TextInputAction.next,
              ),
            ],
          ),
          AppFormSection(
            title: 'Prix et disponibilité',
            subtitle: 'Gardez le prix indicatif et la disponibilité à jour.',
            icon: Icons.payments_rounded,
            children: [
              AppMoneyField(
                controller: _priceController,
                label: 'Prix indicatif',
                currencySymbol: CurrencyService.optionFor(_currency).symbol,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  return FormValidationService.price(text);
                },
              ),
              AppSelectField<String>(
                value: _selectedAvailability,
                items: _availability,
                label: 'Disponibilité',
                icon: Icons.event_available_rounded,
                onChanged:
                    (value) => setState(
                      () =>
                          _selectedAvailability =
                              value ?? _selectedAvailability,
                    ),
              ),
            ],
          ),
          AppFormSection(
            title: 'Description',
            subtitle:
                'Expliquez ce qui rend cette création utile ou désirable.',
            icon: Icons.notes_rounded,
            children: [
              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Matière, coupe, inspiration, occasions...',
                icon: Icons.description_rounded,
                minLines: 4,
                maxLines: 7,
                textInputAction: TextInputAction.newline,
                validator:
                    (value) =>
                        FormValidationService.description(value, minLength: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_existingImages.length + _newImages.length >= 5) {
      _showError('Vous pouvez conserver jusqu’à 5 images.');
      return;
    }
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (image != null) setState(() => _newImages.add(File(image.path)));
  }

  void _removeImageAt(int index) {
    if (index < _newImages.length) {
      setState(() => _newImages.removeAt(index));
      return;
    }
    final existingIndex = index - _newImages.length;
    if (existingIndex < 0 || existingIndex >= _existingImages.length) return;
    setState(() {
      final removed = _existingImages.removeAt(existingIndex);
      _deletedImages.add(removed);
    });
  }

  Future<void> _updateCreation({required bool published}) async {
    if (!_formKey.currentState!.validate()) return;
    if (published && _existingImages.isEmpty && _newImages.isEmpty) {
      _showError('Gardez au moins une image avant de publier dans le Salon.');
      return;
    }
    final id = widget.creation.id;
    if (id == null || id.isEmpty) {
      _showError('Cette création ne peut pas être modifiée pour le moment.');
      return;
    }

    setState(() {
      _formState = AppFormState(
        status: AppFormStatus.saving,
        message:
            published
                ? 'Mise à jour de la création...'
                : 'Masquage de la création...',
      );
    });

    try {
      final compressedFiles = <File>[];
      for (var i = 0; i < _newImages.length; i++) {
        setState(() {
          _formState = AppFormState(
            status: AppFormStatus.saving,
            message:
                'Compression des nouvelles images ${i + 1}/${_newImages.length}...',
            progress: _newImages.isEmpty ? null : (i + 0.2) / _newImages.length,
          );
        });
        compressedFiles.add(await _compressImage(_newImages[i]));
      }

      final newUrls =
          compressedFiles.isEmpty
              ? <String>[]
              : await StorageService.uploadImages(
                compressedFiles,
                onProgress: (progress) {
                  if (!mounted) return;
                  setState(() {
                    _formState = AppFormState(
                      status: AppFormStatus.saving,
                      message: 'Upload des nouvelles images...',
                      progress: progress,
                    );
                  });
                },
              );

      if (_deletedImages.isNotEmpty) {
        await StorageService.deleteImages(_deletedImages);
      }

      final imageUrls = [..._existingImages, ...newUrls];
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final status = published ? 'published' : 'hidden';
      final tags =
          _tagsController.text
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList();

      await FirebaseFirestore.instance.collection('creations').doc(id).update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'images': imageUrls,
        'price': price,
        'currency': _currency,
        'status': status,
        'visibility': published ? 'salon' : 'private',
        'isPublished': published,
        'visibleInSalon': published,
        'availability': _selectedAvailability,
        ...TryOnCompatibilityField.catalogFields(
          preset: _tryOnPreset,
          title: _titleController.text.trim(),
          category: _selectedCategory,
          subtitle: _descriptionController.text.trim(),
        ),
        'tags': tags,
        'coverImage': imageUrls.isEmpty ? '' : imageUrls.first,
        'imageUrl': imageUrls.isEmpty ? '' : imageUrls.first,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _formState = AppFormState(
          status: AppFormStatus.success,
          message:
              published
                  ? 'Création mise à jour.'
                  : 'Création masquée du Salon.',
        );
      });
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error updating creation: $e');
      if (!mounted) return;
      setState(() {
        _formState = const AppFormState(
          status: AppFormStatus.error,
          message:
              'Impossible de mettre à jour cette création. Vérifiez votre connexion ou réessayez.',
        );
      });
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.path}_compressed.jpg',
        quality: 75,
      );
      return result != null ? File(result.path) : file;
    } catch (e) {
      debugPrint('Image compression error: $e');
      return file;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
