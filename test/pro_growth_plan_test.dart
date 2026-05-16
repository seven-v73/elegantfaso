import 'package:elegantfaso/models/commerce/platform_revenue.dart';
import 'package:elegantfaso/services/commerce/pro_access_service.dart';
import 'package:elegantfaso/services/commerce/pro_growth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProGrowthService plan helpers', () {
    test('normalise premium et signature vers la même valeur technique', () {
      expect(ProGrowthService.normalizePlanForStorage('signature'), 'premium');
      expect(ProGrowthService.normalizePlanForStorage('premium'), 'premium');
      expect(
        ProGrowthService.normalizePlanForStorage(' Signature '),
        'premium',
      );
      expect(ProGrowthService.normalizePlanForStorage('pro'), 'pro');
      expect(ProGrowthService.normalizePlanForStorage('inconnu'), 'starter');
    });

    test('affiche Signature comme libellé humain du plan premium', () {
      expect(ProGrowthService.planDisplayLabel('premium'), 'Signature');
      expect(ProGrowthService.planDisplayLabel('signature'), 'Signature');
      expect(ProGrowthService.planDisplayLabel('pro'), 'Pro');
      expect(ProGrowthService.planDisplayLabel('starter'), 'Starter');
    });

    test('autorise le boost uniquement avec Signature actif', () {
      final now = DateTime(2026, 1, 1);

      expect(
        ProGrowthService.hasActiveSignatureAccess(
          subscription: SellerSubscription(
            sellerId: 'seller-1',
            plan: 'premium',
            status: 'active',
            expiresAt: now.add(const Duration(days: 1)),
          ),
          now: now,
        ),
        isTrue,
      );
      expect(
        ProGrowthService.hasActiveSignatureAccess(
          entitlements: {
            'plan': 'signature',
            'status': 'active',
            'expiresAt': now.add(const Duration(days: 1)),
          },
          now: now,
        ),
        isTrue,
      );
      expect(
        ProGrowthService.hasActiveSignatureAccess(
          subscription: SellerSubscription(
            sellerId: 'seller-2',
            plan: 'pro',
            status: 'active',
            expiresAt: now.add(const Duration(days: 1)),
          ),
          now: now,
        ),
        isFalse,
      );
      expect(
        ProGrowthService.hasActiveSignatureAccess(
          entitlements: {
            'plan': 'signature',
            'status': 'active',
            'expiresAt': now.subtract(const Duration(minutes: 1)),
          },
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('ProGrowthState', () {
    test(
      'reconnait Signature même si les anciennes données disent premium',
      () {
        final state = ProGrowthState(
          userId: 'seller-1',
          roles: const ['createur'],
          subscription: SellerSubscription(
            sellerId: 'seller-1',
            plan: 'premium',
            status: 'active',
            expiresAt: DateTime(2099),
          ),
          pendingPlan: null,
          pendingPlanCount: 0,
          boostCount: 0,
          hasActiveBoost: false,
          pendingBoostCount: 0,
        );

        expect(state.hasSignaturePlan, isTrue);
        expect(state.hasPremiumPlan, isTrue);
        expect(state.planLabel, 'Signature');
      },
    );

    test(
      'reconnait Signature si une nouvelle donnée utilise déjà signature',
      () {
        final state = ProGrowthState(
          userId: 'seller-2',
          roles: const ['boutique'],
          subscription: SellerSubscription(
            sellerId: 'seller-2',
            plan: 'signature',
            status: 'active',
            expiresAt: DateTime(2099),
          ),
          pendingPlan: null,
          pendingPlanCount: 0,
          boostCount: 0,
          hasActiveBoost: true,
          pendingBoostCount: 0,
        );

        expect(state.hasSignaturePlan, isTrue);
        expect(state.planLabel, 'Signature');
      },
    );
  });

  group('ProAccessState', () {
    test('réserve vitrine immersive et boost aux comptes Signature actifs', () {
      final signature = ProAccessState(
        userId: 'seller-3',
        tier: ProPlanTier.signature,
        status: 'active',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        limits: ProFeatureLimits.signature,
      );

      expect(signature.isSignature, isTrue);
      expect(signature.canBoost, isTrue);
      expect(signature.canCustomizeShowcase, isTrue);
      expect(signature.canUseAdvancedAnalytics, isTrue);
      expect(signature.limits.featuredSlots, 3);
    });

    test('donne les outils métier au plan Pro sans privilège Signature', () {
      final pro = ProAccessState(
        userId: 'seller-4',
        tier: ProPlanTier.pro,
        status: 'active',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        limits: ProFeatureLimits.pro,
      );

      expect(pro.isPro, isTrue);
      expect(pro.canCreateCommunity, isTrue);
      expect(pro.canUseBasicAnalytics, isTrue);
      expect(pro.canBoost, isFalse);
      expect(pro.canCustomizeShowcase, isFalse);
      expect(pro.canUseAdvancedAnalytics, isFalse);
    });

    test('coupe les avantages quand la date de fin est passée', () {
      final expired = ProAccessState(
        userId: 'seller-5',
        tier: ProPlanTier.signature,
        status: 'active',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        limits: ProFeatureLimits.signature,
      );

      expect(expired.isActive, isFalse);
      expect(expired.hasBusinessPlan, isFalse);
      expect(expired.hasCertifiedBadge, isFalse);
      expect(expired.canBoost, isFalse);
    });

    test('refuse un plan actif sans date de fin', () {
      const state = ProAccessState(
        userId: 'seller-6',
        tier: ProPlanTier.pro,
        status: 'active',
        expiresAt: null,
        limits: ProFeatureLimits.pro,
      );

      expect(state.isActive, isFalse);
      expect(state.hasBusinessPlan, isFalse);
    });
  });
}
