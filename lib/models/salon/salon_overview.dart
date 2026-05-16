import 'salon_highlight.dart';

class SalonOverview {
  const SalonOverview({
    required this.isSignedIn,
    required this.userId,
    required this.displayName,
    required this.activeRole,
    required this.city,
    required this.productCount,
    required this.creationCount,
    required this.talentCount,
    required this.eventCount,
    required this.wishlistCount,
    required this.orderCount,
    required this.myCreationCount,
    required this.myProductCount,
    required this.today,
    required this.nearby,
    required this.activeTalents,
    required this.trending,
    required this.events,
    required this.featuredSignature,
    required this.marketplaceCarousel,
  });

  final bool isSignedIn;
  final String userId;
  final String displayName;
  final String activeRole;
  final String city;
  final int productCount;
  final int creationCount;
  final int talentCount;
  final int eventCount;
  final int wishlistCount;
  final int orderCount;
  final int myCreationCount;
  final int myProductCount;
  final List<SalonHighlight> today;
  final List<SalonHighlight> nearby;
  final List<SalonHighlight> activeTalents;
  final List<SalonHighlight> trending;
  final List<SalonHighlight> events;
  final List<SalonHighlight> featuredSignature;
  final List<SalonHighlight> marketplaceCarousel;

  bool get isGuest => !isSignedIn;
  bool get isCreator =>
      activeRole.toLowerCase().contains('createur') ||
      activeRole.toLowerCase().contains('creator');
  bool get isShop =>
      activeRole.toLowerCase().contains('boutique') ||
      activeRole.toLowerCase().contains('shop');
  bool get isProfessional => isCreator || isShop;

  String get firstName {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }
}
