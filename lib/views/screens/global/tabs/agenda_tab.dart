import 'package:flutter/material.dart';

import '../widgets/agenda/monthly_calendar.dart';
import '../widgets/agenda/upcoming_events.dart';
import '../widgets/agenda/my_events.dart';

class AgendaTab extends StatelessWidget {
  const AgendaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          MonthlyCalendar(),
          UpcomingEvents(),
          MyEvents(),
        ],
      ),
    );
  }
}