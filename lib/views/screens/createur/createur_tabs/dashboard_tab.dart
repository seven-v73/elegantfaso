
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../createur_model.dart';
import '../widgets/welcome_section.dart';
import '../widgets/stats_section.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_activity_section.dart';
import '../widgets/shimmer_effects.dart';
import '../widgets/empty_state.dart';
import '../widgets/sheet_handle.dart';

class DashboardTab extends StatelessWidget {
  final User user;
  final ConfettiController confettiController;
  final bool isOnline;
  final ValueChanged<bool> onStatusChanged;

  const DashboardTab({
    super.key,
    required this.user,
    required this.confettiController,
    required this.isOnline,
    required this.onStatusChanged,
  });

  // Méthode pour récupérer le nombre de RDV confirmés à venir
  Stream<int> _getUpcomingAppointmentsCount() {
    final now = DateTime.now();

    return FirebaseFirestore.instance
        .collection('appointments')
        .where('creatorId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final dateField = data['date'];

        if (dateField == null) return false;

        DateTime appointmentDate;
        if (dateField is Timestamp) {
          appointmentDate = dateField.toDate();
        } else if (dateField is String) {
          try {
            appointmentDate = DateTime.parse(dateField);
          } catch (e) {
            return false;
          }
        } else {
          return false;
        }

        // Vérifier si le RDV est dans le futur
        return appointmentDate.isAfter(now);
      }).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerDashboard();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const EmptyState(
            icon: Icons.error_outline,
            message: 'Erreur de chargement du profil',
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final createur = CreateurModel.fromMap(userData, id: snapshot.data!.id);
        final clientsCount = userData['followersCount'] ?? 0;

        return RefreshIndicator(
          onRefresh: () => Future.delayed(const Duration(seconds: 1)),
          color: const Color(0xFF4A6FA5),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WelcomeSection(
                    createur: createur,
                    isOnline: isOnline,
                    onStatusChanged: onStatusChanged
                ),
                const SizedBox(height: 24),
                // Utiliser StreamBuilder pour les statistiques avec RDV dynamique
                StreamBuilder<int>(
                  stream: _getUpcomingAppointmentsCount(),
                  builder: (context, appointmentsSnapshot) {
                    final upcomingAppointments = appointmentsSnapshot.data ?? 0;

                    return StatsSection(
                      createur: createur,
                      clientsCount: clientsCount as int,
                      upcomingAppointments: upcomingAppointments,
                    );
                  },
                ),
                const SizedBox(height: 24),
                const QuickActions(),
                const SizedBox(height: 24),
                RecentActivitySection(createur: createur),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }
}