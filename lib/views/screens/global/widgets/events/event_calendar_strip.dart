import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/events/salon_event.dart';

class EventCalendarStrip extends StatelessWidget {
  const EventCalendarStrip({
    super.key,
    required this.events,
    required this.onDateSelected,
  });

  final List<SalonEvent> events;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(14, (index) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day + index);
    });

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final count =
              events.where((event) => _sameDay(event.startAt, day)).length;
          return SizedBox(
            width: 64,
            child: AppCard(
              onTap: count == 0 ? null : () => onDateSelected(day),
              padding: const EdgeInsets.symmetric(vertical: 10),
              elevated: index == 0,
              child: Column(
                children: [
                  Text(
                    DateFormat('EEE', 'fr').format(day),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('d', 'fr').format(day),
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: count == 0 ? 5 : 20,
                    height: 5,
                    decoration: BoxDecoration(
                      color:
                          count == 0 ? ModernColors.line : ModernColors.accent,
                      borderRadius: BorderRadius.circular(999),
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

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
