import 'package:cloud_firestore/cloud_firestore.dart' as cf;

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final List<String> following;
  final List<String> followers;
  final int followingCount;
  final int followersCount;
  final String? photoUrl;
  final String? phone;
  final String? specialty;
  final String? location;
  final double rating;
  final bool isVerified;
  final String? boutiqueName;
  final String? boutiqueAddress;
  final String? boutiqueDescription;
  final int productsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.following,
    required this.followers,
    required this.followingCount,
    required this.followersCount,
    this.photoUrl,
    this.phone,
    this.specialty,
    this.location,
    this.rating = 0.0,
    this.isVerified = false,
    this.boutiqueName,
    this.boutiqueAddress,
    this.boutiqueDescription,
    this.productsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is cf.Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      return null;
    }

    return UserModel(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      displayName: map['displayName']?.toString() ??
          map['name']?.toString() ??
          map['boutiqueName']?.toString() ??
          'Utilisateur',
      role: map['role']?.toString() ?? 'client',
      following: List<String>.from(map['following']?.map((e) => e.toString()) ?? []),
      followers: List<String>.from(map['followers']?.map((e) => e.toString()) ?? []),
      followingCount: int.tryParse(map['followingCount']?.toString() ?? '0') ?? 0,
      followersCount: int.tryParse(map['followersCount']?.toString() ?? '0') ?? 0,
      photoUrl: map['photoUrl']?.toString() ??
          map['imageUrl']?.toString() ??
          map['profilePicture']?.toString(),
      phone: map['phone']?.toString() ?? map['phoneNumber']?.toString(),
      specialty: map['specialty']?.toString() ??
          map['category']?.toString() ??
          map['expertise']?.toString(),
      location: map['location']?.toString() ??
          map['address']?.toString() ??
          map['city']?.toString(),
      rating: (map['rating'] is num)
          ? (map['rating'] as num).toDouble()
          : double.tryParse(map['rating']?.toString() ?? '0.0') ?? 0.0,
      isVerified: map['isVerified'] == true,
      boutiqueName: map['boutiqueName']?.toString() ?? map['shopName']?.toString(),
      boutiqueAddress: map['boutiqueAddress']?.toString() ?? map['address']?.toString(),
      boutiqueDescription: map['boutiqueDescription']?.toString() ?? map['description']?.toString(),
      productsCount: int.tryParse(map['productsCount']?.toString() ?? '0') ?? 0,
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role,
      'following': following,
      'followers': followers,
      'followingCount': followingCount,
      'followersCount': followersCount,
      'photoUrl': photoUrl,
      'phone': phone,
      'specialty': specialty,
      'location': location,
      'rating': rating,
      'isVerified': isVerified,
      'boutiqueName': boutiqueName,
      'boutiqueAddress': boutiqueAddress,
      'boutiqueDescription': boutiqueDescription,
      'productsCount': productsCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

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
      rating: 0.0,
      isVerified: false,
      productsCount: 0,
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
      productsCount: 0,
      isVerified: false,
      rating: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  UserModel updateFollowCounts({
    required int newFollowingCount,
    required int newFollowersCount,
  }) {
    return copyWith(
      followingCount: newFollowingCount,
      followersCount: newFollowersCount,
      updatedAt: DateTime.now(),
    );
  }

  UserModel updateFollowers(String userId, {required bool add}) {
    final updated = List<String>.from(followers);
    if (add && !updated.contains(userId)) {
      updated.add(userId);
    } else {
      updated.remove(userId);
    }
    return copyWith(
      followers: updated,
      followersCount: updated.length,
      updatedAt: DateTime.now(),
    );
  }

  UserModel updateFollowing(String userId, {required bool add}) {
    final updated = List<String>.from(following);
    if (add && !updated.contains(userId)) {
      updated.add(userId);
    } else {
      updated.remove(userId);
    }
    return copyWith(
      following: updated,
      followingCount: updated.length,
      updatedAt: DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? role,
    List<String>? following,
    List<String>? followers,
    int? followingCount,
    int? followersCount,
    String? photoUrl,
    String? phone,
    String? specialty,
    String? location,
    double? rating,
    bool? isVerified,
    String? boutiqueName,
    String? boutiqueAddress,
    String? boutiqueDescription,
    int? productsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      followingCount: followingCount ?? this.followingCount,
      followersCount: followersCount ?? this.followersCount,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      specialty: specialty ?? this.specialty,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      isVerified: isVerified ?? this.isVerified,
      boutiqueName: boutiqueName ?? this.boutiqueName,
      boutiqueAddress: boutiqueAddress ?? this.boutiqueAddress,
      boutiqueDescription: boutiqueDescription ?? this.boutiqueDescription,
      productsCount: productsCount ?? this.productsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isBoutique => role == 'boutique';

  String get mainName => isBoutique && boutiqueName != null ? boutiqueName! : displayName;

  String get mainDescription => isBoutique && boutiqueDescription != null
      ? boutiqueDescription!
      : specialty ?? 'Aucune description';

  String? get profileImage => (photoUrl != null && photoUrl!.isNotEmpty) ? photoUrl : null;

  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() => 'UserModel(id: $id, email: $email, name: $displayName, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UserModel && runtimeType == other.runtimeType && id == other.id && email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
