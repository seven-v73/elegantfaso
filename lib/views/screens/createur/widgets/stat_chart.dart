import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatChart extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? color;

  const StatChart({
    Key? key,
    required this.title,
    this.subtitle,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Données simulées pour le graphique
    final data = [
      _ChartData('Jan', 50000, const Color(0xFF4A6FA5)),
      _ChartData('Fév', 75000, const Color(0xFF6B4E71)),
      _ChartData('Mar', 100000, const Color(0xFF2A9D8F)),
      _ChartData('Avr', 90000, const Color(0xFFE76F51)),
      _ChartData('Mai', 120000, const Color(0xFFF4A261)),
      _ChartData('Juin', 150000, const Color(0xFF2A9D8F)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (subtitle != null) Text(
                subtitle!,
                style: TextStyle(
                  color: color ?? const Color(0xFF2A9D8F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(data[value.toInt()].month),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text('${(value ~/ 1000)}K');
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((e) {
                  final index = e.key;
                  final item = e.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.value.toDouble(),
                        color: item.color,
                        width: 22,
                        borderRadius: BorderRadius.circular(4),
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatIndicator(color: const Color(0xFF4A6FA5), label: 'Créations', value: '24'),
              _StatIndicator(color: const Color(0xFF2A9D8F), label: 'Ventes', value: '18'),
              _StatIndicator(color: const Color(0xFFE76F51), label: 'Clients', value: '32'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String month;
  final int value;
  final Color color;

  _ChartData(this.month, this.value, this.color);
}

class _StatIndicator extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _StatIndicator({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}