import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/account_roles.dart';
import '../../../design/app_icons.dart';
import '../../../services/media/media_asset_service.dart';
import '../../../services/media/media_upload_service.dart';
import '../../widgets/forms/app_text_field.dart';

class RoleOnboardingScreen extends StatefulWidget {
  final String role;

  const RoleOnboardingScreen({super.key, required this.role});

  @override
  State<RoleOnboardingScreen> createState() => _RoleOnboardingScreenState();
}

class _RoleOnboardingScreenState extends State<RoleOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roleService = AccountRoleService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();
  final _mediaUploadService = MediaUploadService();
  final _mediaAssetService = MediaAssetService();
  final _displayNameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _shopDescriptionController = TextEditingController();
  File? _imageFile;
  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;
  bool _isLocating = false;

  bool get _isShop => widget.role == AccountRoles.boutique;
  bool get _isCreator => widget.role == AccountRoles.createur;

  static const _primary = Color(0xFF0F766E);
  static const _violet = Color(0xFF7C3AED);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _surface = Colors.white;
  static const _bg = Color(0xFFF6F7F9);
  static const _border = Color(0xFFE5E7EB);

  @override
  void dispose() {
    _displayNameController.dispose();
    _specialtyController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _imageUrlController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _shopDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final imageUrl = await _uploadProfileImageIfNeeded();
      final profileData =
          _isShop
              ? _buildShopPayload(imageUrl: imageUrl)
              : _buildCreatorPayload(imageUrl: imageUrl);
      await _roleService.grantRole(widget.role, profileData: profileData);
      await _upsertSalonPlace(imageUrl: imageUrl);

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        _isShop ? '/shop-dashboard' : '/creator-dashboard',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Activation impossible: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Map<String, dynamic> _buildCreatorPayload({required String imageUrl}) {
    final photoUrl = imageUrl.trim();
    final creatorName = _displayNameController.text.trim();
    final location = _locationController.text.trim();
    return {
      'creatorName': creatorName,
      'specialty': _specialtyController.text.trim(),
      'location': location,
      'bio': _bioController.text.trim(),
      'isPublic': true,
      'publicProfile': true,
      'publicRole': 'createur',
      if (_latitude != null) 'latitude': _latitude,
      if (_longitude != null) 'longitude': _longitude,
      if (_latitude != null && _longitude != null)
        'geo': {'latitude': _latitude, 'longitude': _longitude},
      if (photoUrl.isNotEmpty) 'creatorPhotoUrl': photoUrl,
      'creatorProfile': {
        'status': 'active',
        'name': creatorName,
        'specialty': _specialtyController.text.trim(),
        'location': location,
        'bio': _bioController.text.trim(),
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
        if (photoUrl.isNotEmpty) 'photoUrl': photoUrl,
      },
    };
  }

  Map<String, dynamic> _buildShopPayload({required String imageUrl}) {
    final logoUrl = imageUrl.trim();
    final boutiqueName = _shopNameController.text.trim();
    final address = _shopAddressController.text.trim();
    return {
      'boutiqueName': boutiqueName,
      'boutiqueAddress': address,
      'boutiqueDescription': _shopDescriptionController.text.trim(),
      'specialty': _specialtyController.text.trim(),
      'location': address,
      'isPublic': true,
      'publicProfile': true,
      'publicRole': 'boutique',
      if (_latitude != null) 'latitude': _latitude,
      if (_longitude != null) 'longitude': _longitude,
      if (_latitude != null && _longitude != null)
        'geo': {'latitude': _latitude, 'longitude': _longitude},
      if (logoUrl.isNotEmpty) 'boutiquePhotoUrl': logoUrl,
      if (logoUrl.isNotEmpty) 'boutiqueLogoUrl': logoUrl,
      'shopProfile': {
        'status': 'active',
        'name': boutiqueName,
        'address': address,
        'description': _shopDescriptionController.text.trim(),
        'category': _specialtyController.text.trim(),
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
        if (logoUrl.isNotEmpty) 'logoUrl': logoUrl,
      },
    };
  }

  Future<String> _uploadProfileImageIfNeeded() async {
    final manualUrl = _imageUrlController.text.trim();
    final file = _imageFile;
    if (file == null) return manualUrl;

    final user = _auth.currentUser;
    if (user == null) throw StateError('Utilisateur non connecté');

    final role = _isShop ? 'boutique' : 'createur';
    final upload = await _mediaUploadService.uploadImage(
      file: file,
      folder: '$role/${user.uid}',
      publicId: 'profile_${DateTime.now().millisecondsSinceEpoch}',
    );
    final mediaId = await _mediaAssetService.recordUpload(
      upload: upload,
      ownerId: user.uid,
      ownerRole: role,
      usage: _isShop ? 'shop_logo' : 'creator_profile_photo',
      status: 'public',
      linkedCollection: 'users',
      linkedDocumentId: user.uid,
    );
    final media = upload.copyWithAssetId(mediaId);
    return _isShop
        ? media.optimizedUrl
        : MediaUploadService.avatarUrl(media.url);
  }

  Future<void> _upsertSalonPlace({required String imageUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final name =
        _isShop
            ? _shopNameController.text.trim()
            : _displayNameController.text.trim();
    final location =
        _isShop
            ? _shopAddressController.text.trim()
            : _locationController.text.trim();
    final specialty = _specialtyController.text.trim();
    final now = FieldValue.serverTimestamp();

    await _firestore
        .collection('salon_places')
        .doc('${user.uid}_${widget.role}')
        .set({
          'ownerId': user.uid,
          'userId': user.uid,
          'type': _isShop ? 'boutique' : 'createur',
          'publicRole': _isShop ? 'boutique' : 'createur',
          'name': name,
          'subtitle': specialty,
          'speciality': specialty,
          'category': specialty,
          'imageUrl': imageUrl,
          'city': location,
          'country': '',
          'address': location,
          'tags': [specialty, _isShop ? 'boutique' : 'createur'],
          'isPublic': true,
          'verified': false,
          'openNow': false,
          if (_latitude != null) 'latitude': _latitude,
          if (_longitude != null) 'longitude': _longitude,
          if (_latitude != null && _longitude != null)
            'location': {'latitude': _latitude, 'longitude': _longitude},
          'updatedAt': now,
          'createdAt': now,
        }, SetOptions(merge: true));
  }

  Future<void> _chooseImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 86,
        maxWidth: 1400,
      );
      if (picked == null) return;
      setState(() {
        _imageFile = File(picked.path);
        _imageUrlController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de choisir cette image.')),
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw StateError('Activez la localisation du téléphone.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Autorisez la localisation pour continuer.');
      }

      final location = await _resolveCurrentPosition();
      if (location == null) {
        throw StateError(
          'Position indisponible. Vérifiez la localisation du téléphone puis réessayez.',
        );
      }
      _applyCoordinates(
        location.latitude,
        location.longitude,
        labelPrefix: location.labelPrefix,
        cityLabel: location.cityLabel,
      );
    } catch (error) {
      if (!mounted) return;
      final message =
          error is TimeoutException
              ? 'Localisation trop lente. Réessayez ou renseignez votre ville.'
              : error.toString().replaceFirst('Bad state: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<_ResolvedCoordinates?> _resolveCurrentPosition() async {
    Position? lastKnown;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (enabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          lastKnown = await Geolocator.getLastKnownPosition();

          final fast = await _tryPhonePosition(
            accuracy: LocationAccuracy.low,
            timeout: const Duration(seconds: 10),
          );
          if (fast != null) return _fromPosition(fast, 'Position actuelle');

          final streamPosition = await _tryPositionStream();
          if (streamPosition != null) {
            return _fromPosition(streamPosition, 'Position actuelle');
          }

          final precise = await _tryPhonePosition(
            accuracy: LocationAccuracy.medium,
            timeout: const Duration(seconds: 18),
          );
          if (precise != null) {
            return _fromPosition(precise, 'Position actuelle');
          }
        }
      } else {
        unawaited(Geolocator.openLocationSettings());
      }
    } catch (_) {
      // On continue vers les fallbacks pour garder le bouton vraiment direct.
    }

    if (lastKnown != null) {
      return _fromPosition(lastKnown, 'Dernière position connue');
    }
    return _resolveNetworkApproximatePosition();
  }

  Future<Position?> _tryPhonePosition({
    required LocationAccuracy accuracy,
    required Duration timeout,
  }) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Position?> _tryPositionStream() async {
    try {
      return await Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 0,
        ),
      ).first.timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }

  Future<_ResolvedCoordinates?> _resolveNetworkApproximatePosition() async {
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final lat = _doubleFrom(data['latitude'] ?? data['lat']);
      final lng = _doubleFrom(data['longitude'] ?? data['lon']);
      if (lat == null || lng == null) return null;
      return _ResolvedCoordinates(
        lat,
        lng,
        labelPrefix: 'Position approximative',
        cityLabel: [
          data['city']?.toString(),
          data['country_name']?.toString() ?? data['country']?.toString(),
        ].where((item) => item != null && item.trim().isNotEmpty).join(', '),
      );
    } catch (_) {
      return null;
    }
  }

  _ResolvedCoordinates _fromPosition(Position position, String labelPrefix) {
    return _ResolvedCoordinates(
      position.latitude,
      position.longitude,
      labelPrefix: labelPrefix,
    );
  }

  double? _doubleFrom(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _applyCoordinates(
    double latitude,
    double longitude, {
    String labelPrefix = 'Position actuelle',
    String cityLabel = '',
  }) {
    setState(() {
      _latitude = latitude;
      _longitude = longitude;
      final label =
          cityLabel.trim().isNotEmpty
              ? cityLabel.trim()
              : '$labelPrefix (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
      if (_isShop) {
        if (_shopAddressController.text.trim().isEmpty ||
            _shopAddressController.text.startsWith('Position ')) {
          _shopAddressController.text = label;
        }
      } else if (_locationController.text.trim().isEmpty ||
          _locationController.text.startsWith('Position ')) {
        _locationController.text = label;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isShop ? 'Ouvrir une boutique' : 'Devenir créateur';
    final subtitle =
        _isShop
            ? 'Configurez votre vitrine et commencez à vendre avec le même compte.'
            : 'Présentez votre univers et débloquez votre espace créateur.';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _buildHero(title, subtitle),
              const SizedBox(height: 18),
              _buildIdentitySection(),
              const SizedBox(height: 14),
              _buildStorySection(),
              const SizedBox(height: 14),
              _buildImageSection(),
              const SizedBox(height: 22),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _isShop ? _violet : const Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _isShop ? Icons.storefront_rounded : Icons.brush_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return _buildCard(
      title: _isShop ? 'Identité boutique' : 'Identité créateur',
      icon: _isShop ? AppIcons.boutique : AppIcons.style,
      children: [
        if (_isShop) ...[
          _buildField(
            controller: _shopNameController,
            label: 'Nom de la boutique',
            icon: Icons.store_rounded,
            requiredField: true,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _shopAddressController,
            label: 'Adresse ou ville',
            icon: Icons.location_on_rounded,
            requiredField: true,
          ),
          const SizedBox(height: 10),
          _buildLocationButton(),
        ] else
          _buildField(
            controller: _displayNameController,
            label: 'Nom public',
            icon: Icons.person_rounded,
            requiredField: true,
          ),
        const SizedBox(height: 12),
        _buildField(
          controller: _specialtyController,
          label: _isShop ? 'Catégorie principale' : 'Spécialité',
          hint:
              _isShop
                  ? 'Ex: prêt-à-porter, accessoires, textile local...'
                  : 'Ex: styliste, couture, tissage, broderie...',
          icon: Icons.category_rounded,
          requiredField: true,
        ),
        if (_isCreator) ...[
          const SizedBox(height: 12),
          _buildField(
            controller: _locationController,
            label: 'Ville / atelier',
            icon: Icons.place_rounded,
            requiredField: true,
          ),
          const SizedBox(height: 10),
          _buildLocationButton(),
        ],
      ],
    );
  }

  Widget _buildStorySection() {
    return _buildCard(
      title: _isShop ? 'Présentation' : 'Votre univers',
      icon: Icons.notes_rounded,
      children: [
        _buildField(
          controller: _isShop ? _shopDescriptionController : _bioController,
          label: _isShop ? 'Description boutique' : 'Bio créateur',
          hint:
              'Présentez votre style, votre savoir-faire et ce qui vous rend unique.',
          icon: Icons.short_text_rounded,
          requiredField: true,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    final value = _imageUrlController.text.trim();
    final file = _imageFile;
    final hasPreview = file != null || value.isNotEmpty;
    return _buildCard(
      title: _isShop ? 'Logo boutique' : 'Photo de profil',
      icon: Icons.image_rounded,
      children: [
        if (hasPreview)
          Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
              image: DecorationImage(
                image:
                    file != null
                        ? FileImage(file) as ImageProvider
                        : NetworkImage(value),
                fit: BoxFit.cover,
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _isSubmitting
                        ? null
                        : () => _chooseImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Galerie'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _isSubmitting
                        ? null
                        : () => _chooseImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Appareil'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: const Text(
            'Ou utiliser une URL',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          children: [
            _buildField(
              controller: _imageUrlController,
              label: 'URL image optionnelle',
              hint: 'Ajoutez un lien logo/photo si disponible',
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              onChanged:
                  (_) => setState(() {
                    _imageFile = null;
                  }),
            ),
          ],
        ),
        Text(
          _isShop
              ? 'Visible dans le Salon, la boutique et la carte.'
              : 'Visible dans le Salon, les talents et la carte.',
          style: TextStyle(color: _muted, fontSize: 12, height: 1.3),
        ),
      ],
    );
  }

  Widget _buildLocationButton() {
    final hasCoordinates = _latitude != null && _longitude != null;
    return OutlinedButton.icon(
      onPressed: _isLocating || _isSubmitting ? null : _useCurrentLocation,
      icon:
          _isLocating
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Icon(
                hasCoordinates
                    ? Icons.my_location_rounded
                    : Icons.near_me_outlined,
              ),
      label: Text(
        _isLocating
            ? 'Localisation...'
            : hasCoordinates
            ? 'Position ajoutée à la carte'
            : 'Utiliser la position du téléphone',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: hasCoordinates ? _primary : _ink,
        side: BorderSide(color: hasCoordinates ? _primary : _border),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool requiredField = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      icon: icon,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      onChanged: onChanged,
      textCapitalization:
          keyboardType == TextInputType.emailAddress ||
                  keyboardType == TextInputType.url
              ? TextCapitalization.none
              : TextCapitalization.sentences,
      validator: (value) {
        if (!requiredField) return null;
        if (value == null || value.trim().isEmpty) {
          return 'Ajoutez ${label.toLowerCase()}';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        icon:
            _isSubmitting
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(AppIcons.award),
        label: Text(
          _isSubmitting
              ? 'Activation...'
              : _isShop
              ? 'Activer ma boutique'
              : 'Activer mon espace créateur',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _ResolvedCoordinates {
  const _ResolvedCoordinates(
    this.latitude,
    this.longitude, {
    required this.labelPrefix,
    this.cityLabel = '',
  });

  final double latitude;
  final double longitude;
  final String labelPrefix;
  final String cityLabel;
}
