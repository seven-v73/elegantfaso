import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/inspiration/external_look.dart';
import '../../../../../models/inspiration/inspiration_item.dart';
import '../../../../../services/inspiration/inspiration_wishlist_service.dart';
import '../../salon_search_screen.dart';
import '../../../client/features/virtual_try_on_screen.dart';

class InspirationFeed extends StatefulWidget {
  const InspirationFeed({
    super.key,
    required this.topic,
    required this.searchQuery,
    required this.onFindTutorials,
  });

  final String topic;
  final String searchQuery;
  final ValueChanged<String> onFindTutorials;

  @override
  State<InspirationFeed> createState() => _InspirationFeedState();
}

class _InspirationFeedState extends State<InspirationFeed> {
  static const _initialLimit = 12;
  static const _queryLimit = 24;
  Future<List<QuerySnapshot<Map<String, dynamic>>>>? _feedFuture;
  String _futureKey = '';
  int _visibleCount = _initialLimit;

  @override
  void initState() {
    super.initState();
    _feedFuture = _createFuture();
  }

  @override
  void didUpdateWidget(covariant InspirationFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextKey = _keyFor(widget.topic, widget.searchQuery);
    if (nextKey != _futureKey) {
      _visibleCount = _initialLimit;
      _feedFuture = _createFuture();
    }
  }

  Future<List<QuerySnapshot<Map<String, dynamic>>>> _createFuture() {
    _futureKey = _keyFor(widget.topic, widget.searchQuery);
    final limit =
        widget.searchQuery.trim().isEmpty ? _initialLimit : _queryLimit;
    final creations =
        FirebaseFirestore.instance
            .collection('creations')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
    final products =
        FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
    final editorials =
        FirebaseFirestore.instance
            .collection('inspirations')
            .limit(limit)
            .get();
    return Future.wait([creations, products, editorials]);
  }

  String _keyFor(String topic, String query) {
    return '${topic.trim().toLowerCase()}|${query.trim().toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      future: _feedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _GridSkeleton();
        }
        if (snapshot.hasError) {
          return const _EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Inspirations indisponibles',
            message: 'Impossible de charger le flux pour le moment.',
          );
        }

        final items =
            <InspirationItem>[
                ...?snapshot.data?[0].docs.map(InspirationItem.creation),
                ...?snapshot.data?[1].docs.map(InspirationItem.product),
                ...?snapshot.data?[2].docs.map(InspirationItem.editorial),
              ].where(_matchesTopic).where(_matchesSearch).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.image_outlined,
            title: 'Aucune inspiration',
            message:
                widget.searchQuery.isEmpty
                    ? 'Les looks et idées publiés par les utilisateurs apparaîtront ici.'
                    : 'Aucun résultat pour "${widget.searchQuery}". Essayez le moodboard du Salon.',
          );
        }

        final visible = items.take(_visibleCount).toList();
        final highlight = visible.first;
        final gridItems = visible.skip(1).toList();
        return Column(
          children: [
            _FeaturedInspirationCard(
              item: highlight,
              onTap:
                  () => _openDetail(context, highlight, widget.onFindTutorials),
            ),
            if (gridItems.isNotEmpty) const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 720 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gridItems.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder:
                      (_, index) => _InspirationCard(
                        item: gridItems[index],
                        onTap:
                            () => _openDetail(
                              context,
                              gridItems[index],
                              widget.onFindTutorials,
                            ),
                      ),
                );
              },
            ),
            if (_visibleCount < items.length) ...[
              const SizedBox(height: 14),
              AppButton(
                label: 'Voir plus',
                onPressed: () => setState(() => _visibleCount += _initialLimit),
                icon: Icons.expand_more_rounded,
                variant: AppButtonVariant.outline,
                expand: true,
              ),
            ],
          ],
        );
      },
    );
  }

  bool _matchesTopic(InspirationItem item) {
    final text = item.searchText;
    return switch (widget.topic) {
      'Tenues' =>
        text.contains('tenue') ||
            text.contains('robe') ||
            text.contains('look') ||
            text.contains('outfit'),
      'Coiffures' =>
        text.contains('coiff') ||
            text.contains('hair') ||
            text.contains('tresse') ||
            text.contains('barber'),
      'Chaussures' =>
        text.contains('chauss') ||
            text.contains('shoe') ||
            text.contains('sneaker') ||
            text.contains('sandale'),
      'Mariage' => text.contains('mariage') || text.contains('bridal'),
      'Hommes' =>
        text.contains('homme') ||
            text.contains('mens') ||
            text.contains('masculin'),
      'Accessoires' =>
        text.contains('accessoire') ||
            text.contains('bijou') ||
            text.contains('sac'),
      _ => true,
    };
  }

  bool _matchesSearch(InspirationItem item) {
    final query = widget.searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    return item.searchText.contains(query);
  }

  void _openDetail(
    BuildContext context,
    InspirationItem item,
    ValueChanged<String> onFindTutorials,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _InspirationDetailSheet(
            item: item,
            onFindTutorials: onFindTutorials,
          ),
    );
  }
}

class _FeaturedInspirationCard extends StatelessWidget {
  const _FeaturedInspirationCard({required this.item, required this.onTap});

  final InspirationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      elevated: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ModernRadius.lg),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: [
              item.imageUrl.isEmpty
                  ? ColoredBox(
                    color: item.color.withValues(alpha: 0.12),
                    child: Center(child: Icon(item.icon, color: item.color)),
                  )
                  : CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget:
                        (_, _, _) => ColoredBox(
                          color: item.color.withValues(alpha: 0.12),
                          child: Icon(item.icon, color: item.color),
                        ),
                  ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InspirationBadge(item: item),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.04,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Voir',
                      onPressed: onTap,
                      icon: Icons.open_in_full_rounded,
                      variant: AppButtonVariant.secondary,
                      compact: true,
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
}

class _InspirationCard extends StatelessWidget {
  const _InspirationCard({required this.item, required this.onTap});

  final InspirationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ModernRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            item.imageUrl.isEmpty
                ? ColoredBox(
                  color: item.color.withValues(alpha: 0.12),
                  child: Center(child: Icon(item.icon, color: item.color)),
                )
                : CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget:
                      (_, _, _) => ColoredBox(
                        color: item.color.withValues(alpha: 0.12),
                        child: Icon(item.icon, color: item.color),
                      ),
                ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.66),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InspirationBadge(item: item),
                  const SizedBox(height: 7),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspirationBadge extends StatelessWidget {
  const _InspirationBadge({required this.item});

  final InspirationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        item.badge,
        style: TextStyle(
          color: item.color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InspirationDetailSheet extends StatefulWidget {
  const _InspirationDetailSheet({
    required this.item,
    required this.onFindTutorials,
  });

  final InspirationItem item;
  final ValueChanged<String> onFindTutorials;

  @override
  State<_InspirationDetailSheet> createState() =>
      _InspirationDetailSheetState();
}

class _InspirationDetailSheetState extends State<_InspirationDetailSheet> {
  final InspirationWishlistService _wishlistService =
      InspirationWishlistService();
  bool _isSaving = false;

  ExternalLook get _look => ExternalLook(
    id: ExternalLook.idFromImage(widget.item.imageUrl),
    title: widget.item.title,
    subtitle: widget.item.subtitle,
    imageUrl: widget.item.imageUrl,
    source: widget.item.badge,
    tags: [widget.item.badge, widget.item.subtitle],
  );

  Future<void> _save() async {
    if (_look.imageUrl.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await _wishlistService.save(_look);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de sauvegarder cette inspiration.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ajouté aux souhaits de votre garde-robe.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ModernColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: 0.78,
                  child:
                      widget.item.imageUrl.isEmpty
                          ? ColoredBox(
                            color: widget.item.color.withValues(alpha: 0.12),
                            child: Icon(
                              widget.item.icon,
                              color: widget.item.color,
                              size: 42,
                            ),
                          )
                          : CachedNetworkImage(
                            imageUrl: widget.item.imageUrl,
                            fit: BoxFit.cover,
                          ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.item.title,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.item.subtitle,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Sauvegarder',
                      onPressed: _isSaving ? null : _save,
                      icon: Icons.favorite_rounded,
                      loading: _isSaving,
                      expand: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppOverflowMenu(
                    actions: [
                      AppOverflowAction(
                        label: 'Partager',
                        icon: Icons.ios_share_rounded,
                        onPressed:
                            () => SharePlus.instance.share(
                              ShareParams(
                                text:
                                    '${widget.item.title}\n${widget.item.imageUrl}',
                                subject: 'Inspiration ElegantStyle',
                              ),
                            ),
                      ),
                      AppOverflowAction(
                        label: 'Essayer',
                        icon: Icons.checkroom_rounded,
                        onPressed:
                            widget.item.imageUrl.isEmpty
                                ? null
                                : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => VirtualTryOnScreen(
                                          initialImagePath:
                                              widget.item.imageUrl,
                                        ),
                                  ),
                                ),
                      ),
                      AppOverflowAction(
                        label: 'Explorer',
                        icon: AppIcons.inspiration,
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onFindTutorials(widget.item.title);
                        },
                      ),
                      AppOverflowAction(
                        label: 'Créateurs similaires',
                        icon: Icons.group_rounded,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => SalonSearchScreen(
                                    initialQuery:
                                        '${widget.item.subtitle} ${widget.item.title}',
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemBuilder:
          (_, _) => const AppCard(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
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
        ],
      ),
    );
  }
}
