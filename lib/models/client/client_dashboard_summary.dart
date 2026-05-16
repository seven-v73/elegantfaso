import '../measurements/measurement_profile.dart';
import '../wardrobe/wardrobe_item.dart';
import 'client_saved_item.dart';

class ClientDashboardSummary {
  final String userId;
  final String displayName;
  final String email;
  final String phone;
  final String bio;
  final String photoUrl;
  final String coverPhoto;
  final String city;
  final Map<String, String> paymentMethods;
  final int followersCount;
  final int followingCount;
  final List<WardrobeItem> wardrobeItems;
  final List<ClientSavedItem> savedItems;
  final MeasurementProfile measurementProfile;
  final int unreadMessagesCount;
  final int activeOrdersCount;
  final int upcomingEventsCount;
  final int activeAppointmentsCount;

  const ClientDashboardSummary({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.bio,
    required this.photoUrl,
    required this.coverPhoto,
    required this.city,
    this.paymentMethods = const {},
    this.followersCount = 0,
    this.followingCount = 0,
    required this.wardrobeItems,
    required this.savedItems,
    required this.measurementProfile,
    this.unreadMessagesCount = 0,
    this.activeOrdersCount = 0,
    this.upcomingEventsCount = 0,
    this.activeAppointmentsCount = 0,
  });

  int get wardrobeCount => wardrobeItems.length;
  int get favoriteCount => wardrobeItems.where((item) => item.favorite).length;
  int get wishlistCount => savedItems.length;
  double get measurementCompletion => measurementProfile.completionRate;

  List<WardrobeItem> get recentWardrobeItems => wardrobeItems.take(8).toList();

  bool get hasPendingWork {
    return unreadMessagesCount > 0 ||
        activeOrdersCount > 0 ||
        activeAppointmentsCount > 0 ||
        measurementCompletion < 0.6 ||
        wardrobeCount < 3;
  }

  String get firstName {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'Client';
    return trimmed.split(RegExp(r'\s+')).first;
  }
}
