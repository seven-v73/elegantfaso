class SellerInfo {
  const SellerInfo({
    required this.id,
    required this.name,
    required this.role,
    this.imageUrl = '',
    this.city = '',
    this.phone = '',
    this.speciality = '',
    this.followersCount = 0,
    this.rating = 0,
    this.verified = false,
    this.responseTime = '',
    this.paymentMethods = const {},
  });

  final String id;
  final String name;
  final String role;
  final String imageUrl;
  final String city;
  final String phone;
  final String speciality;
  final int followersCount;
  final double rating;
  final bool verified;
  final String responseTime;
  final Map<String, String> paymentMethods;

  bool get isBoutique => role == 'boutique';
  bool get isClient => role == 'client';

  factory SellerInfo.fallback({required String id, required String role}) {
    return SellerInfo(
      id: id,
      name:
          role == 'boutique'
              ? 'Boutique'
              : role == 'client'
              ? 'Client'
              : 'Créateur',
      role: role,
    );
  }
}
