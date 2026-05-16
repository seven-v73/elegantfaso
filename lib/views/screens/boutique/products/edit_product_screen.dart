import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/boutique/boutique_product.dart';
import '../../../../models/forms/app_form_state.dart';
import '../../../../services/forms/form_validation_service.dart';
import '../../../../services/media/media_asset_service.dart';
import '../../../../services/media/media_upload_service.dart';
import '../../../../services/preferences/currency_service.dart';
import '../../../widgets/forms/app_form_scaffold.dart';
import '../../../widgets/forms/app_form_section.dart';
import '../../../widgets/forms/app_image_picker_field.dart';
import '../../../widgets/forms/app_money_field.dart';
import '../../../widgets/forms/app_select_field.dart';
import '../../../widgets/forms/app_text_field.dart';
import '../../../widgets/forms/try_on_compatibility_field.dart';

class EditProductScreen extends StatefulWidget {
  final BoutiqueProduct product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _mediaUploadService = MediaUploadService();
  final _mediaAssetService = MediaAssetService();
  final _currencyService = CurrencyService();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _descriptionController;

  late String _category;
  late String _currency;
  String _tryOnPreset = TryOnCompatibilityField.autoPreset;
  File? _imageFile;
  String? _imageUrl;
  AppFormState _formState = const AppFormState();

  final List<String> _categories = const [
    'Vêtements',
    'Accessoires',
    'Chaussures',
    'Tissus',
    'Bijoux',
    'Beauté',
    'Autres',
  ];

  bool get _isSaving => _formState.isSaving;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(
      text: widget.product.price.toStringAsFixed(0),
    );
    _stockController = TextEditingController(
      text: widget.product.stock.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    _category =
        _categories.contains(widget.product.category)
            ? widget.product.category
            : _categories.first;
    _currency = CurrencyService.normalize(widget.product.currency);
    _imageUrl = widget.product.imageUrl;
    _loadCurrencyFallback();
  }

  Future<void> _loadCurrencyFallback() async {
    if (_currency != CurrencyService.defaultCode) return;
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
        title: 'Modifier le produit',
        subtitle: 'Publier ou masquer.',
        formState: _formState,
        primaryLabel: 'Mettre à jour',
        secondaryLabel: 'Masquer',
        onPrimary: _isSaving ? null : () => _updateProduct(published: true),
        onSecondary: _isSaving ? null : () => _updateProduct(published: false),
        children: [
          AppFormSection(
            title: 'Photo',
            subtitle: 'Image Salon.',
            icon: Icons.photo_library_rounded,
            children: [
              AppImagePickerField(
                title: 'Image principale',
                subtitle: 'Shopping et fiche.',
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
            subtitle: 'Nom, prix, stock.',
            icon: Icons.shopping_bag_outlined,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Nom du produit',
                hint: 'Nom visible par les clients',
                icon: Icons.sell_rounded,
                textInputAction: TextInputAction.next,
                validator:
                    (value) => FormValidationService.requiredText(
                      value,
                      message: 'Nom requis.',
                      minLength: 3,
                    ),
              ),
              AppSelectField<String>(
                value: _category,
                items: _categories,
                label: 'Catégorie',
                icon: Icons.category_rounded,
                onChanged:
                    (value) => setState(() => _category = value ?? _category),
              ),
              TryOnCompatibilityField(
                value: _tryOnPreset,
                onChanged: (value) => setState(() => _tryOnPreset = value),
              ),
              AppMoneyField(
                controller: _priceController,
                label: 'Prix',
                currencySymbol: CurrencyService.optionFor(_currency).symbol,
                validator: FormValidationService.price,
              ),
              AppTextField(
                controller: _stockController,
                label: 'Stock',
                icon: Icons.inventory_2_rounded,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: FormValidationService.stock,
              ),
            ],
          ),
          AppFormSection(
            title: 'Description',
            subtitle: 'Matière, usage, délai.',
            icon: Icons.notes_rounded,
            children: [
              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Détails, style, taille, matière, délai...',
                icon: Icons.description_rounded,
                minLines: 4,
                maxLines: 7,
                textInputAction: TextInputAction.newline,
                validator:
                    (value) =>
                        FormValidationService.description(value, minLength: 12),
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

  Future<MediaUploadResult?> _uploadImage({required bool published}) async {
    if (_imageFile == null) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Utilisateur non connecté');
    final upload = await _mediaUploadService.uploadImage(
      file: _imageFile!,
      folder: 'products/${user.uid}',
      publicId: 'product_${DateTime.now().millisecondsSinceEpoch}',
    );
    final mediaId = await _mediaAssetService.recordUpload(
      upload: upload,
      ownerId: user.uid,
      ownerRole: 'boutique',
      usage: 'product',
      status: published ? 'public' : 'draft',
      linkedCollection: 'products',
      linkedDocumentId: widget.product.id,
    );
    return upload.copyWithAssetId(mediaId);
  }

  Future<void> _updateProduct({required bool published}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _formState = AppFormState(
        status: AppFormStatus.saving,
        message:
            published
                ? 'Mise à jour du produit...'
                : 'Masquage du produit dans le Salon...',
      );
    });

    try {
      final upload = await _uploadImage(published: published);
      final updatedImageUrl = upload?.optimizedUrl ?? _imageUrl ?? '';
      final status = published ? 'published' : 'hidden';

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .update({
            'name': _nameController.text.trim(),
            'title': _nameController.text.trim(),
            'price': double.parse(_priceController.text.trim()),
            'currency': _currency,
            'stock': int.parse(_stockController.text.trim()),
            'description': _descriptionController.text.trim(),
            'category': _category,
            ...TryOnCompatibilityField.catalogFields(
              preset: _tryOnPreset,
              title: _nameController.text.trim(),
              category: _category,
              subtitle: _descriptionController.text.trim(),
            ),
            'imageUrl': updatedImageUrl,
            'status': status,
            'visibility': published ? 'salon' : 'private',
            'isPublished': published,
            'visibleInSalon': published,
            if (upload != null) 'thumbnailUrl': upload.thumbnailUrl,
            if (upload != null) 'media.cover': upload.toMap(),
            if (upload != null) 'media.coverUrl': upload.optimizedUrl,
            if (upload != null)
              'media.gallery': FieldValue.arrayUnion([upload.toMap()]),
            if (upload != null)
              'media.cloudinaryPublicIds': FieldValue.arrayUnion([
                upload.publicId,
              ]),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      setState(() {
        _formState = AppFormState(
          status: AppFormStatus.success,
          message:
              published ? 'Produit mis à jour.' : 'Produit masqué du Salon.',
        );
      });
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _formState = const AppFormState(
          status: AppFormStatus.error,
          message: 'Mise à jour impossible. Réessayez.',
        );
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
