class CreatorCustomer {
  const CreatorCustomer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.typeLabel,
    required this.appointmentsCount,
    required this.ordersCount,
    required this.hasMeasurements,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String typeLabel;
  final int appointmentsCount;
  final int ordersCount;
  final bool hasMeasurements;
}
