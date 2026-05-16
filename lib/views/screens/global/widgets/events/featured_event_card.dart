import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/events/salon_event.dart';

class FeaturedEventCard extends StatelessWidget {
  const FeaturedEventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onReminder,
  });

  final SalonEvent event;
  final VoidCallback onTap;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.75,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(ModernRadius.lg),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _EventImage(event: event),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          ModernColors.ink.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: _Badge(label: event.formatLabel),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: IconButton.filledTonal(
                      onPressed: onReminder,
                      icon: const Icon(Icons.notifications_active_rounded),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.type.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _DateBox(event: event),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.placeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ModernColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.timeLabel} • ${event.priceLabel} • ${event.capacityLabel}',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({required this.event});

  final SalonEvent event;

  @override
  Widget build(BuildContext context) {
    if (event.hasImage) {
      return CachedNetworkImage(
        imageUrl: event.imageUrl,
        fit: BoxFit.cover,
        memCacheWidth: 640,
        errorWidget: (_, _, _) => const _FallbackPoster(),
      );
    }
    return const _FallbackPoster();
  }
}

class _FallbackPoster extends StatelessWidget {
  const _FallbackPoster();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ModernGradients.warm),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: ModernColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.event});

  final SalonEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: ModernColors.accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            event.day,
            style: const TextStyle(
              color: ModernColors.shop,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            event.month,
            style: const TextStyle(
              color: ModernColors.shop,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
