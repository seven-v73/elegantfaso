import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/account_roles.dart';
import '../../../design/modern_design_system.dart';
import '../../../services/media/media_asset_service.dart';
import '../../../services/media/media_upload_service.dart';
import '../../../services/account/account_closure_service.dart';
import '../../../services/location/salon_place_publisher_service.dart';
import '../../../services/preferences/currency_service.dart';
import '../../../services/salon/salon_analytics_service.dart';
import '../../../services/talent/follow_service.dart';
import '../../widgets/account/account_closure_sheet.dart';
import '../../widgets/account/account_space_switcher.dart';
import '../../widgets/forms/app_form_section.dart';
import '../../widgets/forms/app_sticky_form_bar.dart';
import '../../widgets/forms/app_text_field.dart';
import '../../widgets/forms/payment_methods_editor.dart';
import '../../widgets/preferences/currency_preference_tile.dart';
part 'createur_profile_edit_sheet.dart';

class CreateurProfileScreen extends StatefulWidget {
  final String? userId;

  const CreateurProfileScreen({super.key, this.userId});

  @override
  State<CreateurProfileScreen> createState() => _CreateurProfileScreenState();
}

class _CreateurProfileScreenState extends State<CreateurProfileScreen>
    with TickerProviderStateMixin {
  late final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isCurrentUserProfile = true;
  int _selectedTab = 0;
  Map<String, dynamic>? _userData;
  int _clientsCount = 0;
  int _creationsCount = 0;
  int _profileViewsCount = 0;
  List<Map<String, dynamic>> _profileCreations = [];
  bool _isLoading = true;
  List<String> _competences = [];
  List<Map<String, String>> _certifications = [];
  Map<String, String> _paymentMethods = {};
  String _currency = CurrencyService.defaultCode;
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _specialityController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  final TextEditingController _competenceController = TextEditingController();
  final TextEditingController _certifTitleController = TextEditingController();
  final TextEditingController _certifInstitutionController =
      TextEditingController();
  final TextEditingController _certifYearController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MediaUploadService _mediaUploadService = MediaUploadService();
  final SalonPlacePublisherService _placePublisherService =
      SalonPlacePublisherService();
  final FollowService _followService = FollowService();
  final SalonAnalyticsService _analyticsService = SalonAnalyticsService();
  final ImagePicker _picker = ImagePicker();

  String get _creatorPhotoUrl {
    final data = _userData ?? const <String, dynamic>{};
    final creatorProfile = Map<String, dynamic>.from(
      data['creatorProfile'] ?? const {},
    );
    return data['creatorPhotoUrl']?.toString() ??
        creatorProfile['photoUrl']?.toString() ??
        data['photoUrl']?.toString() ??
        '';
  }

  String get _creatorLocationLabel {
    final data = _userData ?? const <String, dynamic>{};
    final creatorProfile = Map<String, dynamic>.from(
      data['creatorProfile'] ?? const {},
    );
    final city =
        data['city']?.toString().trim().isNotEmpty == true
            ? data['city'].toString().trim()
            : creatorProfile['city']?.toString().trim() ?? '';
    final country =
        data['country']?.toString().trim().isNotEmpty == true
            ? data['country'].toString().trim()
            : creatorProfile['country']?.toString().trim() ?? '';
    final address =
        data['address']?.toString().trim().isNotEmpty == true
            ? data['address'].toString().trim()
            : creatorProfile['address']?.toString().trim() ?? '';
    final parts = [
      if (address.isNotEmpty) address,
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ];
    return parts.join(' • ');
  }

  @override
  void initState() {
    super.initState();
    _isCurrentUserProfile =
        widget.userId == null || widget.userId == _currentUser?.uid;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _loadUserData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _specialityController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _competenceController.dispose();
    _certifTitleController.dispose();
    _certifInstitutionController.dispose();
    _certifYearController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userId = widget.userId ?? _currentUser?.uid;
    if (userId == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          final creatorProfile = Map<String, dynamic>.from(
            _userData?['creatorProfile'] ?? const {},
          );
          _nameController.text =
              _userData?['creatorName']?.toString() ??
              creatorProfile['name']?.toString() ??
              '';
          _bioController.text = _userData!['bio'] ?? '';
          _emailController.text = _userData!['email'] ?? '';
          _specialityController.text = _userData!['speciality'] ?? '';
          _websiteController.text = _userData!['website'] ?? '';
          _addressController.text =
              _userData?['address']?.toString() ??
              creatorProfile['address']?.toString() ??
              '';
          _cityController.text =
              _userData?['city']?.toString() ??
              _userData?['ville']?.toString() ??
              creatorProfile['city']?.toString() ??
              '';
          _countryController.text =
              _userData?['country']?.toString() ??
              _userData?['pays']?.toString() ??
              creatorProfile['country']?.toString() ??
              '';
          _latitude = _doubleFrom(
            _userData?['latitude'] ??
                (_userData?['location'] is Map
                    ? (_userData!['location'] as Map)['latitude']
                    : null) ??
                (creatorProfile['location'] is Map
                    ? (creatorProfile['location'] as Map)['latitude']
                    : null),
          );
          _longitude = _doubleFrom(
            _userData?['longitude'] ??
                (_userData?['location'] is Map
                    ? (_userData!['location'] as Map)['longitude']
                    : null) ??
                (creatorProfile['location'] is Map
                    ? (creatorProfile['location'] as Map)['longitude']
                    : null),
          );

          _competences = List<String>.from(_userData?['competences'] ?? []);
          _certifications = List<Map<String, String>>.from(
            _userData?['certifications']?.map(
                  (e) => Map<String, String>.from(e),
                ) ??
                [],
          );
          _paymentMethods = _readPaymentMethods(_userData ?? {});
          _currency = CurrencyService.currencyFromUserData(_userData ?? {});
          _profileViewsCount =
              (_userData?['profileViewsCount'] as num?)?.toInt() ??
              (_userData?['viewsCount'] as num?)?.toInt() ??
              (_userData?['stats'] is Map
                  ? ((Map<String, dynamic>.from(
                            _userData?['stats'] as Map,
                          )['profileViews']
                          as num?)
                      ?.toInt())
                  : null) ??
              0;
        });
      }

      final clientsQuery =
          await _firestore
              .collection('relationships')
              .where('followingId', isEqualTo: userId)
              .get();

      final creationDocs =
          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final field in const ['creatorId', 'createurId']) {
        final snapshot =
            await _firestore
                .collection('creations')
                .where(field, isEqualTo: userId)
                .limit(80)
                .get();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final status = data['status']?.toString() ?? '';
          if (status == 'archived' ||
              status == 'deleted' ||
              data['deletedAt'] != null) {
            continue;
          }
          creationDocs[doc.id] = doc;
        }
      }

      final creations =
          creationDocs.values.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
      creations.sort((a, b) {
        final aDate = _dateFromAny(a['createdAt'] ?? a['date']);
        final bDate = _dateFromAny(b['createdAt'] ?? b['date']);
        return bDate.compareTo(aDate);
      });

      setState(() {
        _clientsCount = clientsQuery.size;
        _profileCreations = creations;
        _creationsCount = creations.length;
        _isLoading = false;
      });

      _fadeController.forward();
      _slideController.forward();
      await _trackPublicProfileView(userId);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Erreur de chargement: $e');
    }
  }

  Future<void> _trackPublicProfileView(String userId) async {
    if (_isCurrentUserProfile) return;
    await _analyticsService.trackProfileView(
      profileId: userId,
      title: _nameController.text.trim(),
      role: 'createur',
    );
  }

  Future<void> _changeProfilePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    _showLoadingDialog('Mise à jour de la photo...');

    try {
      final userId = _currentUser?.uid;
      if (userId == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final upload = await _mediaUploadService.uploadImage(
        file: File(pickedFile.path),
        folder: 'profiles/$userId',
        publicId: 'avatar_${DateTime.now().millisecondsSinceEpoch}',
      );
      final mediaId = await MediaAssetService().recordUpload(
        upload: upload,
        ownerId: userId,
        ownerRole: 'createur',
        usage: 'profile_avatar',
        status: 'public',
        linkedCollection: 'users',
        linkedDocumentId: userId,
      );
      final media = upload.copyWithAssetId(mediaId);
      final photoUrl = MediaUploadService.avatarUrl(media.url);

      await _firestore.collection('users').doc(userId).update({
        'creatorPhotoUrl': photoUrl,
        'creatorProfile.photoUrl': photoUrl,
        'media.creatorProfileImage': media.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _placePublisherService.publishCurrentUserPlaces();

      if (!mounted) return;
      setState(() {
        _userData?['creatorPhotoUrl'] = photoUrl;
        _userData?['creatorProfile'] = {
          ...Map<String, dynamic>.from(_userData?['creatorProfile'] ?? {}),
          'photoUrl': photoUrl,
        };
      });

      if (!mounted) return;
      Navigator.pop(context);
      _showSuccessSnackBar('Photo de profil mise à jour');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar('Erreur lors de la mise à jour de la photo: $e');
    }
  }

  Future<void> _selectCoverPhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    _showLoadingDialog('Mise à jour de la couverture...');

    try {
      final userId = _currentUser?.uid;
      if (userId == null) return;

      final upload = await _mediaUploadService.uploadImage(
        file: File(pickedFile.path),
        folder: 'profiles/$userId',
        publicId: 'cover_${DateTime.now().millisecondsSinceEpoch}',
      );
      final mediaId = await MediaAssetService().recordUpload(
        upload: upload,
        ownerId: userId,
        ownerRole: 'createur',
        usage: 'profile_cover',
        status: 'public',
        linkedCollection: 'users',
        linkedDocumentId: userId,
      );
      final media = upload.copyWithAssetId(mediaId);
      final coverUrl = media.optimizedUrl;

      await _firestore.collection('users').doc(userId).update({
        'coverPhoto': coverUrl,
        'media.coverImage': media.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _userData?['coverPhoto'] = coverUrl);

      Navigator.pop(context);
      _showSuccessSnackBar('Photo de couverture mise à jour');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar('Erreur lors de la mise à jour de la couverture: $e');
    }
  }

  Future<void> _saveProfileChanges() async {
    if (_nameController.text.isEmpty) {
      _showErrorSnackBar('Le nom ne peut pas être vide');
      return;
    }

    _showLoadingDialog('Sauvegarde...');

    try {
      final userId = _currentUser?.uid;
      if (userId == null) return;
      await _firestore.collection('users').doc(userId).update({
        'creatorName': _nameController.text.trim(),
        'creatorProfile.name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'creatorProfile.description': _bioController.text.trim(),
        'email': _emailController.text.trim(),
        'speciality': _specialityController.text.trim(),
        'creatorProfile.specialty': _specialityController.text.trim(),
        'website': _websiteController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
        'creatorProfile.address': _addressController.text.trim(),
        'creatorProfile.city': _cityController.text.trim(),
        'creatorProfile.country': _countryController.text.trim(),
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
        if (_latitude != null && _longitude != null)
          'location': {'latitude': _latitude, 'longitude': _longitude},
        if (_latitude != null && _longitude != null)
          'creatorProfile.location': {
            'latitude': _latitude,
            'longitude': _longitude,
          },
        'competences': _competences,
        'certifications': _certifications,
        'isPublic': true,
        'publicProfile': true,
        'publicRole': 'createur',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _placePublisherService.publishCurrentUserPlaces();

      if (_emailController.text.trim() != _currentUser?.email) {
        await _currentUser?.verifyBeforeUpdateEmail(
          _emailController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
      _showSuccessSnackBar('Profil mis à jour avec succès');
      _loadUserData();
    } catch (e) {
      debugPrint('Erreur sauvegarde profil créateur: $e');
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar('Mise à jour impossible pour le moment.');
    }
  }

  Future<void> _savePaymentSettings() async {
    _showLoadingDialog('Sauvegarde...');

    try {
      final userId = _currentUser?.uid;
      if (userId == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      final paymentMethods = _normalizedCreatorPaymentMethods();
      final primaryPayment =
          paymentMethods.entries.isNotEmpty
              ? paymentMethods.entries.first
              : null;

      await _firestore.collection('users').doc(userId).update({
        'paymentMethod': primaryPayment?.key ?? '',
        'paymentNumber': primaryPayment?.value ?? '',
        'paymentMethods': paymentMethods,
        'creatorProfile.paymentMethods': paymentMethods,
        'currency': _currency,
        'preferredCurrency': _currency,
        'creatorProfile.currency': _currency,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
      _showSuccessSnackBar('Paiement mis à jour.');
      _loadUserData();
    } catch (e) {
      debugPrint('Erreur sauvegarde paiements créateur: $e');
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar('Paiement impossible à enregistrer pour le moment.');
    }
  }

  Map<String, String> _normalizedCreatorPaymentMethods() {
    final methods = Map<String, String>.from(_paymentMethods)
      ..removeWhere((key, value) => key.trim().isEmpty || value.trim().isEmpty);
    _paymentMethods = methods;
    return methods;
  }

  static Map<String, String> _readPaymentMethods(Map<String, dynamic> data) {
    final creatorProfile = Map<String, dynamic>.from(
      data['creatorProfile'] ?? const {},
    );
    final raw = data['paymentMethods'] ?? creatorProfile['paymentMethods'];
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      )..removeWhere(
        (key, value) => key.trim().isEmpty || value.trim().isEmpty,
      );
    }
    final method = data['paymentMethod']?.toString() ?? '';
    final number = data['paymentNumber']?.toString() ?? '';
    if (method.isNotEmpty && number.isNotEmpty) {
      return {_paymentMethodLabel(method): number};
    }
    return const {};
  }

  static String _paymentMethodLabel(String value) {
    return switch (value) {
      'orange_money' => 'Orange Money',
      'moov_money' => 'Moov Money',
      'wave' => 'Wave',
      _ => value,
    };
  }

  double? _doubleFrom(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  DateTime _dateFromAny(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _stringFromCreatorProfile(String key) {
    final creatorProfile = Map<String, dynamic>.from(
      _userData?['creatorProfile'] ?? const {},
    );
    return _userData?[key]?.toString().trim().isNotEmpty == true
        ? _userData![key].toString().trim()
        : creatorProfile[key]?.toString().trim() ?? '';
  }

  int get _profileCompletion {
    final checks = [
      _stringFromCreatorProfile('creatorName').isNotEmpty ||
          _stringFromCreatorProfile('name').isNotEmpty,
      _creatorPhotoUrl.isNotEmpty,
      _userData?['bio']?.toString().trim().isNotEmpty == true,
      _specialityController.text.trim().isNotEmpty ||
          _stringFromCreatorProfile('specialty').isNotEmpty,
      _creatorLocationLabel.isNotEmpty,
      _paymentMethods.isNotEmpty,
      _profileCreations.isNotEmpty,
    ];
    return (checks.where((value) => value).length / checks.length * 100)
        .round();
  }

  Future<void> _useCurrentLocation({StateSetter? setModalState}) async {
    setState(() => _isLocating = true);
    setModalState?.call(() {});
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
        throw StateError('Autorisez la localisation pour placer le créateur.');
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
      setModalState?.call(() {});
      _showSuccessSnackBar(
        'Position ajoutée. Enregistrez pour publier sur la carte.',
      );
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
        setModalState?.call(() {});
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message),
              ],
            ),
          ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _toggleFollowPublicProfile() async {
    final profileId = widget.userId;
    if (profileId == null || profileId.isEmpty) {
      _showErrorSnackBar('Profil indisponible.');
      return;
    }
    try {
      await _followService.toggleFollow(
        talentId: profileId,
        talentName:
            _userData?['creatorName']?.toString() ??
            _userData?['name']?.toString() ??
            'Créateur',
      );
    } catch (_) {
      _showErrorSnackBar('Connexion requise pour suivre ce profil.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Chargement du profil...',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 320,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color:
                          innerBoxIsScrolled
                              ? (isDarkMode ? Colors.white : Colors.black)
                              : Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    if (_isCurrentUserProfile)
                      IconButton(
                        icon: Icon(
                          Icons.settings,
                          color:
                              innerBoxIsScrolled
                                  ? (isDarkMode ? Colors.white : Colors.black)
                                  : Colors.white,
                        ),
                        onPressed: () => setState(() => _selectedTab = 1),
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: _buildCoverSection(),
                  ),
                ),
              ];
            },
            body: _buildBody(),
          ),
        ),
      ),
      floatingActionButton:
          _isCurrentUserProfile
              ? null
              : FloatingActionButton(
                heroTag: null,
                backgroundColor: primaryColor,
                onPressed: _toggleFollowPublicProfile,
                child: StreamBuilder<bool>(
                  stream: _followService.watchFollowing(widget.userId ?? ''),
                  builder: (context, snapshot) {
                    final following = snapshot.data == true;
                    return Icon(
                      following ? Icons.check_rounded : Icons.person_add,
                      color: Colors.white,
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildCoverSection() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'cover_${widget.userId ?? _currentUser?.uid}',
          child: CachedNetworkImage(
            imageUrl:
                _userData?['coverPhoto']?.isNotEmpty == true
                    ? _userData!['coverPhoto']
                    : 'https://i.pinimg.com/564x/83/7a/4e/837a4ed6ecbd41f63eb123e973f9b202.jpg',
            fit: BoxFit.cover,
            placeholder:
                (context, url) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withValues(alpha: 0.3),
                        primaryColor.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
            errorWidget:
                (context, url, error) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withValues(alpha: 0.3),
                        primaryColor.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.7),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),

        if (_isCurrentUserProfile)
          Positioned(
            top: 60,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: _selectCoverPhoto,
              ),
            ),
          ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Hero(
                      tag: 'avatar_${widget.userId ?? _currentUser?.uid}',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              (_creatorPhotoUrl).isNotEmpty
                                  ? CachedNetworkImageProvider(_creatorPhotoUrl)
                                  : null,
                          child:
                              _creatorPhotoUrl.isEmpty
                                  ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                      ),
                    ),
                    if (_isCurrentUserProfile)
                      Positioned(
                        bottom: -5,
                        right: -5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _changeProfilePhoto,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _userData?['creatorName'] ??
                            (_userData?['creatorProfile']
                                as Map<String, dynamic>?)?['name'] ??
                            _currentUser?.displayName ??
                            'Créateur',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                      if (_userData?['speciality'] != null &&
                          _userData!['speciality'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _userData!['speciality'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildProfileCommandCenter()),
        if (_isCurrentUserProfile)
          SliverToBoxAdapter(child: _buildProfileActions()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildEnhancedStatItem(
                    _clientsCount.toString(),
                    'Clients',
                    Icons.people_alt_rounded,
                    ModernColors.client,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildEnhancedStatItem(
                    _creationsCount.toString(),
                    'Créations',
                    Icons.checkroom_rounded,
                    ModernColors.creator,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildEnhancedStatItem(
                    _profileViewsCount.toString(),
                    'Vues',
                    Icons.visibility_rounded,
                    ModernColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isCurrentUserProfile) SliverToBoxAdapter(child: _buildReadiness()),
        SliverToBoxAdapter(child: _buildAboutSection()),
        SliverToBoxAdapter(child: _buildTabBar()),
        SliverToBoxAdapter(child: _buildCurrentTabContent()),
      ],
    );
  }

  Widget _buildProfileCommandCenter() {
    final specialty =
        _specialityController.text.trim().isNotEmpty
            ? _specialityController.text.trim()
            : _stringFromCreatorProfile('specialty');
    final visibleCount =
        _profileCreations.where((creation) {
          final status = creation['status']?.toString() ?? '';
          final visibility = creation['visibility']?.toString() ?? '';
          return status == 'published' || visibility == 'salon';
        }).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ModernColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ModernColors.creator.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.palette_rounded,
                  color: ModernColors.creator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vitrine créateur',
                      style: TextStyle(
                        color: ModernColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (specialty.isNotEmpty)
                      Text(
                        specialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ModernColors.inkSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              _ProfileScore(score: _profileCompletion),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniSignal(
                  icon: Icons.storefront_rounded,
                  label: 'Salon',
                  value: '$visibleCount visibles',
                  color: ModernColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniSignal(
                  icon: Icons.place_rounded,
                  label: 'Carte',
                  value: _creatorLocationLabel.isEmpty ? 'À placer' : 'OK',
                  color: ModernColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _navigateToEditProfile,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Modifier'),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            tooltip: 'Paramètres',
            onPressed: () => setState(() => _selectedTab = 1),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildReadiness() {
    return _CreatorReadinessCard(
      hasName:
          (_userData?['creatorName']?.toString().trim().isNotEmpty ?? false),
      hasImage: _creatorPhotoUrl.trim().isNotEmpty,
      hasLocation: _creatorLocationLabel.isNotEmpty,
      hasBio: _userData?['bio']?.toString().trim().isNotEmpty ?? false,
      hasPayment: _paymentMethods.isNotEmpty,
      hasCreation: _profileCreations.isNotEmpty,
      onEdit: _navigateToEditProfile,
      onPayment: _navigateToPaymentSettings,
    );
  }

  Widget _buildEnhancedStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: ModernColors.inkSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'À propos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_userData?['bio']?.toString().isNotEmpty ?? false)
            Text(
              _userData!['bio'],
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          if (_creatorLocationLabel.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ModernColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ModernColors.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    color: ModernColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _creatorLocationLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_userData?['website'] != null &&
              _userData!['website'].isNotEmpty) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _launchURL(_userData!['website']),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _userData!['website'],
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                _currentUser?.metadata.creationTime != null
                    ? 'Membre depuis ${DateFormat('MMMM yyyy', 'fr').format(_currentUser!.metadata.creationTime!)}'
                    : 'Créateur de mode',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Portfolio', 0)),
          if (_isCurrentUserProfile)
            Expanded(child: _buildTabButton('Paramètres', 1)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTab == index;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color:
                  isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_selectedTab) {
      // case 0: return _buildActivityTab();
      // case 1: return _buildCreationsTab();
      case 0:
        return _buildPortfolioTab();
      case 1:
        return _buildSettingsTab();
      default:
        return _buildPortfolioTab();
    }
  }

  // ignore: unused_element
  Widget _buildActivityTab() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        final activities = [
          {
            'icon': Icons.person_add,
            'title': 'Nouveau client',
            'color': Colors.blue,
          },
          {
            'icon': Icons.comment,
            'title': 'Commentaire sur votre création',
            'color': Colors.green,
          },
          {
            'icon': Icons.share,
            'title': 'Votre création a été partagée',
            'color': Colors.orange,
          },
          {
            'icon': Icons.favorite,
            'title': 'Votre création a été aimée',
            'color': Colors.red,
          },
          {
            'icon': Icons.star,
            'title': 'Nouvelle évaluation 5 étoiles',
            'color': Colors.amber,
          },
        ];

        final activity = activities[index % activities.length];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (activity['color'] as Color).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  activity['icon'] as IconData,
                  color: activity['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Il y a ${index + 1} ${index == 0 ? 'heure' : 'heures'}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget _buildCreationsTab() {
  //   if (_userCreations.isEmpty) {
  //     return _buildEmptyState(
  //       icon: Icons.brush,
  //       title: 'Aucune création',
  //       subtitle: _isCurrentUserProfile
  //           ? 'Commencez à créer pour voir vos œuvres ici'
  //           : 'Ce créateur n\'a pas encore publié de créations',
  //     );
  //   }
  //
  //   return GridView.builder(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     padding: const EdgeInsets.all(24),
  //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //       crossAxisCount: 2,
  //       crossAxisSpacing: 16,
  //       mainAxisSpacing: 16,
  //       childAspectRatio: 0.8,
  //     ),
  //     itemCount: _userCreations.length,
  //     itemBuilder: (context, index) {
  //       final creation = _userCreations[index];
  //       return _buildCreationCard(creation);
  //     },
  //   );
  // }

  // ignore: unused_element
  Widget _buildCreationCard(Map<String, dynamic> creation) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: CachedNetworkImage(
                  imageUrl: creation['imageUrl'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    creation['title'] ?? 'Sans titre',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.red.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${creation['likes'] ?? 0}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatDate(creation['date']),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCreationsShowcase(),
          const SizedBox(height: 14),
          if (_competences.isNotEmpty)
            _buildPortfolioSection(
              title: 'Compétences',
              icon: Icons.workspace_premium_rounded,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _competences
                        .map(
                          (skill) => Chip(
                            label: Text(skill),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        )
                        .toList(),
              ),
            ),

          if (_competences.isNotEmpty) const SizedBox(height: 24),

          if (_certifications.isNotEmpty)
            _buildPortfolioSection(
              title: 'Certifications',
              icon: Icons.verified,
              child: Column(
                children:
                    _certifications
                        .map(
                          (certif) => _buildCertificationItem(
                            certif['title'] ?? '',
                            certif['institution'] ?? '',
                            certif['year'] ?? '',
                          ),
                        )
                        .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreationsShowcase() {
    if (_profileCreations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ModernColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ModernColors.line),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.checkroom_outlined,
              color: ModernColors.creator,
              size: 34,
            ),
            const SizedBox(height: 10),
            const Text(
              'Aucune création visible',
              style: TextStyle(
                color: ModernColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (_isCurrentUserProfile) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed:
                    () => Navigator.pushNamed(context, '/creator-dashboard'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Publier'),
              ),
            ],
          ],
        ),
      );
    }

    final featured = _profileCreations.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Créations',
                style: TextStyle(
                  color: ModernColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (_isCurrentUserProfile)
              TextButton(
                onPressed:
                    () => Navigator.pushNamed(context, '/creator-dashboard'),
                child: const Text('Gérer'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: featured.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            return _DynamicCreationTile(creation: featured[index]);
          },
        ),
      ],
    );
  }

  Widget _buildPortfolioSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCertificationItem(
    String title,
    String institution,
    String year,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$institution • $year',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    if (!_isCurrentUserProfile) return Container();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const AccountSpaceSwitcher(
            currentSpace: AccountRoles.createur,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            title: 'Compte',
            children: [
              _buildSettingsItem(
                icon: Icons.edit_rounded,
                title: 'Modifier le profil',
                subtitle: 'Identité, bio, localisation',
                onTap: _navigateToEditProfile,
              ),
              _buildSettingsItem(
                icon: Icons.payment,
                title: 'Moyens de paiement',
                subtitle:
                    _paymentMethods.isNotEmpty
                        ? '${_paymentMethods.length} canal${_paymentMethods.length > 1 ? 's' : ''} configuré${_paymentMethods.length > 1 ? 's' : ''}'
                        : 'Non configuré',
                onTap: _navigateToPaymentSettings,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withValues(alpha: 0.22)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _requestCreatorClosure,
              child: Row(
                children: [
                  const Icon(
                    Icons.pause_circle_outline_rounded,
                    color: Colors.red,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fermer l’espace créateur',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Soumettre une demande à l’administration',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.red),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: InkWell(
              onTap: _showLogoutDialog,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Se déconnecter',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Se déconnecter'),
            content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'Se déconnecter',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _requestCreatorClosure() async {
    final submitted = await showAccountClosureSheet(
      context,
      target: AccountClosureTarget.createur,
    );
    if (!mounted || submitted != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Espace créateur fermé. Votre compte client reste actif.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

class _ProfileScore extends StatelessWidget {
  const _ProfileScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color =
        score >= 80
            ? ModernColors.success
            : score >= 50
            ? ModernColors.accent
            : ModernColors.rose;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score%',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _MiniSignal extends StatelessWidget {
  const _MiniSignal({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicCreationTile extends StatelessWidget {
  const _DynamicCreationTile({required this.creation});

  final Map<String, dynamic> creation;

  @override
  Widget build(BuildContext context) {
    final title =
        creation['title']?.toString() ??
        creation['name']?.toString() ??
        'Création';
    final images = creation['images'];
    final imageUrl =
        creation['imageUrl']?.toString().trim().isNotEmpty == true
            ? creation['imageUrl'].toString()
            : images is Iterable && images.isNotEmpty
            ? images.first.toString()
            : '';
    final views = (creation['viewsCount'] as num?)?.toInt() ?? 0;
    final saves =
        (creation['savesCount'] as num?)?.toInt() ??
        (creation['likeCount'] as num?)?.toInt() ??
        0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child:
                imageUrl.isEmpty
                    ? Container(
                      color: ModernColors.canvas,
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: ModernColors.inkSoft,
                        ),
                      ),
                    )
                    : CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 420,
                      errorWidget:
                          (_, _, _) => const Center(
                            child: Icon(Icons.image_not_supported_rounded),
                          ),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_rounded,
                      size: 14,
                      color: ModernColors.inkSoft,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$views',
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.favorite_rounded,
                      size: 14,
                      color: ModernColors.inkSoft,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$saves',
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorReadinessCard extends StatelessWidget {
  const _CreatorReadinessCard({
    required this.hasName,
    required this.hasImage,
    required this.hasLocation,
    required this.hasBio,
    required this.hasPayment,
    required this.hasCreation,
    required this.onEdit,
    required this.onPayment,
  });

  final bool hasName;
  final bool hasImage;
  final bool hasLocation;
  final bool hasBio;
  final bool hasPayment;
  final bool hasCreation;
  final VoidCallback onEdit;
  final VoidCallback onPayment;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Nom public', hasName),
      ('Photo', hasImage),
      ('Position carte', hasLocation),
      ('Bio', hasBio),
      ('Paiement', hasPayment),
      ('Création', hasCreation),
    ];
    final done = items.where((item) => item.$2).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fact_check_outlined,
                color: ModernColors.creator,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$done/${items.length} prêts',
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Wrap(
                spacing: 4,
                children: [
                  TextButton(onPressed: onEdit, child: const Text('Profil')),
                  if (!hasPayment)
                    TextButton(
                      onPressed: onPayment,
                      child: const Text('Paiements'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                items
                    .map(
                      (item) => Chip(
                        avatar: Icon(
                          item.$2
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color:
                              item.$2
                                  ? ModernColors.creator
                                  : ModernColors.inkSoft,
                        ),
                        label: Text(item.$1),
                        side: const BorderSide(color: ModernColors.line),
                        backgroundColor:
                            item.$2
                                ? ModernColors.creator.withValues(alpha: 0.08)
                                : ModernColors.canvas,
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}
