// Create a new file: lib/models/user_profile.dart
class UserProfile {
  final String name;
  final String uid;
  final String? email;
  final String? photoUrl;
  final Map<String, dynamic>? preferences;

  UserProfile({
    required this.name,
    required this.uid,
    this.email,
    this.photoUrl,
    this.preferences,
  });

  // Factory constructor for creating a default profile
  factory UserProfile.defaultProfile({
    required String name,
    required String uid,
    String? email,
    String? photoUrl,
  }) {
    return UserProfile(
      name: name,
      uid: uid,
      email: email,
      photoUrl: photoUrl,
      preferences: <String, dynamic>{},
    );
  }

  // Factory constructor for creating from Firebase document
  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      name: data['name'] ?? 'User',
      uid: uid,
      email: data['email'],
      photoUrl: data['photoUrl'],
      preferences: data['preferences'] ?? <String, dynamic>{},
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'uid': uid,
      'email': email,
      'photoUrl': photoUrl,
      'preferences': preferences,
    };
  }

  // Copy with method for updating profile
  UserProfile copyWith({
    String? name,
    String? uid,
    String? email,
    String? photoUrl,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      name: name ?? this.name,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      preferences: preferences ?? this.preferences,
    );
  }
}