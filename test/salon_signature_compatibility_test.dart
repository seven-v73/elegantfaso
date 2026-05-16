import 'package:elegantfaso/models/salon/salon_highlight.dart';
import 'package:elegantfaso/models/salon/salon_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'SalonHighlight traite signature et premium comme un même plan pro fort',
    () {
      final expiresAt = DateTime.now().add(const Duration(days: 30));
      final highlight = SalonHighlight(
        id: 'h1',
        type: SalonHighlightType.creation,
        title: 'Pièce signature',
        subtitle: 'Atelier certifié',
        imageUrl: '',
        actionLabel: 'Voir',
        searchText: 'piece signature',
        data: {
          'businessEntitlements': {
            'status': 'active',
            'plan': 'signature',
            'expiresAt': expiresAt,
          },
        },
      );

      expect(highlight.isSignature, isTrue);
      expect(highlight.isFeatured, isTrue);
      expect(highlight.isProListing, isTrue);
    },
  );

  test(
    'SalonItem garde la compatibilité avec les anciennes données premium',
    () {
      final expiresAt = DateTime.now().add(const Duration(days: 30));
      final item = SalonItem(
        id: 'i1',
        type: SalonItemType.product,
        title: 'Sac perlé',
        subtitle: 'Boutique certifiée',
        imageUrl: '',
        ownerId: 'seller-1',
        city: 'Ouagadougou',
        price: 15000,
        tags: const ['sac', 'perle'],
        actions: const [],
        data: {
          'businessEntitlements': {
            'status': 'active',
            'plan': 'premium',
            'expiresAt': expiresAt,
          },
        },
      );

      expect(item.isSignature, isTrue);
      expect(item.isFeatured, isTrue);
      expect(item.certificationLabel, 'Signature');
    },
  );
}
