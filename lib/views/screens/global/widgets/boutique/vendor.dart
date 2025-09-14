class Vendor {
  final String id;
  final String name;
  final String role;
  final Map<String, String> paymentMethods;
  final String phone;
  final String photoUrl;
  final String speciality;
  final int followersCount;

  Vendor({
    required this.id,
    required this.name,
    required this.role,
    required this.paymentMethods,
    required this.phone,
    required this.photoUrl,
    this.speciality = '',
    this.followersCount = 0,
  });
}