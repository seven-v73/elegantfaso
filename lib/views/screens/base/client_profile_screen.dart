import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/account_roles.dart';
import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';
import '../../../models/client/client_dashboard_summary.dart';
import '../../../services/client/client_dashboard_service.dart';
import '../../../services/preferences/currency_service.dart';
import '../../../services/media/media_asset_service.dart';
import '../../../services/media/media_upload_service.dart';
import '../../../services/account/account_closure_service.dart';
import '../../../services/talent/follow_service.dart';
import '../../widgets/account/account_closure_sheet.dart';
import '../../widgets/account/account_space_switcher.dart';
import '../../widgets/forms/payment_methods_editor.dart';
import '../../widgets/preferences/currency_preference_tile.dart';

class ClientProfileScreen extends StatefulWidget {
  final String? userId;
  final bool showBackButton;

  const ClientProfileScreen({
    super.key,
    this.userId,
    this.showBackButton = true,
  });

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MediaUploadService _mediaUploadService = MediaUploadService();
  final ImagePicker _picker = ImagePicker();
  final ClientDashboardService _dashboardService = ClientDashboardService();
  final FollowService _followService = FollowService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  Map<String, String> _paymentMethods = {};

  bool _isEditing = false;
  bool _isSaving = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;
  String? get _profileUserId => widget.userId ?? _currentUser?.uid;
  bool get _isCurrentUserProfile =>
      widget.userId == null || widget.userId == _currentUser?.uid;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _profileUserId;
    if (userId == null) {
      return const Scaffold(
        backgroundColor: ModernColors.canvas,
        body: Center(child: Text('Profil indisponible')),
      );
    }

    if (_isCurrentUserProfile) {
      return StreamBuilder<ClientDashboardSummary>(
        stream: _dashboardService.watchSummary(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const _ProfileSkeleton(showBackButton: true);
          }
          final summary = snapshot.data;
          if (summary == null) {
            return _ProfileError(onRetry: () => setState(() {}));
          }
          return _buildProfile(
            profile: _ProfileData.fromSummary(summary),
            summary: summary,
          );
        },
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _ProfileSkeleton(showBackButton: true);
        }
        final doc = snapshot.data;
        if (doc == null || !doc.exists) {
          return _ProfileError(onRetry: () => setState(() {}));
        }
        return _buildProfile(profile: _ProfileData.fromUserDoc(doc));
      },
    );
  }

  Widget _buildProfile({
    required _ProfileData profile,
    ClientDashboardSummary? summary,
  }) {
    _syncControllers(profile);

    return Scaffold(
      backgroundColor: ModernColors.canvas,
      body: RefreshIndicator(
        color: ModernColors.primary,
        onRefresh: () async => setState(() {}),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildAppBar(profile),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              sliver: SliverList.list(
                children: [
                  _buildIdentityCard(profile),
                  const SizedBox(height: 14),
                  if (_isEditing) _buildEditPanel(),
                  if (!_isEditing) ...[
                    _buildTrustGrid(profile),
                    const SizedBox(height: 18),
                    _buildAccountSection(profile),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(_ProfileData profile) {
    return SliverAppBar(
      automaticallyImplyLeading: widget.showBackButton,
      leading:
          widget.showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
              : null,
      pinned: true,
      stretch: true,
      expandedHeight: 246,
      backgroundColor: ModernColors.surface,
      foregroundColor: ModernColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: [
        if (_isCurrentUserProfile)
          IconButton(
            tooltip: _isEditing ? 'Enregistrer' : 'Modifier',
            onPressed: _isSaving ? null : _toggleEditOrSave,
            icon:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Icon(
                      _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                    ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _ProfileHero(
          profile: profile,
          canEdit: _isCurrentUserProfile,
          onChangeAvatar: _changeProfilePhoto,
          onChangeCover: _changeCoverPhoto,
        ),
      ),
    );
  }

  Widget _buildIdentityCard(_ProfileData profile) {
    final joined = _currentUser?.metadata.creationTime;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [
                        if (profile.city.isNotEmpty) profile.city,
                        if (joined != null)
                          'Membre depuis ${DateFormat('MMM yyyy', 'fr').format(joined)}',
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isCurrentUserProfile)
                _FollowProfileButton(profile: profile),
            ],
          ),
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              profile.bio,
              style: const TextStyle(
                color: ModernColors.inkSoft,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrustGrid(_ProfileData profile) {
    final stats = [
      _ProfileStat(
        label: 'Abonnés',
        value: profile.followersCount.toString(),
        icon: Icons.groups_rounded,
        color: ModernColors.primary,
      ),
      _ProfileStat(
        label: 'Suit',
        value: profile.followingCount.toString(),
        icon: Icons.person_add_alt_1_rounded,
        color: ModernColors.client,
      ),
      _ProfileStat(
        label: 'Email',
        value: profile.email.isEmpty ? 'Non' : 'OK',
        icon: Icons.verified_user_rounded,
        color: ModernColors.rose,
      ),
      _ProfileStat(
        label: 'Retrait',
        value: profile.paymentMethods.isEmpty ? 'Non' : 'OK',
        icon: Icons.account_balance_wallet_rounded,
        color: ModernColors.accent,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.9,
      ),
      itemBuilder: (context, index) => _StatTile(stat: stats[index]),
    );
  }

  Widget _buildAccountSection(_ProfileData profile) {
    if (!_isCurrentUserProfile) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(padding: EdgeInsets.zero, title: 'Compte'),
        const SizedBox(height: 10),
        AccountSpaceSwitcher(currentSpace: AccountRoles.client),
        const SizedBox(height: 10),
        CurrencyPreferenceTile(initialCurrency: profile.currency),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.mail_outline_rounded,
          title: 'Email',
          subtitle: profile.email.isEmpty ? 'Non renseigné' : profile.email,
          onTap: () => setState(() => _isEditing = true),
        ),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.phone_outlined,
          title: 'Téléphone',
          subtitle: profile.phone.isEmpty ? 'Non renseigné' : profile.phone,
          onTap: () => setState(() => _isEditing = true),
        ),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Paiement',
          subtitle:
              profile.paymentMethods.isEmpty
                  ? 'À compléter'
                  : '${profile.paymentMethods.length} moyen(s)',
          onTap: () => setState(() => _isEditing = true),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Déconnexion'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ModernColors.rose,
                  side: const BorderSide(color: ModernColors.rose),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.pause_circle_outline_rounded,
          title: 'Fermer mon compte',
          subtitle: 'Demande à valider',
          color: ModernColors.rose,
          onTap: _requestAccountClosure,
        ),
      ],
    );
  }

  Future<void> _requestAccountClosure() async {
    final submitted = await showAccountClosureSheet(
      context,
      target: AccountClosureTarget.account,
    );
    if (!mounted || submitted != true) return;
    _snack(
      'Demande envoyée. Votre accès est mis en pause pendant le traitement.',
    );
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  Widget _buildEditPanel() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            padding: EdgeInsets.zero,
            title: 'Modifier mon profil',
            subtitle: 'Ces informations personnalisent ton espace client',
          ),
          const SizedBox(height: 14),
          _ProfileField(
            label: 'Nom complet',
            icon: Icons.person_rounded,
            controller: _nameController,
          ),
          _ProfileField(
            label: 'Ville',
            icon: Icons.location_on_outlined,
            controller: _cityController,
          ),
          _ProfileField(
            label: 'Bio',
            icon: Icons.notes_rounded,
            controller: _bioController,
            maxLines: 3,
          ),
          _ProfileField(
            label: 'Email',
            icon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          _ProfileField(
            label: 'Téléphone',
            icon: Icons.phone_outlined,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          PaymentMethodsEditor(
            enabled: true,
            methods: _paymentMethods,
            title: 'Paiements',
            subtitle: 'Retraits vide-dressing',
            emptyLabel: 'Aucun moyen de retrait',
            warningLabel: 'Ajoutez un numéro pour recevoir vos ventes.',
            onChanged: (methods) => setState(() => _paymentMethods = methods),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isSaving
                          ? null
                          : () => setState(() => _isEditing = false),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfileChanges,
                  icon:
                      _isSaving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.check_rounded),
                  label: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _syncControllers(_ProfileData profile) {
    if (_isEditing) return;
    _nameController.text = profile.displayName;
    _bioController.text = profile.bio;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
    _cityController.text = profile.city;
    _paymentMethods = Map<String, String>.from(profile.paymentMethods);
  }

  Future<void> _toggleEditOrSave() async {
    if (_isEditing) {
      await _saveProfileChanges();
    } else {
      setState(() => _isEditing = true);
    }
  }

  Future<void> _saveProfileChanges() async {
    final userId = _currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      final paymentMethods = Map<String, String>.from(_paymentMethods);
      await _firestore.collection('users').doc(userId).set({
        'clientName': _nameController.text.trim(),
        'name': _nameController.text.trim(),
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'paymentMethods': paymentMethods,
        'clientProfile.paymentMethods': paymentMethods,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (_emailController.text.trim().isNotEmpty &&
          _emailController.text.trim() != _currentUser?.email) {
        await _currentUser?.verifyBeforeUpdateEmail(
          _emailController.text.trim(),
        );
      }

      if (!mounted) return;
      setState(() => _isEditing = false);
      _snack('Profil mis à jour.');
    } catch (error) {
      if (!mounted) return;
      _snack('Impossible de mettre à jour le profil.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeProfilePhoto() async {
    await _pickAndUploadImage(kind: 'avatar');
  }

  Future<void> _changeCoverPhoto() async {
    await _pickAndUploadImage(kind: 'cover');
  }

  Future<void> _pickAndUploadImage({required String kind}) async {
    final userId = _currentUser?.uid;
    if (!_isCurrentUserProfile || userId == null) return;

    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
    );
    if (pickedFile == null) return;

    setState(() => _isSaving = true);
    try {
      final upload = await _mediaUploadService.uploadImage(
        file: File(pickedFile.path),
        folder: 'profiles/$userId',
        publicId: '${kind}_${DateTime.now().millisecondsSinceEpoch}',
      );
      final mediaId = await MediaAssetService().recordUpload(
        upload: upload,
        ownerId: userId,
        ownerRole: 'client',
        usage: kind == 'cover' ? 'profile_cover' : 'profile_avatar',
        status: 'public',
        linkedCollection: 'users',
        linkedDocumentId: userId,
      );
      final media = upload.copyWithAssetId(mediaId);
      final field = kind == 'cover' ? 'coverPhoto' : 'photoUrl';
      final displayUrl =
          kind == 'cover'
              ? media.optimizedUrl
              : MediaUploadService.avatarUrl(media.url);
      await _firestore.collection('users').doc(userId).set({
        field: displayUrl,
        'media.${kind == 'cover' ? 'coverImage' : 'profileImage'}':
            media.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (kind == 'avatar') await _currentUser?.updatePhotoURL(displayUrl);
      if (!mounted) return;
      _snack(
        kind == 'cover' ? 'Couverture mise à jour.' : 'Photo mise à jour.',
      );
    } catch (error) {
      if (!mounted) return;
      debugPrint('Upload profil client impossible: $error');
      _snack('Upload impossible: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _toggleFollowProfile(_ProfileData profile) async {
    try {
      await _followService.toggleFollow(
        talentId: profile.id,
        talentName: profile.displayName,
      );
    } catch (_) {
      if (!mounted) return;
      _snack('Connexion requise pour suivre ce profil.');
    }
  }
}

class _FollowProfileButton extends StatelessWidget {
  const _FollowProfileButton({required this.profile});

  final _ProfileData profile;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_ClientProfileScreenState>();
    final service = state?._followService ?? FollowService();
    return StreamBuilder<bool>(
      stream: service.watchFollowing(profile.id),
      builder: (context, snapshot) {
        final following = snapshot.data == true;
        return ElevatedButton.icon(
          onPressed: () => state?._toggleFollowProfile(profile),
          icon: Icon(
            following ? Icons.check_rounded : Icons.person_add_alt_rounded,
            size: 18,
          ),
          label: Text(following ? 'Suivi' : 'Suivre'),
        );
      },
    );
  }
}

class _ProfileData {
  final String id;
  final String displayName;
  final String email;
  final String phone;
  final String bio;
  final String city;
  final String currency;
  final Map<String, String> paymentMethods;
  final String photoUrl;
  final String coverPhoto;
  final int followersCount;
  final int followingCount;

  const _ProfileData({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.bio,
    required this.city,
    required this.currency,
    this.paymentMethods = const {},
    required this.photoUrl,
    required this.coverPhoto,
    required this.followersCount,
    required this.followingCount,
  });

  factory _ProfileData.fromSummary(ClientDashboardSummary summary) {
    final user = FirebaseAuth.instance.currentUser;
    return _ProfileData(
      id: summary.userId,
      displayName:
          summary.displayName.trim().isEmpty ? 'Client' : summary.displayName,
      email: summary.email,
      phone: summary.phone,
      bio: summary.bio,
      city: summary.city,
      currency: CurrencyService.defaultCode,
      paymentMethods: summary.paymentMethods,
      photoUrl: summary.photoUrl,
      coverPhoto: summary.coverPhoto,
      followersCount: summary.followersCount,
      followingCount: summary.followingCount,
    ).copyWithFromAuth(user);
  }

  factory _ProfileData.fromUserDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return _ProfileData(
      id: doc.id,
      displayName:
          data['clientName']?.toString() ??
          data['displayName']?.toString() ??
          data['name']?.toString() ??
          'Client',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      bio: data['bio']?.toString() ?? '',
      city:
          data['city']?.toString() ??
          data['ville']?.toString() ??
          data['location']?.toString() ??
          '',
      currency: CurrencyService.currencyFromUserData(data),
      paymentMethods: _readPaymentMethods(data),
      photoUrl:
          data['photoUrl']?.toString() ??
          data['photoURL']?.toString() ??
          data['avatar']?.toString() ??
          '',
      coverPhoto: data['coverPhoto']?.toString() ?? '',
      followersCount: (data['followers'] as List?)?.length ?? 0,
      followingCount: (data['following'] as List?)?.length ?? 0,
    );
  }

  _ProfileData copyWithFromAuth(User? user) {
    return _ProfileData(
      id: id,
      displayName:
          displayName == 'Client' && (user?.displayName?.isNotEmpty ?? false)
              ? user!.displayName!
              : displayName,
      email: email.isEmpty ? user?.email ?? '' : email,
      phone: phone,
      bio: bio,
      city: city,
      currency: currency,
      paymentMethods: paymentMethods,
      photoUrl: photoUrl.isEmpty ? user?.photoURL ?? '' : photoUrl,
      coverPhoto: coverPhoto,
      followersCount: followersCount,
      followingCount: followingCount,
    );
  }

  static Map<String, String> _readPaymentMethods(Map<String, dynamic> data) {
    final clientProfile = Map<String, dynamic>.from(
      data['clientProfile'] ?? const {},
    );
    final methods = <String, String>{
      ..._stringMap(data['paymentMethods']),
      ..._stringMap(clientProfile['paymentMethods']),
    };
    final method = data['paymentMethod']?.toString() ?? '';
    final number = data['paymentNumber']?.toString() ?? '';
    if (method.trim().isNotEmpty && number.trim().isNotEmpty) {
      methods[_paymentMethodLabel(method)] = number.trim();
    }
    return methods;
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    return value.map(
      (key, entry) => MapEntry(key.toString(), entry?.toString() ?? ''),
    )..removeWhere((key, entry) => key.trim().isEmpty || entry.trim().isEmpty);
  }

  static String _paymentMethodLabel(String value) {
    return switch (value.trim().toLowerCase()) {
      'orange_money' => 'Orange Money',
      'moov_money' => 'Moov Money',
      'wave' => 'Wave',
      'mobile_money' => 'Mobile Money',
      _ => value.trim().isEmpty ? 'Paiement mobile' : value.trim(),
    };
  }
}

class _ProfileHero extends StatelessWidget {
  final _ProfileData profile;
  final bool canEdit;
  final VoidCallback onChangeAvatar;
  final VoidCallback onChangeCover;

  const _ProfileHero({
    required this.profile,
    required this.canEdit,
    required this.onChangeAvatar,
    required this.onChangeCover,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _CoverBackground(profile: profile),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.04),
                Colors.black.withValues(alpha: 0.48),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: canEdit ? onChangeAvatar : null,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: ModernColors.canvas,
                        backgroundImage:
                            profile.photoUrl.isEmpty
                                ? null
                                : CachedNetworkImageProvider(profile.photoUrl),
                        child:
                            profile.photoUrl.isEmpty
                                ? const Icon(
                                  Icons.person_rounded,
                                  color: ModernColors.primary,
                                  size: 38,
                                )
                                : null,
                      ),
                    ),
                    if (canEdit)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: ModernColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/logo/logo.svg',
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Profil client',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (canEdit)
                IconButton.filledTonal(
                  onPressed: onChangeCover,
                  tooltip: 'Changer la couverture',
                  icon: const Icon(Icons.wallpaper_rounded),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoverBackground extends StatelessWidget {
  final _ProfileData profile;

  const _CoverBackground({required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.coverPhoto.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: profile.coverPhoto,
        fit: BoxFit.cover,
        placeholder: (_, _) => const _PremiumFallbackCover(),
        errorWidget: (_, _, _) => const _PremiumFallbackCover(),
      );
    }
    return const _PremiumFallbackCover();
  }
}

class _PremiumFallbackCover extends StatelessWidget {
  const _PremiumFallbackCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ModernColors.primary,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ModernColors.primary,
                    ModernColors.client.withValues(alpha: 0.78),
                    ModernColors.accent.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            right: 24,
            top: 78,
            child: Icon(
              Icons.checkroom_rounded,
              color: Colors.white24,
              size: 92,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _StatTile extends StatelessWidget {
  final _ProfileStat stat;

  const _StatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(stat.icon, color: stat.color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = ModernColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const SizedBox(width: 2),
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  const _ProfileField({
    required this.label,
    required this.icon,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  final bool showBackButton;

  const _ProfileSkeleton({required this.showBackButton});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar:
          showBackButton ? AppBar(backgroundColor: ModernColors.canvas) : null,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder:
            (_, index) => Container(
              height: index == 0 ? 210 : 78,
              decoration: BoxDecoration(
                color: ModernColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ModernColors.line),
              ),
            ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProfileError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_off_rounded,
                  color: ModernColors.rose,
                  size: 36,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Profil indisponible',
                  style: TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
