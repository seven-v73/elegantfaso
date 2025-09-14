import 'package:flutter/material.dart';

class MonthlyCalendar extends StatefulWidget {
  const MonthlyCalendar({super.key});

  @override
  State<MonthlyCalendar> createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends State<MonthlyCalendar> {
  late DateTime currentDate;
  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();
    currentDate = DateTime.now();
    selectedMonth = DateTime(currentDate.year, currentDate.month);
  }

  List<String> get monthNames => [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  List<String> get dayNames => ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    });
  }

  bool _isToday(int day) {
    return selectedMonth.year == currentDate.year &&
        selectedMonth.month == currentDate.month &&
        day == currentDate.day;
  }

  bool _hasEvent(int day) {
    // Vous pouvez modifier cette logique selon vos besoins
    // Exemple : événements les 5, 12, 18, 25 de chaque mois
    return [5, 12, 18, 25].contains(day);
  }

  List<Widget> _buildCalendarDays() {
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Obtenir le jour de la semaine du premier jour (1 = lundi, 7 = dimanche)
    int firstWeekday = firstDayOfMonth.weekday;

    List<Widget> days = [];

    // Ajouter les en-têtes des jours de la semaine
    for (String dayName in dayNames) {
      days.add(
        Container(
          height: 30,
          child: Center(
            child: Text(
              dayName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    // Ajouter les jours vides au début
    for (int i = 1; i < firstWeekday; i++) {
      days.add(Container());
    }

    // Ajouter tous les jours du mois
    for (int day = 1; day <= daysInMonth; day++) {
      final isToday = _isToday(day);
      final hasEvent = _hasEvent(day);

      days.add(
        Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isToday
                ? Colors.green[700]
                : (hasEvent ? Colors.orange.withOpacity(0.3) : null),
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: Colors.green[900]!, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              day.toString(),
              style: TextStyle(
                color: isToday ? Colors.white : Colors.black,
                fontWeight: hasEvent || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${monthNames[selectedMonth.month - 1]} ${selectedMonth.year}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousMonth,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 1,
            children: _buildCalendarDays(),
          ),
        ],
      ),
    );
  }
}