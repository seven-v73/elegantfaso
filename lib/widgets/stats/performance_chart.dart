import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PerformanceChart extends StatelessWidget {
  final Map<DateTime, double> data;

  const PerformanceChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedData = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedData.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = entry.value.value;
      return FlSpot(index, value);
    }).toList();

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedData.length) {
                    final date = sortedData[index].key;
                    return Text('${date.day}/${date.month}');
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.deepPurple,
              barWidth: 3,
              belowBarData: BarAreaData(show: true, color: Colors.deepPurple.withOpacity(0.3)),
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}
