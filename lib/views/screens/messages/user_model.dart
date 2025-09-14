import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserModel {
  // Core properties
  final String id;
  final String email;
  final String displayName;
  final String role;
  final String? photoUrl;

  // Social properties
  final List<String> following;
  final List<String> followers;
  final int followingCount;
  final int followersCount;

  // Contact & profile
  final String? phone;
  final String? specialty;
  final String? location;
  final String? bio;

  // Shop properties
  final String? boutiqueName;
  final String? boutiqueAddress;
  final String? boutiqueDescription;
  final int productsCount;

  // Status & presence
  final bool isOnline;
  final DateTime lastSeen;
  final String fcmToken;
  final Map<String, dynamic>? preferences;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  // Roles management
  final List<String> roles;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
    required this.following,
    required this.followers,
    required this.followingCount,
    required this.followersCount,
    this.phone,
    this.specialty,
    this.location,
    this.bio,
    this.boutiqueName,
    this.boutiqueAddress,
    this.boutiqueDescription,
    this.productsCount = 0,
    required this.isOnline,
    required this.lastSeen,
    this.fcmToken = '',
    this.preferences,
    required this.createdAt,
    required this.updatedAt,
    this.roles = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      return DateTime.now();
    }

    return UserModel(
      id: docId ?? map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      displayName: map['displayName']?.toString() ??
          map['name']?.toString() ??
          map['boutiqueName']?.toString() ??
          'Utilisateur',
      role: map['role']?.toString() ?? 'client',
      photoUrl: map['photoUrl']?.toString(),
      following: List<String>.from(map['following']?.map((e) => e.toString()) ?? []),
      followers: List<String>.from(map['followers']?.map((e) => e.toString()) ?? []),
      followingCount: (map['followingCount'] as int?) ?? 0,
      followersCount: (map['followersCount'] as int?) ?? 0,
      phone: map['phone']?.toString() ?? map['phoneNumber']?.toString(),
      specialty: map['specialty']?.toString(),
      location: map['location']?.toString(),
      bio: map['bio']?.toString(),
      boutiqueName: map['boutiqueName']?.toString(),
      boutiqueAddress: map['boutiqueAddress']?.toString(),
      boutiqueDescription: map['boutiqueDescription']?.toString(),
      productsCount: (map['productsCount'] as int?) ?? 0,
      isOnline: (map['isOnline'] as bool?) ?? false,
      lastSeen: parseTimestamp(map['lastSeen']) ?? DateTime.now(),
      fcmToken: map['fcmToken']?.toString() ?? '',
      preferences: map['preferences'] is Map
          ? Map<String, dynamic>.from(map['preferences'])
          : null,
      createdAt: parseTimestamp(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseTimestamp(map['updatedAt']) ?? DateTime.now(),
      roles: List<String>.from(map['roles'] ?? []),
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel.fromMap(
      doc.data() as Map<String, dynamic>,
      docId: doc.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role,
      'photoUrl': photoUrl,
      'following': following,
      'followers': followers,
      'followingCount': followingCount,
      'followersCount': followersCount,
      'phone': phone,
      'specialty': specialty,
      'location': location,
      'bio': bio,
      'boutiqueName': boutiqueName,
      'boutiqueAddress': boutiqueAddress,
      'boutiqueDescription': boutiqueDescription,
      'productsCount': productsCount,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'fcmToken': fcmToken,
      'preferences': preferences,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'roles': roles,
    };
  }

  // Helper methods
  bool get isBoutique => role == 'boutique';
  bool get isAdmin => roles.contains('admin');
  bool get isCustomer => !isBoutique;

  String get mainName => isBoutique ? (boutiqueName ?? displayName) : displayName;

  String get lastSeenFormatted {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';

    return DateFormat('dd/MM/yy HH:mm').format(lastSeen);
  }

  String get statusText => isOnline
      ? 'En ligne'
      : 'Vu $lastSeenFormatted';

  String get safePhotoUrl {
    return photoUrl?.isNotEmpty == true
        ? photoUrl!
        : 'https://ui-avatars.com/api/?name=$displayName&background=random';
  }

  String get shortName {
    final parts = displayName.trim().split(' ');
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.length > 1
        ? displayName.substring(0, 2).toUpperCase()
        : displayName.toUpperCase();
  }

  // Factory methods
  factory UserModel.createNewUser({
    required String userId,
    required String email,
    String? displayName,
  }) {
    return UserModel(
      id: userId,
      email: email,
      displayName: displayName ?? email.split('@').first,
      role: 'client',
      following: [],
      followers: [],
      followingCount: 0,
      followersCount: 0,
      isOnline: true,
      lastSeen: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory UserModel.createNewBoutique({
    required String userId,
    required String name,
    required String address,
    String? email,
    String? description,
  }) {
    return UserModel(
      id: userId,
      email: email ?? '',
      displayName: name,
      role: 'boutique',
      following: [],
      followers: [],
      followingCount: 0,
      followersCount: 0,
      boutiqueName: name,
      boutiqueAddress: address,
      boutiqueDescription: description ?? '',
      isOnline: true,
      lastSeen: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Copy with
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? role,
    String? photoUrl,
    List<String>? following,
    List<String>? followers,
    int? followingCount,
    int? followersCount,
    String? phone,
    String? specialty,
    String? location,
    String? bio,
    String? boutiqueName,
    String? boutiqueAddress,
    String? boutiqueDescription,
    int? productsCount,
    bool? isOnline,
    DateTime? lastSeen,
    String? fcmToken,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? roles,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      followingCount: followingCount ?? this.followingCount,
      followersCount: followersCount ?? this.followersCount,
      phone: phone ?? this.phone,
      specialty: specialty ?? this.specialty,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      boutiqueName: boutiqueName ?? this.boutiqueName,
      boutiqueAddress: boutiqueAddress ?? this.boutiqueAddress,
      boutiqueDescription: boutiqueDescription ?? this.boutiqueDescription,
      productsCount: productsCount ?? this.productsCount,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roles: roles ?? this.roles,
    );
  }

  @override
  String toString() => 'UserModel($id, $displayName, ${isOnline ? "online" : "offline"})';
}