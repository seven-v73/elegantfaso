import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class BoutiqueStatsScreen extends StatefulWidget {
  const BoutiqueStatsScreen({Key? key}) : super(key: key);

  @override
  _BoutiqueStatsScreenState createState() => _BoutiqueStatsScreenState();
}

class _BoutiqueStatsScreenState extends State<BoutiqueStatsScreen> {
  final String boutiqueId = FirebaseAuth.instance.currentUser?.uid ?? '';
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final orders = await FirebaseFirestore.instance
          .collection('orders')
          .where('boutiqueId', isEqualTo: boutiqueId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(_selectedRange.start))
          .where('createdAt', isLessThan: Timestamp.fromDate(_selectedRange.end))
          .get();

      double totalRevenue = 0;
      int orderCount = orders.size;
      int productCount = 0;
      final dailyData = <DateTime, double>{};

      for (final doc in orders.docs) {
        final data = doc.data();
        totalRevenue += (data['totalAmount'] ?? 0).toDouble();
        productCount += (data['items']?.length ?? 0) as int;

        final date = (data['createdAt'] as Timestamp).toDate();
        final day = DateTime(date.year, date.month, date.day);
        dailyData[day] = (dailyData[day] ?? 0) + (data['totalAmount'] ?? 0).toDouble();
      }

      setState(() {
        _stats = {
          'totalRevenue': totalRevenue,
          'orderCount': orderCount,
          'avgOrderValue': orderCount > 0 ? totalRevenue / orderCount : 0,
          'productCount': productCount,
          'dailyData': dailyData,
        };
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytiques')),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: _stats.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
              children: [
                _buildStatCard('Revenu total', _stats['totalRevenue'], true),
                _buildStatCard('Commandes', _stats['orderCount'], false),
                _buildStatCard('Panier moyen', _stats['avgOrderValue'], true),
                _buildPerformanceChart(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text(
            '${DateFormat('dd MMM').format(_selectedRange.start)} - ${DateFormat('dd MMM').format(_selectedRange.end)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, dynamic value, bool isMoney) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              isMoney
                  ? NumberFormat.currency(symbol: 'FCFA').format(value)
                  : value.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    final dailyData = _stats['dailyData'] as Map<DateTime, double>;
    final sortedDates = dailyData.keys.toList()..sort();
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final amount = dailyData[date]!;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: Colors.deepPurple,
              width: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1.7,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (dailyData.values.isNotEmpty) ? (dailyData.values.reduce((a, b) => a > b ? a : b)) * 1.2 : 100,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < sortedDates.length) {
                      return Text(DateFormat('dd').format(sortedDates[index]), style: const TextStyle(fontSize: 10));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
            gridData: FlGridData(show: true),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
    );

    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
      _loadStatistics();
    }
  }
}
