import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/inspiration/external_look.dart';
import '../../../../../models/inspiration/style_guide.dart';
import '../../../../../models/inspiration/youtube_video.dart';
import '../../../../../services/inspiration/inspiration_wishlist_service.dart';
import '../../../../../services/inspiration/style_guide_service.dart';
import '../../../../../services/inspiration/youtube_tutorial_service.dart';
import '../../salon_search_screen.dart';

class VideoTutorialsSection extends StatefulWidget {
  const VideoTutorialsSection({
    super.key,
    required this.searchQuery,
    this.externalQuery,
  });

  final String searchQuery;
  final String? externalQuery;

  @override
  State<VideoTutorialsSection> createState() => VideoTutorialsSectionState();
}

class VideoTutorialsSectionState extends State<VideoTutorialsSection> {
  final StyleGuideService _guideService = StyleGuideService();
  final YoutubeTutorialService _youtubeService = YoutubeTutorialService();
  final InspirationWishlistService _wishlistService =
      InspirationWishlistService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedQuery = _intentions.first.query;
  String _selectedTitle = _intentions.first.label;
  List<StyleGuide> _guides = const [];
  List<YoutubeVideo> _videos = const [];
  bool _isLoading = true;
  bool _showVideos = false;

  static const _intentions = [
    _GuideIntent('Mariage', 'mariage cérémonie tenue', Icons.favorite_rounded),
    _GuideIntent('Bureau', 'bureau professionnel élégance', Icons.work_rounded),
    _GuideIntent(
      'Couleurs',
      'couleurs harmonie palette',
      Icons.palette_rounded,
    ),
    _GuideIntent(
      'Morphologie',
      'morphologie silhouette coupe',
      Icons.accessibility_new_rounded,
    ),
    _GuideIntent(
      'Beauté',
      'beauté coiffure maquillage',
      Icons.face_retouching_natural_rounded,
    ),
    _GuideIntent(
      'Cérémonie',
      'cérémonie soirée accessoires',
      Icons.celebration_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final initial =
        widget.externalQuery?.trim().isNotEmpty == true
            ? widget.externalQuery!.trim()
            : widget.searchQuery.trim();
    if (initial.isNotEmpty) {
      _searchController.text = initial;
      _loadGuides(initial, title: initial);
    } else {
      _loadGuides(_selectedQuery, title: _selectedTitle);
    }
  }

  @override
  void didUpdateWidget(covariant VideoTutorialsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = widget.externalQuery?.trim();
    if (query != null &&
        query.isNotEmpty &&
        widget.externalQuery != oldWidget.externalQuery) {
      search(query);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> search(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    _searchController.text = clean;
    await _loadGuides(clean, title: clean);
  }

  Future<void> _loadGuides(String query, {String? title}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;
    setState(() {
      _selectedQuery = cleanQuery;
      _selectedTitle = title ?? 'Recherche';
      _isLoading = true;
    });

    final results = await Future.wait([
      _guideService.loadGuides(query: cleanQuery),
      _youtubeService.load('$cleanQuery fashion style tutorial'),
    ]);
    if (!mounted) return;
    setState(() {
      _guides = results[0] as List<StyleGuide>;
      _videos = results[1] as List<YoutubeVideo>;
      _isLoading = false;
    });
  }

  void _submitSearch() => search(_searchController.text);

  void _openGuide(StyleGuide guide) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuideDetailSheet(guide: guide),
    );
  }

  Future<void> _saveGuide(StyleGuide guide) async {
    try {
      await _wishlistService.save(
        ExternalLook(
          id: 'guide_${guide.id.isEmpty ? guide.title : guide.id}',
          title: guide.title,
          subtitle: guide.subtitle,
          imageUrl: guide.imageUrl,
          source: 'Guides Style',
          tags: [guide.category, ...guide.tags],
        ),
      );
      if (!mounted) return;
      _snack('Guide sauvegardé.');
    } catch (_) {
      if (!mounted) return;
      _snack('Sauvegarde indisponible.');
    }
  }

  void _openSalonSearch(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SalonSearchScreen(initialQuery: query)),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  StyleGuide? get _momentGuide {
    if (_guides.isEmpty) return null;
    final queryWords =
        _selectedQuery
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((word) => word.length > 2)
            .toList();
    final featured = _guides.where((guide) => guide.featured).toList();
    final pool = featured.isEmpty ? _guides : featured;
    for (final guide in pool) {
      final text =
          '${guide.title} ${guide.subtitle} ${guide.category} ${guide.tags.join(' ')}'
              .toLowerCase();
      if (queryWords.any(text.contains)) return guide;
    }
    return pool.first;
  }

  List<StyleGuide> get _recommendedGuides {
    final moment = _momentGuide;
    return _guides
        .where(
          (guide) => !(guide.id == moment?.id && guide.title == moment?.title),
        )
        .take(3)
        .toList();
  }

  int get _liveGuideCount {
    return _guides
        .where(
          (guide) =>
              guide.linkedProducts.isNotEmpty ||
              guide.linkedCreations.isNotEmpty,
        )
        .length;
  }

  int get _proGuideCount => _guides.where((guide) => guide.isProGuide).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          padding: EdgeInsets.zero,
          title: 'Conseils Style',
          subtitle: _isLoading ? 'Préparation...' : _selectedTitle,
          action: IconButton.filledTonal(
            tooltip: 'Actualiser',
            onPressed: () => _loadGuides(_selectedQuery, title: _selectedTitle),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        const SizedBox(height: 12),
        _GuideIntentRail(
          selectedQuery: _selectedQuery,
          intentions: _intentions,
          onSelected: (intent) {
            _searchController.clear();
            _loadGuides(intent.query, title: intent.label);
          },
        ),
        const SizedBox(height: 12),
        _GuideSearchBar(controller: _searchController, onSubmit: _submitSearch),
        if (!_isLoading) ...[
          const SizedBox(height: 10),
          _GuideSignalStrip(
            liveCount: _liveGuideCount,
            proCount: _proGuideCount,
            videoCount: _videos.length,
          ),
        ],
        const SizedBox(height: 14),
        if (_isLoading)
          const AppCard(
            child: SizedBox(
              height: 118,
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else ...[
          _GuideHero(
            guide: _momentGuide,
            onOpen: _openGuide,
            onSave: _saveGuide,
            onOpenSalon: _openSalonSearch,
          ),
          const SizedBox(height: 12),
          if (_recommendedGuides.isNotEmpty) ...[
            const Text(
              'Guides utiles',
              style: TextStyle(
                color: ModernColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
          ],
          for (final guide in _recommendedGuides) ...[
            _GuideTile(
              guide: guide,
              onOpen: () => _openGuide(guide),
              onSave: () => _saveGuide(guide),
              onOpenSalon: _openSalonSearch,
            ),
            const SizedBox(height: 10),
          ],
          _VideoToggle(
            count: _videos.length,
            isOpen: _showVideos,
            onTap: () => setState(() => _showVideos = !_showVideos),
          ),
          if (_showVideos) ...[
            const SizedBox(height: 10),
            _YoutubeCompanionList(videos: _videos),
          ],
        ],
      ],
    );
  }
}

class _GuideSearchBar extends StatelessWidget {
  const _GuideSearchBar({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: ModernColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSubmit(),
                decoration: const InputDecoration(
                  hintText: 'Occasion, couleur, pièce...',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Rechercher',
              onPressed: onSubmit,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideIntent {
  const _GuideIntent(this.label, this.query, this.icon);

  final String label;
  final String query;
  final IconData icon;
}

class _GuideIntentRail extends StatelessWidget {
  const _GuideIntentRail({
    required this.selectedQuery,
    required this.intentions,
    required this.onSelected,
  });

  final String selectedQuery;
  final List<_GuideIntent> intentions;
  final ValueChanged<_GuideIntent> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: intentions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = intentions[index];
          final selected = selectedQuery == item.query;
          return ChoiceChip(
            selected: selected,
            avatar: Icon(
              item.icon,
              size: 16,
              color: selected ? ModernColors.primary : ModernColors.inkSoft,
            ),
            label: Text(item.label),
            onSelected: (_) => onSelected(item),
            selectedColor: ModernColors.primary.withValues(alpha: 0.12),
            labelStyle: TextStyle(
              color: selected ? ModernColors.primary : ModernColors.inkSoft,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }
}

class _GuideSignalStrip extends StatelessWidget {
  const _GuideSignalStrip({
    required this.liveCount,
    required this.proCount,
    required this.videoCount,
  });

  final int liveCount;
  final int proCount;
  final int videoCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GuideSignalPill(
            icon: Icons.storefront_rounded,
            label: '$liveCount live',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GuideSignalPill(
            icon: Icons.verified_rounded,
            label: '$proCount pros',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GuideSignalPill(
            icon: Icons.play_circle_outline_rounded,
            label: '$videoCount vidéos',
          ),
        ),
      ],
    );
  }
}

class _GuideSignalPill extends StatelessWidget {
  const _GuideSignalPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: ModernColors.primary),
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

class _VideoToggle extends StatelessWidget {
  const _VideoToggle({
    required this.count,
    required this.isOpen,
    required this.onTap,
  });

  final int count;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      elevated: false,
      child: Row(
        children: [
          const Icon(
            Icons.play_circle_outline_rounded,
            color: ModernColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 0 ? 'À regarder' : 'À regarder · $count',
              style: const TextStyle(
                color: ModernColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(
            isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: ModernColors.inkSoft,
          ),
        ],
      ),
    );
  }
}

class _GuideHero extends StatelessWidget {
  const _GuideHero({
    required this.guide,
    required this.onOpen,
    required this.onSave,
    required this.onOpenSalon,
  });

  final StyleGuide? guide;
  final ValueChanged<StyleGuide> onOpen;
  final ValueChanged<StyleGuide> onSave;
  final ValueChanged<String> onOpenSalon;

  @override
  Widget build(BuildContext context) {
    final item = guide;
    if (item == null) {
      return const AppCard(
        child: Text(
          'Aucun guide trouvé pour cette recherche. Essayez une matière, une occasion ou une catégorie.',
          style: TextStyle(
            color: ModernColors.inkSoft,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return AppCard(
      onTap: () => onOpen(item),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _GuideImage(url: item.imageUrl),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.68),
                      ],
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
                      _GuideBadge(label: item.category, dark: true),
                      const SizedBox(height: 6),
                      const _GuideBadge(label: 'Conseil du moment', dark: true),
                      if (item.linkedProducts.isNotEmpty ||
                          item.linkedCreations.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        const _GuideBadge(label: 'Depuis le Salon', dark: true),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Composer',
                        onPressed: () => onOpen(item),
                        icon: Icons.arrow_forward_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Sauvegarder',
                      onPressed: () => onSave(item),
                      icon: const Icon(AppIcons.save),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _GuideActionChip(
                      label: 'Voir produits',
                      icon: AppIcons.shop,
                      onTap: () => onOpenSalon('${item.category} produit'),
                    ),
                    _GuideActionChip(
                      label: 'Trouver créateur',
                      icon: AppIcons.creator,
                      onTap: () => onOpenSalon('${item.category} createur'),
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

class _GuideTile extends StatelessWidget {
  const _GuideTile({
    required this.guide,
    required this.onOpen,
    required this.onSave,
    required this.onOpenSalon,
  });

  final StyleGuide guide;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final ValueChanged<String> onOpenSalon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 82,
              height: 72,
              child: _GuideImage(url: guide.imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _GuideBadge(label: guide.category),
                    if (guide.isProGuide)
                      const _GuideBadge(label: 'Compte certifié'),
                    if (guide.linkedProducts.isNotEmpty ||
                        guide.linkedCreations.isNotEmpty)
                      const _GuideBadge(label: 'Salon live'),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  guide.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  guide.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    height: 1.22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _GuideActionChip(
                      label: 'Produits',
                      icon: AppIcons.shop,
                      onTap: () => onOpenSalon('${guide.category} produit'),
                    ),
                    _GuideActionChip(
                      label: 'Créateur',
                      icon: AppIcons.creator,
                      onTap: () => onOpenSalon('${guide.category} createur'),
                    ),
                    _GuideActionChip(
                      label: 'Sauver',
                      icon: AppIcons.save,
                      onTap: onSave,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: ModernColors.inkSoft),
        ],
      ),
    );
  }
}

class _GuideActionChip extends StatelessWidget {
  const _GuideActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: ModernColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: ModernColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: ModernColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ModernColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: ModernColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: ModernColors.ink,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _YoutubeCompanionList extends StatelessWidget {
  const _YoutubeCompanionList({required this.videos});

  final List<YoutubeVideo> videos;

  @override
  Widget build(BuildContext context) {
    final visible = videos.take(6).toList();
    if (visible.isEmpty) {
      return const AppCard(
        child: Text(
          'Aucune vidéo externe trouvée. Les guides natifs restent disponibles.',
          style: TextStyle(
            color: ModernColors.inkSoft,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final video in visible) ...[
          _YoutubeTile(video: video),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _YoutubeTile extends StatelessWidget {
  const _YoutubeTile({required this.video});

  final YoutubeVideo video;

  Future<void> _openVideo() async {
    await launchUrl(Uri.parse(video.url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: _openVideo,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: video.thumbnailUrl,
              width: 88,
              height: 64,
              fit: BoxFit.cover,
              errorWidget:
                  (_, _, _) => Container(
                    width: 88,
                    height: 64,
                    color: ModernColors.line,
                    child: const Icon(Icons.play_arrow_rounded),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  video.channelTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.open_in_new_rounded, color: ModernColors.primary),
        ],
      ),
    );
  }
}

class _GuideDetailSheet extends StatelessWidget {
  const _GuideDetailSheet({required this.guide});

  final StyleGuide guide;

  Future<void> _save(BuildContext context) async {
    try {
      await InspirationWishlistService().save(
        ExternalLook(
          id: 'guide_${guide.id.isEmpty ? guide.title : guide.id}',
          title: guide.title,
          subtitle: guide.subtitle,
          imageUrl: guide.imageUrl,
          source: 'Guides Style',
          tags: [guide.category, ...guide.tags],
        ),
      );
      if (context.mounted) _snack(context, 'Guide sauvegardé.');
    } catch (_) {
      if (context.mounted) _snack(context, 'Sauvegarde indisponible.');
    }
  }

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.tryParse(guide.videoUrl);
    if (uri == null) {
      _snack(context, 'Aucune vidéo associée à ce guide.');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _snack(context, 'Impossible d’ouvrir la vidéo.');
    }
  }

  Future<void> _share(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Guide Style ElegantStyle',
          text:
              '${guide.title}\n${guide.subtitle}'
              '${guide.videoUrl.isEmpty ? '' : '\n${guide.videoUrl}'}',
        ),
      );
    } catch (_) {
      if (context.mounted) _snack(context, 'Partage indisponible.');
    }
  }

  void _openLinkedSalon(BuildContext context, {String suffix = ''}) {
    final query = [
      guide.category,
      ...guide.tags.take(3),
      guide.title,
      suffix,
    ].where((item) => item.trim().isNotEmpty).join(' ');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SalonSearchScreen(initialQuery: query)),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.46,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
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
                  aspectRatio: 16 / 10,
                  child: _GuideImage(url: guide.imageUrl),
                ),
              ),
              const SizedBox(height: 16),
              _GuideBadge(label: guide.category),
              const SizedBox(height: 10),
              Text(
                guide.title,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 22,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                guide.subtitle,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AppButton(
                    label: 'Voir la vidéo',
                    onPressed:
                        guide.videoUrl.isEmpty
                            ? null
                            : () => _openVideo(context),
                    icon: Icons.play_circle_rounded,
                    compact: true,
                  ),
                  AppButton(
                    label: 'Sauver',
                    onPressed: () => _save(context),
                    icon: AppIcons.save,
                    variant: AppButtonVariant.secondary,
                    compact: true,
                  ),
                  AppButton(
                    label: 'Partager',
                    onPressed: () => _share(context),
                    icon: Icons.ios_share_rounded,
                    variant: AppButtonVariant.secondary,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _GuideActionChip(
                    label: 'Produits liés',
                    icon: AppIcons.shop,
                    onTap: () => _openLinkedSalon(context, suffix: 'produit'),
                  ),
                  _GuideActionChip(
                    label: 'Créateur',
                    icon: AppIcons.creator,
                    onTap: () => _openLinkedSalon(context, suffix: 'createur'),
                  ),
                  _GuideActionChip(
                    label: 'Inspirations',
                    icon: AppIcons.inspiration,
                    onTap:
                        () => _openLinkedSalon(context, suffix: 'inspiration'),
                  ),
                  _GuideActionChip(
                    label: 'Événement',
                    icon: Icons.event_rounded,
                    onTap: () => _openLinkedSalon(context, suffix: 'evenement'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < guide.steps.length; i++) ...[
                _GuideStep(index: i + 1, text: guide.steps[i]),
                if (i != guide.steps.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GuideBadge extends StatelessWidget {
  const _GuideBadge({required this.label, this.dark = false});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color:
            dark
                ? Colors.white.withValues(alpha: 0.16)
                : ModernColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dark ? Colors.white : ModernColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GuideImage extends StatelessWidget {
  const _GuideImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: ModernColors.primary.withValues(alpha: 0.08),
        child: const Icon(AppIcons.inspiration, color: ModernColors.primary),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget:
          (_, _, _) => Container(
            color: ModernColors.primary.withValues(alpha: 0.08),
            child: const Icon(
              AppIcons.inspiration,
              color: ModernColors.primary,
            ),
          ),
    );
  }
}
