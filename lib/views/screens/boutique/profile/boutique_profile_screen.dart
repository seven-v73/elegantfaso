import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../services/account/account_closure_service.dart';
import '../../../../services/location/salon_place_publisher_service.dart';
import '../../../../services/media/media_asset_service.dart';
import '../../../../services/media/media_upload_service.dart';
import '../../../../services/preferences/currency_service.dart';
import '../../../widgets/account/account_closure_sheet.dart';
import '../../../widgets/forms/app_form_section.dart';
import '../../../widgets/forms/app_sticky_form_bar.dart';
import '../../../widgets/forms/app_text_field.dart';
import '../../../widgets/forms/payment_methods_editor.dart';
import '../../../widgets/preferences/currency_preference_tile.dart';
import '../widgets/boutique_status_chip.dart';

class BoutiqueProfileScreen extends StatefulWidget {
  const BoutiqueProfileScreen({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<BoutiqueProfileScreen> createState() => _BoutiqueProfileScreenState();
}

class _BoutiqueProfileScreenState extends State<BoutiqueProfileScreen>
    with AutomaticKeepAliveClientMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MediaUploadService _mediaUploadService = MediaUploadService();
  final MediaAssetService _mediaAssetService = MediaAssetService();
  final SalonPlacePublisherService _placePublisherService =
      SalonPlacePublisherService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _specialityController = TextEditingController();
  final Map<String, TextEditingController> _paymentControllers = {};
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  File? _imageFile;
  String? _photoUrl;
  double? _latitude;
  double? _longitude;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLocating = false;
  bool _isEditing = false;
  String _currency = CurrencyService.defaultCode;
  List<String> _selectedSpecialities = [];

  bool get _hasWithdrawalMethod {
    return _paymentControllers.values.any(
      (controller) => controller.text.trim().isNotEmpty,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};
      final shopProfile = Map<String, dynamic>.from(
        data['shopProfile'] ?? const {},
      );
      _nameController.text =
          data['boutiqueName']?.toString() ??
          shopProfile['name']?.toString() ??
          '';
      _emailController.text = data['email']?.toString() ?? user.email ?? '';
      _phoneController.text = data['phone']?.toString() ?? '';
      _addressController.text =
          data['address']?.toString() ??
          data['boutiqueAddress']?.toString() ??
          shopProfile['address']?.toString() ??
          '';
      _cityController.text =
          data['city']?.toString() ??
          data['ville']?.toString() ??
          shopProfile['city']?.toString() ??
          '';
      _descriptionController.text =
          data['description']?.toString() ??
          shopProfile['description']?.toString() ??
          '';
      _latitude = _doubleFrom(
        data['latitude'] ??
            (data['location'] is Map ? data['location']['latitude'] : null),
      );
      _longitude = _doubleFrom(
        data['longitude'] ??
            (data['location'] is Map ? data['location']['longitude'] : null),
      );
      _photoUrl =
          data['boutiquePhotoUrl']?.toString() ??
          data['boutiqueLogoUrl']?.toString() ??
          shopProfile['logoUrl']?.toString() ??
          data['photoUrl']?.toString() ??
          data['photoURL']?.toString();
      _currency = CurrencyService.currencyFromUserData(data);
      _selectedSpecialities = List<String>.from(data['specialities'] ?? []);
      final payments = Map<String, dynamic>.from(data['paymentMethods'] ?? {});
      _setPaymentControllers(payments);
    } catch (_) {
      _showSnackbar('Impossible de charger le profil.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (_) {
      _showSnackbar('Impossible de choisir cette image.', isError: true);
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      String? newPhotoUrl = _photoUrl;
      MediaUploadResult? uploadedLogo;
      if (_imageFile != null) {
        uploadedLogo = await _mediaUploadService.uploadImage(
          file: _imageFile!,
          folder: 'shops/${user.uid}',
          publicId: 'logo_${DateTime.now().millisecondsSinceEpoch}',
        );
        final mediaId = await _mediaAssetService.recordUpload(
          upload: uploadedLogo,
          ownerId: user.uid,
          ownerRole: 'boutique',
          usage: 'profile_logo',
          status: 'public',
          linkedCollection: 'users',
          linkedDocumentId: user.uid,
        );
        uploadedLogo = uploadedLogo.copyWithAssetId(mediaId);
        newPhotoUrl = MediaUploadService.avatarUrl(uploadedLogo.url);
      }

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final address = _addressController.text.trim();
      final city = _cityController.text.trim();
      final description = _descriptionController.text.trim();
      final hasLocation = _latitude != null && _longitude != null;

      await _firestore.collection('users').doc(user.uid).set({
        'boutiqueName': name,
        'shopProfile.name': name,
        'phone': phone,
        'address': address,
        'boutiqueAddress': address,
        'city': city,
        'ville': city,
        'description': description,
        'shopProfile.address': address,
        'shopProfile.city': city,
        'shopProfile.description': description,
        'boutiquePhotoUrl': newPhotoUrl,
        'boutiqueLogoUrl': newPhotoUrl,
        'shopProfile.logoUrl': newPhotoUrl,
        if (hasLocation) ...{
          'latitude': _latitude,
          'longitude': _longitude,
          'location': {'latitude': _latitude, 'longitude': _longitude},
          'shopProfile.location': {
            'latitude': _latitude,
            'longitude': _longitude,
          },
        },
        if (uploadedLogo != null) 'media.shopLogo': uploadedLogo.toMap(),
        'specialities': _selectedSpecialities,
        'isPublic': true,
        'publicProfile': true,
        'publicRole': 'boutique',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _placePublisherService.publishCurrentUserPlaces();

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _photoUrl = newPhotoUrl;
        _imageFile = null;
      });
      _showSnackbar('Profil boutique mis à jour.');
    } catch (_) {
      if (!mounted) return;
      _showSnackbar('Impossible de sauvegarder le profil.', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _savePaymentSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      final paymentMethods = _paymentMethodsMap();
      final primary =
          paymentMethods.entries.isEmpty ? null : paymentMethods.entries.first;
      await _firestore.collection('users').doc(user.uid).set({
        'paymentMethod': primary?.key ?? '',
        'paymentNumber': primary?.value ?? '',
        'paymentMethods': paymentMethods,
        'shopProfile.paymentMethods': paymentMethods,
        'currency': _currency,
        'preferredCurrency': _currency,
        'shopProfile.currency': _currency,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackbar('Paiements mis à jour.');
    } catch (_) {
      if (!mounted) return;
      _showSnackbar('Impossible de sauvegarder les paiements.', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _imageFile = null;
      _specialityController.clear();
    });
    _loadProfile();
  }

  void _addSpeciality() {
    final text = _specialityController.text.trim();
    if (text.isEmpty || _selectedSpecialities.contains(text)) return;
    setState(() {
      _selectedSpecialities.add(text);
      _specialityController.clear();
    });
  }

  void _removeSpeciality(String speciality) {
    setState(() => _selectedSpecialities.remove(speciality));
  }

  double? _doubleFrom(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _setPaymentControllers(Map<String, dynamic> methods) {
    for (final controller in _paymentControllers.values) {
      controller.dispose();
    }
    _paymentControllers.clear();
    for (final entry in methods.entries) {
      final label = entry.key.trim();
      final value = entry.value?.toString().trim() ?? '';
      if (label.isNotEmpty && value.isNotEmpty) {
        _paymentControllers[label] = TextEditingController(text: value);
      }
    }
  }

  Map<String, String> _paymentMethodsMap() {
    final methods = <String, String>{};
    for (final entry in _paymentControllers.entries) {
      final value = entry.value.text.trim();
      if (entry.key.trim().isNotEmpty && value.isNotEmpty) {
        methods[entry.key.trim()] = value;
      }
    }
    return methods;
  }

  Future<void> _useCurrentLocation() async {
    if (!_isEditing) setState(() => _isEditing = true);
    setState(() => _isLocating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await Geolocator.openLocationSettings();
        throw StateError(
          'Activez la localisation du téléphone puis réessayez.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Autorisez la localisation pour placer la boutique.');
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) {
        throw StateError('Position indisponible. Réessayez dans un instant.');
      }

      if (!mounted) return;
      setState(() {
        _latitude = position!.latitude;
        _longitude = position.longitude;
        if (_addressController.text.trim().isEmpty) {
          _addressController.text =
              'Position du téléphone (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        }
      });
      _showSnackbar('Position ajoutée. Enregistrez pour publier sur la carte.');
    } catch (error) {
      if (!mounted) return;
      _showSnackbar(
        error.toString().replaceFirst('Bad state: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Voulez-vous quitter votre espace boutique ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Déconnexion'),
              ),
            ],
          ),
    );
    if (shouldLogout != true) return;
    try {
      await _auth.signOut();
      widget.onLogout?.call();
    } catch (_) {
      if (!mounted) return;
      _showSnackbar('Impossible de se déconnecter.', isError: true);
    }
  }

  void _openPaymentSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => FractionallySizedBox(
                  heightFactor: 0.72,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: Scaffold(
                      backgroundColor: ModernColors.canvas,
                      bottomNavigationBar: AppStickyFormBar(
                        primaryLabel: 'Enregistrer',
                        onPrimary: _isSaving ? null : _savePaymentSettings,
                        secondaryLabel: 'Annuler',
                        onSecondary: () => Navigator.pop(context),
                        isLoading: _isSaving,
                      ),
                      body: SafeArea(
                        top: false,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 116),
                          children: [
                            Center(
                              child: Container(
                                width: 44,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: ModernColors.line,
                                  borderRadius: BorderRadius.circular(99),
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
                                    color: ModernColors.shop.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.payments_rounded,
                                    color: ModernColors.shop,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Paiements',
                                    style: TextStyle(
                                      color: ModernColors.ink,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            CurrencyPreferenceTile(
                              initialCurrency: _currency,
                              onChanged:
                                  (value) => setModalState(
                                    () => setState(() => _currency = value),
                                  ),
                            ),
                            const SizedBox(height: 16),
                            PaymentMethodsEditor(
                              enabled: true,
                              methods: _paymentMethodsMap(),
                              onChanged:
                                  (methods) => setModalState(
                                    () => setState(
                                      () => _setPaymentControllers(methods),
                                    ),
                                  ),
                              title: 'Retraits boutique',
                              subtitle: 'Canaux de règlement',
                              emptyLabel: 'Aucun moyen de retrait',
                              warningLabel:
                                  'Ajoutez un numéro pour recevoir vos retraits.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  Future<void> _requestShopClosure() async {
    final submitted = await showAccountClosureSheet(
      context,
      target: AccountClosureTarget.boutique,
    );
    if (!mounted || submitted != true) return;
    _showSnackbar('Espace boutique fermé. Votre compte client reste actif.');
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      body:
          _isLoading
              ? const _ProfileLoading()
              : Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _loadProfile,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 108),
                      children: [
                        _ProfileHeader(
                          name: _nameController.text,
                          email: _emailController.text,
                          photoUrl: _photoUrl,
                          imageFile: _imageFile,
                          isEditing: _isEditing,
                          onPickImage: _pickImage,
                          onEditToggle:
                              () => setState(() => _isEditing = !_isEditing),
                        ),
                        const SizedBox(height: 16),
                        _ProfileReadinessCard(
                          hasName: _nameController.text.trim().isNotEmpty,
                          hasImage:
                              _imageFile != null ||
                              (_photoUrl?.trim().isNotEmpty ?? false),
                          hasLocation: _latitude != null && _longitude != null,
                          hasDescription:
                              _descriptionController.text.trim().isNotEmpty,
                        ),
                        const SizedBox(height: 16),
                        _ProfileForm(
                          enabled: _isEditing,
                          isLocating: _isLocating,
                          hasLocation: _latitude != null && _longitude != null,
                          nameController: _nameController,
                          emailController: _emailController,
                          phoneController: _phoneController,
                          addressController: _addressController,
                          cityController: _cityController,
                          descriptionController: _descriptionController,
                          nameFocusNode: _nameFocusNode,
                          phoneFocusNode: _phoneFocusNode,
                          addressFocusNode: _addressFocusNode,
                          cityFocusNode: _cityFocusNode,
                          descriptionFocusNode: _descriptionFocusNode,
                          onUseCurrentLocation: _useCurrentLocation,
                        ),
                        const SizedBox(height: 16),
                        _SpecialitiesCard(
                          enabled: _isEditing,
                          controller: _specialityController,
                          specialities: _selectedSpecialities,
                          onAdd: _addSpeciality,
                          onRemove: _removeSpeciality,
                        ),
                        const SizedBox(height: 16),
                        _PaymentSummaryCard(
                          hasAnyMethod: _hasWithdrawalMethod,
                          methodsCount: _paymentMethodsMap().length,
                          currency: _currency,
                          onTap: _openPaymentSettings,
                        ),
                        const SizedBox(height: 16),
                        AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: ModernColors.rose.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.pause_circle_outline_rounded,
                                    color: ModernColors.rose,
                                  ),
                                ),
                                title: const Text(
                                  'Fermer l’espace boutique',
                                  style: TextStyle(
                                    color: ModernColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                subtitle: const Text('Demande admin'),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                ),
                                onTap: _requestShopClosure,
                              ),
                              const Divider(height: 18),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: ModernColors.rose.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    color: ModernColors.rose,
                                  ),
                                ),
                                title: const Text(
                                  'Déconnexion',
                                  style: TextStyle(
                                    color: ModernColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                subtitle: const Text('Quitter la session'),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                ),
                                onTap: _handleLogout,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isEditing)
                    _ProfileSaveBar(
                      onCancel: _cancelEditing,
                      onSave: _saveProfile,
                      isSaving: _isSaving,
                    ),
                  if (_isSaving)
                    Container(
                      color: Colors.black.withValues(alpha: 0.08),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? ModernColors.danger : ModernColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _specialityController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    _cityFocusNode.dispose();
    _descriptionFocusNode.dispose();
    for (final controller in _paymentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.imageFile,
    required this.isEditing,
    required this.onPickImage,
    required this.onEditToggle,
  });

  final String name;
  final String email;
  final String? photoUrl;
  final File? imageFile;
  final bool isEditing;
  final VoidCallback onPickImage;
  final VoidCallback onEditToggle;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imageFile != null || (photoUrl != null && photoUrl!.isNotEmpty);
    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Row(
        children: [
          GestureDetector(
            onTap: isEditing ? onPickImage : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: ModernColors.canvas,
                  backgroundImage:
                      imageFile != null
                          ? FileImage(imageFile!)
                          : hasImage
                          ? NetworkImage(photoUrl!) as ImageProvider
                          : null,
                  child:
                      hasImage
                          ? null
                          : const Icon(
                            Icons.storefront_rounded,
                            color: ModernColors.primary,
                            size: 30,
                          ),
                ),
                if (isEditing)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: ModernColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Ma boutique' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isEmpty ? 'Profil public du Salon' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ModernColors.inkSoft),
                ),
                const SizedBox(height: 8),
                const BoutiqueStatusChip(
                  label: 'Boutique Salon',
                  color: ModernColors.shop,
                  icon: Icons.verified_rounded,
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onEditToggle,
            icon: Icon(isEditing ? Icons.close_rounded : Icons.edit_rounded),
          ),
        ],
      ),
    );
  }
}

class _ProfileReadinessCard extends StatelessWidget {
  const _ProfileReadinessCard({
    required this.hasName,
    required this.hasImage,
    required this.hasLocation,
    required this.hasDescription,
  });

  final bool hasName;
  final bool hasImage;
  final bool hasLocation;
  final bool hasDescription;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Nom public', hasName),
      ('Photo de vitrine', hasImage),
      ('Position carte', hasLocation),
      ('Description', hasDescription),
    ];
    final done = items.where((item) => item.$2).length;

    return AppCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ModernColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: ModernColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visibilité Salon',
                      style: TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$done/${items.length} éléments prêts pour une vitrine complète',
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                items
                    .map(
                      (item) =>
                          _ReadinessChip(label: item.$1, completed: item.$2),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

class _ReadinessChip extends StatelessWidget {
  const _ReadinessChip({required this.label, required this.completed});

  final String label;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed ? ModernColors.primary : ModernColors.inkSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: completed ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.enabled,
    required this.isLocating,
    required this.hasLocation,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.cityController,
    required this.descriptionController,
    required this.nameFocusNode,
    required this.phoneFocusNode,
    required this.addressFocusNode,
    required this.cityFocusNode,
    required this.descriptionFocusNode,
    required this.onUseCurrentLocation,
  });

  final bool enabled;
  final bool isLocating;
  final bool hasLocation;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController descriptionController;
  final FocusNode nameFocusNode;
  final FocusNode phoneFocusNode;
  final FocusNode addressFocusNode;
  final FocusNode cityFocusNode;
  final FocusNode descriptionFocusNode;
  final VoidCallback onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    return AppFormSection(
      title: 'Informations publiques',
      subtitle: 'Salon et carte.',
      icon: Icons.storefront_rounded,
      children: [
        AppTextField(
          controller: nameController,
          focusNode: nameFocusNode,
          label: 'Nom de la boutique',
          icon: Icons.storefront_outlined,
          enabled: enabled,
          textInputAction: TextInputAction.next,
        ),
        AppTextField(
          controller: emailController,
          label: 'Email',
          icon: Icons.mail_outline_rounded,
          enabled: false,
          keyboardType: TextInputType.emailAddress,
        ),
        AppTextField(
          controller: phoneController,
          focusNode: phoneFocusNode,
          label: 'Téléphone',
          hint: 'Numéro WhatsApp ou appel',
          icon: Icons.phone_outlined,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        AppTextField(
          controller: addressController,
          focusNode: addressFocusNode,
          label: 'Adresse',
          hint: 'Rue, quartier, repère...',
          icon: Icons.location_on_outlined,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.sentences,
        ),
        AppTextField(
          controller: cityController,
          focusNode: cityFocusNode,
          label: 'Ville',
          hint: 'Ex: Abidjan, Paris, Ouagadougou...',
          icon: Icons.location_city_outlined,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
        ),
        OutlinedButton.icon(
          onPressed: !enabled || isLocating ? null : onUseCurrentLocation,
          icon:
              isLocating
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Icon(
                    hasLocation
                        ? Icons.my_location_rounded
                        : Icons.near_me_outlined,
                  ),
          label: Text(
            isLocating
                ? 'Localisation...'
                : hasLocation
                ? 'Position ajoutée'
                : 'Utiliser ma position',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                hasLocation ? ModernColors.primary : ModernColors.ink,
            side: BorderSide(
              color: hasLocation ? ModernColors.primary : ModernColors.line,
            ),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        AppTextField(
          controller: descriptionController,
          focusNode: descriptionFocusNode,
          label: 'Description',
          hint: 'Style, services, délais.',
          icon: Icons.notes_rounded,
          enabled: enabled,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}

class _SpecialitiesCard extends StatelessWidget {
  const _SpecialitiesCard({
    required this.enabled,
    required this.controller,
    required this.specialities,
    required this.onAdd,
    required this.onRemove,
  });

  final bool enabled;
  final TextEditingController controller;
  final List<String> specialities;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            padding: EdgeInsets.zero,
            title: 'Spécialités',
            subtitle: 'Mots-clés',
          ),
          if (enabled) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Ex: prêt-à-porter, pagne, robes...',
                      filled: true,
                      fillColor: ModernColors.canvas,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => onAdd(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (specialities.isEmpty)
            const Text(
              'Aucune spécialité ajoutée.',
              style: TextStyle(color: ModernColors.inkSoft),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  specialities.map((speciality) {
                    return InputChip(
                      label: Text(speciality),
                      onDeleted: enabled ? () => onRemove(speciality) : null,
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({
    required this.hasAnyMethod,
    required this.methodsCount,
    required this.currency,
    required this.onTap,
  });

  final bool hasAnyMethod;
  final int methodsCount;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currencyOption = CurrencyService.optionFor(currency);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  hasAnyMethod
                      ? ModernColors.success.withValues(alpha: 0.1)
                      : ModernColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasAnyMethod
                  ? Icons.account_balance_wallet_rounded
                  : Icons.add_card_rounded,
              color: hasAnyMethod ? ModernColors.success : ModernColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paiements',
                  style: TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasAnyMethod
                      ? '$methodsCount canal${methodsCount > 1 ? 's' : ''} · ${currencyOption.symbol} ${currencyOption.code}'
                      : 'À configurer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: ModernColors.inkSoft),
        ],
      ),
    );
  }
}

class _ProfileSaveBar extends StatelessWidget {
  const _ProfileSaveBar({
    required this.onCancel,
    required this.onSave,
    required this.isSaving,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AppStickyFormBar(
        primaryLabel: 'Enregistrer',
        onPrimary: onSave,
        secondaryLabel: 'Annuler',
        onSecondary: onCancel,
        isLoading: isSaving,
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        5,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}
