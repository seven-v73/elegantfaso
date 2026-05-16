import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/forms/app_form_state.dart';
import '../../../../services/commerce/pro_access_service.dart';
import '../../../../services/forms/form_validation_service.dart';
import '../../../../services/preferences/currency_service.dart';
import '../../../widgets/forms/app_form_scaffold.dart';
import '../../../widgets/forms/app_form_section.dart';
import '../../../widgets/forms/app_image_picker_field.dart';
import '../../../widgets/forms/app_money_field.dart';
import '../../../widgets/forms/app_responsive_field_row.dart';
import '../../../widgets/forms/app_select_field.dart';
import '../../../widgets/forms/app_text_field.dart';
import '../../../widgets/forms/try_on_compatibility_field.dart';
import '../model/creation.dart';
import '../service/firestore_service.dart';
import '../service/storage_service.dart';

class AddCreationScreen extends StatefulWidget {
  const AddCreationScreen({super.key});

  @override
  State<AddCreationScreen> createState() => _AddCreationScreenState();
}

class _AddCreationScreenState extends State<AddCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _images = <File>[];
  final _proAccessService = ProAccessService();
  final _currencyService = CurrencyService();
  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _tagsController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  String _selectedCategory = 'Robe';
  String _selectedAvailability = 'Disponible sur demande';
  String _currency = CurrencyService.defaultCode;
  String _tryOnPreset = TryOnCompatibilityField.autoPreset;
  AppFormState _formState = const AppFormState();
  int _photoLimit = 5;

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
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await _currencyService.currentUserCurrency();
    if (mounted) setState(() => _currency = currency);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _tagsController.dispose();
    _cityController.dispose();
    _countryController.dispose();
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
        title: 'Nouvelle création',
        subtitle: 'Images, titre, disponibilité. Le reste peut évoluer après.',
        formState: _formState,
        primaryLabel: 'Publier',
        secondaryLabel: 'Brouillon',
        onPrimary: _isSaving ? null : () => _submitCreation(published: true),
        onSecondary: _isSaving ? null : () => _submitCreation(published: false),
        children: [
          AppFormSection(
            title: 'Galerie',
            subtitle: 'La première image devient la couverture.',
            icon: Icons.photo_library_rounded,
            children: [
              AppImagePickerField(
                title: 'Images de la création',
                subtitle: 'Coupe, détail, matière.',
                files: _images,
                maxImages: _photoLimit,
                onAdd: _pickImage,
                onRemove: _removeImageAt,
              ),
            ],
          ),
          AppFormSection(
            title: 'Identité de la création',
            subtitle: 'Titre, catégorie et tags utiles.',
            icon: Icons.label_rounded,
            children: [
              AppTextField(
                controller: _titleController,
                label: 'Titre',
                hint: 'Robe cérémonie moderne, boubou brodé...',
                icon: Icons.title_rounded,
                textInputAction: TextInputAction.next,
                validator:
                    (value) => FormValidationService.requiredText(
                      value,
                      message: 'Ajoutez un titre clair',
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
                hint: 'mariage, wax, moderne, cérémonie...',
                icon: Icons.sell_rounded,
                textInputAction: TextInputAction.next,
              ),
            ],
          ),
          AppFormSection(
            title: 'Prix et disponibilité',
            subtitle: 'Prix indicatif ou portfolio.',
            icon: Icons.payments_rounded,
            children: [
              AppMoneyField(
                controller: _priceController,
                label: 'Prix indicatif',
                hint: 'Ex: 25000',
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
            subtitle: 'Inspiration, matières, occasions.',
            icon: Icons.notes_rounded,
            children: [
              AppTextField(
                controller: _descriptionController,
                label: 'Description détaillée',
                hint: 'Silhouette, détails, style, personnalisation',
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
          AppFormSection(
            title: 'Contexte local',
            subtitle: 'Optionnel. Utile pour les recherches locales.',
            icon: Icons.public_rounded,
            children: [
              AppResponsiveFieldRow(
                children: [
                  AppTextField(
                    controller: _cityController,
                    label: 'Ville',
                    hint: 'Ville',
                    icon: Icons.location_city_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  AppTextField(
                    controller: _countryController,
                    label: 'Pays',
                    hint: 'Pays',
                    icon: Icons.public_rounded,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (image == null) return;
    final access = await _proAccessService.getCurrentAccess();
    final limit = access.limits.photosPerItem;
    if (_photoLimit != limit && mounted) {
      setState(() => _photoLimit = limit);
    }
    if (_images.length >= limit) {
      _showError('Votre plan permet jusqu’à $limit images par création.');
      return;
    }
    setState(() => _images.add(File(image.path)));
  }

  void _removeImageAt(int index) {
    if (index < 0 || index >= _images.length) return;
    setState(() => _images.removeAt(index));
  }

  Future<void> _submitCreation({required bool published}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty && published) {
      _showError('Ajoutez au moins une image avant de publier dans le Salon.');
      return;
    }

    setState(() {
      _formState = AppFormState(
        status: AppFormStatus.saving,
        message:
            published
                ? 'Publication de la création...'
                : 'Enregistrement du brouillon...',
        progress: _images.isEmpty ? null : 0.05,
      );
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Utilisateur non connecté');
      final access = await _proAccessService.getCurrentAccess();
      final creationCount = await _proAccessService.countOwnedCreations(
        user.uid,
      );
      if (creationCount >= access.limits.creationLimit) {
        throw StateError(
          '${access.planLabel} permet de gérer ${access.limits.creationLimit} création(s). Passez à Pro ou Signature pour publier davantage.',
        );
      }
      if (_images.length > access.limits.photosPerItem) {
        throw StateError(
          'Votre plan permet jusqu’à ${access.limits.photosPerItem} images par création.',
        );
      }

      final compressedFiles = <File>[];
      for (var i = 0; i < _images.length; i++) {
        setState(() {
          _formState = AppFormState(
            status: AppFormStatus.saving,
            message: 'Compression des images ${i + 1}/${_images.length}...',
            progress: _images.isEmpty ? null : (i + 0.2) / _images.length,
          );
        });
        compressedFiles.add(await _compressImage(_images[i]));
      }

      final imageUrls =
          compressedFiles.isEmpty
              ? <String>[]
              : await StorageService.uploadImages(
                compressedFiles,
                onProgress: (progress) {
                  if (!mounted) return;
                  setState(() {
                    _formState = AppFormState(
                      status: AppFormStatus.saving,
                      message: 'Upload des images...',
                      progress: progress,
                    );
                  });
                },
              );

      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final status = published ? 'published' : 'draft';
      final tags =
          _tagsController.text
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList();

      final creation = Creation(
        createurId: user.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        images: imageUrls,
        price: price,
        createdAt: DateTime.now(),
      );

      await FirestoreService.addCreation(
        creation,
        extraData: {
          'ownerId': user.uid,
          'sellerId': user.uid,
          'status': status,
          'visibility': published ? 'salon' : 'private',
          'isPublished': published,
          'visibleInSalon': published,
          'availability': _selectedAvailability,
          'currency': _currency,
          ...TryOnCompatibilityField.catalogFields(
            preset: _tryOnPreset,
            title: _titleController.text.trim(),
            category: _selectedCategory,
            subtitle: _descriptionController.text.trim(),
          ),
          'tags': tags,
          'city': _cityController.text.trim(),
          'country': _countryController.text.trim(),
          'coverImage': imageUrls.isEmpty ? '' : imageUrls.first,
          'imageUrl': imageUrls.isEmpty ? '' : imageUrls.first,
        },
      );

      if (!mounted) return;
      setState(() {
        _formState = AppFormState(
          status: AppFormStatus.success,
          message:
              published
                  ? 'Création publiée dans le Salon.'
                  : 'Brouillon enregistré.',
        );
      });
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error submitting creation: $e');
      if (!mounted) return;
      setState(() {
        _formState = AppFormState(
          status: AppFormStatus.error,
          message:
              e is StateError
                  ? e.message
                  : 'Impossible d’enregistrer pour le moment. Vérifiez votre connexion ou réessayez dans quelques instants.',
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
