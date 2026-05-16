import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityAccessModes {
  static const public = 'public';
  static const membersOnly = 'members_only';
  static const restricted = 'restricted';
  static const closed = 'closed';

  static const values = [public, membersOnly, restricted, closed];
}

class CommunityAccessPolicy {
  const CommunityAccessPolicy({
    required this.mode,
    this.reason = '',
    this.lockedUntil,
    this.allowedUserIds = const [],
    this.blockedUserIds = const [],
  });

  factory CommunityAccessPolicy.open() {
    return const CommunityAccessPolicy(mode: CommunityAccessModes.public);
  }

  factory CommunityAccessPolicy.fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return CommunityAccessPolicy.open();

    final mode = data['mode']?.toString() ?? CommunityAccessModes.public;
    final lockedUntil = data['lockedUntil'];

    return CommunityAccessPolicy(
      mode:
          CommunityAccessModes.values.contains(mode)
              ? mode
              : CommunityAccessModes.public,
      reason: data['reason']?.toString() ?? '',
      lockedUntil:
          lockedUntil is Timestamp
              ? lockedUntil.toDate()
              : lockedUntil is DateTime
              ? lockedUntil
              : null,
      allowedUserIds: _stringList(data['allowedUserIds']),
      blockedUserIds: _stringList(data['blockedUserIds']),
    );
  }

  final String mode;
  final String reason;
  final DateTime? lockedUntil;
  final List<String> allowedUserIds;
  final List<String> blockedUserIds;

  bool get hasActiveTimeLock {
    final limit = lockedUntil;
    return limit != null && DateTime.now().isBefore(limit);
  }

  bool get isClosed {
    return mode == CommunityAccessModes.closed &&
        (lockedUntil == null || hasActiveTimeLock);
  }

  bool canRead(String? userId) {
    if (isClosed) return false;
    if (userId != null && blockedUserIds.contains(userId)) return false;
    return true;
  }

  bool canWrite(String? userId) {
    if (userId == null || userId.trim().isEmpty) return false;
    if (blockedUserIds.contains(userId)) return false;
    if (isClosed) return false;
    if (mode == CommunityAccessModes.restricted) {
      return allowedUserIds.contains(userId);
    }
    return true;
  }

  String messageFor(String? userId) {
    if (userId != null && blockedUserIds.contains(userId)) {
      return reason.isNotEmpty
          ? reason
          : 'Votre accès à la communauté est temporairement limité.';
    }
    if (isClosed) {
      return reason.isNotEmpty
          ? reason
          : 'La communauté est en pause pour le moment.';
    }
    if (mode == CommunityAccessModes.restricted && !canWrite(userId)) {
      return reason.isNotEmpty
          ? reason
          : 'Cette discussion est limitée à certains membres.';
    }
    return '';
  }

  static List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
