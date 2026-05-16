import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/talent/talent_filter.dart';
import '../../../../models/talent/talent_portfolio_item.dart';
import '../../../../models/talent/talent_profile.dart';
import '../../../../services/talent/talent_service.dart';
import '../widgets/talents/talent_card.dart';
import '../widgets/talents/talent_detail_sheet.dart';
import '../widgets/talents/talents_filter_rail.dart';
import '../widgets/talents/talents_stats_strip.dart';

class CreateursTab extends StatefulWidget {
  const CreateursTab({super.key, this.initialQuery = '', this.initialRole});

  final String initialQuery;
  final String? initialRole;

  @override
  State<CreateursTab> createState() => _CreateursTabState();
}

class _CreateursTabState extends State<CreateursTab> {
  final TalentService _talentService = TalentService();

  String _query = '';
  TalentFilter _filter = const TalentFilter();
  String _intent = 'match';

  static const _roleFilters = [
    TalentRoleFilter('Tous', AppIcons.talents),
    TalentRoleFilter('Créateur', AppIcons.creator),
    TalentRoleFilter('Boutique', AppIcons.boutique),
    TalentRoleFilter('Coiffure', Icons.content_cut_rounded),
    TalentRoleFilter('Chaussures', Icons.directions_walk_rounded),
    TalentRoleFilter('Maquillage', AppIcons.style),
    TalentRoleFilter('Styliste', Icons.design_services_rounded),
  ];

  static const _intentFilters = [
    _TalentIntent('match', 'Meilleur', Icons.star_rounded),
    _TalentIntent('fit', 'Sur mesure', Icons.straighten_rounded),
    _TalentIntent('now', 'Disponible', Icons.flash_on_rounded),
    _TalentIntent('shop', 'Acheter', Icons.shopping_bag_rounded),
    _TalentIntent('event', 'Événement', Icons.celebration_rounded),
    _TalentIntent('beauty', 'Beauté', Icons.face_retouching_natural_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _filter = _filter.copyWith(role: widget.initialRole ?? _roleFor(_query));
  }

  String _roleFor(String query) {
    final text = query.toLowerCase();
    if (text.contains('coiff')) return 'Coiffure';
    if (text.contains('chauss') || text.contains('cordonn')) {
      return 'Chaussures';
    }
    if (text.contains('boutique')) return 'Boutique';
    if (text.contains('styliste') || text.contains('mesure')) return 'Styliste';
    if (text.contains('maquill')) return 'Maquillage';
    if (text.contains('créateur') || text.contains('createur')) {
      return 'Créateur';
    }
    return 'Tous';
  }

  Future<void> _openFilters() async {
    final filters = await showModalBottomSheet<TalentFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TalentFiltersSheet(initial: _filter),
    );
    if (filters != null) setState(() => _filter = filters);
  }

  TalentFilter get _effectiveFilter {
    return switch (_intent) {
      'fit' => _filter.copyWith(
        role: 'Créateur',
        madeToMeasureOnly: true,
        withCreationsOnly: true,
      ),
      'now' => _filter.copyWith(availableOnly: true),
      'shop' => _filter.copyWith(role: 'Boutique', withProductsOnly: true),
      'beauty' => _filter.copyWith(role: 'Coiffure'),
      _ => _filter,
    };
  }

  void _selectIntent(String value) {
    setState(() {
      _intent = value;
      if (value == 'match') {
        _filter = _filter.copyWith(
          role: 'Tous',
          availableOnly: false,
          withCreationsOnly: false,
          withProductsOnly: false,
          madeToMeasureOnly: false,
          appointmentOnly: false,
        );
      } else if (value == 'fit') {
        _filter = _filter.copyWith(role: 'Créateur', madeToMeasureOnly: true);
      } else if (value == 'now') {
        _filter = _filter.copyWith(availableOnly: true);
      } else if (value == 'shop') {
        _filter = _filter.copyWith(role: 'Boutique', withProductsOnly: true);
      } else if (value == 'beauty') {
        _filter = _filter.copyWith(role: 'Coiffure');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TalentProfile>>(
      stream: _talentService.watchPublicTalents(
        query: _query,
        filter: _effectiveFilter,
      ),
      builder: (context, snapshot) {
        final talents = snapshot.data ?? const <TalentProfile>[];
        return ListView(
          key: const PageStorageKey('salon_talents_tab'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _TalentsDiscoveryHeader(
              activeQuery: _query,
              onOpenFilters: _openFilters,
              onReset:
                  () => setState(() {
                    _query = '';
                    _intent = 'match';
                    _filter = const TalentFilter();
                  }),
            ),
            const SizedBox(height: 12),
            TalentsFilterRail(
              filters: _roleFilters,
              selected: _filter.role,
              onSelected:
                  (role) => setState(() {
                    _intent = 'match';
                    _filter = _filter.copyWith(role: role);
                  }),
            ),
            const SizedBox(height: 14),
            _IntentRail(
              intents: _intentFilters,
              selected: _intent,
              onSelected: _selectIntent,
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState == ConnectionState.waiting)
              const _LoadingList()
            else if (snapshot.hasError)
              const _StateCard(
                icon: Icons.error_outline_rounded,
                title: 'Talents indisponibles',
                message: 'Impossible de charger les profils pour le moment.',
              )
            else ...[
              TalentsStatsStrip(talents: talents),
              const SizedBox(height: 18),
              _TalentSections(
                talents: talents,
                activeRole: _effectiveFilter.role,
                intent: _intent,
                onReset:
                    () => setState(() {
                      _intent = 'match';
                      _filter = const TalentFilter();
                    }),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TalentsDiscoveryHeader extends StatelessWidget {
  const _TalentsDiscoveryHeader({
    required this.activeQuery,
    required this.onOpenFilters,
    required this.onReset,
  });

  final String activeQuery;
  final VoidCallback onOpenFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ModernColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              AppIcons.talents,
              color: ModernColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeQuery.isEmpty ? 'Boutiques & ateliers' : activeQuery,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Choisir un filtre ou une intention',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ModernColors.inkSoft, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Filtres',
            onPressed: onOpenFilters,
            icon: const Icon(Icons.tune_rounded),
          ),
          if (activeQuery.isNotEmpty)
            IconButton(
              tooltip: 'Réinitialiser',
              onPressed: onReset,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

class _TalentSections extends StatelessWidget {
  const _TalentSections({
    required this.talents,
    required this.activeRole,
    required this.intent,
    required this.onReset,
  });

  final List<TalentProfile> talents;
  final String activeRole;
  final String intent;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (talents.isEmpty) {
      return _StateCard(
        icon: AppIcons.talents,
        title: 'Aucun talent trouvé',
        message: 'Aucun profil ne correspond à ce filtre.',
        actionLabel: 'Voir tous',
        onAction: onReset,
      );
    }

    final roleText = activeRole.toLowerCase();
    final creatorMode =
        roleText.contains('créateur') || roleText.contains('createur');
    final creatorsAll =
        talents.where((talent) => talent.primaryRole == 'Créateur').toList();
    final displayTalents =
        creatorMode
            ? [
              ...creatorsAll,
              ...talents.where((talent) => talent.primaryRole != 'Créateur'),
            ]
            : talents;
    final best = _bestPick(displayTalents);
    final recommended =
        displayTalents
            .where((talent) => talent.id != best?.id)
            .take(8)
            .toList();
    final contextual = _contextualTalents(displayTalents).take(6).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (best != null) ...[
          _BestTalentPanel(talent: best),
          const SizedBox(height: 18),
        ],
        _TalentSignalStrip(talents: displayTalents),
        const SizedBox(height: 18),
        if (contextual.isNotEmpty && intent != 'match') ...[
          _HorizontalTalentSection(
            title: _contextualTitle,
            talents: contextual,
          ),
          const SizedBox(height: 18),
        ] else if (recommended.isNotEmpty) ...[
          _HorizontalTalentSection(
            title: creatorMode ? 'Créateurs recommandés' : 'Recommandés',
            talents: recommended.take(6).toList(),
          ),
          const SizedBox(height: 18),
        ],
        SectionHeader(
          padding: EdgeInsets.zero,
          title: creatorMode ? 'Tous les créateurs' : 'Tous les profils',
        ),
        const SizedBox(height: 12),
        for (final talent in displayTalents.take(30)) ...[
          TalentCard(talent: talent, portfolio: _previewPortfolio(talent)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  TalentProfile? _bestPick(List<TalentProfile> items) {
    if (items.isEmpty) return null;
    final ranked = [...items]..sort((a, b) {
      final aScore = _decisionScore(a);
      final bScore = _decisionScore(b);
      return bScore.compareTo(aScore);
    });
    return ranked.first;
  }

  int _decisionScore(TalentProfile talent) {
    var score = talent.relevanceScore;
    final isShop = talent.primaryRole == 'Boutique';
    final isCreator = talent.primaryRole == 'Créateur';
    if (talent.verified) score += 60;
    if (talent.hasPortfolio) score += 50;
    if (talent.isAvailable) score += 35;
    if (talent.madeToMeasure) score += intent == 'fit' ? 90 : 20;
    if (isCreator && talent.hasCreations) score += intent == 'fit' ? 50 : 20;
    if (isShop && talent.hasProducts) score += intent == 'shop' ? 90 : 20;
    if (talent.acceptsAppointments) score += 25;
    if (intent == 'beauty' &&
        (talent.primaryRole == 'Coiffure' ||
            talent.primaryRole == 'Maquillage')) {
      score += 90;
    }
    if (intent == 'event' &&
        (talent.searchText.contains('mariage') ||
            talent.searchText.contains('soirée') ||
            talent.searchText.contains('event') ||
            talent.searchText.contains('événement'))) {
      score += 90;
    }
    return score;
  }

  Iterable<TalentProfile> _contextualTalents(List<TalentProfile> items) {
    return switch (intent) {
      'fit' => items.where(
        (talent) => talent.madeToMeasure || talent.hasCreations,
      ),
      'now' => items.where((talent) => talent.isAvailable),
      'shop' => items.where(
        (talent) => talent.hasProducts || talent.primaryRole == 'Boutique',
      ),
      'event' => items.where(
        (talent) =>
            talent.searchText.contains('mariage') ||
            talent.searchText.contains('cérémonie') ||
            talent.searchText.contains('soirée') ||
            talent.searchText.contains('event') ||
            talent.searchText.contains('événement'),
      ),
      'beauty' => items.where(
        (talent) =>
            talent.primaryRole == 'Coiffure' ||
            talent.primaryRole == 'Maquillage' ||
            talent.searchText.contains('beaut'),
      ),
      _ => items,
    };
  }

  String get _contextualTitle {
    return switch (intent) {
      'fit' => 'Sur mesure',
      'now' => 'Disponibles',
      'shop' => 'Prêts à commander',
      'event' => 'Pour événement',
      'beauty' => 'Beauté',
      _ => 'Recommandés',
    };
  }
}

class _HorizontalTalentSection extends StatelessWidget {
  const _HorizontalTalentSection({required this.title, required this.talents});

  final String title;
  final List<TalentProfile> talents;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(padding: EdgeInsets.zero, title: title),
        const SizedBox(height: 10),
        SizedBox(
          height: 348,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: talents.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final talent = talents[index];
              return SizedBox(
                width: 300,
                child: TalentCard(
                  talent: talent,
                  portfolio: _previewPortfolio(talent),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TalentIntent {
  const _TalentIntent(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

class _IntentRail extends StatelessWidget {
  const _IntentRail({
    required this.intents,
    required this.selected,
    required this.onSelected,
  });

  final List<_TalentIntent> intents;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: intents.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final intent = intents[index];
          final isSelected = selected == intent.id;
          return _IntentButton(
            intent: intent,
            selected: isSelected,
            onTap: () => onSelected(intent.id),
          );
        },
      ),
    );
  }
}

class _IntentButton extends StatelessWidget {
  const _IntentButton({
    required this.intent,
    required this.selected,
    required this.onTap,
  });

  final _TalentIntent intent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Material(
        color: selected ? ModernColors.primary : ModernColors.surface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            constraints: const BoxConstraints(minWidth: 92, maxWidth: 132),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? ModernColors.primary : ModernColors.line,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  intent.icon,
                  size: 17,
                  color: selected ? Colors.white : ModernColors.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    intent.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : ModernColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BestTalentPanel extends StatelessWidget {
  const _BestTalentPanel({required this.talent});

  final TalentProfile talent;

  Color get _color {
    return switch (talent.primaryRole) {
      'Boutique' => ModernColors.shop,
      'Coiffure' => ModernColors.client,
      'Chaussures' => ModernColors.rose,
      'Maquillage' => ModernColors.rose,
      _ => ModernColors.creator,
    };
  }

  void _openDetail(BuildContext context, List<TalentPortfolioItem> portfolio) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TalentDetailSheet(talent: talent, portfolio: portfolio),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = _previewPortfolio(talent);
    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(14),
      color: _color.withValues(alpha: 0.06),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'Meilleur choix',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (talent.verified)
                const Icon(
                  Icons.verified_rounded,
                  color: ModernColors.client,
                  size: 21,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 86,
                  height: 104,
                  child:
                      talent.photoUrl.isEmpty
                          ? ColoredBox(
                            color: _color.withValues(alpha: 0.14),
                            child: Icon(
                              AppIcons.talents,
                              color: _color,
                              size: 34,
                            ),
                          )
                          : CachedNetworkImage(
                            imageUrl: talent.photoUrl,
                            fit: BoxFit.cover,
                            errorWidget:
                                (_, _, _) => ColoredBox(
                                  color: _color.withValues(alpha: 0.14),
                                  child: Icon(AppIcons.talents, color: _color),
                                ),
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      talent.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${talent.primaryRole} · ${talent.place}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      talent.speciality,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _color,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      talent.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        height: 1.25,
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
          Row(
            children: [
              Expanded(
                child: _SignalPill(
                  icon:
                      talent.primaryRole == 'Boutique'
                          ? AppIcons.shop
                          : AppIcons.creations,
                  label:
                      talent.primaryRole == 'Boutique'
                          ? '${talent.productsCount} produits'
                          : '${talent.creationsCount} créations',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SignalPill(
                  icon:
                      talent.primaryRole == 'Boutique'
                          ? AppIcons.boutique
                          : AppIcons.creator,
                  label:
                      talent.primaryRole == 'Boutique' ? 'Boutique' : 'Atelier',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openDetail(context, portfolio),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Voir le profil'),
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

List<TalentPortfolioItem> _previewPortfolio(TalentProfile talent) {
  final type = talent.primaryRole == 'Boutique' ? 'product' : 'creation';
  return talent.portfolioImages
      .where((url) => url.trim().isNotEmpty)
      .take(3)
      .toList()
      .asMap()
      .entries
      .map(
        (entry) => TalentPortfolioItem(
          id: '${talent.id}-preview-${entry.key}',
          title: talent.displayName,
          imageUrl: entry.value,
          type: type,
        ),
      )
      .toList();
}

class _TalentSignalStrip extends StatelessWidget {
  const _TalentSignalStrip({required this.talents});

  final List<TalentProfile> talents;

  @override
  Widget build(BuildContext context) {
    final available = talents.where((talent) => talent.isAvailable).length;
    final verified = talents.where((talent) => talent.verified).length;
    final portfolio = talents.where((talent) => talent.hasPortfolio).length;
    return Row(
      children: [
        Expanded(
          child: _SignalPill(
            icon: Icons.flash_on_rounded,
            label: '$available dispo',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SignalPill(
            icon: Icons.verified_rounded,
            label: '$verified vérifiés',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SignalPill(
            icon: Icons.photo_library_rounded,
            label: '$portfolio portfolios',
          ),
        ),
      ],
    );
  }
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: ModernColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: ModernColors.primary, size: 16),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TalentFiltersSheet extends StatefulWidget {
  const _TalentFiltersSheet({required this.initial});

  final TalentFilter initial;

  @override
  State<_TalentFiltersSheet> createState() => _TalentFiltersSheetState();
}

class _TalentFiltersSheetState extends State<_TalentFiltersSheet> {
  late TextEditingController _locationController;
  late TextEditingController _languageController;
  late bool _availableOnly;
  late bool _verifiedOnly;
  late bool _withCreationsOnly;
  late bool _withProductsOnly;
  late bool _madeToMeasureOnly;
  late bool _appointmentOnly;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.initial.location);
    _languageController = TextEditingController(text: widget.initial.language);
    _availableOnly = widget.initial.availableOnly;
    _verifiedOnly = widget.initial.verifiedOnly;
    _withCreationsOnly = widget.initial.withCreationsOnly;
    _withProductsOnly = widget.initial.withProductsOnly;
    _madeToMeasureOnly = widget.initial.madeToMeasureOnly;
    _appointmentOnly = widget.initial.appointmentOnly;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ModernColors.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: ModernShadows.elevated,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtres Talents',
                style: TextStyle(
                  color: ModernColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Localisation',
                  hintText: 'Paris, Dakar, Tokyo, Abidjan...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _languageController,
                decoration: const InputDecoration(
                  labelText: 'Langue',
                  hintText: 'Français, Mooré, Dioula...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language_rounded),
                ),
              ),
              const SizedBox(height: 12),
              _SwitchTile(
                value: _availableOnly,
                title: 'Disponible maintenant',
                onChanged: (value) => setState(() => _availableOnly = value),
              ),
              _SwitchTile(
                value: _verifiedOnly,
                title: 'Profil vérifié',
                onChanged: (value) => setState(() => _verifiedOnly = value),
              ),
              _SwitchTile(
                value: _withCreationsOnly,
                title: 'Avec créations publiées',
                onChanged:
                    (value) => setState(() => _withCreationsOnly = value),
              ),
              _SwitchTile(
                value: _withProductsOnly,
                title: 'Avec produits à acheter',
                onChanged: (value) => setState(() => _withProductsOnly = value),
              ),
              _SwitchTile(
                value: _madeToMeasureOnly,
                title: 'Sur mesure',
                onChanged:
                    (value) => setState(() => _madeToMeasureOnly = value),
              ),
              _SwitchTile(
                value: _appointmentOnly,
                title: 'Rendez-vous disponible',
                onChanged: (value) => setState(() => _appointmentOnly = value),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          widget.initial.copyWith(
                            location: _locationController.text.trim(),
                            language: _languageController.text.trim(),
                            availableOnly: _availableOnly,
                            verifiedOnly: _verifiedOnly,
                            withCreationsOnly: _withCreationsOnly,
                            withProductsOnly: _withProductsOnly,
                            madeToMeasureOnly: _madeToMeasureOnly,
                            appointmentOnly: _appointmentOnly,
                          ),
                        );
                      },
                      child: const Text('Appliquer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.value,
    required this.title,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        4,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: AppCard(child: _TalentSkeleton()),
        ),
      ),
    );
  }
}

class _TalentSkeleton extends StatelessWidget {
  const _TalentSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SkeletonBox(width: 82, height: 96, radius: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SkeletonBox(width: 150, height: 16, radius: 8),
              SizedBox(height: 10),
              _SkeletonBox(width: 210, height: 12, radius: 8),
              SizedBox(height: 8),
              _SkeletonBox(width: 180, height: 12, radius: 8),
              SizedBox(height: 16),
              Row(
                children: [
                  _SkeletonBox(width: 70, height: 34, radius: 12),
                  SizedBox(width: 8),
                  _SkeletonBox(width: 86, height: 34, radius: 12),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ModernColors.line.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ModernColors.inkSoft, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ModernColors.inkSoft),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
