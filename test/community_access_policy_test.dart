import 'package:elegantfaso/models/community/community_access_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommunityAccessPolicy', () {
    test('public policy lets connected users write', () {
      final policy = CommunityAccessPolicy.open();

      expect(policy.canRead('user-a'), isTrue);
      expect(policy.canWrite('user-a'), isTrue);
      expect(policy.canWrite(null), isFalse);
    });

    test('restricted policy only lets allowed users write', () {
      const policy = CommunityAccessPolicy(
        mode: CommunityAccessModes.restricted,
        allowedUserIds: ['allowed-user'],
      );

      expect(policy.canRead('other-user'), isTrue);
      expect(policy.canWrite('allowed-user'), isTrue);
      expect(policy.canWrite('other-user'), isFalse);
    });

    test('closed policy blocks reads and writes while active', () {
      const policy = CommunityAccessPolicy(mode: CommunityAccessModes.closed);

      expect(policy.canRead('user-a'), isFalse);
      expect(policy.canWrite('user-a'), isFalse);
    });

    test('blocked users cannot read or write', () {
      const policy = CommunityAccessPolicy(
        mode: CommunityAccessModes.public,
        blockedUserIds: ['blocked-user'],
      );

      expect(policy.canRead('blocked-user'), isFalse);
      expect(policy.canWrite('blocked-user'), isFalse);
      expect(policy.canRead('other-user'), isTrue);
    });
  });
}
