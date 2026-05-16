import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:elegantfaso/services/media/media_asset_service.dart';
import 'package:elegantfaso/services/media/media_upload_service.dart';
import 'package:elegantfaso/services/commerce/pro_access_service.dart';
import 'package:elegantfaso/core/account_roles.dart';
import 'package:elegantfaso/design/app_icons.dart';
import 'package:elegantfaso/design/ecommerce_widgets.dart';
import 'package:elegantfaso/models/community/community_access_policy.dart';
import 'package:elegantfaso/models/community/community_group.dart';
import 'package:elegantfaso/views/widgets/forms/app_responsive_field_row.dart';
import 'package:elegantfaso/views/widgets/forms/app_select_field.dart';
import 'package:elegantfaso/views/widgets/forms/app_text_field.dart';
part 'community_reply_modals.dart';
part 'community_media_widgets.dart';
part 'community_question_widgets.dart';
part 'community_question_card.dart';
part 'community_video_viewer.dart';
part 'community_question_modal.dart';
part 'community_replies_widgets.dart';
part 'community_fullscreen_viewer.dart';

class AppColors {
  static const Color primary = Color(0xFF0F766E);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color accent = Color(0xFFF59E0B);
  static const Color rose = Color(0xFFE11D48);
  static const Color ink = Color(0xFF111827);
  static const Color inkSoft = Color(0xFF4B5563);
  static const Color muted = Color(0xFF9CA3AF);
  static const Color line = Color(0xFFE5E7EB);
  static const Color background = Color(0xFFF6F7F9);
  static const Color surface = Colors.white;
  static const Color surfaceRaised = Color(0xFFFBFCFD);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF16A34A);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = ink;
  static const Color onSurface = ink;
  static const Color onError = Colors.white;

  static Color primaryLight = primary.withValues(alpha: 0.1);
  static Color secondaryLight = secondary.withValues(alpha: 0.1);
  static Color accentLight = accent.withValues(alpha: 0.1);
  static Color roseLight = rose.withValues(alpha: 0.1);

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x140F172A),
      offset: Offset(0, 14),
      blurRadius: 28,
      spreadRadius: -16,
    ),
  ];

  static const LinearGradient communityGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
}

class _CommunityCreateSheet extends StatefulWidget {
  const _CommunityCreateSheet();

  @override
  State<_CommunityCreateSheet> createState() => _CommunityCreateSheetState();
}

class _CommunityCreateSheetState extends State<_CommunityCreateSheet> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
  final _whyController = TextEditingController();
  String _category = 'Mode';
  String _accessMode = CommunityGroupAccessModes.request;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _whyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.55,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Créer une communauté',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Un espace clair pour réunir une ville, un métier ou un style.',
                style: TextStyle(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              _sheetField(
                controller: _nameController,
                label: 'Nom',
                hint: 'Abidjan Coiffure, Dakar Mariage...',
                icon: Icons.groups_3_rounded,
              ),
              const SizedBox(height: 12),
              AppSelectField<String>(
                value: _category,
                items: const [
                  'Mode',
                  'Coiffure',
                  'Mariage',
                  'Beauté',
                  'Chaussures',
                  'Textile',
                  'Créateurs',
                  'Boutiques',
                ],
                label: 'Catégorie',
                icon: Icons.category_rounded,
                onChanged:
                    (value) => setState(() => _category = value ?? 'Mode'),
              ),
              const SizedBox(height: 12),
              AppResponsiveFieldRow(
                children: [
                  _sheetField(
                    controller: _cityController,
                    label: 'Ville',
                    hint: 'Abidjan',
                    icon: Icons.location_city_rounded,
                  ),
                  _sheetField(
                    controller: _countryController,
                    label: 'Pays',
                    hint: 'Côte d’Ivoire',
                    icon: Icons.public_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppSelectField<String>(
                value: _accessMode,
                items: const [
                  CommunityGroupAccessModes.open,
                  CommunityGroupAccessModes.request,
                  CommunityGroupAccessModes.inviteOnly,
                ],
                label: 'Adhésion',
                icon: Icons.verified_user_rounded,
                itemLabelBuilder:
                    (value) => switch (value) {
                      CommunityGroupAccessModes.open => 'Libre',
                      CommunityGroupAccessModes.request => 'Sur demande',
                      CommunityGroupAccessModes.inviteOnly => 'Invitation',
                      _ => value,
                    },
                onChanged:
                    (value) => setState(
                      () =>
                          _accessMode =
                              value ?? CommunityGroupAccessModes.request,
                    ),
              ),
              const SizedBox(height: 12),
              _sheetField(
                controller: _descriptionController,
                label: 'Description courte',
                hint: 'À qui s’adresse cette communauté ?',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _sheetField(
                controller: _rulesController,
                label: 'Règles',
                hint: 'Respect, entraide, pas de spam...',
                icon: Icons.rule_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _sheetField(
                controller: _whyController,
                label: 'Pourquoi cette communauté ?',
                hint: 'Expliquez en une phrase ce qu’elle apporte.',
                icon: AppIcons.inspiration,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Créer la communauté',
                onPressed: _submit,
                icon: Icons.groups_3_rounded,
                expand: true,
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (name.length < 3 || description.length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ajoutez un nom et une description un peu plus précise.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    Navigator.pop(context, {
      'name': name,
      'category': _category,
      'city': _cityController.text.trim(),
      'country': _countryController.text.trim(),
      'description': description,
      'rules': _rulesController.text.trim(),
      'reviewReason': _whyController.text.trim(),
      'accessMode': _accessMode,
    });
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      icon: icon,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}

class _CommunityGroupSheet extends StatelessWidget {
  const _CommunityGroupSheet({
    required this.group,
    required this.currentUserId,
    required this.isAdmin,
    required this.firestore,
    required this.onOpen,
    required this.onSnack,
  });

  final CommunityGroup group;
  final String? currentUserId;
  final bool isAdmin;
  final FirebaseFirestore firestore;
  final VoidCallback onOpen;
  final ValueChanged<String> onSnack;

  bool get _isOwner => group.isOwner(currentUserId);
  bool get _canModerateGlobally => isAdmin;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                group.name,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${group.category} • ${group.locationLabel} • ${group.memberCount} membres',
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                group.description,
                style: const TextStyle(
                  color: AppColors.ink,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (group.rules.isNotEmpty) ...[
                const SizedBox(height: 14),
                _infoBox(Icons.rule_rounded, 'Règles', group.rules),
              ],
              const SizedBox(height: 16),
              AppButton(
                label: 'Ouvrir les discussions',
                onPressed:
                    group.canPost(currentUserId, isAdmin: isAdmin)
                        ? onOpen
                        : null,
                icon: Icons.forum_rounded,
                expand: true,
              ),
              if (_isOwner) ...[
                const SizedBox(height: 18),
                const Text(
                  'Gestion de la communauté',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 10),
                _buildOwnerAccessControls(),
                const SizedBox(height: 14),
                const Text(
                  'Demandes d’adhésion',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                _buildJoinRequests(),
              ],
              if (_canModerateGlobally) ...[
                const SizedBox(height: 18),
                const Text(
                  'Modération globale',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 10),
                _infoBox(
                  Icons.admin_panel_settings_rounded,
                  'Intervention admin',
                  'L’admin peut protéger le Salon, mais la gestion quotidienne reste au propriétaire.',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            () => _setGroupAccess(
                              CommunityGroupAccessModes.closed,
                              'Communauté fermée par l’administration',
                            ),
                        icon: const Icon(Icons.lock_rounded),
                        label: const Text('Fermer'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            () => _setGroupStatus(
                              CommunityGroupStatuses.suspended,
                              'Communauté suspendue par l’administration',
                            ),
                        icon: const Icon(Icons.block_rounded),
                        label: const Text('Suspendre'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildOwnerAccessControls() {
    const options = {
      CommunityGroupAccessModes.open: ('Libre', Icons.lock_open_rounded),
      CommunityGroupAccessModes.request: (
        'Sur demande',
        Icons.how_to_reg_rounded,
      ),
      CommunityGroupAccessModes.inviteOnly: (
        'Invitation',
        Icons.mark_email_read_rounded,
      ),
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          options.entries.map((entry) {
            final selected = group.accessMode == entry.key;
            return ChoiceChip(
              selected: selected,
              avatar: Icon(
                entry.value.$2,
                size: 16,
                color: selected ? Colors.white : AppColors.primary,
              ),
              label: Text(entry.value.$1),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
              onSelected:
                  selected
                      ? null
                      : (_) => _setGroupAccess(
                        entry.key,
                        'Mode d’adhésion modifié par le gestionnaire',
                      ),
            );
          }).toList(),
    );
  }

  Widget _buildJoinRequests() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          firestore
              .collection('community_groups')
              .doc(group.id)
              .collection('join_requests')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (docs.isEmpty) {
          return _infoBox(
            Icons.inbox_rounded,
            'Aucune demande',
            'Les nouvelles demandes apparaîtront ici.',
          );
        }
        return Column(
          children:
              docs.map((doc) {
                final data = doc.data();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userName']?.toString() ?? 'Membre',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if ((data['message']?.toString() ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            data['message'].toString(),
                            style: const TextStyle(color: AppColors.inkSoft),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Accepter',
                              onPressed: () => _approveRequest(doc),
                              expand: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              label: 'Refuser',
                              onPressed: () => _rejectRequest(doc),
                              variant: AppButtonVariant.outline,
                              expand: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _infoBox(IconData icon, String title, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (!_isOwner) {
      onSnack('Seul le gestionnaire peut accepter les demandes');
      return;
    }
    final data = doc.data();
    final userId = data['userId']?.toString() ?? doc.id;
    final batch = firestore.batch();
    final groupRef = firestore.collection('community_groups').doc(group.id);
    batch.set(groupRef, {
      'memberIds': FieldValue.arrayUnion([userId]),
      'memberCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(groupRef.collection('members').doc(userId), {
      'userId': userId,
      'userName': data['userName'],
      'role': CommunityMemberRoles.member,
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(doc.reference, {
      'status': 'approved',
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedBy': currentUserId,
    }, SetOptions(merge: true));
    await batch.commit();
    onSnack('Membre accepté');
  }

  Future<void> _rejectRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (!_isOwner) {
      onSnack('Seul le gestionnaire peut refuser les demandes');
      return;
    }
    await doc.reference.set({
      'status': 'rejected',
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedBy': currentUserId,
    }, SetOptions(merge: true));
    onSnack('Demande refusée');
  }

  Future<void> _setGroupAccess(String accessMode, String reason) async {
    if (!_isOwner && !isAdmin) {
      onSnack('Action réservée au gestionnaire');
      return;
    }
    await firestore.collection('community_groups').doc(group.id).set({
      'accessMode': accessMode,
      'lastManagementReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
    }, SetOptions(merge: true));
    onSnack('Accès du groupe mis à jour');
  }

  Future<void> _setGroupStatus(String status, String reason) async {
    if (!isAdmin) {
      onSnack('Action réservée à la modération');
      return;
    }
    await firestore.collection('community_groups').doc(group.id).set({
      'status': status,
      'adminReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
    }, SetOptions(merge: true));
    onSnack('Statut du groupe mis à jour');
  }
}

enum MediaType { image, video, audio, text }

class MediaAttachment {
  final String url;
  final MediaType type;
  final String? filename;
  final int? duration;

  MediaAttachment({
    required this.url,
    required this.type,
    this.filename,
    this.duration,
  });
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  static const _tabFeed = 'Flux';
  static const _tabMyGroups = 'Mes groupes';
  static const _tabGroups = 'Groupes';

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MediaUploadService _mediaUploadService = MediaUploadService();
  final ImagePicker _imagePicker = ImagePicker();
  final AccountRoleService _roleService = AccountRoleService();
  final ProAccessService _proAccessService = ProAccessService();

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedCategory = 'Tout';
  final List<MediaAttachment> _selectedMedia = [];
  bool _isUploading = false;
  bool _isAdmin = false;
  String _communityTab = _tabFeed;
  String? _activeGroupId;
  String? _activeGroupName;
  CommunityGroup? _activeGroup;
  CommunityAccessPolicy _accessPolicy = CommunityAccessPolicy.open();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _communityPolicySubscription;

  final List<String> _categories = [
    'Tout',
    'Général',
    'Textiles du monde',
    'Imprimés',
    'Bijoux',
    'Coiffures',
    'Mariage',
    'Tendances',
    'Conseils',
  ];

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
    _loadCurrentRole();
    _watchCommunityPolicy();
  }

  @override
  void dispose() {
    _communityPolicySubscription?.cancel();
    _questionController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  bool get _canWriteCommunity {
    if (_activeGroup != null) {
      return _activeGroup!.canPost(_auth.currentUser?.uid, isAdmin: _isAdmin);
    }
    return _isAdmin || _accessPolicy.canWrite(_auth.currentUser?.uid);
  }

  String get _communityTitle {
    if (_activeGroup != null) return _activeGroup!.name;
    return switch (_communityTab) {
      _tabMyGroups => 'Mes groupes',
      _tabGroups => 'Groupes',
      _ => 'Flux style',
    };
  }

  String get _communitySubtitle {
    if (_activeGroup != null) {
      return '${_activeGroup!.category} • ${_activeGroup!.locationLabel}';
    }
    return switch (_communityTab) {
      _tabMyGroups => 'Espaces suivis',
      _tabGroups => 'Par ville, métier et style',
      _ => 'Avis, idées et entraide',
    };
  }

  Future<void> _loadCurrentRole() async {
    final state = await _roleService.getCurrentState();
    if (!mounted || state == null) return;
    setState(() => _isAdmin = state.hasRole(AccountRoles.admin));
  }

  void _watchCommunityPolicy() {
    _communityPolicySubscription = _firestore
        .collection('community_settings')
        .doc('main')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          setState(() {
            _accessPolicy = CommunityAccessPolicy.fromMap(snapshot.data());
          });
        });
  }

  bool _ensureCommunityWriteAccess() {
    final user = _auth.currentUser;
    if (user == null) {
      _showLoginDialog();
      return false;
    }
    if (_canWriteCommunity) return true;

    final group = _activeGroup;
    final message =
        group != null
            ? 'Rejoignez ${group.name} pour participer à cette communauté.'
            : _accessPolicy.messageFor(user.uid);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.isEmpty
              ? 'Cette discussion est limitée pour le moment.'
              : message,
        ),
        backgroundColor: AppColors.rose,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedMedia.add(
          MediaAttachment(
            url: image.path,
            type: MediaType.image,
            filename: image.name,
          ),
        );
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );

    if (video != null) {
      setState(() {
        _selectedMedia.add(
          MediaAttachment(
            url: video.path,
            type: MediaType.video,
            filename: video.name,
          ),
        );
      });
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _selectedMedia.add(
          MediaAttachment(
            url: file.path!,
            type: MediaType.audio,
            filename: file.name,
          ),
        );
      });
    }
  }

  Future<String> _uploadMedia(MediaAttachment media) async {
    final file = File(media.url);
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${media.filename ?? 'file'}';
    final String path = 'community_media/${media.type.name}/$fileName';

    final upload = await _mediaUploadService.uploadFile(
      file: file,
      folder: path,
      publicId: '${DateTime.now().millisecondsSinceEpoch}',
    );
    final user = _auth.currentUser;
    if (user != null) {
      await MediaAssetService().recordUpload(
        upload: upload,
        ownerId: user.uid,
        ownerRole: 'client',
        usage: 'community_${media.type.name}',
        status: 'public',
        linkedCollection: 'community_posts',
      );
    }
    return upload.resourceType == 'image' ? upload.optimizedUrl : upload.url;
  }

  Future<void> _postQuestion() async {
    if (_questionController.text.trim().isEmpty && _selectedMedia.isEmpty) {
      return;
    }

    if (!_ensureCommunityWriteAccess()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      List<Map<String, dynamic>> mediaUrls = [];

      for (MediaAttachment media in _selectedMedia) {
        final uploadedUrl = await _uploadMedia(media);
        mediaUrls.add({
          'url': uploadedUrl,
          'type': media.type.name,
          'filename': media.filename,
          'duration': media.duration,
        });
      }

      final now = DateTime.now();
      await _firestore.collection('community_questions').add({
        'userId': user.uid,
        'userName':
            userData['displayName'] ?? user.displayName ?? 'Utilisateur',
        'userPhoto': userData['photoURL'] ?? user.photoURL,
        'question': _questionController.text.trim(),
        'category': _selectedCategory == 'Tout' ? 'Général' : _selectedCategory,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'likesCount': 0,
        'answersCount': 0,
        'isVerified': userData['isVerified'] ?? false,
        'tags': _extractTags(_questionController.text),
        'media': mediaUrls,
        'groupId': _activeGroupId,
        'groupName': _activeGroupName,
        'status': 'published',
        'isDeleted': false,
        'isPublic': true,
        'isEditable': true,
        'editableUntil': Timestamp.fromDate(
          now.add(const Duration(minutes: 2)),
        ),
      });
      if (!mounted) return;

      _questionController.clear();
      _selectedMedia.clear();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Question publiée avec succès!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Erreur publication question communauté: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publication impossible pour le moment.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _updateQuestion(
    String questionId,
    String newQuestion,
    String newCategory,
    List<MediaAttachment> newMedia,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final questionDoc =
          await _firestore
              .collection('community_questions')
              .doc(questionId)
              .get();
      if (!questionDoc.exists) return;
      if (!mounted) return;

      final questionData = questionDoc.data()!;
      final isAuthor = questionData['userId'] == user.uid;

      if (!isAuthor && !_isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous ne pouvez modifier que vos messages.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      List<Map<String, dynamic>> mediaUrls = [];

      for (MediaAttachment media in newMedia) {
        final uploadedUrl = await _uploadMedia(media);
        mediaUrls.add({
          'url': uploadedUrl,
          'type': media.type.name,
          'filename': media.filename,
          'duration': media.duration,
        });
      }

      await _firestore
          .collection('community_questions')
          .doc(questionId)
          .update({
            'question': newQuestion,
            'category': newCategory,
            'media': mediaUrls,
            'tags': _extractTags(newQuestion),
            'editedAt': FieldValue.serverTimestamp(),
            'editedBy': user.uid,
          });
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question mise à jour avec succès!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      debugPrint('Erreur mise à jour question communauté: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mise à jour impossible pour le moment.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer la question?'),
            content: const Text(
              'La question sera retirée de la communauté. Une trace est conservée pour la modération.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final questionDoc =
          await _firestore
              .collection('community_questions')
              .doc(questionId)
              .get();
      if (!questionDoc.exists) return;
      if (!mounted) return;

      final questionData = questionDoc.data()!;
      final isAuthor = questionData['userId'] == user.uid;

      if (!isAuthor && !_isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous ne pouvez supprimer que vos messages.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      await _firestore
          .collection('community_questions')
          .doc(questionId)
          .update({
            'status': 'deleted',
            'isDeleted': true,
            'isPublic': false,
            'deletedAt': FieldValue.serverTimestamp(),
            'deletedBy': user.uid,
            'deleteReason': isAuthor ? 'deleted_by_author' : 'deleted_by_admin',
          });
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question supprimée avec succès!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      debugPrint('Erreur suppression question communauté: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suppression impossible pour le moment.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<String> _extractTags(String text) {
    final words = text.toLowerCase().split(' ');
    final tags = <String>[];
    final keywords = [
      'textile',
      'imprimé',
      'artisanat',
      'bijoux',
      'mariage',
      'traditionnel',
      'moderne',
    ];

    for (final word in words) {
      for (final keyword in keywords) {
        if (word.contains(keyword)) {
          tags.add(keyword);
        }
      }
    }
    return tags.toSet().toList();
  }

  String _slugify(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Connexion requise'),
            content: const Text(
              'Veuillez vous connecter pour poser une question.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildSearchBar(),
          _buildCommunityTabs(),
          if (!_canWriteCommunity) _buildAccessNotice(),
          if (_communityTab == _tabFeed) ...[
            if (_activeGroup != null) _buildActiveGroupBanner(),
            _buildCategoryFilter(),
            _buildQuestionsList(),
          ] else if (_communityTab == _tabMyGroups) ...[
            _buildMyCommunities(),
          ] else ...[
            _buildCommunityDiscovery(),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: FloatingActionButton.extended(
              onPressed:
                  _communityTab == _tabGroups || _communityTab == _tabMyGroups
                      ? _showCreateCommunityForm
                      : _canWriteCommunity
                      ? () => _showQuestionModal()
                      : null,
              backgroundColor:
                  (_communityTab == _tabGroups ||
                          _communityTab == _tabMyGroups ||
                          _canWriteCommunity)
                      ? AppColors.ink
                      : AppColors.muted,
              foregroundColor: AppColors.onPrimary,
              icon: Icon(
                _communityTab == _tabGroups || _communityTab == _tabMyGroups
                    ? Icons.group_add_rounded
                    : Icons.chat_bubble_outline_rounded,
              ),
              label: Text(
                _communityTab == _tabGroups || _communityTab == _tabMyGroups
                    ? 'Créer'
                    : _activeGroup == null
                    ? 'Poser'
                    : 'Publier',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              heroTag: null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 136,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(
          start: 56,
          end: 64,
          bottom: 12,
        ),
        title: Text(
          _activeGroupName ?? 'Communauté',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 0,
          ),
        ),
        background: Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(16, 72, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.line),
              boxShadow: AppColors.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _communityTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 17,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _communitySubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildHeroPill(Icons.chat_bubble_outline_rounded, 'Avis'),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton.filledTonal(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeroPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child:
            _isSearching
                ? Container(
                  key: const ValueKey('community-search'),
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText:
                          _communityTab == _tabGroups
                              ? 'Chercher une communauté, une ville...'
                              : 'Chercher une question, un style...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon:
                          _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                onPressed:
                                    () => setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    }),
                                icon: const Icon(Icons.close_rounded),
                              ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                )
                : const SizedBox.shrink(key: ValueKey('community-no-search')),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SliverToBoxAdapter(
      child: Container(
        height: 58,
        margin: const EdgeInsets.fromLTRB(0, 8, 0, 10),
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = category == _selectedCategory;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                avatar: Icon(
                  _categoryIcon(category),
                  size: 17,
                  color: isSelected ? Colors.white : AppColors.inkSoft,
                ),
                label: Text(category),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCategory = category),
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.primary,
                disabledColor: AppColors.surface,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.line,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                elevation: 0,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.inkSoft,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCommunityTabs() {
    const tabs = [_tabFeed, _tabGroups, _tabMyGroups];
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final selected = tab == _communityTab;
            final icon = switch (tab) {
              _tabFeed => Icons.chat_bubble_outline_rounded,
              _tabMyGroups => Icons.groups_rounded,
              _ => Icons.explore_outlined,
            };
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap:
                    () => setState(() {
                      _communityTab = tab;
                      if (tab != _tabFeed) {
                        _activeGroup = null;
                        _activeGroupId = null;
                        _activeGroupName = null;
                      }
                    }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: selected ? Colors.white : AppColors.inkSoft,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.inkSoft,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActiveGroupBanner() {
    final group = _activeGroup;
    if (group == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.groups_3_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        group.locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      () => setState(() {
                        _activeGroup = null;
                        _activeGroupId = null;
                        _activeGroupName = null;
                      }),
                  icon: const Icon(Icons.public_rounded, size: 16),
                  label: const Text('Flux'),
                ),
              ],
            ),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                group.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccessNotice() {
    final message = _accessPolicy.messageFor(_auth.currentUser?.uid);
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.roseLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.rose.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_clock_rounded, color: AppColors.rose),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message.isEmpty
                    ? 'Publication limitée pour le moment.'
                    : message,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Tout':
        return AppIcons.inspiration;
      case 'Général':
        return Icons.forum_rounded;
      case 'Textiles du monde':
        return Icons.texture_rounded;
      case 'Imprimés':
        return AppIcons.style;
      case 'Bijoux':
        return AppIcons.save;
      case 'Coiffures':
        return Icons.face_retouching_natural_rounded;
      case 'Mariage':
        return Icons.favorite_rounded;
      case 'Tendances':
        return Icons.trending_up_rounded;
      case 'Conseils':
        return AppIcons.inspiration;
      default:
        return Icons.style_rounded;
    }
  }

  Widget _buildCommunityDiscovery() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          _firestore
              .collection('community_groups')
              .where('status', isEqualTo: CommunityGroupStatuses.approved)
              .limit(30)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildShimmerCard(),
              childCount: 3,
            ),
          );
        }
        final groups =
            snapshot.data?.docs.map(CommunityGroup.fromDoc).toList() ?? [];
        groups.sort((a, b) => b.memberCount.compareTo(a.memberCount));
        final visibleGroups = _filterGroups(groups);
        return SliverList(
          delegate: SliverChildListDelegate([
            _buildCreateCommunityCard(),
            if (visibleGroups.isEmpty)
              _buildStatePanel(
                icon: Icons.travel_explore_rounded,
                title:
                    _searchQuery.isEmpty
                        ? 'Aucune communauté validée'
                        : 'Aucune communauté trouvée',
                message:
                    _searchQuery.isEmpty
                        ? 'Propose un groupe par ville, métier ou style.'
                        : 'Essaie une autre ville, catégorie ou spécialité.',
                color: AppColors.primary,
              )
            else
              ...visibleGroups.map(_buildCommunityGroupCard),
          ]),
        );
      },
    );
  }

  Widget _buildMyCommunities() {
    final user = _auth.currentUser;
    if (user == null) {
      return SliverToBoxAdapter(
        child: _buildStatePanel(
          icon: Icons.login_rounded,
          title: 'Connexion requise',
          message:
              'Connectez-vous pour retrouver vos communautés, gérer vos groupes et suivre vos demandes.',
          color: AppColors.primary,
        ),
      );
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          _firestore
              .collection('community_groups')
              .where('memberIds', arrayContains: user.uid)
              .limit(30)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildShimmerCard(),
              childCount: 3,
            ),
          );
        }
        final groups =
            snapshot.data?.docs.map(CommunityGroup.fromDoc).toList() ?? [];
        final visibleGroups = _filterGroups(groups);
        return SliverList(
          delegate: SliverChildListDelegate([
            if (visibleGroups.isEmpty)
              _buildStatePanel(
                icon: AppIcons.talents,
                title:
                    _searchQuery.isEmpty
                        ? 'Aucune communauté rejointe'
                        : 'Aucune communauté trouvée',
                message:
                    _searchQuery.isEmpty
                        ? 'Explore les communautés validées ou propose ton propre espace thématique.'
                        : 'Ajuste ta recherche pour retrouver un groupe suivi.',
                color: AppColors.secondary,
              )
            else
              ...visibleGroups.map(_buildCommunityGroupCard),
          ]),
        );
      },
    );
  }

  List<CommunityGroup> _filterGroups(List<CommunityGroup> groups) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return groups;
    return groups.where((group) {
      final searchable =
          [
            group.name,
            group.description,
            group.category,
            group.city,
            group.country,
            group.ownerName,
          ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  Widget _buildCreateCommunityCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.group_add_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créer une communauté',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ville, métier ou style. Validation rapide.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: _showCreateCommunityForm,
            icon: const Icon(Icons.arrow_forward_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityGroupCard(CommunityGroup group) {
    final userId = _auth.currentUser?.uid;
    final isMember = group.isMember(userId);
    final isOwner = group.isOwner(userId);
    final canPost = group.canPost(userId, isAdmin: _isAdmin);
    final ctaLabel =
        canPost
            ? 'Ouvrir'
            : group.accessMode == CommunityGroupAccessModes.open
            ? 'Rejoindre'
            : 'Demander accès';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 96,
            decoration: BoxDecoration(gradient: AppColors.communityGradient),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  top: -28,
                  child: Icon(
                    Icons.groups_3_rounded,
                    color: Colors.white.withValues(alpha: 0.16),
                    size: 130,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.groups_3_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${group.category} • ${group.locationLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isOwner || _isAdmin)
                        IconButton.filledTonal(
                          onPressed: () => _showCommunityGroupSheet(group),
                          icon: const Icon(Icons.admin_panel_settings_rounded),
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (group.description.isNotEmpty) ...[
                  Text(
                    group.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMiniChip(
                      Icons.people_rounded,
                      '${group.memberCount} membres',
                    ),
                    _buildMiniChip(
                      Icons.lock_open_rounded,
                      _groupAccessLabel(group.accessMode),
                    ),
                    if (isMember)
                      _buildMiniChip(Icons.check_circle_rounded, 'Membre'),
                    if (isOwner) _buildMiniChip(AppIcons.award, 'Gestion'),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: ctaLabel,
                        onPressed:
                            canPost
                                ? () => _openCommunityGroup(group)
                                : group.canRequestAccess(userId)
                                ? () => _requestCommunityAccess(group)
                                : null,
                        icon:
                            canPost
                                ? Icons.forum_rounded
                                : Icons.how_to_reg_rounded,
                        expand: true,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.outlined(
                      onPressed: () => _showCommunityGroupSheet(group),
                      icon: const Icon(Icons.info_outline_rounded),
                      color: AppColors.inkSoft,
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

  Widget _buildMiniChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _groupAccessLabel(String accessMode) {
    return switch (accessMode) {
      CommunityGroupAccessModes.open => 'Libre',
      CommunityGroupAccessModes.request => 'Sur demande',
      CommunityGroupAccessModes.inviteOnly => 'Invitation',
      CommunityGroupAccessModes.closed => 'Fermée',
      _ => accessMode,
    };
  }

  void _openCommunityGroup(CommunityGroup group) {
    setState(() {
      _communityTab = _tabFeed;
      _activeGroup = group;
      _activeGroupId = group.id;
      _activeGroupName = group.name;
      _selectedCategory = 'Tout';
    });
  }

  Future<void> _requestCommunityAccess(CommunityGroup group) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showLoginDialog();
      return;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? const {};
    if (group.accessMode == CommunityGroupAccessModes.open) {
      await _firestore.collection('community_groups').doc(group.id).set({
        'memberIds': FieldValue.arrayUnion([user.uid]),
        'memberCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _firestore
          .collection('community_groups')
          .doc(group.id)
          .collection('members')
          .doc(user.uid)
          .set({
            'userId': user.uid,
            'userName': userData['displayName'] ?? user.displayName ?? 'Membre',
            'role': CommunityMemberRoles.member,
            'status': 'active',
            'joinedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (!mounted) return;
      _showSuccessSnack('Vous avez rejoint ${group.name}');
      return;
    }

    final message = await _showJoinRequestDialog(group.name);
    if (message == null) return;
    await _firestore
        .collection('community_groups')
        .doc(group.id)
        .collection('join_requests')
        .doc(user.uid)
        .set({
          'userId': user.uid,
          'userName': userData['displayName'] ?? user.displayName ?? 'Membre',
          'userPhoto': userData['photoURL'] ?? user.photoURL,
          'message': message,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    if (!mounted) return;
    _showSuccessSnack('Demande envoyée au gestionnaire');
  }

  Future<String?> _showJoinRequestDialog(String groupName) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Rejoindre $groupName'),
            content: AppTextField(
              controller: controller,
              label: 'Message',
              hint: 'Ex: coiffeuse à Abidjan',
              icon: Icons.chat_bubble_outline_rounded,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Envoyer'),
              ),
            ],
          ),
    );
    controller.dispose();
    return value;
  }

  Future<void> _showCreateCommunityForm() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showLoginDialog();
      return;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? const <String, dynamic>{};
    final access = await _proAccessService.getCurrentAccess();
    if (!access.canCreateCommunity) {
      if (!mounted) return;
      _showCommunityProDialog();
      return;
    }
    final communityCount = await _proAccessService.countOwnedCommunities(
      user.uid,
    );
    if (communityCount >= access.limits.communityLimit) {
      if (!mounted) return;
      _showCommunityLimitDialog(access);
      return;
    }

    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CommunityCreateSheet(),
    );
    if (result == null) return;

    final name = result['name'] ?? '';
    final slug = _slugify('${result['city']}-${result['category']}-$name');
    final groupRef = _firestore.collection('community_groups').doc();
    final batch = _firestore.batch();
    final ownerName =
        userData['displayName']?.toString() ??
        userData['name']?.toString() ??
        user.displayName ??
        'Membre';
    final ownerPhoto =
        userData['photoURL'] ?? userData['photoUrl'] ?? user.photoURL;
    batch.set(groupRef, {
      ...result,
      'slug': slug,
      'ownerId': user.uid,
      'ownerName': ownerName,
      'ownerPhoto': ownerPhoto,
      'status': CommunityGroupStatuses.approved,
      'accessMode': result['accessMode'] ?? CommunityGroupAccessModes.request,
      'memberIds': [user.uid],
      'memberCount': 1,
      'adminValidationRequired': false,
      'autoApproved': true,
      'planTier': access.isSignature ? 'signature' : 'pro',
      'managedBy': user.uid,
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(groupRef.collection('members').doc(user.uid), {
      'userId': user.uid,
      'userName': ownerName,
      'userPhoto': ownerPhoto,
      'role': CommunityMemberRoles.owner,
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    if (!mounted) return;
    _showSuccessSnack('Communauté publiée. Vous en êtes le gestionnaire.');
  }

  void _showCommunityProDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text('Communautés Pro'),
            content: const Text(
              'La création de groupe est réservée aux comptes Pro ou Signature.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Compris'),
              ),
            ],
          ),
    );
  }

  void _showCommunityLimitDialog(ProAccessState access) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text('Limite atteinte'),
            content: Text(
              '${access.planLabel} permet ${access.limits.communityLimit} groupe(s). Signature ouvre plus d’espaces.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Compris'),
              ),
            ],
          ),
    );
  }

  void _showCommunityGroupSheet(CommunityGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _CommunityGroupSheet(
            group: group,
            currentUserId: _auth.currentUser?.uid,
            isAdmin: _isAdmin,
            firestore: _firestore,
            onOpen: () {
              Navigator.pop(context);
              _openCommunityGroup(group);
            },
            onSnack: _showSuccessSnack,
          ),
    );
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildQuestionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getQuestionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildShimmerCard(),
              childCount: 5,
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: _buildStatePanel(
              icon: Icons.cloud_off_rounded,
              title: 'Impossible de charger les échanges',
              message: '${snapshot.error}',
              color: AppColors.error,
            ),
          );
        }

        final questions = snapshot.data?.docs ?? [];

        final visibleQuestions = _filterQuestions(questions);

        if (visibleQuestions.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildStatePanel(
              icon: Icons.chat_bubble_outline_rounded,
              title:
                  _searchQuery.isEmpty
                      ? 'La conversation commence ici'
                      : 'Aucun échange trouvé',
              message:
                  _searchQuery.isEmpty
                      ? 'Pose une question ou demande un avis.'
                      : 'Essaie un autre mot-clé ou une autre catégorie.',
              color: AppColors.primary,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final questionDoc = visibleQuestions[index];
            final questionData = questionDoc.data() as Map<String, dynamic>;
            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 100)),
              curve: Curves.easeOutBack,
              child: EnhancedQuestionCard(
                questionId: questionDoc.id,
                questionData: questionData,
                currentUserId: _auth.currentUser?.uid,
                onReply:
                    (questionId) => _showReplyModal(questionId, questionData),
                onReplyToReply:
                    (questionId, replyId, userName) =>
                        _showReplyToReplyModal(questionId, replyId, userName),
                onEdit:
                    (questionId) => _showEditModal(questionId, questionData),
                onDelete: (questionId) => _deleteQuestion(questionId),
                onEditReply: _showEditReplyDialog,
                onDeleteReply: _deleteReply,
                onToggleHelpfulReply: _toggleHelpfulReply,
                canReply: _canWriteCommunity,
                isAdmin: _isAdmin,
              ),
            );
          }, childCount: visibleQuestions.length),
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterQuestions(
    List<QueryDocumentSnapshot> questions,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final visible =
        questions.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['isDeleted'] != true &&
              data['status'] != 'deleted' &&
              data['status'] != 'hidden' &&
              data['isPublic'] != false;
        }).toList();
    if (query.isEmpty) return visible;

    return visible.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final searchable =
          [
            data['question'],
            data['category'],
            data['userName'],
            ...(data['tags'] is List ? data['tags'] as List : const []),
          ].whereType<Object>().join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  Stream<QuerySnapshot> _getQuestionsStream() {
    Query query = _firestore.collection('community_questions');

    if (_activeGroupId == null) {
      query = query.where('groupId', isNull: true);
    } else {
      query = query.where('groupId', isEqualTo: _activeGroupId);
    }

    if (_selectedCategory != 'Tout') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    query = query.orderBy('timestamp', descending: true).limit(40);

    return query.snapshots();
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.softShadow,
      ),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE8ECEF),
        highlightColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 150, height: 16, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 96, height: 12, color: Colors.white),
                      ],
                    ),
                  ),
                  Container(width: 72, height: 28, color: Colors.white),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                height: 16,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Container(width: 240, height: 16, color: Colors.white),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(width: 76, height: 32, color: Colors.white),
                  const SizedBox(width: 10),
                  Container(width: 96, height: 32, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatePanel({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 42, 16, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionModal() {
    if (!_ensureCommunityWriteAccess()) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => EnhancedQuestionModal(
            controller: _questionController,
            onPost: _postQuestion,
            categories: _categories.where((c) => c != 'Tout').toList(),
            selectedMedia: _selectedMedia,
            onPickImage: _pickImage,
            onPickVideo: _pickVideo,
            onPickAudio: _pickAudio,
            onRemoveMedia: (index) {
              setState(() {
                _selectedMedia.removeAt(index);
              });
            },
            onCategoryChanged:
                (category) => setState(() => _selectedCategory = category),
            isUploading: _isUploading,
          ),
    );
  }

  void _showEditModal(String questionId, Map<String, dynamic> questionData) {
    final controller = TextEditingController(text: questionData['question']);
    var category = questionData['category'] ?? 'Général';
    _selectedMedia.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => EnhancedQuestionModal(
            controller: controller,
            onPost:
                () => _updateQuestion(
                  questionId,
                  controller.text.trim(),
                  category,
                  _selectedMedia,
                ),
            categories: _categories.where((c) => c != 'Tout').toList(),
            selectedMedia: _selectedMedia,
            onPickImage: _pickImage,
            onPickVideo: _pickVideo,
            onPickAudio: _pickAudio,
            onRemoveMedia: (index) {
              setState(() {
                _selectedMedia.removeAt(index);
              });
            },
            onCategoryChanged: (value) => category = value,
            isUploading: _isUploading,
            initialCategory: category,
            isEditing: true,
          ),
    );
  }

  void _showReplyModal(String questionId, Map<String, dynamic> questionData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ReplyModal(
            questionId: questionId,
            questionData: questionData,
            onReply: _postReply,
          ),
    );
  }

  void _showReplyToReplyModal(
    String questionId,
    String replyId,
    String userName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ReplyToReplyModal(
            questionId: questionId,
            replyId: replyId,
            userName: userName,
            onReply: _postReplyToReply,
          ),
    );
  }

  Future<void> _postReply(
    String questionId,
    String reply,
    List<MediaAttachment> media,
  ) async {
    if (!_ensureCommunityWriteAccess()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      List<Map<String, dynamic>> mediaUrls = [];

      for (MediaAttachment mediaItem in media) {
        final uploadedUrl = await _uploadMedia(mediaItem);
        mediaUrls.add({
          'url': uploadedUrl,
          'type': mediaItem.type.name,
          'filename': mediaItem.filename,
          'duration': mediaItem.duration,
        });
      }

      await _firestore
          .collection('community_questions')
          .doc(questionId)
          .collection('replies')
          .add({
            'userId': user.uid,
            'userName': userData['name'] ?? user.displayName ?? 'Utilisateur',
            'userPhoto': userData['photoUrl'] ?? user.photoURL,
            'reply': reply,
            'timestamp': FieldValue.serverTimestamp(),
            'likes': [],
            'likesCount': 0,
            'isVerified': userData['isVerified'] ?? false,
            'media': mediaUrls,
            'parentReplyId': null,
            'isHelpful': false,
            'status': 'published',
            'isDeleted': false,
          });

      await _firestore.collection('community_questions').doc(questionId).update(
        {'answersCount': FieldValue.increment(1)},
      );
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Réponse publiée avec succès!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Erreur publication réponse communauté: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réponse impossible pour le moment.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _postReplyToReply(
    String questionId,
    String parentReplyId,
    String reply,
    List<MediaAttachment> media,
  ) async {
    if (!_ensureCommunityWriteAccess()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      List<Map<String, dynamic>> mediaUrls = [];

      for (MediaAttachment mediaItem in media) {
        final uploadedUrl = await _uploadMedia(mediaItem);
        mediaUrls.add({
          'url': uploadedUrl,
          'type': mediaItem.type.name,
          'filename': mediaItem.filename,
          'duration': mediaItem.duration,
        });
      }

      await _firestore
          .collection('community_questions')
          .doc(questionId)
          .collection('replies')
          .add({
            'userId': user.uid,
            'userName': userData['name'] ?? user.displayName ?? 'Utilisateur',
            'userPhoto': userData['photoUrl'] ?? user.photoURL,
            'reply': reply,
            'timestamp': FieldValue.serverTimestamp(),
            'likes': [],
            'likesCount': 0,
            'isVerified': userData['isVerified'] ?? false,
            'media': mediaUrls,
            'parentReplyId': parentReplyId,
            'isHelpful': false,
            'status': 'published',
            'isDeleted': false,
          });

      await _firestore.collection('community_questions').doc(questionId).update(
        {'answersCount': FieldValue.increment(1)},
      );
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Réponse publiée avec succès!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Erreur publication sous-réponse communauté: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réponse impossible pour le moment.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showEditReplyDialog(
    String questionId,
    String replyId,
    String currentText,
  ) async {
    final controller = TextEditingController(text: currentText);
    final updatedText = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Modifier la réponse'),
            content: AppTextField(
              controller: controller,
              label: 'Réponse',
              hint: 'Ajustez votre réponse',
              icon: Icons.reply_rounded,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
    controller.dispose();
    if (updatedText == null || updatedText.isEmpty) return;
    await _updateReply(questionId, replyId, updatedText);
  }

  Future<void> _updateReply(
    String questionId,
    String replyId,
    String updatedText,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final replyRef = _firestore
        .collection('community_questions')
        .doc(questionId)
        .collection('replies')
        .doc(replyId);
    final replyDoc = await replyRef.get();
    final data = replyDoc.data();
    if (data == null) return;

    if (data['userId'] != user.uid && !_isAdmin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez modifier que vos réponses.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await replyRef.update({
      'reply': updatedText,
      'editedAt': FieldValue.serverTimestamp(),
      'editedBy': user.uid,
    });
  }

  Future<void> _toggleHelpfulReply(
    String questionId,
    String replyId,
    bool helpful,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final questionRef = _firestore
        .collection('community_questions')
        .doc(questionId);
    final questionDoc = await questionRef.get();
    final questionData = questionDoc.data();
    if (questionData == null) return;

    final canHighlight = _isAdmin || questionData['userId'] == user.uid;
    if (!canHighlight) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seul l’auteur peut choisir une réponse utile.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final repliesRef = questionRef.collection('replies');
    final batch = _firestore.batch();
    if (helpful) {
      final currentHelpful =
          await repliesRef.where('isHelpful', isEqualTo: true).limit(10).get();
      for (final doc in currentHelpful.docs) {
        if (doc.id != replyId) {
          batch.update(doc.reference, {
            'isHelpful': false,
            'helpfulRemovedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    final replyRef = repliesRef.doc(replyId);
    batch.update(replyRef, {
      'isHelpful': helpful,
      'helpfulBy': helpful ? user.uid : FieldValue.delete(),
      'helpfulAt': helpful ? FieldValue.serverTimestamp() : FieldValue.delete(),
    });
    batch.update(questionRef, {
      'helpfulReplyId': helpful ? replyId : FieldValue.delete(),
      'hasHelpfulReply': helpful,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          helpful ? 'Réponse mise en avant.' : 'Mise en avant retirée.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteReply(String questionId, String replyId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer la réponse?'),
            content: const Text(
              'Elle sera retirée de la discussion, avec une trace pour la modération.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.rose),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    final replyRef = _firestore
        .collection('community_questions')
        .doc(questionId)
        .collection('replies')
        .doc(replyId);
    final replyDoc = await replyRef.get();
    final data = replyDoc.data();
    if (data == null) return;

    if (data['userId'] != user.uid && !_isAdmin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez supprimer que vos réponses.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await replyRef.update({
      'status': 'deleted',
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': user.uid,
      'deleteReason':
          data['userId'] == user.uid ? 'deleted_by_author' : 'deleted_by_admin',
    });
    await _firestore.collection('community_questions').doc(questionId).update({
      'answersCount': FieldValue.increment(-1),
    });
  }
}
