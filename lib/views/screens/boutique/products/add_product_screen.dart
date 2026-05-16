import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/forms/app_form_state.dart';
import '../../../../services/commerce/pro_access_service.dart';
import '../../../../services/forms/form_validation_service.dart';
import '../../../../services/media/media_asset_service.dart';
import '../../../../services/media/media_upload_service.dart';
import '../../../../services/preferences/currency_service.dart';
import '../../../widgets/forms/app_form_scaffold.dart';
import '../../../widgets/forms/app_form_section.dart';
import '../../../widgets/forms/app_image_picker_field.dart';
import '../../../widgets/forms/app_money_field.dart';
import '../../../widgets/forms/app_responsive_field_row.dart';
import '../../../widgets/forms/app_select_field.dart';
import '../../../widgets/forms/app_text_field.dart';
import '../../../widgets/forms/try_on_compatibility_field.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _firestore = FirebaseFirestore.instance;
  final _mediaUploadService = MediaUploadService();
  final _mediaAssetService = MediaAssetService();
  final _proAccessService = ProAccessService();
  final _currencyService = CurrencyService();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  File? _imageFile;
  String? _imageUrl;
  String _selectedCategory = 'Vêtements';
  String _deliveryMode = 'Livraison ou retrait';
  String _currency = CurrencyService.defaultCode;
  String _tryOnPreset = TryOnCompatibilityField.autoPreset;
  AppFormState _formState = const AppFormState();

  final List<String> _categories = const [
    'Vêtements',
    'Accessoires',
    'Chaussures',
    'Tissus',
    'Bijoux',
    'Beauté',
  ];

  final List<String> _deliveryModes = const [
    'Livraison ou retrait',
    'Livraison uniquement',
    'Retrait uniquement',
    'Sur mesure',
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
        title: 'Ajouter un produit',
        subtitle: 'Photo, prix, stock. Le reste peut évoluer après.',
        formState: _formState,
        primaryLabel: 'Publier',
        secondaryLabel: 'Brouillon',
        onPrimary: _isSaving ? null : () => _saveProduct(published: true),
        onSecondary: _isSaving ? null : () => _saveProduct(published: false),
        children: [
          AppFormSection(
            title: 'Photos',
            subtitle: 'Image claire pour le Salon.',
            icon: Icons.photo_library_rounded,
            children: [
              AppImagePickerField(
                title: 'Photo principale',
                subtitle: 'Format vertical.',
                files: _imageFile == null ? const [] : [_imageFile!],
                existingUrls: _imageUrl == null ? const [] : [_imageUrl!],
                maxImages: 1,
                onAdd: _pickImage,
                onRemove:
                    (_) => setState(() {
                      _imageFile = null;
                      _imageUrl = null;
                    }),
              ),
            ],
          ),
          AppFormSection(
            title: 'Essentiel',
            subtitle: 'Nom, catégorie, prix et stock.',
            icon: Icons.shopping_bag_outlined,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Nom du produit',
                hint: 'Robe fluide cérémonie, sandales cuir...',
                icon: Icons.sell_rounded,
                textInputAction: TextInputAction.next,
                validator:
                    (value) => FormValidationService.requiredText(
                      value,
                      message: 'Ajoute un nom de produit',
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
              AppMoneyField(
                controller: _priceController,
                label: 'Prix',
                hint: 'Ex: 15000',
                currencySymbol: CurrencyService.optionFor(_currency).symbol,
                validator: FormValidationService.price,
              ),
              AppTextField(
                controller: _stockController,
                label: 'Stock',
                hint: 'Quantité disponible',
                icon: Icons.inventory_2_rounded,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: FormValidationService.stock,
              ),
            ],
          ),
          AppFormSection(
            title: 'Détails',
            subtitle: 'Ce qui aide à décider.',
            icon: Icons.notes_rounded,
            children: [
              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Matière, coupe, occasion, entretien',
                icon: Icons.description_rounded,
                minLines: 4,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                validator:
                    (value) =>
                        FormValidationService.description(value, minLength: 12),
              ),
              AppSelectField<String>(
                value: _deliveryMode,
                items: _deliveryModes,
                label: 'Livraison / retrait',
                icon: Icons.local_shipping_rounded,
                onChanged:
                    (value) =>
                        setState(() => _deliveryMode = value ?? _deliveryMode),
              ),
            ],
          ),
          AppFormSection(
            title: 'Localisation',
            subtitle: 'Optionnel.',
            icon: Icons.place_rounded,
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
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1400,
      imageQuality: 84,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProduct({required bool published}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _formState = AppFormState(
        status: AppFormStatus.saving,
        message:
            published ? 'Publication...' : 'Enregistrement du brouillon...',
      );
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Utilisateur non connecté');
      final access = await _proAccessService.getCurrentAccess();
      final productCount = await _proAccessService.countOwnedProducts(user.uid);
      if (productCount >= access.limits.productLimit) {
        throw StateError('Limite ${access.planLabel} atteinte.');
      }

      MediaUploadResult? uploadedImage;
      final productRef = _firestore.collection('products').doc();
      if (_imageFile != null) {
        setState(() {
          _formState = const AppFormState(
            status: AppFormStatus.saving,
            message: 'Upload photo...',
            progress: 0.45,
          );
        });
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        uploadedImage = await _mediaUploadService.uploadImage(
          file: _imageFile!,
          folder: 'products/${user.uid}',
          publicId: 'product_$timestamp',
        );
        final mediaId = await _mediaAssetService.recordUpload(
          upload: uploadedImage,
          ownerId: user.uid,
          ownerRole: 'boutique',
          usage: 'product',
          status: published ? 'public' : 'draft',
          linkedCollection: 'products',
          linkedDocumentId: productRef.id,
        );
        uploadedImage = uploadedImage.copyWithAssetId(mediaId);
        _imageUrl = uploadedImage.optimizedUrl;
      }

      final price = double.parse(_priceController.text.trim());
      final stock = int.parse(_stockController.text.trim());
      final status = published ? 'published' : 'draft';

      await productRef.set({
        'name': _nameController.text.trim(),
        'title': _nameController.text.trim(),
        'category': _selectedCategory,
        'price': price,
        'currency': _currency,
        'description': _descriptionController.text.trim(),
        'stock': stock,
        'boutiqueId': user.uid,
        'sellerId': user.uid,
        'ownerId': user.uid,
        'deliveryMode': _deliveryMode,
        ...TryOnCompatibilityField.catalogFields(
          preset: _tryOnPreset,
          title: _nameController.text.trim(),
          category: _selectedCategory,
          subtitle: _descriptionController.text.trim(),
        ),
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
        'imageUrl': _imageUrl ?? '',
        'status': status,
        'visibility': published ? 'salon' : 'private',
        'isPublished': published,
        'visibleInSalon': published,
        if (uploadedImage != null) 'thumbnailUrl': uploadedImage.thumbnailUrl,
        'media': {
          if (uploadedImage != null) 'cover': uploadedImage.toMap(),
          'coverUrl': uploadedImage?.optimizedUrl ?? _imageUrl ?? '',
          'imageUrls': _imageUrl == null ? <String>[] : [_imageUrl],
          if (uploadedImage != null)
            'cloudinaryPublicIds': [uploadedImage.publicId],
          if (uploadedImage != null) 'gallery': [uploadedImage.toMap()],
        },
        if (uploadedImage != null) 'imageUrls': [uploadedImage.optimizedUrl],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _formState = AppFormState(
          status: AppFormStatus.success,
          message: published ? 'Produit publié.' : 'Brouillon enregistré.',
        );
      });
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _formState = AppFormState(
          status: AppFormStatus.error,
          message:
              e is StateError
                  ? e.message
                  : 'Enregistrement impossible. Réessayez.',
        );
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }
}
