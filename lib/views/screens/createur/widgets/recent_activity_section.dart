import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../createur_model.dart';
import 'recent_creations_section.dart';
import 'upcoming_appointments_section.dart';

class RecentActivitySection extends StatelessWidget {
  final CreateurModel createur;

  const RecentActivitySection({super.key, required this.createur});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité Récente',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: 'Dernières créations'),
                    Tab(text: 'Prochains RDV'),
                  ],
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A6FA5), Color(0xFF6B4E71)],
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context).hintColor,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      RecentCreationsSection(userId: createur.id),
                      UpcomingAppointmentsSection(userId: createur.id),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}