import 'package:flutter/material.dart';

import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/salon/salon_overview.dart';
import '../../../../models/salon/salon_quick_entry.dart';
import '../../../../services/salon/salon_overview_service.dart';
import '../widgets/exploration/exploration_hero.dart';
import '../widgets/exploration/guest_cta_card.dart';
import '../widgets/exploration/live_highlights_section.dart';
import '../widgets/exploration/nearby_salon_section.dart';
import '../widgets/exploration/quick_entry_grid.dart';
import '../widgets/exploration/trending_now_section.dart';
import '../widgets/inspiration/community_screen.dart';

typedef SalonTargetOpener =
    void Function({
      String? query,
      String? category,
      String? role,
      String? topic,
    });

class DecouvrirTab extends StatefulWidget {
  const DecouvrirTab({
    super.key,
    required this.onOpenShop,
    required this.onOpenCreators,
    required this.onOpenInspiration,
    required this.onOpenAgenda,
    required this.onOpenMap,
    required this.onLogin,
  });

  final SalonTargetOpener onOpenShop;
  final SalonTargetOpener onOpenCreators;
  final SalonTargetOpener onOpenInspiration;
  final VoidCallback onOpenAgenda;
  final VoidCallback onOpenMap;
  final VoidCallback onLogin;

  @override
  State<DecouvrirTab> createState() => _DecouvrirTabState();
}

class _DecouvrirTabState extends State<DecouvrirTab>
    with AutomaticKeepAliveClientMixin {
  final SalonOverviewService _service = SalonOverviewService();
  late Future<SalonOverview> _future = _service.loadOverview();

  static const _entries = [
    SalonQuickEntry(
      title: 'Shopping',
      subtitle: 'Acheter',
      icon: AppIcons.shop,
      query: 'tenue',
      target: SalonQuickTarget.shop,
      color: ModernColors.shop,
    ),
    SalonQuickEntry(
      title: 'Talents',
      subtitle: 'Trouver un pro',
      icon: AppIcons.talents,
      query: 'créateur styliste',
      target: SalonQuickTarget.talents,
      color: ModernColors.creator,
    ),
    SalonQuickEntry(
      title: 'Agenda',
      subtitle: 'Sortir',
      icon: Icons.event_available_rounded,
      query: 'événement',
      target: SalonQuickTarget.agenda,
      color: ModernColors.accent,
    ),
    SalonQuickEntry(
      title: 'Carte',
      subtitle: 'Autour',
      icon: Icons.map_rounded,
      query: 'autour de moi',
      target: SalonQuickTarget.map,
      color: ModernColors.primary,
    ),
    SalonQuickEntry(
      title: 'Communauté',
      subtitle: 'Avis & conseils',
      icon: Icons.forum_rounded,
      query: 'avis communauté',
      target: SalonQuickTarget.community,
      color: ModernColors.accent,
    ),
  ];

  Future<void> _refresh() async {
    _service.clearCache();
    setState(() {
      _future = _service.loadOverview();
    });
    await _future;
  }

  void _openTarget(SalonQuickTarget target) {
    switch (target) {
      case SalonQuickTarget.shop:
        widget.onOpenShop();
      case SalonQuickTarget.talents:
        widget.onOpenCreators();
      case SalonQuickTarget.inspiration:
        widget.onOpenInspiration();
      case SalonQuickTarget.agenda:
        widget.onOpenAgenda();
      case SalonQuickTarget.map:
        widget.onOpenMap();
      case SalonQuickTarget.community:
        _openCommunity();
    }
  }

  void _openEntry(SalonQuickEntry entry) {
    switch (entry.target) {
      case SalonQuickTarget.shop:
        widget.onOpenShop(
          query: entry.query,
          category: _shopCategory(entry.query),
        );
      case SalonQuickTarget.talents:
        widget.onOpenCreators(
          query: entry.query,
          role: _talentRole(entry.query),
        );
      case SalonQuickTarget.inspiration:
        widget.onOpenInspiration(
          query: entry.query,
          topic: _inspirationTopic(entry.query),
        );
      case SalonQuickTarget.agenda:
        widget.onOpenAgenda();
      case SalonQuickTarget.map:
        widget.onOpenMap();
      case SalonQuickTarget.community:
        _openCommunity();
    }
  }

  void _openCommunity() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityScreen()),
    );
  }

  String _shopCategory(String query) {
    final text = query.toLowerCase();
    if (text.contains('coiff')) return 'Coiffures';
    if (text.contains('chauss')) return 'Chaussures';
    if (text.contains('accessoire')) return 'Accessoires';
    if (text.contains('mariage')) return 'Mariage';
    if (text.contains('homme')) return 'Hommes';
    if (text.contains('tenue') || text.contains('robe')) return 'Tenues';
    return 'Nouveautés';
  }

  String _talentRole(String query) {
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

  String _inspirationTopic(String query) {
    final text = query.toLowerCase();
    if (text.contains('coiff')) return 'Coiffures';
    if (text.contains('chauss')) return 'Chaussures';
    if (text.contains('mariage')) return 'Mariage';
    if (text.contains('homme')) return 'Hommes';
    if (text.contains('accessoire')) return 'Accessoires';
    if (text.contains('tenue') || text.contains('robe')) return 'Tenues';
    return 'Tous';
  }

  void _openWorkspace(SalonOverview overview) {
    if (overview.isShop) {
      Navigator.pushNamed(context, '/shop-dashboard');
    } else if (overview.isCreator) {
      Navigator.pushNamed(context, '/creator-dashboard');
    } else {
      Navigator.pushNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<SalonOverview>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ExplorationLoading();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _ExplorationState(
            icon: Icons.error_outline_rounded,
            title: 'Exploration indisponible',
            message: 'Impossible de charger la vitrine du Salon.',
            onRetry: _refresh,
          );
        }

        final overview = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            key: const PageStorageKey('salon_decouvrir_tab'),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              ExplorationHero(
                overview: overview,
                onOpenShop: () => widget.onOpenShop(),
                onOpenTalents: () => widget.onOpenCreators(),
              ),
              const SizedBox(height: 18),
              SectionHeader(padding: EdgeInsets.zero, title: 'Accès rapides'),
              const SizedBox(height: 12),
              QuickEntryGrid(entries: _entries, onSelected: _openEntry),
              const SizedBox(height: 18),
              if (overview.featuredSignature.isNotEmpty) ...[
                LiveHighlightsSection(
                  title: 'À la une',
                  subtitle: 'Signature',
                  items: overview.featuredSignature,
                  fallbackIcon: Icons.diamond_rounded,
                  onOpenTarget: _openTarget,
                  featured: true,
                ),
                const SizedBox(height: 22),
              ],
              LiveHighlightsSection(
                title: 'Aujourd’hui',
                subtitle: 'Nouveautés',
                items: overview.today,
                fallbackIcon: AppIcons.inspiration,
                onOpenTarget: _openTarget,
              ),
              const SizedBox(height: 22),
              NearbySalonSection(
                city: overview.city,
                items: overview.nearby,
                onOpenTarget: _openTarget,
              ),
              const SizedBox(height: 22),
              TrendingNowSection(
                items: overview.trending,
                onOpenTarget: _openTarget,
              ),
              const SizedBox(height: 22),
              GuestCtaCard(
                overview: overview,
                onOpenWorkspace: () => _openWorkspace(overview),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _ExplorationLoading extends StatelessWidget {
  const _ExplorationLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        Container(
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ModernRadius.lg),
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.36,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder:
              (_, _) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ModernRadius.lg),
                ),
              ),
        ),
      ],
    );
  }
}

class _ExplorationState extends StatelessWidget {
  const _ExplorationState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(icon, color: ModernColors.primary, size: 34),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ModernColors.inkSoft),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
