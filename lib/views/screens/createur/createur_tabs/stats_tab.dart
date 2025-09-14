import 'package:flutter/material.dart';

import '../widgets/stat_chart.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Mes Statistiques',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  StatChart(title: 'Revenus Mensuels', subtitle: '12% vs mois dernier', color: const Color(0xFF2A9D8F)),
                  const SizedBox(height: 24),
                  StatChart(title: 'Activité Hebdomadaire'),
                  const SizedBox(height: 24),
                  StatChart(title: 'Démographie Clients', color: const Color(0xFF4A6FA5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}