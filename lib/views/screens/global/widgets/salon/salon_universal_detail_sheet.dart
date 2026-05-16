import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/app_icons.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/app/app_user_capabilities.dart';
import '../../../../../models/salon/salon_action.dart';
import '../../../../../models/salon/salon_context.dart';
import '../../../../../models/salon/salon_item.dart';
import '../../../../../models/try_on/try_on_source.dart';
import '../../../../../services/app/app_action_service.dart';
import '../../../../../services/salon/salon_action_service.dart';
import '../../../../../services/salon/salon_analytics_service.dart';
import '../../../../../services/salon/salon_recommendation_service.dart';
import '../../../../../services/salon/salon_recently_viewed_service.dart';
import '../../../client/features/virtual_try_on_screen.dart';
import 'salon_item_card.dart';

class SalonUniversalDetailSheet extends StatefulWidget {
  const SalonUniversalDetailSheet({
    super.key,
    required this.item,
    required this.onExploreContext,
    required this.onLoginRequired,
  });

  final SalonItem item;
  final ValueChanged<SalonContext> onExploreContext;
  final VoidCallback onLoginRequired;

  @override
  State<SalonUniversalDetailSheet> createState() =>
      _SalonUniversalDetailSheetState();
}

class _SalonUniversalDetailSheetState extends State<SalonUniversalDetailSheet> {
  final AppActionService _appActionService = AppActionService();
  final SalonActionService _actionService = SalonActionService();
  final SalonAnalyticsService _analyticsService = SalonAnalyticsService();
  final SalonRecommendationService _recommendationService =
      SalonRecommendationService();
  final SalonRecentlyViewedService _recentlyViewedService =
      SalonRecentlyViewedService();
  late final Future<List<SalonItem>> _related = _recommendationService
      .relatedTo(widget.item);

  @override
  void initState() {
    super.initState();
    _recentlyViewedService.remember(widget.item);
    _analyticsService.trackView(item: widget.item);
  }

  Future<void> _handleAction(SalonAction action) async {
    final intent = _intentFor(action.type);
    final guard = await _appActionService.guard(
      intent,
      ownerId: widget.item.ownerId,
    );
    if (!guard.allowed) {
      if (!mounted) return;
      if (guard.message.toLowerCase().contains('connect')) {
        widget.onLoginRequired();
      } else {
        _snack(guard.message);
      }
      return;
    }

    try {
      switch (action.type) {
        case SalonActionType.save:
          await _actionService.save(widget.item);
          _snack('${widget.item.typeLabel} sauvegardé dans tes souhaits.');
        case SalonActionType.share:
          await _actionService.share(widget.item);
          _snack('Partage préparé.');
        case SalonActionType.contact:
          await _analyticsService.track(
            item: widget.item,
            eventType: 'contact_click',
          );
          final ok = await _actionService.contact(widget.item);
          if (!ok) _snack('Contact indisponible pour ce contenu.');
        case SalonActionType.tryOn:
          _openTryOn();
        case SalonActionType.tutorials:
          _exploreAndClose(
            '${widget.item.title} ${widget.item.subtitle} inspiration style',
            'Inspirations',
          );
        case SalonActionType.book:
          await _openExternalOrExplore(
            fallbackQuery: '${widget.item.title} ${widget.item.city}',
            fallbackSource: 'Agenda',
          );
        case SalonActionType.buy:
        case SalonActionType.creator:
        case SalonActionType.similar:
          _exploreAndClose(
            '${widget.item.title} ${widget.item.subtitle}',
            widget.item.typeLabel,
          );
      }
    } catch (_) {
      _snack('Action indisponible pour le moment.');
    }
  }

  SalonAction _primaryActionFor(SalonItem item) {
    final preferred = switch (item.type) {
      SalonItemType.product => SalonActionType.buy,
      SalonItemType.creation => SalonActionType.tryOn,
      SalonItemType.talent => SalonActionType.contact,
      SalonItemType.event => SalonActionType.book,
      SalonItemType.inspiration => SalonActionType.tryOn,
      SalonItemType.video => SalonActionType.similar,
      SalonItemType.article => SalonActionType.similar,
    };
    return item.actions.firstWhere(
      (action) => action.type == preferred,
      orElse:
          () =>
              item.actions.isNotEmpty
                  ? item.actions.first
                  : const SalonAction(
                    type: SalonActionType.similar,
                    label: 'Voir',
                    icon: Icons.arrow_forward_rounded,
                  ),
    );
  }

  List<SalonAction> _moreActionsFor(SalonAction primary) {
    return widget.item.actions
        .where(
          (action) =>
              action.type != primary.type &&
              action.type != SalonActionType.save &&
              action.type != SalonActionType.share,
        )
        .toList();
  }

  void _openMapContext() {
    _analyticsService.track(item: widget.item, eventType: 'map_click');
    widget.onExploreContext(
      SalonContext.fromQuery(
        widget.item.locationLabel.isEmpty
            ? widget.item.title
            : widget.item.locationLabel,
        source: 'Carte',
      ),
    );
    Navigator.pop(context);
  }

  void _showMoreActions(List<SalonAction> actions) {
    if (actions.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: ModernColors.surface,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final action in actions)
                    ListTile(
                      leading: Icon(action.icon, color: ModernColors.primary),
                      title: Text(action.label),
                      onTap: () {
                        Navigator.pop(context);
                        _handleAction(action);
                      },
                    ),
                ],
              ),
            ),
          ),
    );
  }

  AppActionIntent _intentFor(SalonActionType type) {
    return switch (type) {
      SalonActionType.save => AppActionIntent.save,
      SalonActionType.share => AppActionIntent.share,
      SalonActionType.contact => AppActionIntent.contact,
      SalonActionType.buy => AppActionIntent.buy,
      SalonActionType.book => AppActionIntent.book,
      SalonActionType.tryOn => AppActionIntent.tryOn,
      SalonActionType.creator => AppActionIntent.explore,
      SalonActionType.similar => AppActionIntent.explore,
      SalonActionType.tutorials => AppActionIntent.explore,
    };
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _exploreAndClose(String query, String source) {
    widget.onExploreContext(SalonContext.fromQuery(query, source: source));
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _openExternalOrExplore({
    required String fallbackQuery,
    required String fallbackSource,
  }) async {
    if (widget.item.url.trim().isNotEmpty) {
      final opened = await _actionService.openUrl(widget.item.url);
      if (opened) return;
      _snack('Lien externe indisponible, ouverture d’une recherche liée.');
    }
    _exploreAndClose(fallbackQuery, fallbackSource);
  }

  void _openTryOn() {
    if (widget.item.imageUrl.trim().isEmpty) {
      _snack('Image indisponible pour l’essayage.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => VirtualTryOnScreen(
              initialSource: TryOnSource(
                id: widget.item.id,
                type: _tryOnTypeFor(widget.item.type),
                title: widget.item.title,
                subtitle: widget.item.subtitle,
                imageUrl: widget.item.imageUrl,
                ownerId: widget.item.ownerId,
                raw: widget.item.data,
              ),
            ),
      ),
    );
  }

  TryOnSourceType _tryOnTypeFor(SalonItemType type) {
    return switch (type) {
      SalonItemType.creation => TryOnSourceType.creation,
      SalonItemType.product => TryOnSourceType.product,
      SalonItemType.inspiration => TryOnSourceType.wishlist,
      SalonItemType.talent ||
      SalonItemType.event ||
      SalonItemType.video ||
      SalonItemType.article => TryOnSourceType.wishlist,
    };
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.54,
      maxChildSize: 0.96,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
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
              const SizedBox(height: 14),
              _Hero(item: widget.item),
              const SizedBox(height: 16),
              Row(
                children: [
                  _TypeBadge(item: widget.item),
                  const SizedBox(width: 8),
                  if (widget.item.verified)
                    _CertificationBadge(item: widget.item),
                  if (widget.item.isFeatured) ...[
                    const SizedBox(width: 8),
                    const _FeaturedBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.item.title,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 24,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.item.subtitle,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _EditorialPanel(item: widget.item),
              const SizedBox(height: 14),
              _PrimaryActionRow(
                item: widget.item,
                primary: _primaryActionFor(widget.item),
                moreActions: _moreActionsFor(_primaryActionFor(widget.item)),
                onPrimary: _handleAction,
                onSave:
                    () => _handleAction(
                      const SalonAction(
                        type: SalonActionType.save,
                        label: 'Sauvegarder',
                        icon: Icons.bookmark_border_rounded,
                      ),
                    ),
                onShare:
                    () => _handleAction(
                      const SalonAction(
                        type: SalonActionType.share,
                        label: 'Partager',
                        icon: Icons.ios_share_rounded,
                      ),
                    ),
                onMap:
                    widget.item.locationLabel.isEmpty ? null : _openMapContext,
                onMore: _showMoreActions,
              ),
              const SizedBox(height: 18),
              _MetaPanel(item: widget.item),
              const SizedBox(height: 22),
              FutureBuilder<_PublicProfileExtras>(
                future: _PublicProfileExtras.load(widget.item.ownerId),
                builder: (context, snapshot) {
                  final extras = snapshot.data ?? _PublicProfileExtras.empty;
                  if (extras.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      _PremiumExtrasPanel(extras: extras),
                      const SizedBox(height: 22),
                    ],
                  );
                },
              ),
              FutureBuilder<List<SalonItem>>(
                future: _related,
                builder: (context, snapshot) {
                  final items =
                      (snapshot.data ?? const <SalonItem>[])
                          .where((item) => item.id != widget.item.id)
                          .take(8)
                          .toList();
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        padding: EdgeInsets.zero,
                        title: 'Lié à ce contenu',
                        subtitle:
                            'Produits, talents, idées et événements proches',
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 224,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return SalonItemCard(
                              item: item,
                              compact: true,
                              onTap:
                                  () => showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder:
                                        (_) => SalonUniversalDetailSheet(
                                          item: item,
                                          onExploreContext:
                                              widget.onExploreContext,
                                          onLoginRequired:
                                              widget.onLoginRequired,
                                        ),
                                  ),
                            );
                          },
                        ),
                      ),
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
}

class _PrimaryActionRow extends StatelessWidget {
  const _PrimaryActionRow({
    required this.item,
    required this.primary,
    required this.moreActions,
    required this.onPrimary,
    required this.onSave,
    required this.onShare,
    required this.onMap,
    required this.onMore,
  });

  final SalonItem item;
  final SalonAction primary;
  final List<SalonAction> moreActions;
  final ValueChanged<SalonAction> onPrimary;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback? onMap;
  final ValueChanged<List<SalonAction>> onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: primary.label,
            onPressed: () => onPrimary(primary),
            icon: primary.icon,
            expand: true,
          ),
        ),
        const SizedBox(width: 8),
        AppIconAction(
          icon: Icons.bookmark_border_rounded,
          tooltip: 'Sauvegarder',
          onPressed: onSave,
        ),
        const SizedBox(width: 8),
        AppIconAction(
          icon: Icons.ios_share_rounded,
          tooltip: 'Partager',
          onPressed: onShare,
        ),
        const SizedBox(width: 8),
        AppIconAction(
          icon:
              item.locationLabel.isEmpty
                  ? Icons.more_horiz_rounded
                  : Icons.map_rounded,
          tooltip: item.locationLabel.isEmpty ? 'Plus' : 'Carte',
          onPressed: item.locationLabel.isEmpty ? _moreHandler : onMap,
        ),
        if (item.locationLabel.isNotEmpty && moreActions.isNotEmpty) ...[
          const SizedBox(width: 8),
          AppIconAction(
            icon: Icons.more_horiz_rounded,
            tooltip: 'Plus',
            onPressed: _moreHandler,
          ),
        ],
      ],
    );
  }

  VoidCallback? get _moreHandler {
    if (moreActions.isEmpty) return null;
    return () => onMore(moreActions);
  }
}

class _CertificationBadge extends StatelessWidget {
  const _CertificationBadge({required this.item});

  final SalonItem item;

  @override
  Widget build(BuildContext context) {
    final color =
        item.isSignature ? ModernColors.creator : ModernColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.isSignature ? Icons.diamond_rounded : Icons.verified_rounded,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            item.certificationLabel,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedBadge extends StatelessWidget {
  const _FeaturedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: ModernColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Mis en avant',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.item});

  final SalonItem item;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.34,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child:
                item.hasImage
                    ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _Fallback(item: item),
                    )
                    : _Fallback(item: item),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    item.editorialLine,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (item.isSignature)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: ModernColors.creator,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.diamond_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'Signature',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
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
}

class _PremiumExtrasPanel extends StatelessWidget {
  const _PremiumExtrasPanel({required this.extras});

  final _PublicProfileExtras extras;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            padding: EdgeInsets.zero,
            title: 'Dans cette vitrine',
            subtitle: 'Pièces, agenda et communautés liées',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (extras.portfolioCount > 0)
                _ExtraChip(
                  icon: AppIcons.shop,
                  label: '${extras.portfolioCount} pièces à découvrir',
                ),
              if (extras.eventCount > 0)
                _ExtraChip(
                  icon: Icons.event_available_rounded,
                  label: '${extras.eventCount} événements à venir',
                ),
              if (extras.communityCount > 0)
                _ExtraChip(
                  icon: Icons.groups_3_rounded,
                  label: '${extras.communityCount} communautés',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExtraChip extends StatelessWidget {
  const _ExtraChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: ModernColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: ModernColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicProfileExtras {
  const _PublicProfileExtras({
    required this.portfolioCount,
    required this.eventCount,
    required this.communityCount,
  });

  final int portfolioCount;
  final int eventCount;
  final int communityCount;

  bool get isEmpty =>
      portfolioCount == 0 && eventCount == 0 && communityCount == 0;

  static const empty = _PublicProfileExtras(
    portfolioCount: 0,
    eventCount: 0,
    communityCount: 0,
  );

  static Future<_PublicProfileExtras> load(String ownerId) async {
    if (ownerId.trim().isEmpty) return empty;
    final firestore = FirebaseFirestore.instance;
    final now = Timestamp.fromDate(DateTime.now());
    try {
      final results = await Future.wait([
        firestore
            .collection('products')
            .where('ownerId', isEqualTo: ownerId)
            .limit(6)
            .get(),
        firestore
            .collection('creations')
            .where('ownerId', isEqualTo: ownerId)
            .limit(6)
            .get(),
        firestore
            .collection('events')
            .where('organizerId', isEqualTo: ownerId)
            .where('startAt', isGreaterThanOrEqualTo: now)
            .limit(6)
            .get(),
        firestore
            .collection('community_groups')
            .where('ownerId', isEqualTo: ownerId)
            .where('status', isEqualTo: 'approved')
            .limit(6)
            .get(),
      ]);
      return _PublicProfileExtras(
        portfolioCount: results[0].size + results[1].size,
        eventCount: results[2].size,
        communityCount: results[3].size,
      );
    } catch (_) {
      return empty;
    }
  }
}

class _EditorialPanel extends StatelessWidget {
  const _EditorialPanel({required this.item});

  final SalonItem item;

  @override
  Widget build(BuildContext context) {
    final chips = [
      if (item.ownerName.isNotEmpty) (AppIcons.creator, item.ownerName),
      if (item.locationLabel.isNotEmpty)
        (Icons.place_outlined, item.locationLabel),
      if (item.priceLabel.isNotEmpty) (Icons.sell_outlined, item.priceLabel),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          chips
              .map(
                (chip) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: ModernColors.canvas,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: ModernColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(chip.$1, size: 14, color: ModernColors.inkSoft),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          chip.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.item});

  final SalonItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: item.color.withValues(alpha: 0.12),
      child: Icon(item.icon, color: item.color, size: 54),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.item});

  final SalonItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${item.typeLabel} • ${item.badgeLabel}',
        style: TextStyle(
          color: item.color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetaPanel extends StatelessWidget {
  const _MetaPanel({required this.item});

  final SalonItem item;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (item.city.isNotEmpty) ('Localisation', item.city),
      if (item.priceLabel.isNotEmpty) ('Prix', item.priceLabel),
      if (item.source.isNotEmpty) ('Source', item.source),
      if (item.tags.isNotEmpty) ('Styles', item.tags.take(4).join(', ')),
    ];
    if (meta.isEmpty) return const SizedBox.shrink();
    return AppCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Column(
        children: [
          for (final entry in meta) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.$1,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    entry.$2,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            if (entry != meta.last) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}
