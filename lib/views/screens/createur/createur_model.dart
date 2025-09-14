import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateurModel {
  final String id;
  final String name;
  final String email;
  final String profileImage;
  final String specialty;
  final double rating;
  final int reviewsCount;
  final int ordersCount;
  final int appointmentsCount;
  final double revenue;
  final int clientsCount;
  final DateTime lastActive;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> categories;
  final Map<String, dynamic> socialMedia;
  final Map<String, dynamic> contactInfo;
  final List<String> gallery;
  final String bio;

  CreateurModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImage,
    this.specialty = 'Artisan Créateur',
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.ordersCount = 0,
    this.appointmentsCount = 0,
    this.revenue = 0.0,
    this.clientsCount = 0,
    required this.lastActive,
    this.isOnline = false,
    required this.createdAt,
    required this.updatedAt,
    this.categories = const [],
    this.socialMedia = const {},
    this.contactInfo = const {},
    this.gallery = const [],
    this.bio = '',
  });

  factory CreateurModel.fromMap(Map<String, dynamic> data, {required String id}) {
    return CreateurModel(
      id: id,
      name: data['name'] as String? ?? 'Nouveau Créateur',
      email: data['email'] as String? ?? '',
      profileImage: data['profileImage'] as String? ?? '',
      specialty: data['specialty'] as String? ?? 'Artisan Créateur',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: data['reviewsCount'] as int? ?? 0,
      ordersCount: data['ordersCount'] as int? ?? 0,
      appointmentsCount: data['appointmentsCount'] as int? ?? 0,
      revenue: (data['revenue'] as num?)?.toDouble() ?? 0.0,
      clientsCount: data['clientsCount'] as int? ?? 0,
      lastActive: _parseDateTime(data['lastActive']),
      isOnline: data['isOnline'] as bool? ?? false,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      categories: List<String>.from(data['categories'] as List? ?? []),
      socialMedia: Map<String, dynamic>.from(data['socialMedia'] as Map? ?? {}),
      contactInfo: Map<String, dynamic>.from(data['contactInfo'] as Map? ?? {}),
      gallery: List<String>.from(data['gallery'] as List? ?? []),
      bio: data['bio'] as String? ?? '',
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'specialty': specialty,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'ordersCount': ordersCount,
      'appointmentsCount': appointmentsCount,
      'revenue': revenue,
      'clientsCount': clientsCount,
      'lastActive': Timestamp.fromDate(lastActive),
      'isOnline': isOnline,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'categories': categories,
      'socialMedia': socialMedia,
      'contactInfo': contactInfo,
      'gallery': gallery,
      'bio': bio,
    };
  }

  CreateurModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImage,
    String? specialty,
    double? rating,
    int? reviewsCount,
    int? ordersCount,
    int? appointmentsCount,
    double? revenue,
    int? clientsCount,
    DateTime? lastActive,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? categories,
    Map<String, dynamic>? socialMedia,
    Map<String, dynamic>? contactInfo,
    List<String>? gallery,
    String? bio,
  }) {
    return CreateurModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      specialty: specialty ?? this.specialty,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      ordersCount: ordersCount ?? this.ordersCount,
      appointmentsCount: appointmentsCount ?? this.appointmentsCount,
      revenue: revenue ?? this.revenue,
      clientsCount: clientsCount ?? this.clientsCount,
      lastActive: lastActive ?? this.lastActive,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categories: categories ?? this.categories,
      socialMedia: socialMedia ?? this.socialMedia,
      contactInfo: contactInfo ?? this.contactInfo,
      gallery: gallery ?? this.gallery,
      bio: bio ?? this.bio,
    );
  }

  CreateurModel updateOnlineStatus(bool status) {
    return copyWith(
      isOnline: status,
      lastActive: DateTime.now(),
    );
  }

  CreateurModel addCategory(String category) {
    final updatedCategories = List<String>.from(categories)..add(category);
    return copyWith(categories: updatedCategories);
  }

  CreateurModel addToGallery(String imageUrl) {
    final updatedGallery = List<String>.from(gallery)..add(imageUrl);
    return copyWith(gallery: updatedGallery);
  }

  CreateurModel incrementStats({
    int orders = 0,
    int appointments = 0,
    double revenue = 0,
    int clients = 0,
    int reviews = 0,
  }) {
    return copyWith(
      ordersCount: ordersCount + orders,
      appointmentsCount: appointmentsCount + appointments,
      revenue: this.revenue + revenue,
      clientsCount: clientsCount + clients,
      reviewsCount: reviewsCount + reviews,
    );
  }

  String get formattedRevenue {
    final formatter = NumberFormat.currency(
      symbol: 'XOF',
      decimalDigits: 0,
      locale: 'fr_BF',
    );
    return formatter.format(revenue);
  }

  String get lastActiveFormatted {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inSeconds < 60) return 'À l\'instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
    if (difference.inDays == 1) return 'Hier';
    return DateFormat('dd/MM/yyyy HH:mm').format(lastActive);
  }

  bool get isProfileComplete {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        profileImage.isNotEmpty &&
        specialty.isNotEmpty;
  }

  String? getSocialLink(String platform) {
    return socialMedia[platform] as String?;
  }

  String? getContactInfo(String type) {
    return contactInfo[type] as String?;
  }
}
