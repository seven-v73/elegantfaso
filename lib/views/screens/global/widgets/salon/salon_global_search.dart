import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/app_icons.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/salon/salon_context.dart';
import '../../../../../models/salon/salon_item.dart';
import '../../../../../models/salon/salon_section.dart';
import '../../../../../services/app/app_context_service.dart';
import '../../../../../services/salon/salon_context_service.dart';
import '../../../../../services/salon/salon_recently_viewed_service.dart';
import '../../../../../services/salon/salon_unified_search_service.dart';
import 'salon_empty_state.dart';
import 'salon_section_rail.dart';
import 'salon_universal_detail_sheet.dart';

class SalonGlobalSearch extends StatefulWidget {
  const SalonGlobalSearch({
    super.key,
    required this.onExploreContext,
    required this.onLoginRequired,
    this.initialQuery = '',
  });

  final ValueChanged<SalonContext> onExploreContext;
  final VoidCallback onLoginRequired;
  final String initialQuery;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<SalonContext> onExploreContext,
    required VoidCallback onLoginRequired,
    String initialQuery = '',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => SalonGlobalSearch(
            initialQuery: initialQuery,
            onExploreContext: onExploreContext,
            onLoginRequired: onLoginRequired,
          ),
    );
  }

  @override
  State<SalonGlobalSearch> createState() => _SalonGlobalSearchState();
}

class _SalonGlobalSearchState extends State<SalonGlobalSearch> {
  final TextEditingController _controller = TextEditingController();
  final SalonUnifiedSearchService _searchService = SalonUnifiedSearchService();
  final SalonContextService _contextService = SalonContextService();
  final AppContextService _appContextService = AppContextService();
  final SalonRecentlyViewedService _recentlyViewedService =
      SalonRecentlyViewedService();

  Future<List<SalonSection>>? _future;
  String _query = '';
  Timer? _debounce;
  _SearchTab _activeTab = _SearchTab.all;

  static const _suggestions = [
    'tenue mariage',
    'coiffure mariage',
    'boutiques mode',
    'créateurs proches',
    'chaussures cuir',
    'textile culturel',
    'atelier couture',
    'look bureau',
  ];

  static const _intents = [
    _SearchIntent(
      label: 'Acheter',
      query: 'produits disponibles',
      icon: AppIcons.shop,
      tab: _SearchTab.products,
    ),
    _SearchIntent(
      label: 'Pro',
      query: 'boutiques créateurs',
      icon: Icons.groups_2_rounded,
      tab: _SearchTab.shops,
    ),
    _SearchIntent(
      label: 'Sur mesure',
      query: 'créateur sur mesure',
      icon: AppIcons.creator,
      tab: _SearchTab.creators,
    ),
    _SearchIntent(
      label: 'Idées',
      query: 'inspiration style',
      icon: AppIcons.inspiration,
      tab: _SearchTab.ideas,
    ),
    _SearchIntent(
      label: 'Agenda',
      query: 'événement mode',
      icon: Icons.event_available_rounded,
      tab: _SearchTab.events,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _controller.text = _query;
    if (_query.isNotEmpty) _search(_query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleSearch(String value) {
    final query = value.trim();
    _debounce?.cancel();
    setState(() {
      _query = query;
      _activeTab = _SearchTab.all;
      if (query.isEmpty) _future = null;
    });
    if (query.length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 280), () => _search(query));
  }

  void _search(
    String value, {
    bool remember = false,
    _SearchTab targetTab = _SearchTab.all,
  }) {
    final query = value.trim();
    final context = SalonContext.fromQuery(query, source: 'search');
    setState(() {
      _query = query;
      _future = query.isEmpty ? null : _searchService.search(context);
      _activeTab = query.isEmpty ? _SearchTab.all : targetTab;
    });
    _appContextService.setSalonContext(context, source: 'global_search');
    if (remember) _contextService.remember(context);
  }

  void _openItem(SalonItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => SalonUniversalDetailSheet(
            item: item,
            onExploreContext: (context) {
              widget.onExploreContext(context);
              Navigator.pop(this.context);
            },
            onLoginRequired: widget.onLoginRequired,
          ),
    );
  }

  void _explore() {
    final salonContext = _contextForExplore();
    if (salonContext.isEmpty) return;
    _appContextService.setSalonContext(salonContext, source: 'global_search');
    _contextService.remember(salonContext);
    widget.onExploreContext(salonContext);
    Navigator.pop(context);
  }

  SalonContext _contextForExplore() {
    final base = SalonContext.fromQuery(_query, source: 'global_search');
    return switch (_activeTab) {
      _SearchTab.products => base.copyWith(type: 'produit'),
      _SearchTab.shops => base.copyWith(type: 'boutique'),
      _SearchTab.creators => base.copyWith(type: 'créateur'),
      _SearchTab.ideas => base.copyWith(type: 'inspiration'),
      _SearchTab.events => base.copyWith(type: 'événement'),
      _SearchTab.all => base,
    };
  }

  List<String> _suggestionsFor(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return _suggestions;
    final related = <String>{
      '$clean produits',
      '$clean créations',
      '$clean talents',
    };
    if (!clean.contains('mariage')) related.add('$clean mariage');
    if (!clean.contains('accessoire')) related.add('$clean accessoires');
    return related.take(6).toList();
  }

  void _applyQuery(
    String query, {
    bool remember = true,
    _SearchTab targetTab = _SearchTab.all,
  }) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    _search(query, remember: remember, targetTab: targetTab);
  }

  void _applyIntent(_SearchIntent intent) {
    _applyQuery(intent.query, targetTab: intent.tab);
  }

  void _clearQuery() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _query = '';
      _future = null;
      _activeTab = _SearchTab.all;
    });
  }

  List<SalonItem> _filteredItemsForTab(List<SalonSection> sections) {
    if (_activeTab == _SearchTab.all) return const [];
    return _uniqueSalonItems(
      sections.expand((section) => section.items).where(_matchesActiveTab),
    );
  }

  bool _matchesActiveTab(SalonItem item) {
    return switch (_activeTab) {
      _SearchTab.all => true,
      _SearchTab.products => item.type == SalonItemType.product,
      _SearchTab.shops =>
        item.type == SalonItemType.talent &&
            (item.data['salonRole']?.toString().toLowerCase() ?? '').contains(
              'boutique',
            ),
      _SearchTab.creators =>
        item.type == SalonItemType.talent &&
            (item.data['salonRole']?.toString().toLowerCase() ?? '').contains(
              'createur',
            ),
      _SearchTab.ideas =>
        item.type == SalonItemType.inspiration ||
            item.type == SalonItemType.article ||
            item.type == SalonItemType.creation,
      _SearchTab.events => item.type == SalonItemType.event,
    };
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.52,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ModernColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SearchField(
                controller: _controller,
                query: _query,
                onChanged: _scheduleSearch,
                onSubmitted: (value) => _search(value, remember: true),
                onClear: _clearQuery,
                onExplore: _query.isEmpty ? null : _explore,
              ),
              const SizedBox(height: 12),
              _IntentRail(intents: _intents, onSelected: _applyIntent),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _suggestionsFor(_query)
                        .map(
                          (item) => ActionChip(
                            avatar: const Icon(
                              Icons.north_east_rounded,
                              size: 15,
                            ),
                            label: Text(item),
                            onPressed: () => _applyQuery(item),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 18),
              if (_future == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuickAccess(onSelected: _applyIntent),
                    const SizedBox(height: 18),
                    _RecentSearches(
                      service: _contextService,
                      onSelected:
                          (context) => _applyQuery(
                            context.displayQuery,
                            remember: false,
                          ),
                    ),
                    const SizedBox(height: 18),
                    _RecentlyViewedRail(
                      service: _recentlyViewedService,
                      onItemTap: _openItem,
                    ),
                    const SizedBox(height: 18),
                    _ForYouPreview(
                      service: _searchService,
                      onItemTap: _openItem,
                    ),
                  ],
                )
              else
                FutureBuilder<List<SalonSection>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _SearchLoading();
                    }
                    if (snapshot.hasError) {
                      return const SalonEmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Recherche indisponible',
                        message: 'Impossible de charger le Salon maintenant.',
                      );
                    }
                    final sections = snapshot.data ?? const <SalonSection>[];
                    if (sections.isEmpty) {
                      return const SalonEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Aucun résultat',
                        message:
                            'Essaie une recherche plus large ou une catégorie.',
                      );
                    }
                    final highlights = _topItems(sections);
                    final filteredItems = _filteredItemsForTab(sections);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ResultSummary(sections: sections, onExplore: _explore),
                        const SizedBox(height: 12),
                        _ResultTabs(
                          active: _activeTab,
                          sections: sections,
                          onChanged: (tab) => setState(() => _activeTab = tab),
                        ),
                        const SizedBox(height: 16),
                        if (_activeTab == _SearchTab.all &&
                            highlights.isNotEmpty) ...[
                          _TopResults(items: highlights, onItemTap: _openItem),
                          const SizedBox(height: 18),
                        ],
                        if (_activeTab != _SearchTab.all &&
                            filteredItems.isNotEmpty)
                          _FilteredResultsList(
                            title: _activeTab.label,
                            subtitle: _activeTab.subtitle,
                            items: filteredItems,
                            onItemTap: _openItem,
                          )
                        else if (_activeTab != _SearchTab.all)
                          SalonEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'Rien ici',
                            message:
                                'Essaie un autre onglet ou une recherche plus large.',
                            onRetry:
                                () =>
                                    setState(() => _activeTab = _SearchTab.all),
                          )
                        else
                          for (final section in _secondarySections(
                            sections,
                          )) ...[
                            SalonSectionRail(
                              section: section,
                              onItemTap: _openItem,
                            ),
                            const SizedBox(height: 22),
                          ],
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  List<SalonItem> _topItems(List<SalonSection> sections) {
    final explicit =
        _uniqueSalonItems(
          sections
              .where((section) => section.title == 'Meilleurs choix')
              .expand((section) => section.items),
        ).take(3).toList();
    if (explicit.isNotEmpty) return explicit;
    return _uniqueSalonItems(
      sections.expand((section) => section.items),
    ).take(3).toList();
  }

  List<SalonSection> _secondarySections(List<SalonSection> sections) {
    if (_activeTab != _SearchTab.all) return sections;
    return sections
        .where((section) => section.title != 'Meilleurs choix')
        .toList();
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.sections, required this.onExplore});

  final List<SalonSection> sections;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final uniqueItems = _uniqueSalonItems(
      sections
          .where((section) => section.title != 'Meilleurs choix')
          .expand((section) => section.items),
    );
    final total = uniqueItems.length;
    final visible =
        sections
            .where((section) => section.title != 'Meilleurs choix')
            .take(5)
            .toList();
    return AppCard(
      padding: const EdgeInsets.all(12),
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
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: ModernColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  total <= 1 ? '$total résultat' : '$total résultats',
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onExplore,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Explorer'),
              ),
            ],
          ),
          if (visible.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  visible
                      .map(
                        (section) => Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            '${section.title} ${section.items.length}',
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onExplore,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevated: false,
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: ModernColors.inkSoft),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Style, produit, talent, ville...',
              ),
              onSubmitted: onSubmitted,
              onChanged: onChanged,
            ),
          ),
          if (query.isNotEmpty)
            IconButton(
              tooltip: 'Effacer',
              icon: const Icon(Icons.close_rounded),
              onPressed: onClear,
            ),
          IconButton(
            tooltip: 'Explorer',
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: onExplore,
          ),
        ],
      ),
    );
  }
}

class _IntentRail extends StatelessWidget {
  const _IntentRail({required this.intents, required this.onSelected});

  final List<_SearchIntent> intents;
  final ValueChanged<_SearchIntent> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: intents.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final intent = intents[index];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onSelected(intent),
            child: Container(
              width: 92,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ModernColors.canvas,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ModernColors.line),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(intent.icon, size: 20, color: ModernColors.primary),
                  const SizedBox(height: 6),
                  Text(
                    intent.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.onSelected});

  final ValueChanged<_SearchIntent> onSelected;

  static const _items = [
    _SearchIntent(
      label: 'Boutique',
      query: 'boutiques mode',
      icon: AppIcons.boutique,
      tab: _SearchTab.shops,
    ),
    _SearchIntent(
      label: 'Créateur',
      query: 'créateurs ateliers',
      icon: AppIcons.creator,
      tab: _SearchTab.creators,
    ),
    _SearchIntent(
      label: 'Produit',
      query: 'produits disponibles',
      icon: AppIcons.shop,
      tab: _SearchTab.products,
    ),
    _SearchIntent(
      label: 'Idée',
      query: 'inspiration style',
      icon: AppIcons.inspiration,
      tab: _SearchTab.ideas,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          padding: EdgeInsets.zero,
          title: 'Accès rapides',
          subtitle: 'Aller droit au bon contenu',
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 58,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = _items[index];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onSelected(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: ModernColors.canvas,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ModernColors.line),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: ModernColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ModernColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ResultTabs extends StatelessWidget {
  const _ResultTabs({
    required this.active,
    required this.sections,
    required this.onChanged,
  });

  final _SearchTab active;
  final List<SalonSection> sections;
  final ValueChanged<_SearchTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _SearchTab.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = _SearchTab.values[index];
          final selected = tab == active;
          return ChoiceChip(
            selected: selected,
            label: Text('${tab.label} ${_countFor(tab)}'),
            onSelected: (_) => onChanged(tab),
          );
        },
      ),
    );
  }

  int _countFor(_SearchTab tab) {
    final items = _uniqueSalonItems(
      sections
          .where((section) => section.title != 'Meilleurs choix')
          .expand((section) => section.items),
    );
    return switch (tab) {
      _SearchTab.all => items.length,
      _SearchTab.products =>
        items.where((item) => item.type == SalonItemType.product).length,
      _SearchTab.shops =>
        items.where((item) {
          final role = item.data['salonRole']?.toString().toLowerCase() ?? '';
          return item.type == SalonItemType.talent && role.contains('boutique');
        }).length,
      _SearchTab.creators =>
        items.where((item) {
          final role = item.data['salonRole']?.toString().toLowerCase() ?? '';
          return item.type == SalonItemType.talent && role.contains('createur');
        }).length,
      _SearchTab.ideas =>
        items
            .where(
              (item) =>
                  item.type == SalonItemType.inspiration ||
                  item.type == SalonItemType.article ||
                  item.type == SalonItemType.creation,
            )
            .length,
      _SearchTab.events =>
        items.where((item) => item.type == SalonItemType.event).length,
    };
  }
}

class _FilteredResultsList extends StatelessWidget {
  const _FilteredResultsList({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onItemTap,
  });

  final String title;
  final String subtitle;
  final List<SalonItem> items;
  final ValueChanged<SalonItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          padding: EdgeInsets.zero,
          title: title,
          subtitle: subtitle,
        ),
        const SizedBox(height: 10),
        for (final item in items.take(18)) ...[
          _SearchResultTile(item: item, onTap: () => onItemTap(item)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TopResults extends StatelessWidget {
  const _TopResults({required this.items, required this.onItemTap});

  final List<SalonItem> items;
  final ValueChanged<SalonItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          padding: EdgeInsets.zero,
          title: 'Meilleurs choix',
          subtitle: 'À ouvrir en premier',
        ),
        const SizedBox(height: 10),
        for (final item in items) ...[
          _SearchResultTile(item: item, onTap: () => onItemTap(item)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.item, required this.onTap});

  final SalonItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      elevated: false,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 58,
              height: 58,
              child:
                  item.hasImage
                      ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _TileFallback(item: item),
                      )
                      : _TileFallback(item: item),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.priceLabel.isEmpty ? item.subtitle : item.priceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        item.priceLabel.isEmpty
                            ? ModernColors.inkSoft
                            : item.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text(item.typeLabel),
          ),
        ],
      ),
    );
  }
}

class _TileFallback extends StatelessWidget {
  const _TileFallback({required this.item});

  final SalonItem item;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: item.color.withValues(alpha: 0.1),
      child: Icon(item.icon, color: item.color, size: 24),
    );
  }
}

class _RecentlyViewedRail extends StatelessWidget {
  const _RecentlyViewedRail({required this.service, required this.onItemTap});

  final SalonRecentlyViewedService service;
  final ValueChanged<SalonItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SalonItem>>(
      future: service.load(limit: 10),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <SalonItem>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return SalonSectionRail(
          section: SalonSection(
            title: 'Vu récemment',
            subtitle: 'Reprendre une inspiration, un produit ou un talent',
            items: items,
          ),
          onItemTap: onItemTap,
        );
      },
    );
  }
}

class _ForYouPreview extends StatelessWidget {
  const _ForYouPreview({required this.service, required this.onItemTap});

  final SalonUnifiedSearchService service;
  final ValueChanged<SalonItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SalonItem>>(
      future: service.loadRecommendations(
        SalonContext(
          query: 'mode style création boutique événement',
          source: 'for_you',
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SearchLoading();
        }
        final items = snapshot.data ?? const <SalonItem>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return SalonSectionRail(
          section: SalonSection(
            title: 'Pour toi',
            subtitle: 'Sélection du Salon',
            items: items.take(12).toList(),
          ),
          onItemTap: onItemTap,
        );
      },
    );
  }
}

class _RecentSearches extends StatefulWidget {
  const _RecentSearches({required this.service, required this.onSelected});

  final SalonContextService service;
  final ValueChanged<SalonContext> onSelected;

  @override
  State<_RecentSearches> createState() => _RecentSearchesState();
}

class _RecentSearchesState extends State<_RecentSearches> {
  late Future<List<SalonContext>> _future = widget.service.loadRecent();

  void _reload() {
    setState(() {
      _future = widget.service.loadRecent();
    });
  }

  Future<void> _remove(SalonContext context) async {
    await widget.service.remove(context.displayQuery);
    if (!mounted) return;
    _reload();
  }

  Future<void> _clear() async {
    await widget.service.clearRecent();
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SalonContext>>(
      future: _future,
      builder: (context, snapshot) {
        final recent = snapshot.data ?? const <SalonContext>[];
        if (recent.isEmpty) {
          return const SalonEmptyState(
            icon: AppIcons.salon,
            title: 'Cherche dans tout le Salon',
            message:
                'Une seule recherche relie inspirations, produits, talents et événements.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: SectionHeader(
                    padding: EdgeInsets.zero,
                    title: 'Vu récemment',
                    subtitle: 'Reprendre une recherche',
                  ),
                ),
                TextButton(onPressed: _clear, child: const Text('Effacer')),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  recent
                      .map(
                        (recentContext) => InputChip(
                          avatar: const Icon(Icons.history_rounded, size: 16),
                          label: Text(recentContext.displayQuery),
                          onDeleted: () => _remove(recentContext),
                          deleteIcon: const Icon(Icons.close_rounded, size: 16),
                          onPressed: () => widget.onSelected(recentContext),
                        ),
                      )
                      .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _SearchLoading extends StatelessWidget {
  const _SearchLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 224,
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

List<SalonItem> _uniqueSalonItems(Iterable<SalonItem> items) {
  final seen = <String>{};
  final result = <SalonItem>[];
  for (final item in items) {
    final key = '${item.type.name}:${item.id}';
    if (seen.add(key)) result.add(item);
  }
  return result;
}

enum _SearchTab {
  all('Tous', 'Résultats'),
  products('Produits', 'À acheter'),
  shops('Boutiques', 'Vitrines'),
  creators('Ateliers', 'Créateurs'),
  ideas('Idées', 'Inspirations'),
  events('Agenda', 'Événements');

  const _SearchTab(this.label, this.subtitle);

  final String label;
  final String subtitle;
}

class _SearchIntent {
  const _SearchIntent({
    required this.label,
    required this.query,
    required this.icon,
    this.tab = _SearchTab.all,
  });

  final String label;
  final String query;
  final IconData icon;
  final _SearchTab tab;
}
