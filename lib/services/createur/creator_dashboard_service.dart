import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/createur/creator_activity.dart';
import '../../models/createur/creator_dashboard_summary.dart';
import 'creator_appointment_service.dart';
import 'creator_creation_service.dart';

class CreatorDashboardService {
  CreatorDashboardService({
    FirebaseFirestore? firestore,
    CreatorCreationService? creationService,
    CreatorAppointmentService? appointmentService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _creationService = creationService ?? CreatorCreationService(),
       _appointmentService = appointmentService ?? CreatorAppointmentService();

  final FirebaseFirestore _firestore;
  final CreatorCreationService _creationService;
  final CreatorAppointmentService _appointmentService;

  Stream<CreatorDashboardSummary> watchSummary(String creatorId) {
    if (creatorId.isEmpty) return Stream.value(_empty);
    return _firestore.collection('users').doc(creatorId).snapshots().asyncMap((
      userDoc,
    ) async {
      final userData = userDoc.data() ?? {};
      final creations = await _creationService.loadCreations(creatorId);
      final appointments = await _appointmentService.loadAppointments(
        creatorId,
      );
      final notificationsSnapshot = await _getSafely(
        _firestore
            .collection('notifications')
            .where('userId', isEqualTo: creatorId)
            .where('read', isEqualTo: false)
            .limit(40),
      );

      final now = DateTime.now();
      final todayAppointments =
          appointments.where((appointment) => appointment.isToday).toList();
      final pendingAppointments =
          appointments.where((appointment) => appointment.isPending).toList();
      final totalViews = creations.fold<int>(
        0,
        (total, creation) => total + creation.viewsCount,
      );
      final totalSaves = creations.fold<int>(
        0,
        (total, creation) => total + creation.savesCount,
      );
      final profileViews =
          (userData['profileViewsCount'] as num?)?.toInt() ??
          (userData['viewsCount'] as num?)?.toInt() ??
          (userData['stats'] is Map
              ? ((Map<String, dynamic>.from(
                        userData['stats'] as Map,
                      )['profileViews']
                      as num?)
                  ?.toInt())
              : null) ??
          0;
      final followers = List<String>.from(userData['followers'] ?? const []);
      final activities = <CreatorActivity>[
        if (pendingAppointments.isNotEmpty)
          CreatorActivity(
            title: '${pendingAppointments.length} rendez-vous à confirmer',
            subtitle: 'Validez ou contactez le client',
            icon: Icons.event_available_rounded,
            color: const Color(0xFFF59E0B),
          ),
        if (todayAppointments.isNotEmpty)
          CreatorActivity(
            title: '${todayAppointments.length} rendez-vous aujourd’hui',
            subtitle: 'Préparez vos essayages et mesures',
            icon: Icons.today_rounded,
            color: const Color(0xFF2563EB),
          ),
        if (creations.where((creation) => creation.isDraft).isNotEmpty)
          CreatorActivity(
            title: 'Créations en brouillon',
            subtitle: 'Publiez-les pour augmenter votre visibilité Salon',
            icon: Icons.edit_note_rounded,
            color: const Color(0xFF7C3AED),
          ),
        if (notificationsSnapshot?.docs.isNotEmpty == true)
          CreatorActivity(
            title: '${notificationsSnapshot!.docs.length} notifications',
            subtitle: 'Messages, demandes ou alertes à vérifier',
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFFE11D48),
          ),
      ];

      creations.sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
      todayAppointments.sort((a, b) {
        final aDate = a.date ?? now;
        final bDate = b.date ?? now;
        return aDate.compareTo(bDate);
      });

      return CreatorDashboardSummary(
        creatorName:
            userData['creatorName']?.toString() ??
            userData['creatorProfile']?['name']?.toString() ??
            userData['displayName']?.toString() ??
            'Créateur',
        photoUrl:
            userData['creatorPhotoUrl']?.toString() ??
            userData['creatorProfile']?['photoUrl']?.toString() ??
            userData['photoUrl']?.toString() ??
            '',
        specialty:
            userData['specialty']?.toString() ??
            userData['creatorProfile']?['specialty']?.toString() ??
            '',
        isOnline: userData['isOnline'] == true,
        creationsCount: creations.length,
        publishedCount:
            creations.where((creation) => creation.isVisibleInSalon).length,
        draftCount: creations.where((creation) => creation.isDraft).length,
        hiddenCount: creations.where((creation) => creation.isHidden).length,
        pendingAppointmentsCount: pendingAppointments.length,
        todayAppointmentsCount: todayAppointments.length,
        followersCount:
            (userData['followersCount'] as num?)?.toInt() ?? followers.length,
        unreadMessagesCount: notificationsSnapshot?.docs.length ?? 0,
        profileViewsCount: profileViews,
        totalViews: totalViews,
        totalSaves: totalSaves,
        topCreations: creations.take(5).toList(),
        todayAppointments: todayAppointments.take(4).toList(),
        activities: activities,
      );
    });
  }

  Future<QuerySnapshot<Map<String, dynamic>>?> _getSafely(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      return await query.get();
    } catch (_) {
      return null;
    }
  }

  static const _empty = CreatorDashboardSummary(
    creatorName: 'Créateur',
    photoUrl: '',
    specialty: '',
    isOnline: false,
    creationsCount: 0,
    publishedCount: 0,
    draftCount: 0,
    hiddenCount: 0,
    pendingAppointmentsCount: 0,
    todayAppointmentsCount: 0,
    followersCount: 0,
    unreadMessagesCount: 0,
    profileViewsCount: 0,
    totalViews: 0,
    totalSaves: 0,
    topCreations: [],
    todayAppointments: [],
    activities: [],
  );
}
