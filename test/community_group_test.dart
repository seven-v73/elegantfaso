import 'package:elegantfaso/models/community/community_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommunityGroup', () {
    test('open approved group lets any connected user post', () {
      const group = CommunityGroup(
        id: 'abidjan-coiffure',
        name: 'Abidjan Coiffure',
        description: 'Conseils et entraide coiffure',
        category: 'Coiffure',
        city: 'Abidjan',
        country: 'Côte d’Ivoire',
        ownerId: 'owner',
        ownerName: 'Owner',
        status: CommunityGroupStatuses.approved,
        accessMode: CommunityGroupAccessModes.open,
        memberIds: ['owner'],
        memberCount: 1,
      );

      expect(group.canPost('visitor'), isTrue);
      expect(group.canRequestAccess('visitor'), isTrue);
    });

    test('request group requires membership to post', () {
      const group = CommunityGroup(
        id: 'dakar-mariage',
        name: 'Dakar Mariage',
        description: 'Looks mariage',
        category: 'Mariage',
        city: 'Dakar',
        country: 'Sénégal',
        ownerId: 'owner',
        ownerName: 'Owner',
        status: CommunityGroupStatuses.approved,
        accessMode: CommunityGroupAccessModes.request,
        memberIds: ['owner', 'member'],
        memberCount: 2,
      );

      expect(group.canPost('member'), isTrue);
      expect(group.canPost('visitor'), isFalse);
      expect(group.canRequestAccess('visitor'), isTrue);
    });

    test('admin can post even when group is closed', () {
      const group = CommunityGroup(
        id: 'closed',
        name: 'Closed',
        description: 'Closed group',
        category: 'Mode',
        city: '',
        country: '',
        ownerId: 'owner',
        ownerName: 'Owner',
        status: CommunityGroupStatuses.closed,
        accessMode: CommunityGroupAccessModes.closed,
        memberIds: [],
        memberCount: 0,
      );

      expect(group.canPost('user'), isFalse);
      expect(group.canPost('admin', isAdmin: true), isTrue);
    });
  });
}
