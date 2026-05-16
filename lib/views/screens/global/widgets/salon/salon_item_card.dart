import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/salon/salon_item.dart';

class SalonItemCard extends StatelessWidget {
  const SalonItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.compact = false,
  });

  final SalonItem item;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 164 : null,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        elevated: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: compact ? 1.2 : 1.65,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(ModernRadius.lg),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Image(item: item),
                    Positioned(left: 8, top: 8, child: _Badge(item: item)),
                    if (item.verified)
                      const Positioned(
                        right: 8,
                        top: 8,
                        child: Icon(
                          Icons.verified_rounded,
                          color: ModernColors.primary,
                          size: 22,
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
                    maxLines: compact ? 1 : 2,
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
          ],
        ),
      ),
    );
  }
}

class _Image extends StatelessWidget {
  const _Image({required this.item});

  final SalonItem item;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: item.color.withValues(alpha: 0.1),
      child: Icon(item.icon, color: item.color, size: 32),
    );
    if (!item.hasImage) return fallback;
    return Image.network(
      item.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.item});

  final SalonItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${item.typeLabel} • ${item.badgeLabel}',
        style: const TextStyle(
          color: ModernColors.ink,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
