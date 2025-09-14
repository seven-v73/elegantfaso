import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Rôles spécifiques
  final double? rating;
  final int? reviewsCount;
  final String? createurId;
  final String? boutiqueId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImage = '',
    required this.createdAt,
    required this.updatedAt,
    this.rating,
    this.reviewsCount,
    this.createurId,
    this.boutiqueId,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, {required String id}) {
    return UserModel(
      id: id,
      name: data['name'] ?? 'Inconnu',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      profileImage: data['profileImage'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: data['rating'] != null
          ? (data['rating'] is int
          ? (data['rating'] as int).toDouble()
          : data['rating'])
          : null,
      reviewsCount: data['reviewsCount'],
      createurId: data['createurId'],
      boutiqueId: data['boutiqueId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'profileImage': profileImage,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'createurId': createurId,
      'boutiqueId': boutiqueId,
    };
  }
}
