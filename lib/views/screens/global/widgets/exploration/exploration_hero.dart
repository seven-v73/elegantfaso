import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/salon/salon_highlight.dart';
import '../../../../../models/salon/salon_overview.dart';

class ExplorationHero extends StatefulWidget {
  const ExplorationHero({
    super.key,
    required this.overview,
    required this.onOpenShop,
    required this.onOpenTalents,
  });

  final SalonOverview overview;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenTalents;

  @override
  State<ExplorationHero> createState() => _ExplorationHeroState();
}

class _ExplorationHeroState extends State<ExplorationHero> {
  Timer? _timer;
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    _startCarousel();
  }

  @override
  void didUpdateWidget(covariant ExplorationHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSignature = _carouselSignature(oldWidget.overview);
    final nextSignature = _carouselSignature(widget.overview);
    if (oldSignature != nextSignature) {
      _stopCarousel();
      setState(() => _activePage = 0);
      _startCarousel();
    }
  }

  @override
  void dispose() {
    _stopCarousel();
    super.dispose();
  }

  void _stopCarousel() {
    _timer?.cancel();
    _timer = null;
  }

  void _startCarousel() {
    _stopCarousel();
    if (_carouselItems.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final itemCount = _carouselItems.length;
      if (itemCount < 2) return;
      final nextPage = (_activePage + 1) % itemCount;
      setState(() => _activePage = nextPage);
    });
  }

  List<SalonHighlight> get _carouselItems {
    if (widget.overview.marketplaceCarousel.isNotEmpty) {
      return widget.overview.marketplaceCarousel;
    }
    return widget.overview.today.where((item) => item.hasImage).toList();
  }

  String _carouselSignature(SalonOverview overview) {
    final items =
        overview.marketplaceCarousel.isNotEmpty
            ? overview.marketplaceCarousel
            : overview.today.where((item) => item.hasImage).toList();
    return items.map((item) => '${item.type.name}:${item.id}').join('|');
  }

  @override
  Widget build(BuildContext context) {
    final carouselItems = _carouselItems;
    final carouselSignature = _carouselSignature(widget.overview);
    final activePage =
        carouselItems.isEmpty
            ? 0
            : _activePage.clamp(0, carouselItems.length - 1);
    final greeting =
        widget.overview.isGuest
            ? 'Bienvenue dans le Salon'
            : 'Pour toi${widget.overview.firstName.isEmpty ? '' : ', ${widget.overview.firstName}'}';
    final subtitle =
        widget.overview.isProfessional
            ? '${widget.overview.myCreationCount + widget.overview.myProductCount} publications à toi dans le Salon, et de nouvelles opportunités à explorer.'
            : '${widget.overview.productCount + widget.overview.creationCount} pièces et créations, ${widget.overview.talentCount} talents, ${widget.overview.eventCount} événements.';

    return AppCard(
      padding: EdgeInsets.zero,
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.72,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(ModernRadius.lg),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (carouselItems.isEmpty)
                    _FallbackHero()
                  else
                    _HeroCarouselSlide(
                      key: ValueKey(
                        'hero-$carouselSignature-${carouselItems[activePage].type.name}-${carouselItems[activePage].id}',
                      ),
                      item: carouselItems[activePage],
                      onTap: widget.onOpenShop,
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ModernColors.ink.withValues(alpha: 0.05),
                          ModernColors.ink.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LiveBadge(city: widget.overview.city),
                        const SizedBox(height: 10),
                        Text(
                          greeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (carouselItems.length > 1)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: _CarouselDots(
                        count: carouselItems.length,
                        activeIndex: activePage,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: _StatPill(
                    value:
                        '${widget.overview.productCount + widget.overview.creationCount}',
                    label: 'Nouveautés',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    value: '${widget.overview.talentCount}',
                    label: 'Talents',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    value: '${widget.overview.eventCount}',
                    label: 'Agenda',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Nouveautés',
                    icon: AppIcons.shop,
                    onPressed: widget.onOpenShop,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Talents',
                    icon: AppIcons.talents,
                    variant: AppButtonVariant.secondary,
                    onPressed: widget.onOpenTalents,
                    compact: true,
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

class _FallbackHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ModernGradients.warm),
    );
  }
}

class _HeroCarouselSlide extends StatelessWidget {
  const _HeroCarouselSlide({
    super.key,
    required this.item,
    required this.onTap,
  });

  final SalonHighlight item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.hasImage)
              Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, _, _) => _HeroImageFallback(icon: _iconFor(item.type)),
              )
            else
              _HeroImageFallback(icon: _iconFor(item.type)),
            Positioned(
              left: 16,
              top: 14,
              child: Row(
                children: [
                  _HeroBadge(
                    label: item.isProduct ? 'Produit boutique' : 'Création',
                    color:
                        item.isProduct
                            ? ModernColors.shop
                            : ModernColors.creator,
                    icon: item.isProduct ? AppIcons.shop : AppIcons.creations,
                  ),
                  if (item.isProListing) ...[
                    const SizedBox(width: 8),
                    const _HeroBadge(
                      label: 'Compte certifié',
                      color: ModernColors.accent,
                      icon: Icons.workspace_premium_rounded,
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: Color(0x99000000),
                          offset: Offset(0, 1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _slideSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      shadows: const [
                        Shadow(
                          color: Color(0x99000000),
                          offset: Offset(0, 1),
                          blurRadius: 8,
                        ),
                      ],
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

  String get _slideSubtitle {
    if (item.priceLabel.isNotEmpty) {
      return '${item.priceLabel} • ${item.subtitle}';
    }
    if (item.city.isNotEmpty) return '${item.subtitle} • ${item.city}';
    return item.subtitle;
  }

  IconData _iconFor(SalonHighlightType type) {
    return switch (type) {
      SalonHighlightType.product => AppIcons.shop,
      SalonHighlightType.creation => AppIcons.creations,
      SalonHighlightType.talent => AppIcons.talents,
      SalonHighlightType.event => Icons.event_rounded,
      SalonHighlightType.inspiration => Icons.image_rounded,
    };
  }
}

class _HeroImageFallback extends StatelessWidget {
  const _HeroImageFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ModernGradients.warm),
      child: Icon(icon, color: Colors.white, size: 54),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final visibleCount = count > 5 ? 5 : count;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(visibleCount, (index) {
        final active =
            count > 5
                ? activeIndex % visibleCount == index
                : activeIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 18 : 6,
          height: 6,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: active ? 0.95 : 0.45),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Text(
        city.isEmpty ? 'Salon vivant' : 'Autour de $city',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: ModernColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.inkSoft,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
