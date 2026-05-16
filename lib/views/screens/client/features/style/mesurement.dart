import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../../../../../models/measurements/measurement_profile.dart';
import '../../../../../services/measurements/measurement_service.dart';
import '../../../../widgets/forms/app_responsive_field_row.dart';
import '../../../../widgets/forms/app_select_field.dart';
import '../../../../widgets/forms/app_text_field.dart';

class ProfileMeasurementsPage extends StatefulWidget {
  const ProfileMeasurementsPage({super.key});

  @override
  State<ProfileMeasurementsPage> createState() =>
      _ProfileMeasurementsPageState();
}

class _ProfileMeasurementsPageState extends State<ProfileMeasurementsPage>
    with TickerProviderStateMixin {
  final MeasurementService _service = MeasurementService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _braController = TextEditingController();
  final TextEditingController _cupController = TextEditingController();

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _advancedMode = false;
  String _unitSystem = 'cm';
  String _shoeUnit = 'EU';
  String _bodyProfile = '';
  MeasurementProfile? _profileCache;

  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _primaryDark = Color(0xFF115E59);
  static const Color _amberAccent = Color(0xFFF59E0B);
  static const Color _roseAccent = Color(0xFFE11D48);
  static const Color _blueInfo = Color(0xFF2563EB);
  static const Color _successGreen = Color(0xFF16A34A);
  static const Color _errorRed = Color(0xFFDC2626);
  static const Color _bgColor = Color(0xFFF3F5F7);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF1F2933);
  static const Color _textSecondary = Color(0xFF7B8492);
  static const Color _borderColor = Color(0xFFE4E8EE);

  static const List<_MeasurementFieldDefinition> _fields = [
    _MeasurementFieldDefinition(
      key: 'tour_poitrine',
      label: 'Tour poitrine',
      group: 'Haut du corps',
      icon: FeatherIcons.user,
      min: 40,
      max: 180,
      essential: true,
      guideTitle: 'Tour de poitrine',
      guide:
          'Mesurez horizontalement au niveau le plus fort de la poitrine, sans trop serrer.',
      tip:
          'Respirez normalement et gardez le mètre ruban bien parallèle au sol.',
    ),
    _MeasurementFieldDefinition(
      key: 'largeur_epaules',
      label: 'Largeur épaules',
      group: 'Haut du corps',
      icon: FeatherIcons.maximize2,
      min: 25,
      max: 80,
      essential: true,
      guideTitle: 'Largeur d’épaules',
      guide: 'Mesurez d’un bout d’épaule à l’autre, idéalement par le dos.',
      tip: 'Demandez de l’aide pour une mesure plus fiable.',
    ),
    _MeasurementFieldDefinition(
      key: 'longueur_bras',
      label: 'Longueur bras',
      group: 'Haut du corps',
      icon: FeatherIcons.move,
      min: 35,
      max: 100,
      guideTitle: 'Longueur de bras',
      guide: 'Mesurez de l’épaule jusqu’au poignet.',
      tip: 'Gardez le bras légèrement fléchi pour plus de confort.',
    ),
    _MeasurementFieldDefinition(
      key: 'tour_bras',
      label: 'Tour bras',
      group: 'Haut du corps',
      icon: FeatherIcons.circle,
      min: 15,
      max: 80,
      guideTitle: 'Tour de bras',
      guide: 'Mesurez la partie la plus large du bras.',
      tip: 'Le bras doit rester détendu le long du corps.',
    ),
    _MeasurementFieldDefinition(
      key: 'tour_taille',
      label: 'Tour taille',
      group: 'Bas du corps',
      icon: FeatherIcons.minimize2,
      min: 40,
      max: 180,
      essential: true,
      guideTitle: 'Tour de taille',
      guide: 'Mesurez à l’endroit le plus étroit de la taille.',
      tip: 'Ne rentrez pas le ventre, l’objectif est un vêtement confortable.',
    ),
    _MeasurementFieldDefinition(
      key: 'tour_hanches',
      label: 'Tour hanches',
      group: 'Bas du corps',
      icon: FeatherIcons.disc,
      min: 45,
      max: 200,
      essential: true,
      guideTitle: 'Tour de hanches',
      guide: 'Mesurez à la partie la plus large des hanches.',
      tip: 'Tenez-vous debout, pieds joints.',
    ),
    _MeasurementFieldDefinition(
      key: 'longueur_jambe',
      label: 'Longueur jambe',
      group: 'Bas du corps',
      icon: FeatherIcons.move,
      min: 45,
      max: 140,
      essential: true,
      guideTitle: 'Longueur de jambe',
      guide:
          'Mesurez de la taille jusqu’à la cheville ou au sol selon l’usage.',
      tip: 'Pour un pantalon, mesurez aussi l’entrejambe si nécessaire.',
    ),
    _MeasurementFieldDefinition(
      key: 'tour_cuisse',
      label: 'Tour cuisse',
      group: 'Bas du corps',
      icon: Icons.circle,
      min: 25,
      max: 110,
      guideTitle: 'Tour de cuisse',
      guide: 'Mesurez la partie la plus large de la cuisse.',
      tip: 'Gardez le poids bien réparti sur les deux jambes.',
    ),
    _MeasurementFieldDefinition(
      key: 'tour_cou',
      label: 'Tour cou',
      group: 'Confort',
      icon: FeatherIcons.circle,
      min: 20,
      max: 70,
      guideTitle: 'Tour de cou',
      guide: 'Mesurez autour de la base du cou.',
      tip: 'Laissez l’espace d’un doigt pour le confort des cols.',
    ),
    _MeasurementFieldDefinition(
      key: 'pointure',
      label: 'Pointure',
      group: 'Tailles',
      icon: FeatherIcons.compass,
      min: 15,
      max: 55,
      guideTitle: 'Pointure',
      guide: 'Indiquez votre pointure habituelle.',
      tip: 'Choisissez le système de pointure adapté : EU, US ou UK.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final field in _fields) {
      _controllers[field.key] = TextEditingController();
    }
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animationController = animationController;
    _fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic),
    );
    animationController.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _braController.dispose();
    _cupController.dispose();
    super.dispose();
  }

  void _syncControllers(MeasurementProfile profile) {
    if (_isEditing) return;
    _profileCache = profile;
    for (final field in _fields) {
      final value = profile.values[field.key];
      _controllers[field.key]?.text = value == null ? '' : '$value';
    }
    _braController.text = profile.braSize;
    _cupController.text = profile.cup;
    _unitSystem = _normalizeSelection(profile.unitSystem, const [
      'cm',
      'inch',
    ], fallback: 'cm');
    _shoeUnit = _normalizeSelection(profile.shoeUnit, const [
      'EU',
      'US',
      'UK',
    ], fallback: 'EU');
    _bodyProfile = profile.bodyProfile;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return _buildSignedOutState();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        foregroundColor: _textPrimary,
        elevation: 0,
        title: const Text(
          'Mes mesures',
          style: TextStyle(fontWeight: FontWeight.w900, color: _textPrimary),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              tooltip: 'Modifier',
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(FeatherIcons.edit2),
            )
          else
            IconButton(
              tooltip: 'Annuler',
              onPressed: _cancelEditing,
              icon: const Icon(FeatherIcons.x),
            ),
        ],
      ),
      body: StreamBuilder<MeasurementBundle>(
        stream: _service.watchBundle(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return _buildLoadingState();
          }

          final bundle = snapshot.data!;
          final profile = bundle.profile;
          final shares = bundle.shares;
          _syncControllers(profile);

          return RefreshIndicator(
            color: _primaryColor,
            onRefresh: () async => setState(() {}),
            child: FadeTransition(
              opacity:
                  _fadeAnimation ?? const AlwaysStoppedAnimation<double>(1),
              child: SlideTransition(
                position:
                    _slideAnimation ??
                    const AlwaysStoppedAnimation<Offset>(Offset.zero),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildSummaryHeader(user, profile, shares),
                    ),
                    SliverToBoxAdapter(child: _buildModeAndUnits(profile)),
                    SliverToBoxAdapter(child: _buildSharesSection(shares)),
                    SliverToBoxAdapter(child: _buildMeasurementSections()),
                    if (_isEditing)
                      SliverToBoxAdapter(child: _buildAdviceCard()),
                    const SliverToBoxAdapter(child: SizedBox(height: 104)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar:
          _isEditing
              ? SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  decoration: const BoxDecoration(
                    color: _cardColor,
                    boxShadow: [
                      BoxShadow(color: Color(0x140F172A), blurRadius: 18),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveMeasurements,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
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
                            : const Icon(FeatherIcons.check),
                    label: Text(
                      _isSaving ? 'Sauvegarde...' : 'Enregistrer les mesures',
                    ),
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildSummaryHeader(
    User user,
    MeasurementProfile profile,
    List<MeasurementShare> shares,
  ) {
    final percent = (profile.completionRate * 100).round();
    final updated = _formatDate(profile.updatedAt);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: _premiumCardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _primaryColor.withValues(alpha: 0.1),
                backgroundImage: _imageProviderFromUrl(user.photoURL),
                child:
                    user.photoURL == null
                        ? const Icon(FeatherIcons.user, color: _primaryColor)
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profil mesures',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      updated == null
                          ? 'Aucune mise à jour'
                          : 'Mis à jour le $updated',
                      style: const TextStyle(
                        color: _textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => _showShareSheet(profile),
                style: IconButton.styleFrom(
                  backgroundColor: _primaryColor.withValues(alpha: 0.1),
                ),
                icon: const Icon(FeatherIcons.share2),
                color: _primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: profile.completionRate,
              minHeight: 9,
              color: _progressColor(profile.completionRate),
              backgroundColor: _borderColor,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  FeatherIcons.checkSquare,
                  '${profile.completedCount}/${MeasurementProfile.totalExpectedFields}',
                  'Mesures',
                  _primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatTile(
                  FeatherIcons.barChart2,
                  '$percent%',
                  'Complet',
                  _amberAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatTile(
                  FeatherIcons.userCheck,
                  '${shares.length}',
                  'Autorisés',
                  _blueInfo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: _textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeAndUnits(MeasurementProfile profile) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: _premiumCardDecoration(radius: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(FeatherIcons.activity),
                      label: Text('Rapide'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(FeatherIcons.sliders),
                      label: Text('Avancé'),
                    ),
                  ],
                  selected: {_advancedMode},
                  onSelectionChanged:
                      (value) => setState(() => _advancedMode = value.first),
                ),
              ),
            ],
          ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _pillSelector(
                    label: 'Unité',
                    value: _unitSystem,
                    values: const ['cm', 'inch'],
                    onChanged: (value) => setState(() => _unitSystem = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _pillSelector(
                    label: 'Pointure',
                    value: _shoeUnit,
                    values: const ['EU', 'US', 'UK'],
                    onChanged: (value) => setState(() => _shoeUnit = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _pillSelector(
              label: 'Morphologie',
              value: _bodyProfile.isEmpty ? 'regular' : _bodyProfile,
              values: const ['slim', 'regular', 'curvy', 'athletic'],
              onChanged: (value) => setState(() => _bodyProfile = value),
            ),
          ] else if (profile.bodyProfile.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _readOnlyPill(FeatherIcons.user, profile.bodyProfile),
                _readOnlyPill(FeatherIcons.maximize2, _unitSystem),
                _readOnlyPill(FeatherIcons.compass, _shoeUnit),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _pillSelector({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    return AppSelectField<String>(
      value: values.contains(value) ? value : values.first,
      items: values,
      label: label,
      icon: _selectorIcon(label),
      itemLabelBuilder: _humanSelectorLabel,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  Widget _readOnlyPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _primaryColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: _primaryDark)),
        ],
      ),
    );
  }

  Widget _buildSharesSection(List<MeasurementShare> shares) {
    if (shares.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: _premiumCardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FeatherIcons.unlock, color: _primaryColor),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Accès créateurs',
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showAccessManager(shares),
                child: const Text('Gérer'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                shares
                    .take(3)
                    .map(
                      (share) =>
                          _readOnlyPill(FeatherIcons.user, share.creatorName),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementSections() {
    final visibleFields =
        _advancedMode
            ? _fields
            : _fields.where((field) => field.essential).toList();
    final grouped = <String, List<_MeasurementFieldDefinition>>{};
    for (final field in visibleFields) {
      grouped.putIfAbsent(field.group, () => []).add(field);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        children:
            grouped.entries.map<Widget>((entry) {
                return _MeasurementSection(
                  title: entry.key,
                  icon: _groupIcon(entry.key),
                  children:
                      entry.value
                          .map((field) => _buildMeasurementTile(field))
                          .toList(),
                );
              }).toList()
              ..add(_buildSpecificSizesSection()),
      ),
    );
  }

  Widget _buildSpecificSizesSection() {
    return _MeasurementSection(
      title: 'Tailles et confort',
      icon: FeatherIcons.tag,
      children: [
        if (_isEditing) ...[
          AppResponsiveFieldRow(
            children: [
              _textField(
                controller: _braController,
                label: 'Soutien-gorge',
                icon: FeatherIcons.tag,
              ),
              _textField(
                controller: _cupController,
                label: 'Bonnet',
                icon: FeatherIcons.bookmark,
              ),
            ],
          ),
        ] else ...[
          _ReadMeasurementCard(
            icon: FeatherIcons.tag,
            label: 'Taille soutien-gorge',
            value:
                _braController.text.trim().isEmpty
                    ? 'Non renseigné'
                    : _braController.text.trim(),
            missing: _braController.text.trim().isEmpty,
            onTap: () => setState(() => _isEditing = true),
            onGuide:
                () => _showSimpleGuide(
                  title: 'Taille soutien-gorge',
                  text:
                      'Indiquez votre taille habituelle si elle est utile pour des robes, bustiers ou pièces ajustées.',
                ),
          ),
          _ReadMeasurementCard(
            icon: FeatherIcons.bookmark,
            label: 'Bonnet',
            value:
                _cupController.text.trim().isEmpty
                    ? 'Non renseigné'
                    : _cupController.text.trim(),
            missing: _cupController.text.trim().isEmpty,
            onTap: () => setState(() => _isEditing = true),
            onGuide:
                () => _showSimpleGuide(
                  title: 'Bonnet',
                  text:
                      'Cette information reste optionnelle et peut être partagée seulement avec les créateurs autorisés.',
                ),
          ),
        ],
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppTextField(
        controller: controller,
        label: label,
        icon: icon,
        textCapitalization: TextCapitalization.characters,
      ),
    );
  }

  Widget _buildMeasurementTile(_MeasurementFieldDefinition field) {
    final controller = _controllers.putIfAbsent(
      field.key,
      TextEditingController.new,
    );
    final currentUnit = field.key == 'pointure' ? _shoeUnit : _unitSystem;

    if (!_isEditing) {
      final value = controller.text.trim();
      return _ReadMeasurementCard(
        icon: field.icon,
        label: field.label,
        value: value.isEmpty ? 'Non renseigné' : '$value $currentUnit',
        missing: value.isEmpty,
        onTap: () => setState(() => _isEditing = true),
        onGuide: () => _showGuideSheet(field),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppTextField(
        controller: controller,
        label: field.label,
        icon: field.icon,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        ],
        onChanged: (_) => setState(() {}),
        suffixText: currentUnit,
        helperText: '${field.min.round()}-${field.max.round()} $currentUnit',
        errorText: _fieldError(field),
        suffixIcon: IconButton(
          tooltip: 'Guide',
          onPressed: () => _showGuideSheet(field),
          icon: const Icon(FeatherIcons.helpCircle),
        ),
      ),
    );
  }

  IconData _selectorIcon(String label) {
    switch (label) {
      case 'Unité':
        return FeatherIcons.maximize2;
      case 'Pointure':
        return FeatherIcons.compass;
      case 'Morphologie':
        return FeatherIcons.user;
      default:
        return FeatherIcons.sliders;
    }
  }

  String _humanSelectorLabel(String value) {
    switch (value) {
      case 'cm':
        return 'Centimètres';
      case 'inch':
        return 'Pouces';
      case 'slim':
        return 'Fine';
      case 'regular':
        return 'Standard';
      case 'curvy':
        return 'Courbes';
      case 'athletic':
        return 'Athlétique';
      default:
        return value;
    }
  }

  Widget _buildAdviceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.1)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(FeatherIcons.feather, color: _primaryColor),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mètre souple, posture droite, valeurs simples. Partagez seulement avec les créateurs de confiance.',
              style: TextStyle(
                color: _primaryDark,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMeasurements() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final invalid =
        _fields.where((field) => _fieldError(field) != null).toList();
    if (invalid.isNotEmpty) {
      _showSnack('Certaines valeurs semblent incorrectes.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final values = <String, num>{};
      for (final field in _fields) {
        final parsed = _parseNumber(_controllers[field.key]?.text);
        if (parsed != null) values[field.key] = parsed;
      }

      final profile = MeasurementProfile(
        userId: user.uid,
        values: values,
        braSize: _braController.text.trim(),
        cup: _cupController.text.trim(),
        bodyProfile: _bodyProfile,
        unitSystem: _unitSystem,
        shoeUnit: _shoeUnit,
        visibility: _profileCache?.visibility ?? 'private',
        sharedWith: _profileCache?.sharedWith ?? const [],
      );

      await _service.saveProfile(profile);
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _profileCache = profile;
      });
      _showSaveConfirmation(profile);
    } catch (e) {
      _showSnack('Sauvegarde impossible: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelEditing() {
    final cache = _profileCache;
    if (cache != null) {
      for (final field in _fields) {
        final value = cache.values[field.key];
        _controllers[field.key]?.text = value == null ? '' : '$value';
      }
      _braController.text = cache.braSize;
      _cupController.text = cache.cup;
      _unitSystem = _normalizeSelection(cache.unitSystem, const [
        'cm',
        'inch',
      ], fallback: 'cm');
      _shoeUnit = _normalizeSelection(cache.shoeUnit, const [
        'EU',
        'US',
        'UK',
      ], fallback: 'EU');
      _bodyProfile = cache.bodyProfile;
    }
    setState(() => _isEditing = false);
  }

  void _showSaveConfirmation(MeasurementProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _successGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FeatherIcons.checkCircle,
                    color: _successGreen,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mesures à jour',
                        style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        '${(profile.completionRate * 100).round()}% complété',
                        style: const TextStyle(color: _textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showShareSheet(profile);
                  },
                  child: const Text('Partager'),
                ),
              ],
            ),
          ),
    );
  }

  void _showGuideSheet(_MeasurementFieldDefinition field) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(field.icon, color: _primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          field.guideTitle,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    field.guide,
                    style: const TextStyle(color: _textPrimary, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _amberAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(FeatherIcons.info, color: _amberAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            field.tip,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
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
    );
  }

  void _showSimpleGuide({required String title, required String text}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(text, style: const TextStyle(height: 1.45)),
                ],
              ),
            ),
          ),
    );
  }

  void _showShareSheet(MeasurementProfile profile) async {
    if (profile.completedCount == 0) {
      _showSnack('Ajoutez vos mesures avant de les partager.', isError: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _ShareMeasurementsSheet(
            service: _service,
            profile: profile,
            onShared:
                (name) => _showSnack('Accès accordé à $name.', isError: false),
          ),
    );
  }

  void _showAccessManager(List<MeasurementShare> shares) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.88,
            builder:
                (context, controller) => Container(
                  decoration: const BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(18),
                    children: [
                      const Text(
                        'Accès actifs',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...shares.map(
                        (share) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: _bgColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0x190F766E),
                              child: Icon(
                                FeatherIcons.user,
                                color: _primaryColor,
                              ),
                            ),
                            title: Text(
                              share.creatorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              share.expiresAt == null
                                  ? 'Accès actif'
                                  : 'Expire le ${_formatDate(share.expiresAt)}',
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                await _service.revokeShare(share);
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                _showSnack('Accès révoqué.');
                              },
                              child: const Text(
                                'Révoquer',
                                style: TextStyle(color: _errorRed),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  String? _fieldError(_MeasurementFieldDefinition field) {
    final raw = _controllers[field.key]?.text.trim() ?? '';
    if (raw.isEmpty) return null;
    final value = _parseNumber(raw);
    if (value == null) return 'Nombre invalide';
    if (value < field.min || value > field.max) {
      return 'Valeur inhabituelle';
    }
    return null;
  }

  num? _parseNumber(String? raw) {
    final normalized = raw?.replaceAll(',', '.').trim() ?? '';
    if (normalized.isEmpty) return null;
    return num.tryParse(normalized);
  }

  IconData _groupIcon(String group) {
    switch (group) {
      case 'Haut du corps':
        return FeatherIcons.user;
      case 'Bas du corps':
        return FeatherIcons.move;
      case 'Tailles':
        return FeatherIcons.tag;
      default:
        return Icons.favorite_border;
    }
  }

  Color _progressColor(double value) {
    if (value >= 0.8) return _successGreen;
    if (value >= 0.45) return _amberAccent;
    return _roseAccent;
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _normalizeSelection(
    String value,
    List<String> allowed, {
    required String fallback,
  }) {
    return allowed.contains(value) ? value : fallback;
  }

  ImageProvider? _imageProviderFromUrl(String? url) {
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return NetworkImage(trimmed);
  }

  BoxDecoration _premiumCardDecoration({double radius = 22}) {
    return BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
      boxShadow: const [
        BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 14),
        BoxShadow(
          color: Color(0x140F172A),
          offset: Offset(6, 8),
          blurRadius: 18,
        ),
      ],
    );
  }

  Widget _buildSignedOutState() {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(FeatherIcons.lock, color: _primaryColor, size: 42),
              const SizedBox(height: 14),
              const Text(
                'Connectez-vous pour gérer vos mesures.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: _primaryColor));
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: _errorRed, size: 72),
            const SizedBox(height: 14),
            const Text(
              'Impossible de charger les mesures',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _errorRed : _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _ShareMeasurementsSheet extends StatefulWidget {
  final MeasurementService service;
  final MeasurementProfile profile;
  final ValueChanged<String> onShared;

  const _ShareMeasurementsSheet({
    required this.service,
    required this.profile,
    required this.onShared,
  });

  @override
  State<_ShareMeasurementsSheet> createState() =>
      _ShareMeasurementsSheetState();
}

class _ShareMeasurementsSheetState extends State<_ShareMeasurementsSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<MeasurementCreator> _creators = [];
  String _query = '';
  Duration _duration = const Duration(days: 30);
  bool _includeSnapshot = false;
  bool _loading = true;
  bool _sharing = false;

  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _bgColor = Color(0xFFF3F5F7);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF1F2933);
  static const Color _textSecondary = Color(0xFF7B8492);
  static const Color _borderColor = Color(0xFFE4E8EE);
  static const Color _errorRed = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _loadCreators();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCreators() async {
    setState(() => _loading = true);
    try {
      final creators = await widget.service.loadCreators();
      if (!mounted) return;
      setState(() => _creators = creators);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MeasurementCreator> get _filteredCreators {
    final query = _query.toLowerCase().trim();
    if (query.isEmpty) return _creators;
    return _creators.where((creator) {
      return creator.name.toLowerCase().contains(query) ||
          creator.email.toLowerCase().contains(query) ||
          creator.speciality.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
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
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Partager',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _buildConsentOptions(),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _searchController,
                  label: 'Créateur',
                  hint: 'Nom, spécialité',
                  icon: FeatherIcons.search,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 14),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(color: _primaryColor),
                    ),
                  )
                else if (_filteredCreators.isEmpty)
                  _buildEmptyCreators()
                else
                  ..._filteredCreators.map(_buildCreatorTile),
              ],
            ),
          ),
    );
  }

  Widget _buildConsentOptions() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: _primaryColor),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Durée d’accès',
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DropdownButton<Duration>(
                value: _duration,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(
                    value: Duration(days: 7),
                    child: Text('7 jours'),
                  ),
                  DropdownMenuItem(
                    value: Duration(days: 30),
                    child: Text('30 jours'),
                  ),
                  DropdownMenuItem(
                    value: Duration(days: 90),
                    child: Text('90 jours'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _duration = value);
                },
              ),
            ],
          ),
          SwitchListTile(
            value: _includeSnapshot,
            onChanged: (value) => setState(() => _includeSnapshot = value),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: _primaryColor,
            title: const Text(
              'Inclure une copie figée',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Sinon, le créateur consulte le profil autorisé le plus récent.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorTile(MeasurementCreator creator) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: _primaryColor.withValues(alpha: 0.1),
          backgroundImage:
              creator.photoUrl == null ? null : NetworkImage(creator.photoUrl!),
          child:
              creator.photoUrl == null
                  ? Text(
                    creator.name.isEmpty ? 'C' : creator.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                  : null,
        ),
        title: Text(
          creator.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          [
            if (creator.speciality.isNotEmpty) creator.speciality,
            if (creator.email.isNotEmpty) creator.email,
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing:
            _sharing
                ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primaryColor,
                  ),
                )
                : const Icon(FeatherIcons.chevronRight, size: 16),
        onTap: _sharing ? null : () => _confirmShare(creator),
      ),
    );
  }

  Widget _buildEmptyCreators() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(FeatherIcons.users, color: _textSecondary, size: 44),
          const SizedBox(height: 12),
          const Text(
            'Aucun créateur trouvé',
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les comptes créateurs all-in-one doivent avoir roles.creator ou isCreator activé.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _loadCreators,
            icon: const Icon(FeatherIcons.refreshCw),
            label: const Text('Recharger'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmShare(MeasurementCreator creator) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Partager avec ${creator.name} ?'),
            content: Text(
              'Le créateur aura accès à votre profil de mesures pendant ${_duration.inDays} jours. Vous pourrez révoquer cet accès à tout moment.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmer'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    setState(() => _sharing = true);
    try {
      await widget.service.shareWithCreator(
        profile: widget.profile,
        creator: creator,
        duration: _duration,
        includeSnapshot: _includeSnapshot,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onShared(creator.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Bad state: ', '')),
          backgroundColor: _errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class _MeasurementSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _MeasurementSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-5, -5),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Color(0x140F172A),
            offset: Offset(6, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: _IconBadge(icon: icon),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1F2933),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          children: children,
        ),
      ),
    );
  }
}

class _ReadMeasurementCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool missing;
  final VoidCallback? onTap;
  final VoidCallback onGuide;

  const _ReadMeasurementCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.missing,
    this.onTap,
    required this.onGuide,
  });

  @override
  Widget build(BuildContext context) {
    final color = missing ? const Color(0xFF7B8492) : const Color(0xFF0F766E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _IconBadge(
              icon: icon,
              color: color,
              backgroundColor: color.withValues(alpha: 0.1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF7B8492),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color:
                          missing
                              ? const Color(0xFF7B8492)
                              : const Color(0xFF1F2933),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  FeatherIcons.edit2,
                  color: Color(0xFF0F766E),
                  size: 18,
                ),
              ),
            IconButton(
              tooltip: 'Guide',
              onPressed: onGuide,
              icon: const Icon(FeatherIcons.helpCircle),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? backgroundColor;

  const _IconBadge({
    required this.icon,
    this.color = const Color(0xFF0F766E),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _MeasurementFieldDefinition {
  final String key;
  final String label;
  final String group;
  final IconData icon;
  final num min;
  final num max;
  final bool essential;
  final String guideTitle;
  final String guide;
  final String tip;

  const _MeasurementFieldDefinition({
    required this.key,
    required this.label,
    required this.group,
    required this.icon,
    required this.min,
    required this.max,
    this.essential = false,
    required this.guideTitle,
    required this.guide,
    required this.tip,
  });
}
