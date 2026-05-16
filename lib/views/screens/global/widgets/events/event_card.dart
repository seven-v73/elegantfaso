import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/events/salon_event.dart';

class EventCard extends StatelessWidget {
  const EventCard({
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
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateBox(event: event),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MiniBadge(label: event.type),
                    const SizedBox(width: 6),
                    if (event.isOnline) const _MiniBadge(label: 'En ligne'),
                    const Spacer(),
                    IconButton(
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: onReminder,
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(icon: Icons.place_rounded, label: event.placeLabel),
                    _Chip(icon: Icons.schedule_rounded, label: event.timeLabel),
                    _Chip(
                      icon: Icons.payments_rounded,
                      label: event.priceLabel,
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

class _DateBox extends StatelessWidget {
  const _DateBox({required this.event});

  final SalonEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: ModernColors.accent.withValues(alpha: 0.12),
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

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: ModernColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: ModernColors.shop,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: ModernColors.inkSoft),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.inkSoft,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
