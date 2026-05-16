import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityGroupStatuses {
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const suspended = 'suspended';
  static const closed = 'closed';
}

class CommunityGroupAccessModes {
  static const open = 'open';
  static const request = 'request';
  static const inviteOnly = 'invite_only';
  static const closed = 'closed';
}

class CommunityMemberRoles {
  static const owner = 'owner';
  static const moderator = 'moderator';
  static const member = 'member';
}

class CommunityGroup {
  const CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.city,
    required this.country,
    required this.ownerId,
    required this.ownerName,
    required this.status,
    required this.accessMode,
    required this.memberIds,
    required this.memberCount,
    this.rules = '',
    this.imageUrl = '',
  });

  factory CommunityGroup.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const {};
    return CommunityGroup(
      id: snapshot.id,
      name: data['name']?.toString() ?? 'Communauté',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Mode',
      city: data['city']?.toString() ?? '',
      country: data['country']?.toString() ?? '',
      ownerId: data['ownerId']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? 'Gestionnaire',
      status: data['status']?.toString() ?? CommunityGroupStatuses.pending,
      accessMode:
          data['accessMode']?.toString() ?? CommunityGroupAccessModes.request,
      memberIds:
          (data['memberIds'] as Iterable?)
              ?.map((id) => id.toString())
              .where((id) => id.isNotEmpty)
              .toList() ??
          const [],
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      rules: data['rules']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
    );
  }

  final String id;
  final String name;
  final String description;
  final String category;
  final String city;
  final String country;
  final String ownerId;
  final String ownerName;
  final String status;
  final String accessMode;
  final List<String> memberIds;
  final int memberCount;
  final String rules;
  final String imageUrl;

  bool get isApproved => status == CommunityGroupStatuses.approved;
  bool get isClosed {
    return status == CommunityGroupStatuses.closed ||
        accessMode == CommunityGroupAccessModes.closed;
  }

  bool isOwner(String? userId) => userId != null && userId == ownerId;
  bool isMember(String? userId) {
    return userId != null && memberIds.contains(userId);
  }

  bool canRequestAccess(String? userId) {
    if (userId == null || userId.isEmpty || !isApproved || isClosed) {
      return false;
    }
    if (isMember(userId)) return false;
    return accessMode != CommunityGroupAccessModes.inviteOnly;
  }

  bool canPost(String? userId, {bool isAdmin = false}) {
    if (isAdmin) return true;
    if (userId == null || userId.isEmpty || !isApproved || isClosed) {
      return false;
    }
    return accessMode == CommunityGroupAccessModes.open || isMember(userId);
  }

  String get locationLabel {
    final parts = [city, country].where((part) => part.trim().isNotEmpty);
    return parts.isEmpty ? 'Monde entier' : parts.join(', ');
  }
}
