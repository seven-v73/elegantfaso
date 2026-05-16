import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/salon/salon_highlight.dart';
import '../../../../../models/salon/salon_quick_entry.dart';

class LiveHighlightsSection extends StatelessWidget {
  const LiveHighlightsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.fallbackIcon,
    required this.onOpenTarget,
    this.featured = false,
  });

  final String title;
  final String subtitle;
  final List<SalonHighlight> items;
  final IconData fallbackIcon;
  final ValueChanged<SalonQuickTarget> onOpenTarget;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptySection(
        title: title,
        subtitle: 'Le Salon attend de nouveaux contenus.',
        icon: fallbackIcon,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          padding: EdgeInsets.zero,
          title: title,
          subtitle: subtitle,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 224,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _HighlightCard(
                item: items[index],
                featured: featured,
                onTap: () => onOpenTarget(_targetFor(items[index].type)),
              );
            },
          ),
        ),
      ],
    );
  }

  SalonQuickTarget _targetFor(SalonHighlightType type) {
    return switch (type) {
      SalonHighlightType.product ||
      SalonHighlightType.creation => SalonQuickTarget.shop,
      SalonHighlightType.talent => SalonQuickTarget.talents,
      SalonHighlightType.event => SalonQuickTarget.agenda,
      SalonHighlightType.inspiration => SalonQuickTarget.inspiration,
    };
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.item,
    required this.onTap,
    this.featured = false,
  });

  final SalonHighlight item;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        elevated: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(ModernRadius.lg),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: ModernColors.primary.withValues(alpha: 0.08),
                      child:
                          item.hasImage
                              ? CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 360,
                                errorWidget:
                                    (_, _, _) => Icon(
                                      _iconFor(item.type),
                                      color: ModernColors.primary,
                                    ),
                              )
                              : Icon(
                                _iconFor(item.type),
                                color: ModernColors.primary,
                              ),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.typeLabel,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (featured || item.isFeatured)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: ModernColors.creator,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.diamond_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'À la une',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
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
                  const SizedBox(height: 3),
                  Text(
                    _subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  String get _subtitle {
    if (item.priceLabel.isNotEmpty) return item.priceLabel;
    if (item.city.isNotEmpty) return item.city;
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

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: ModernColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: ModernColors.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
