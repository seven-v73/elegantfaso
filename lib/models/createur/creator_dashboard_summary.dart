import 'creator_activity.dart';
import 'creator_appointment.dart';
import 'creator_creation.dart';

class CreatorDashboardSummary {
  const CreatorDashboardSummary({
    required this.creatorName,
    required this.photoUrl,
    required this.specialty,
    required this.isOnline,
    required this.creationsCount,
    required this.publishedCount,
    required this.draftCount,
    required this.hiddenCount,
    required this.pendingAppointmentsCount,
    required this.todayAppointmentsCount,
    required this.followersCount,
    required this.unreadMessagesCount,
    required this.profileViewsCount,
    required this.totalViews,
    required this.totalSaves,
    required this.topCreations,
    required this.todayAppointments,
    required this.activities,
  });

  final String creatorName;
  final String photoUrl;
  final String specialty;
  final bool isOnline;
  final int creationsCount;
  final int publishedCount;
  final int draftCount;
  final int hiddenCount;
  final int pendingAppointmentsCount;
  final int todayAppointmentsCount;
  final int followersCount;
  final int unreadMessagesCount;
  final int profileViewsCount;
  final int totalViews;
  final int totalSaves;
  final List<CreatorCreation> topCreations;
  final List<CreatorAppointment> todayAppointments;
  final List<CreatorActivity> activities;
}
