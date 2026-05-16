import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/account_roles.dart';

class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.displayName,
    required this.photoUrl,
    required this.roles,
    this.city = '',
    this.country = '',
    this.bio = '',
    this.specialty = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.secondhandListings = 0,
    this.secondhandSold = 0,
    this.isVerified = false,
    this.publicBadges = const [],
  });

  factory PublicProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return PublicProfile.fromMap(doc.data() ?? const {}, id: doc.id);
  }

  factory PublicProfile.fromMap(Map<String, dynamic> data, {String id = ''}) {
    return PublicProfile(
      id: id.isNotEmpty ? id : data['id']?.toString() ?? '',
      displayName:
          data['displayName']?.toString() ??
          data['name']?.toString() ??
          'Client ElegantStyle',
      photoUrl: data['photoUrl']?.toString() ?? '',
      roles: AccountRoles.normalize(data),
      city:
          data['city']?.toString() ??
          data['location']?.toString() ??
          data['shopProfile']?['city']?.toString() ??
          data['creatorProfile']?['city']?.toString() ??
          '',
      country:
          data['country']?.toString() ??
          data['shopProfile']?['country']?.toString() ??
          data['creatorProfile']?['country']?.toString() ??
          '',
      bio:
          data['bio']?.toString() ??
          data['description']?.toString() ??
          data['boutiqueDescription']?.toString() ??
          '',
      specialty:
          data['specialty']?.toString() ??
          data['creatorProfile']?['specialty']?.toString() ??
          data['shopProfile']?['shopName']?.toString() ??
          data['boutiqueName']?.toString() ??
          '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      secondhandListings: (data['secondhandListings'] as num?)?.toInt() ?? 0,
      secondhandSold: (data['secondhandSold'] as num?)?.toInt() ?? 0,
      isVerified: data['isVerified'] == true,
      publicBadges:
          (data['publicBadges'] as Iterable?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
    );
  }

  factory PublicProfile.fromUserData({
    required String uid,
    required String role,
    required Map<String, dynamic> data,
  }) {
    final normalized = <String>{AccountRoles.client, role};
    final shopProfile = data['shopProfile'];
    final creatorProfile = data['creatorProfile'];
    final roleData =
        role == AccountRoles.boutique && shopProfile is Map
            ? shopProfile
            : role == AccountRoles.createur && creatorProfile is Map
            ? creatorProfile
            : const {};
    return PublicProfile.fromMap({
      ...data,
      ...Map<String, dynamic>.from(roleData),
      'id': uid,
      'roles': normalized.toList(),
      'activeRole': role,
      'displayName':
          role == AccountRoles.boutique
              ? data['boutiqueName'] ??
                  roleData['shopName'] ??
                  roleData['name'] ??
                  data['displayName']
              : data['creatorName'] ??
                  roleData['name'] ??
                  data['displayName'] ??
                  data['name'],
      'photoUrl':
          role == AccountRoles.boutique
              ? data['boutiqueLogoUrl'] ??
                  data['boutiquePhotoUrl'] ??
                  roleData['logoUrl'] ??
                  roleData['photoUrl'] ??
                  data['photoUrl']
              : data['creatorPhotoUrl'] ??
                  roleData['photoUrl'] ??
                  data['photoUrl'],
      'specialty':
          role == AccountRoles.boutique
              ? data['boutiqueDescription'] ??
                  roleData['description'] ??
                  roleData['category'] ??
                  data['boutiqueName']
              : data['specialty'] ??
                  roleData['specialty'] ??
                  roleData['description'] ??
                  data['bio'],
      'city':
          roleData['city'] ??
          data['city'] ??
          data['ville'] ??
          roleData['address'],
      'country': roleData['country'] ?? data['country'] ?? data['pays'],
      'bio':
          role == AccountRoles.boutique
              ? data['boutiqueDescription'] ??
                  roleData['description'] ??
                  data['bio']
              : roleData['bio'] ??
                  roleData['description'] ??
                  data['bio'] ??
                  data['description'],
      'isVerified': data['isVerified'] == true || role != AccountRoles.client,
    }, id: uid);
  }

  final String id;
  final String displayName;
  final String photoUrl;
  final List<String> roles;
  final String city;
  final String country;
  final String bio;
  final String specialty;
  final double rating;
  final int reviewCount;
  final int secondhandListings;
  final int secondhandSold;
  final bool isVerified;
  final List<String> publicBadges;

  String get primaryRole {
    if (roles.contains(AccountRoles.boutique)) return AccountRoles.boutique;
    if (roles.contains(AccountRoles.createur)) return AccountRoles.createur;
    return AccountRoles.client;
  }

  String get roleLabel {
    return switch (primaryRole) {
      AccountRoles.boutique => 'Boutique certifiée',
      AccountRoles.createur => 'Créateur certifié',
      _ => 'Client de la communauté',
    };
  }

  bool get canPublish {
    return id.isNotEmpty &&
        displayName.trim().isNotEmpty &&
        roles.any(
          (role) =>
              role == AccountRoles.boutique || role == AccountRoles.createur,
        );
  }

  String get initials {
    final cleaned = displayName.trim();
    if (cleaned.isEmpty) return 'ES';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return cleaned.length > 1
        ? cleaned.substring(0, 2).toUpperCase()
        : cleaned.toUpperCase();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'roles': roles,
      'city': city,
      'country': country,
      'bio': bio,
      'specialty': specialty,
      'rating': rating,
      'reviewCount': reviewCount,
      'secondhandListings': secondhandListings,
      'secondhandSold': secondhandSold,
      'isVerified': isVerified,
      'publicBadges': publicBadges,
      'primaryRole': primaryRole,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toSalonPlaceMap() {
    return {
      'ownerId': id,
      'userId': id,
      'name': displayName,
      'displayName': displayName,
      'imageUrl': photoUrl,
      'photoUrl': photoUrl,
      'type': primaryRole,
      'role': primaryRole,
      'publicRole': primaryRole,
      'primaryRole': primaryRole,
      'roles': roles,
      'isPublic': true,
      'publicProfile': true,
      'subtitle': specialty.isEmpty ? roleLabel : specialty,
      'specialty': specialty,
      'city': city,
      'country': country,
      'bio': bio,
      'verified': isVerified,
      'isVerified': isVerified,
      'rating': rating,
      'reviewCount': reviewCount,
      'tags': [
        primaryRole,
        if (specialty.isNotEmpty) specialty,
        ...publicBadges,
      ],
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
