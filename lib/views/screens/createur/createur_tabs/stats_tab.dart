import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/createur/creator_appointment.dart';
import '../../../../models/createur/creator_creation.dart';
import '../../../../services/createur/creator_appointment_service.dart';
import '../../../../services/createur/creator_creation_service.dart';
import '../../commerce/catalogue_express_screen.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final creationService = CreatorCreationService();
    final appointmentService = CreatorAppointmentService();
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
        builder: (context, profileSnapshot) {
          final profileData = profileSnapshot.data?.data() ?? const {};
          final profileViews =
              (profileData['profileViewsCount'] as num?)?.toInt() ??
              (profileData['viewsCount'] as num?)?.toInt() ??
              (profileData['stats'] is Map
                  ? ((Map<String, dynamic>.from(
                            profileData['stats'] as Map,
                          )['profileViews']
                          as num?)
                      ?.toInt())
                  : null) ??
              0;
          return StreamBuilder<List<CreatorCreation>>(
            stream: creationService.watchCreations(user.uid),
            builder: (context, creationsSnapshot) {
              return StreamBuilder<List<CreatorAppointment>>(
                stream: appointmentService.watchAppointments(user.uid),
                builder: (context, appointmentsSnapshot) {
                  final creations = creationsSnapshot.data ?? const [];
                  final appointments = appointmentsSnapshot.data ?? const [];
                  final totalViews = creations.fold<int>(
                    0,
                    (total, creation) => total + creation.viewsCount,
                  );
                  final totalSaves = creations.fold<int>(
                    0,
                    (total, creation) => total + creation.savesCount,
                  );
                  final completedAppointments =
                      appointments
                          .where((appointment) => appointment.isDone)
                          .length;
                  final conversion =
                      totalViews == 0
                          ? 0
                          : (totalSaves / totalViews * 100).round();

                  return RefreshIndicator(
                    onRefresh: () async {},
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      children: [
                        const SectionHeader(
                          padding: EdgeInsets.zero,
                          title: 'Performance',
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.35,
                          children: [
                            _KpiCard(
                              label: 'Vues profil',
                              value: '$profileViews',
                              icon: Icons.person_search_rounded,
                              color: ModernColors.primary,
                            ),
                            _KpiCard(
                              label: 'Vues créations',
                              value: '$totalViews',
                              icon: Icons.visibility_rounded,
                              color: ModernColors.creator,
                            ),
                            _KpiCard(
                              label: 'Souhaits',
                              value: '$totalSaves',
                              icon: Icons.favorite_rounded,
                              color: ModernColors.rose,
                            ),
                            _KpiCard(
                              label: 'Intérêt',
                              value: '$conversion%',
                              icon: Icons.trending_up_rounded,
                              color: ModernColors.accent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        SectionHeader(
                          padding: EdgeInsets.zero,
                          title: 'Créations les plus vues',
                          subtitle: creations.isEmpty ? null : 'Top Salon',
                        ),
                        const SizedBox(height: 12),
                        if (creations.isEmpty)
                          _StatsEmpty(
                            onPublish: () => _openCatalogueExpress(context),
                          )
                        else
                          ..._topCreations(creations).map(
                            (creation) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AppCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        width: 54,
                                        height: 54,
                                        color: ModernColors.canvas,
                                        child:
                                            creation.coverImage.isEmpty
                                                ? const Icon(
                                                  Icons.image_rounded,
                                                )
                                                : Image.network(
                                                  creation.coverImage,
                                                  fit: BoxFit.cover,
                                                ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            creation.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: ModernColors.ink,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          Text(
                                            '${creation.viewsCount} vues • ${creation.savesCount} souhaits',
                                            style: const TextStyle(
                                              color: ModernColors.inkSoft,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _RecommendationCard(
                          hasData:
                              creations.isNotEmpty || appointments.isNotEmpty,
                          totalViews: totalViews,
                          profileViews: profileViews,
                          completedAppointments: completedAppointments,
                          pendingDrafts:
                              creations
                                  .where((creation) => creation.isDraft)
                                  .length,
                          onTap: () => _openCatalogueExpress(context),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<CreatorCreation> _topCreations(List<CreatorCreation> creations) {
    final sorted = [...creations];
    sorted.sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    return sorted.take(6).toList();
  }

  void _openCatalogueExpress(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CatalogueExpressScreen(role: 'createur'),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.inkSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsEmpty extends StatelessWidget {
  const _StatsEmpty({required this.onPublish});

  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Icon(
            Icons.insights_rounded,
            color: ModernColors.inkSoft,
            size: 38,
          ),
          const SizedBox(height: 10),
          const Text(
            'Pas encore assez de données',
            style: TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Publiez une création.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ModernColors.inkSoft),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Publier',
            onPressed: onPublish,
            icon: Icons.add_rounded,
            variant: AppButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.hasData,
    required this.totalViews,
    required this.profileViews,
    required this.completedAppointments,
    required this.pendingDrafts,
    required this.onTap,
  });

  final bool hasData;
  final int totalViews;
  final int profileViews;
  final int completedAppointments;
  final int pendingDrafts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title =
        !hasData
            ? 'À publier'
            : pendingDrafts > 0
            ? 'Brouillons'
            : totalViews < 20
            ? 'Faible visibilité'
            : 'Top création';
    final subtitle =
        !hasData
            ? 'Ajoutez une pièce visible.'
            : pendingDrafts > 0
            ? '$pendingDrafts à finaliser.'
            : totalViews < 20
            ? '$profileViews vues profil · $completedAppointments RDV terminés.'
            : 'Voir Salon et garder ce style actif.';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      color: ModernColors.creator.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: ModernColors.creator),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: ModernColors.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
