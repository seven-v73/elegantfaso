import 'package:elegantfaso/models/commerce/platform_revenue.dart';
import 'package:elegantfaso/services/salon/salon_boost_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalonBoostIndex', () {
    test('booste tout le compte quand le ownerId correspond', () {
      final index = SalonBoostIndex.fromBoosts([
        BoostCampaign(
          id: 'boost_1',
          ownerId: 'account_1',
          targetId: 'account_1',
          targetType: 'account',
          placement: 'salon_all',
          budget: 1000,
          status: 'active',
          startsAt: DateTime.now().subtract(const Duration(hours: 1)),
          endsAt: DateTime.now().add(const Duration(days: 7)),
        ),
      ]);

      expect(
        index.isBoosted(
          id: 'product_1',
          ownerId: 'account_1',
          data: const {'sellerId': 'account_1'},
        ),
        isTrue,
      );
      expect(
        index.isBoosted(
          id: 'creation_1',
          ownerId: 'account_1',
          data: const {'createurId': 'account_1'},
        ),
        isTrue,
      );
    });

    test('ignore les campagnes expirées ou non actives', () {
      final index = SalonBoostIndex.fromBoosts([
        BoostCampaign(
          id: 'boost_old',
          ownerId: 'account_1',
          targetId: 'account_1',
          targetType: 'account',
          placement: 'salon_all',
          budget: 1000,
          status: 'active',
          startsAt: DateTime.now().subtract(const Duration(days: 10)),
          endsAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        BoostCampaign(
          id: 'boost_pending',
          ownerId: 'account_2',
          targetId: 'account_2',
          targetType: 'account',
          placement: 'salon_all',
          budget: 1000,
          status: 'pending_payment',
        ),
      ]);

      expect(index.isEmpty, isTrue);
      expect(index.boostScore(id: 'product_1', ownerId: 'account_1'), 0);
    });

    test('détecte aussi un entitlement boost actif sur le profil', () {
      const index = SalonBoostIndex();

      expect(
        index.isBoosted(
          id: 'talent_1',
          ownerId: 'talent_1',
          data: const {
            'businessEntitlements': {
              'boost': {'status': 'active'},
            },
          },
        ),
        isTrue,
      );
    });

    test('ignore un entitlement boost expiré sur le profil', () {
      const index = SalonBoostIndex();

      expect(
        index.isBoosted(
          id: 'talent_1',
          ownerId: 'talent_1',
          data: {
            'businessEntitlements': {
              'boost': {
                'status': 'active',
                'endsAt': DateTime.now().subtract(const Duration(days: 1)),
              },
            },
          },
        ),
        isFalse,
      );
    });
  });
}
