import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../models/style/fashion_assistant_models.dart';
import '../../../../../services/style/fashion_assistant_service.dart';
import '../../../../widgets/preferences/currency_preference_tile.dart';
import '../../../global/salon_search_screen.dart';
import '../../../global/widgets/inspiration/community_screen.dart';
import '../virtual_try_on_screen.dart';
import 'chat_screen.dart';

enum _StudioStep { source, compose, finalize }

enum _StudioSource { wardrobe, salon, occasion, inspiration, iris }

class FashionAssistantScreen extends StatefulWidget {
  const FashionAssistantScreen({super.key});

  @override
  State<FashionAssistantScreen> createState() => _FashionAssistantScreenState();
}

/// Compatibility alias for older routes/imports.
class BurkinabeFashionAssistant extends StatefulWidget {
  const BurkinabeFashionAssistant({super.key});

  @override
  State<BurkinabeFashionAssistant> createState() =>
      _BurkinabeFashionAssistantState();
}

class _BurkinabeFashionAssistantState extends State<BurkinabeFashionAssistant> {
  @override
  Widget build(BuildContext context) => const FashionAssistantScreen();
}

class _FashionAssistantScreenState extends State<FashionAssistantScreen> {
  final FashionAssistantService _service = FashionAssistantService();
  final TextEditingController _promptController = TextEditingController();

  Future<StyleUserContext>? _contextFuture;
  StyleUserContext? _userContext;
  GeneratedLook? _currentLook;
  String _selectedGender = 'Femme';
  String _selectedSeasonId = styleSeasons.first.id;
  String _selectedOccasionId = styleOccasions.first.id;
  String _imageStyle = 'editorial';
  String _cultureMode = 'local';
  _StudioStep _studioStep = _StudioStep.source;
  _StudioSource _studioSource = _StudioSource.occasion;
  bool _useWardrobe = true;
  bool _useMeasurements = true;
  bool _isGenerating = false;
  bool _isSaving = false;
  String _progressStage = '';
  int _generationToken = 0;

  static const Color _kCanvas = Color(0xFFF3F5F7);
  static const Color _kInk = Color(0xFF1F2933);
  static const Color _kMuted = Color(0xFF7B8492);
  static const Color _kLine = Color(0xFFE4E8EE);
  static const Color _kPrimary = Color(0xFF0F766E);
  static const Color _kPrimaryDark = Color(0xFF115E59);
  static const Color _kAccent = Color(0xFFF59E0B);
  static const Color _kRose = Color(0xFFE11D48);
  static const Color _kBlue = Color(0xFF2563EB);
  static const Color _kSuccess = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _loadContext() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _contextFuture = _service.loadUserContext(user.uid);
  }

  void _refreshContext() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _service.clearUserContextCache(user.uid);
    _contextFuture = _service.loadUserContext(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _buildSignedOutState();

    return Scaffold(
      backgroundColor: _kCanvas,
      appBar: AppBar(
        backgroundColor: _kCanvas,
        foregroundColor: _kInk,
        elevation: 0,
        leadingWidth: 102,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: TextButton.icon(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back, size: 20),
            label: const Text('Retour'),
            style: TextButton.styleFrom(
              foregroundColor: _kInk,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        title: const Text(
          'Studio Style',
          style: TextStyle(fontWeight: FontWeight.w900, color: _kInk),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: () => setState(_refreshContext),
            icon: const Icon(AppIcons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<StyleUserContext>(
        future: _contextFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _userContext == null) {
            return const Center(
              child: CircularProgressIndicator(color: _kPrimary),
            );
          }
          if (snapshot.hasData) _userContext = snapshot.data!;
          final userContext = _userContext ?? const StyleUserContext();

          return _buildAssistantTab(user.uid, userContext);
        },
      ),
    );
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Widget _buildAssistantTab(String userId, StyleUserContext userContext) {
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async => setState(_refreshContext),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildDashboard(userContext)),
          SliverToBoxAdapter(child: _buildStudioFlow(userContext)),
          SliverToBoxAdapter(child: _buildQuickStart(userContext)),
          SliverToBoxAdapter(child: _buildInputs(userContext)),
          if (!_service.hasGeminiKey || !_service.hasImageGeneration)
            SliverToBoxAdapter(child: _buildApiFallbackCard()),
          if (_isGenerating) SliverToBoxAdapter(child: _buildProgressCard()),
          if (_currentLook != null)
            SliverToBoxAdapter(
              child: _buildGeneratedLook(userId, _currentLook!),
            ),
          SliverToBoxAdapter(child: _buildPaletteTab()),
          SliverToBoxAdapter(child: _buildHistoryTab(userId)),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  Widget _buildDashboard(StyleUserContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: _premiumDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(AppIcons.style, color: _kPrimary, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Studio',
                      style: TextStyle(
                        color: _kInk,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${context.region}, ${context.country} • ${context.currency}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  AppIcons.wardrobe,
                  '${context.wardrobeCount}',
                  'Pièces',
                  _kPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  AppIcons.measurements,
                  '${context.measurementPercent}%',
                  'Mesures',
                  _kAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  AppIcons.recommendations,
                  context.latestLook == null ? '0' : '1+',
                  'Looks',
                  _kBlue,
                ),
              ),
            ],
          ),
          if (context.latestLook != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.history, color: _kPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dernière idée : ${context.latestLook!.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kPrimaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label, Color color) {
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
            style: const TextStyle(
              color: _kInk,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: _kMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioFlow(StyleUserContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: _premiumDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Atelier', ''),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _studioStepPill(
                  step: _StudioStep.source,
                  index: '1',
                  label: 'Départ',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _studioStepPill(
                  step: _StudioStep.compose,
                  index: '2',
                  label: 'Composer',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _studioStepPill(
                  step: _StudioStep.finalize,
                  index: '3',
                  label: 'Finaliser',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_studioStep) {
              _StudioStep.source => _buildSourceStep(context),
              _StudioStep.compose => _buildComposeStep(context),
              _StudioStep.finalize => _buildFinalizeStep(context),
            },
          ),
        ],
      ),
    );
  }

  Widget _studioStepPill({
    required _StudioStep step,
    required String index,
    required String label,
  }) {
    final selected = _studioStep == step;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _studioStep = step);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : _kCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _kPrimary : _kLine),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: selected ? Colors.white : _kPrimary,
              child: Text(
                index,
                style: TextStyle(
                  color: selected ? _kPrimary : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : _kInk,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceStep(StyleUserContext userContext) {
    final sources = [
      _StudioSourceCard(
        source: _StudioSource.wardrobe,
        icon: AppIcons.wardrobe,
        title: 'Dressing',
        subtitle: '${userContext.wardrobeCount} pièce(s)',
      ),
      const _StudioSourceCard(
        source: _StudioSource.salon,
        icon: AppIcons.salon,
        title: 'Le Salon',
        subtitle: 'Shopping · talents',
      ),
      const _StudioSourceCard(
        source: _StudioSource.occasion,
        icon: AppIcons.appointments,
        title: 'Occasion',
        subtitle: 'Mariage · bureau',
      ),
      const _StudioSourceCard(
        source: _StudioSource.inspiration,
        icon: AppIcons.inspiration,
        title: 'Inspiration',
        subtitle: 'Favoris · guides',
      ),
      const _StudioSourceCard(
        source: _StudioSource.iris,
        icon: AppIcons.messages,
        title: 'Conseil',
        subtitle: 'Discussion',
      ),
    ];

    return Column(
      key: const ValueKey('source-step'),
      children: [
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: sources.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = sources[index];
              final selected = _studioSource == item.source;
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _studioSource = item.source;
                    _applySourcePrompt(item.source, userContext);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 178,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        selected ? _kPrimary.withValues(alpha: 0.1) : _kCanvas,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? _kPrimary : _kLine,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, color: selected ? _kPrimary : _kMuted),
                      const Spacer(),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kInk,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kMuted,
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        AppButton(
          label: 'Continuer',
          onPressed: () => setState(() => _studioStep = _StudioStep.compose),
          icon: Icons.arrow_forward_rounded,
          expand: true,
        ),
      ],
    );
  }

  Widget _buildComposeStep(StyleUserContext context) {
    final filledSlots = _useWardrobe ? context.wardrobe.take(3).length : 0;
    final missing = _missingPiecesPreview();
    return Column(
      key: const ValueKey('compose-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kCanvas,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(AppIcons.style, color: _kPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      filledSlots > 0
                          ? '$filledSlots pièce(s) prêtes'
                          : 'Base du look',
                      style: const TextStyle(
                        color: _kInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _slotChip('Haut', filledSlots > 0),
                  _slotChip('Bas', filledSlots > 1),
                  _slotChip('Chaussures', false),
                  _slotChip('Accessoire', false),
                  _slotChip('Coiffure', false),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Manque : ${missing.join(', ')}',
                style: const TextStyle(
                  color: _kMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _assistChip(
              icon: AppIcons.messages,
              label: 'Conseil',
              onTap: () => _openIrisWithDraft(),
            ),
            _assistChip(
              icon: AppIcons.salon,
              label: 'Salon',
              onTap: () => _openSalonSearch(),
            ),
            _assistChip(
              icon: AppIcons.wardrobe,
              label: 'Sans achat',
              onTap: () {
                setState(() {
                  _useWardrobe = true;
                  _promptController.text =
                      'Compose un look complet avec ma garde-robe uniquement, sans achat si possible.';
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Retour',
                onPressed:
                    () => setState(() => _studioStep = _StudioStep.source),
                variant: AppButtonVariant.tertiary,
                expand: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: 'Finaliser',
                onPressed:
                    () => setState(() => _studioStep = _StudioStep.finalize),
                icon: Icons.check_rounded,
                expand: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinalizeStep(StyleUserContext context) {
    return Column(
      key: const ValueKey('finalize-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _finalActionTile(
          icon: AppIcons.recommendations,
          title: 'Composer',
          subtitle: 'Look complet',
          onTap: _isGenerating ? null : () => _generate(context),
        ),
        _finalActionTile(
          icon: Icons.checkroom_rounded,
          title: 'Essayer',
          subtitle: 'Aperçu visuel',
          onTap: _openTryOn,
        ),
        _finalActionTile(
          icon: AppIcons.publicSpace,
          title: 'Avis',
          subtitle: 'Communauté',
          onTap: _openCommunity,
        ),
        _finalActionTile(
          icon: AppIcons.salon,
          title: 'Compléter',
          subtitle: 'Boutique ou créateur',
          onTap: _openSalonSearch,
        ),
      ],
    );
  }

  Widget _slotChip(String label, bool filled) {
    return Chip(
      avatar: Icon(
        filled ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
        color: filled ? _kSuccess : _kMuted,
        size: 18,
      ),
      label: Text(label),
      backgroundColor:
          filled ? _kSuccess.withValues(alpha: 0.08) : Colors.white,
      side: BorderSide(
        color: filled ? _kSuccess.withValues(alpha: 0.2) : _kLine,
      ),
    );
  }

  Widget _assistChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 17),
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _finalActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _kCanvas,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _kPrimary.withValues(alpha: 0.1),
                  child: Icon(icon, color: _kPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _kInk,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _kMuted,
                          fontSize: 12.5,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _kMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStart(StyleUserContext context) {
    final cards = [
      _QuickPrompt(
        title: 'Tenue pour aujourd’hui',
        subtitle: 'Aujourd’hui',
        icon: AppIcons.today,
        prompt:
            'Propose une tenue confortable pour aujourd’hui à ${context.region}.',
        occasion: 'daily',
      ),
      const _QuickPrompt(
        title: 'Look avec mes pièces',
        subtitle: 'Dressing',
        icon: AppIcons.wardrobe,
        prompt:
            'Crée un look à partir de ma garde-robe, avec peu ou pas d’achat.',
        occasion: 'daily',
      ),
      const _QuickPrompt(
        title: 'Style cérémonie',
        subtitle: 'Cérémonie',
        icon: AppIcons.appointments,
        prompt: 'Je veux un look de cérémonie élégant, respectueux et moderne.',
        occasion: 'ceremony',
      ),
      const _QuickPrompt(
        title: 'Adapter à la météo',
        subtitle: 'Confort',
        icon: AppIcons.today,
        prompt:
            'Adapte ma tenue au climat, avec confort et style toute la journée.',
        occasion: 'daily',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Scénarios', ''),
          const SizedBox(height: 12),
          SizedBox(
            height: 126,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final card = cards[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    setState(() {
                      _promptController.text = card.prompt;
                      _selectedOccasionId = card.occasion;
                    });
                  },
                  child: Container(
                    width: 184,
                    padding: const EdgeInsets.all(14),
                    decoration: _premiumDecoration(radius: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(card.icon, color: _kPrimary, size: 26),
                        const Spacer(),
                        Text(
                          card.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kInk,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputs(StyleUserContext userContext) {
    final selectedSeason = styleSeasons.firstWhere(
      (season) => season.id == _selectedSeasonId,
      orElse: () => styleSeasons.first,
    );
    final selectedOccasion = styleOccasions.firstWhere(
      (occasion) => occasion.id == _selectedOccasionId,
      orElse: () => styleOccasions.first,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: _premiumDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Demande', ''),
          const SizedBox(height: 12),
          TextField(
            controller: _promptController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Ex: tenue chic pour dîner confortable...',
              filled: true,
              fillColor: _kCanvas,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _promptChip('Mariage chic'),
              _promptChip('Bureau moderne'),
              _promptChip('Sortie décontractée'),
              _promptChip('Look avec mes pièces'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _dropdown<String>(
                  label: 'Genre',
                  value: _selectedGender,
                  values: const ['Femme', 'Homme', 'Enfant', 'Unisexe'],
                  labelOf: (value) => value,
                  onChanged: (value) => setState(() => _selectedGender = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dropdown<StyleOccasion>(
                  label: 'Occasion',
                  value: selectedOccasion,
                  values: styleOccasions,
                  labelOf: (value) => value.name,
                  onChanged:
                      (value) => setState(() => _selectedOccasionId = value.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dropdown<StyleSeason>(
                  label: 'Climat',
                  value: selectedSeason,
                  values: styleSeasons,
                  labelOf: (value) => value.name,
                  onChanged:
                      (value) => setState(() => _selectedSeasonId = value.id),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dropdown<String>(
                  label: 'Visualisation',
                  value: _imageStyle,
                  values: const ['editorial', 'flat lay', 'modèle', 'boutique'],
                  labelOf: (value) => value,
                  onChanged: (value) => setState(() => _imageStyle = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _dropdown<String>(
            label: 'Mode culturel',
            value: _cultureMode,
            values: const ['local', 'global', 'traditionnel', 'moderne'],
            labelOf: (value) => value,
            onChanged: (value) => setState(() => _cultureMode = value),
          ),
          const SizedBox(height: 12),
          CurrencyPreferenceTile(
            initialCurrency: userContext.currency,
            onChanged: (_) => setState(_refreshContext),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _useWardrobe,
            onChanged: (value) => setState(() => _useWardrobe = value),
            activeThumbColor: _kPrimary,
            contentPadding: EdgeInsets.zero,
            title: const Text('Garde-robe'),
            subtitle: Text('${userContext.wardrobeCount} pièce(s)'),
          ),
          SwitchListTile(
            value: _useMeasurements,
            onChanged: (value) => setState(() => _useMeasurements = value),
            activeThumbColor: _kPrimary,
            contentPadding: EdgeInsets.zero,
            title: const Text('Mensurations'),
            subtitle: Text('${userContext.measurementPercent}%'),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: _isGenerating ? 'Préparation...' : 'Composer',
            onPressed: _isGenerating ? null : () => _generate(userContext),
            icon: AppIcons.recommendations,
            loading: _isGenerating,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _promptChip(String label) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(AppIcons.guide, size: 17),
      onPressed: () {
        setState(() {
          _promptController.text = switch (label) {
            'Mariage chic' => 'Je veux un look chic pour un mariage.',
            'Bureau moderne' =>
              'Je veux une tenue de bureau moderne et confiante.',
            'Sortie décontractée' => 'Je veux un look décontracté mais soigné.',
            _ => 'Crée un look avec les pièces de ma garde-robe.',
          };
        });
      },
    );
  }

  void _applySourcePrompt(_StudioSource source, StyleUserContext context) {
    final prompt = switch (source) {
      _StudioSource.wardrobe =>
        'Compose un look complet avec ma garde-robe, en limitant les achats aux pièces vraiment manquantes.',
      _StudioSource.salon =>
        'Aide-moi à construire un look avec des pièces du Salon, en privilégiant boutiques et créateurs certifiés proches de ma zone.',
      _StudioSource.occasion =>
        'Je prépare une tenue pour une occasion précise. Propose une silhouette élégante, confortable et adaptée à ${context.region}.',
      _StudioSource.inspiration =>
        'Transforme mon inspiration en look portable, avec une version sobre, une version plus audacieuse et les pièces à chercher.',
      _StudioSource.iris =>
        'Aide-moi à transformer une discussion avec Iris en look concret, avec prochaines actions simples.',
    };
    switch (source) {
      case _StudioSource.wardrobe:
        _useWardrobe = true;
      case _StudioSource.salon:
      case _StudioSource.occasion:
      case _StudioSource.inspiration:
      case _StudioSource.iris:
        break;
    }
    _promptController.text = prompt;
  }

  List<String> _missingPiecesPreview() {
    final prompt = _promptController.text.toLowerCase();
    if (prompt.contains('mariage') || prompt.contains('cérémonie')) {
      return const ['chaussures habillées', 'accessoire discret', 'finition'];
    }
    if (prompt.contains('bureau') || prompt.contains('travail')) {
      return const ['veste légère', 'chaussures confortables', 'sac'];
    }
    if (prompt.contains('sortie')) {
      return const ['pièce forte', 'accessoire signature', 'chaussures'];
    }
    return const ['chaussures', 'accessoire', 'pièce de liaison'];
  }

  String _studioDraft() {
    final base = _promptController.text.trim();
    final missing = _missingPiecesPreview().join(', ');
    final occasion =
        styleOccasions
            .firstWhere(
              (item) => item.id == _selectedOccasionId,
              orElse: () => styleOccasions.first,
            )
            .name;
    return [
      if (base.isNotEmpty) base,
      'Source Studio: ${_sourceLabel(_studioSource)}.',
      'Occasion: $occasion.',
      'Aide-moi à améliorer ce look, à vérifier ce qui manque ($missing), et propose des actions: garde-robe, Salon, communauté ou essayage.',
    ].join('\n');
  }

  String _sourceLabel(_StudioSource source) {
    return switch (source) {
      _StudioSource.wardrobe => 'ma garde-robe',
      _StudioSource.salon => 'le Salon',
      _StudioSource.occasion => 'une occasion',
      _StudioSource.inspiration => 'une inspiration',
      _StudioSource.iris => 'Iris',
    };
  }

  void _openIrisWithDraft() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(initialDraft: _studioDraft()),
      ),
    );
  }

  void _openTryOn() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VirtualTryOnScreen()),
    );
  }

  void _openCommunity() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityScreen()),
    );
  }

  void _openSalonSearch() {
    final query =
        _promptController.text.trim().isEmpty
            ? _missingPiecesPreview().first
            : _promptController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SalonSearchScreen(initialQuery: query)),
    );
  }

  void _openCreatorSearchForLook(GeneratedLook look) {
    final occasion =
        styleOccasions
            .firstWhere(
              (item) => item.id == _selectedOccasionId,
              orElse: () => styleOccasions.first,
            )
            .name;
    final shoppingContext =
        look.shoppingList.isEmpty
            ? look.title
            : look.shoppingList.take(3).join(' ');
    final query = <String>[
      'créateur',
      'styliste',
      occasion,
      shoppingContext,
      look.region,
    ].where((item) => item.trim().isNotEmpty).join(' ');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SalonSearchScreen(initialQuery: query)),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _kCanvas,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items:
          values
              .map(
                (item) =>
                    DropdownMenuItem(value: item, child: Text(labelOf(item))),
              )
              .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  Widget _buildApiFallbackCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAccent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.info, color: _kAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              !_service.hasGeminiKey
                  ? 'Le service externe n’est pas configuré : une sélection locale sera utilisée.'
                  : 'Le rendu image n’est pas configuré : le conseil texte restera disponible. Configurez STYLE_IMAGE_PROVIDER=openai avec OPENAI_API_KEY, ou STABILITY_API_KEY.',
              style: const TextStyle(
                color: _kInk,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    const stages = [
      'Analyse du contexte',
      'Lecture garde-robe',
      'Palette',
      'Budget',
      'Image',
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: _premiumDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircularProgressIndicator(color: _kPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _progressStage.isEmpty ? 'Préparation...' : _progressStage,
                  style: const TextStyle(
                    color: _kInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: _cancelGeneration,
                child: const Text('Annuler'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                stages.map((stage) {
                  final active = _progressStage.toLowerCase().contains(
                    stage.split(' ').first.toLowerCase(),
                  );
                  return Chip(
                    label: Text(stage),
                    avatar: Icon(
                      active
                          ? Icons.radio_button_checked
                          : Icons.circle_outlined,
                      size: 16,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedLook(String userId, GeneratedLook look) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: _premiumDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _kSuccess.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.check, color: _kSuccess),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      look.title,
                      style: const TextStyle(
                        color: _kInk,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Score ${look.score}/100 • ${look.region}',
                      style: const TextStyle(
                        color: _kMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (look.imageBytes != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(
                look.imageBytes!,
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            _imageFallback(),
          ],
          const SizedBox(height: 12),
          _resultActions(userId, look),
          const SizedBox(height: 10),
          _resultSection(
            icon: AppIcons.wardrobe,
            title: 'Look',
            child: SelectableText(
              look.consultation,
              style: const TextStyle(color: _kInk, height: 1.48),
            ),
          ),
          _resultSection(
            icon: AppIcons.style,
            title: 'Couleurs',
            child: Column(
              children:
                  look.palette
                      .map(
                        (item) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: Color(item.value),
                          ),
                          title: Text(item.name),
                          subtitle: Text(item.meaning),
                        ),
                      )
                      .toList(),
            ),
          ),
          _resultSection(
            icon: AppIcons.revenue,
            title: 'Budget',
            child: Column(
              children:
                  look.budget
                      .map(
                        (item) => ListTile(
                          dense: true,
                          title: Text(item.label),
                          subtitle: Text(item.details),
                          trailing: Text('${item.amount} ${look.currency}'),
                        ),
                      )
                      .toList(),
            ),
          ),
          _resultSection(
            icon: AppIcons.boutique,
            title: 'À acheter / utiliser',
            child: Column(
              children:
                  look.shoppingList
                      .map((item) => ListTile(dense: true, title: Text(item)))
                      .toList(),
            ),
          ),
          _resultSection(
            icon: AppIcons.publicSpace,
            title: 'Conseils culturels',
            child: Column(
              children:
                  look.culturalTips
                      .map((item) => ListTile(dense: true, title: Text(item)))
                      .toList(),
            ),
          ),
          const SizedBox(height: 10),
          _variantButtons(),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kCanvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kLine),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined, color: _kMuted, size: 38),
            SizedBox(height: 8),
            Text(
              'Image indisponible, conseil texte disponible',
              style: TextStyle(color: _kMuted, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultActions(String userId, GeneratedLook look) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(AppIcons.save),
          label: Text(_isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
          onPressed: _isSaving ? null : () => _saveLook(userId, look),
        ),
        ActionChip(
          avatar: const Icon(AppIcons.copy),
          label: const Text('Copier'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: look.consultation));
            _showSnack('Consultation copiée');
          },
        ),
        ActionChip(
          avatar: const Icon(AppIcons.share),
          label: const Text('Partager'),
          onPressed:
              () => SharePlus.instance.share(
                ShareParams(text: '${look.title}\n\n${look.consultation}'),
              ),
        ),
        ActionChip(
          avatar: const Icon(AppIcons.favorites),
          label: const Text('Favori'),
          onPressed: () async {
            if (look.id.isNotEmpty) await _service.toggleFavorite(userId, look);
            _showSnack('Look marqué comme favori');
          },
        ),
        ActionChip(
          avatar: const Icon(AppIcons.salon),
          label: const Text('Trouver créateur'),
          onPressed: () => _openCreatorSearchForLook(look),
        ),
      ],
    );
  }

  Widget _resultSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: _kCanvas,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: title == 'Look',
          leading: Icon(icon, color: _kPrimary),
          title: Text(
            title,
            style: const TextStyle(color: _kInk, fontWeight: FontWeight.w900),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: [child],
        ),
      ),
    );
  }

  Widget _variantButtons() {
    final contextData = _userContext;
    if (contextData == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _variantChip('Plus moderne', 'modern', contextData),
        _variantChip('Plus traditionnel', 'traditional', contextData),
        _variantChip('Plus économique', 'budget', contextData),
        _variantChip('Plus coloré', 'colorful', contextData),
      ],
    );
  }

  Widget _variantChip(
    String label,
    String variant,
    StyleUserContext contextData,
  ) {
    return ActionChip(
      avatar: const Icon(AppIcons.refresh),
      label: Text(label),
      onPressed:
          _isGenerating ? null : () => _generate(contextData, variant: variant),
    );
  }

  Widget _buildPaletteTab() {
    final season = styleSeasons.firstWhere(
      (item) => item.id == _selectedSeasonId,
      orElse: () => styleSeasons.first,
    );
    final occasion = styleOccasions.firstWhere(
      (item) => item.id == _selectedOccasionId,
      orElse: () => styleOccasions.first,
    );
    final palette = _service.buildPalette(
      _buildContext(_userContext, season, occasion),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Palette du moment',
            'Couleurs selon climat et occasion',
          ),
          const SizedBox(height: 12),
          ...palette.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: _premiumDecoration(radius: 20),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Color(item.value),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: _kInk,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          item.meaning,
                          style: const TextStyle(color: _kMuted),
                        ),
                      ],
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

  Widget _buildHistoryTab(String userId) {
    return StreamBuilder<List<GeneratedLook>>(
      stream: _service.watchHistory(userId),
      builder: (context, snapshot) {
        final looks = snapshot.data ?? const <GeneratedLook>[];
        if (!snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            padding: const EdgeInsets.all(18),
            decoration: _premiumDecoration(radius: 22),
            child: const Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: _kPrimary,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chargement de votre historique...',
                    style: TextStyle(
                      color: _kMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (looks.isEmpty) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            padding: const EdgeInsets.all(18),
            decoration: _premiumDecoration(radius: 22),
            child: const Row(
              children: [
                Icon(AppIcons.history, color: _kMuted),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aucune consultation sauvegardée pour le moment.',
                    style: TextStyle(
                      color: _kMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final visibleLooks = looks.take(5).toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Historique', 'Vos dernières idées sauvegardées'),
              const SizedBox(height: 12),
              ...visibleLooks.map(
                (look) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: _kLine),
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x190F766E),
                      child: Icon(AppIcons.recommendations, color: _kPrimary),
                    ),
                    title: Text(
                      look.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text('${look.score}/100 • ${look.region}'),
                    trailing: Icon(
                      look.favorite ? Icons.favorite : Icons.chevron_right,
                      color: look.favorite ? _kRose : _kMuted,
                    ),
                    onTap: () => setState(() => _currentLook = look),
                  ),
                ),
              ),
              if (looks.length > visibleLooks.length)
                Text(
                  '${looks.length - visibleLooks.length} autre(s) consultation(s) disponible(s) dans votre historique complet.',
                  style: const TextStyle(
                    color: _kMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generate(
    StyleUserContext userContext, {
    String variant = 'balanced',
  }) async {
    if (_promptController.text.trim().isEmpty) {
      _showSnack('Décrivez votre besoin ou choisissez un prompt rapide');
      return;
    }

    final token = ++_generationToken;
    final season = styleSeasons.firstWhere(
      (item) => item.id == _selectedSeasonId,
      orElse: () => styleSeasons.first,
    );
    final occasion = styleOccasions.firstWhere(
      (item) => item.id == _selectedOccasionId,
      orElse: () => styleOccasions.first,
    );

    setState(() {
      _isGenerating = true;
      _progressStage = 'Analyse du contexte';
    });

    try {
      final look = await _service.generateLook(
        _buildContext(userContext, season, occasion),
        variant: variant,
        onStage: (stage) {
          if (!mounted || token != _generationToken) return;
          setState(() => _progressStage = stage);
        },
      );
      if (!mounted || token != _generationToken) return;
      setState(() => _currentLook = look);
    } catch (e) {
      if (!mounted || token != _generationToken) return;
      _showSnack('Génération impossible: $e');
    } finally {
      if (mounted && token == _generationToken) {
        setState(() {
          _isGenerating = false;
          _progressStage = '';
        });
      }
    }
  }

  StyleContext _buildContext(
    StyleUserContext? userContext,
    StyleSeason season,
    StyleOccasion occasion,
  ) {
    final current = userContext ?? const StyleUserContext();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StyleContext(
      userId: userId,
      prompt: _promptController.text.trim(),
      gender: _selectedGender,
      country: current.country,
      region: current.region,
      climate: season.climate,
      cultureMode: _cultureMode,
      currency: current.currency,
      season: season,
      occasion: occasion,
      imageStyle: _imageStyle,
      useWardrobe: _useWardrobe,
      useMeasurements: _useMeasurements,
      wardrobe: _useWardrobe ? current.wardrobe : const [],
      measurements: _useMeasurements ? current.measurements : null,
    );
  }

  Future<void> _saveLook(String userId, GeneratedLook look) async {
    setState(() => _isSaving = true);
    try {
      final id = await _service.saveLook(userId, look);
      if (!mounted) return;
      setState(() => _currentLook = look.copyWith(id: id));
      _showSnack('Look sauvegardé');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelGeneration() {
    _generationToken++;
    setState(() {
      _isGenerating = false;
      _progressStage = '';
    });
    _showSnack('Génération annulée');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _kInk,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  BoxDecoration _premiumDecoration({double radius = 22}) {
    return BoxDecoration(
      color: Colors.white,
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
    return const Scaffold(
      backgroundColor: _kCanvas,
      body: Center(
        child: Text(
          'Connectez-vous pour utiliser le Studio Style.',
          style: TextStyle(color: _kInk, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _QuickPrompt {
  final String title;
  final String subtitle;
  final IconData icon;
  final String prompt;
  final String occasion;

  const _QuickPrompt({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.prompt,
    required this.occasion,
  });
}

class _StudioSourceCard {
  const _StudioSourceCard({
    required this.source,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final _StudioSource source;
  final IconData icon;
  final String title;
  final String subtitle;
}
