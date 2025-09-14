import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum UserRole { client, boutique, createur, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.metadata,
  });

  // Conversion depuis Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? 'Sans nom',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      role: _parseRole(data['role']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'],
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': _roleToString(role),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      if (metadata != null) 'metadata': metadata,
    };
  }

  // Helpers
  static UserRole _parseRole(String role) {
    switch (role) {
      case 'boutique': return UserRole.boutique;
      case 'createur': return UserRole.createur;
      case 'admin': return UserRole.admin;
      default: return UserRole.client;
    }
  }

  static String _roleToString(UserRole role) {
    return role.toString().split('.').last;
  }

  // Formatteurs
  String formattedDate() {
    return DateFormat('dd/MM/yyyy à HH:mm').format(createdAt);
  }

  String roleName() {
    switch (role) {
      case UserRole.client: return 'Client';
      case UserRole.boutique: return 'Boutique';
      case UserRole.createur: return 'Créateur';
      case UserRole.admin: return 'Administrateur';
    }
  }
}