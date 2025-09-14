import 'package:cloud_firestore/cloud_firestore.dart';

class CreateurModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final String specialty;
  final String bio;
  final int experience;
  final double rating;
  final int reviewsCount;
  final int ordersCount;
  final int appointmentsCount;
  final double revenue;
  final int clientsCount;
  final DateTime? lastLogin;
  final DateTime? memberSince;
  final List<String> galleryImages;
  final List<String> services;
  final List<String> certifications;
  final bool isVerified;
  final Map<String, bool> availability;
  final Map<String, double> servicePrices;
  final String address;
  final List<String> languages;
  final DateTime createdAt;

  CreateurModel({
    required this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.profileImage = '',
    this.specialty = 'Createur Mode',
    this.bio = '',
    this.experience = 0,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.ordersCount = 0,
    this.appointmentsCount = 0,
    this.revenue = 0.0,
    this.clientsCount = 0,
    this.lastLogin,
    this.memberSince,
    this.galleryImages = const [],
    this.services = const [],
    this.certifications = const [],
    this.isVerified = false,
    this.availability = const {},
    this.servicePrices = const {},
    this.address = '',
    this.languages = const [],
    required this.createdAt,
  });

  factory CreateurModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return CreateurModel(
      id: id ?? data['id'] ?? '',
      name: data['name'] ?? 'Nom inconnu',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profileImage: data['profileImage'] ?? '',
      specialty: data['specialty'] ?? 'Createur Mode',
      bio: data['bio'] ?? '',
      experience: _toInt(data['experience']),
      rating: _toDouble(data['rating']),
      reviewsCount: _toInt(data['reviewsCount']),
      ordersCount: _toInt(data['ordersCount']),
      appointmentsCount: _toInt(data['appointmentsCount']),
      revenue: _toDouble(data['revenue']),
      clientsCount: _toInt(data['clientsCount']),
      lastLogin: _toDateTime(data['lastLogin']),
      memberSince: _toDateTime(data['memberSince']),
      galleryImages: _toStringList(data['galleryImages']),
      services: _toStringList(data['services']),
      certifications: _toStringList(data['certifications']),
      isVerified: data['isVerified'] ?? false,
      availability: _toBoolMap(data['availability']),
      servicePrices: _toDoubleMap(data['servicePrices']),
      address: data['address'] ?? '',
      languages: _toStringList(data['languages']),
      createdAt: _toDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'specialty': specialty,
      'bio': bio,
      'experience': experience,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'ordersCount': ordersCount,
      'appointmentsCount': appointmentsCount,
      'revenue': revenue,
      'clientsCount': clientsCount,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'memberSince': memberSince != null ? Timestamp.fromDate(memberSince!) : null,
      'galleryImages': galleryImages,
      'services': services,
      'certifications': certifications,
      'isVerified': isVerified,
      'availability': availability,
      'servicePrices': servicePrices,
      'address': address,
      'languages': languages,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // === Méthodes utilitaires robustes ===
  static int _toInt(dynamic value) =>
      value is int ? value : int.tryParse(value.toString()) ?? 0;

  static double _toDouble(dynamic value) =>
      value is double ? value : double.tryParse(value.toString()) ?? 0.0;

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static Map<String, bool> _toBoolMap(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val == true));
    }
    return {};
  }

  static Map<String, double> _toDoubleMap(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), _toDouble(val)));
    }
    return {};
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final date = DateTime.tryParse(value);
      if (date != null) return date;
      final unix = int.tryParse(value);
      if (unix != null) return DateTime.fromMillisecondsSinceEpoch(unix);
    }
    return null;
  }

  // === Getters formatés ===
  double get averageRevenuePerClient =>
      clientsCount > 0 ? revenue / clientsCount : 0;

  bool isAvailableOn(String day) =>
      availability[day.toLowerCase()] ?? false;

  double getServicePrice(String service) =>
      servicePrices[service.toLowerCase()] ?? 0.0;

  String get formattedExperience =>
      experience > 1 ? '$experience ans d\'expérience' : 'Débutant';

  String get formattedRating =>
      '${rating.toStringAsFixed(1)} ⭐ ($reviewsCount avis)';
}