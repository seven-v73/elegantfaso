import 'package:elegantfaso/models/secondhand/secondhand_listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'prépare une annonce vide-dressing avec devise et visibilité client',
    () {
      const listing = SecondhandListing(
        id: 'listing-1',
        title: 'Sac cérémonie',
        description: 'Porté une fois, très propre',
        category: 'Accessoires',
        condition: 'Très bon état',
        price: 18000,
        currency: 'XOF',
        city: 'Abidjan',
        sellerId: 'client-1',
        sellerName: 'Awa',
        sellerPhotoUrl: '',
        imageUrls: ['https://example.com/sac.jpg'],
        status: 'available',
        likedBy: [],
        visibilityTierId: 'curator',
        visibilityLabel: 'Curateur style',
        visibilityCategory: 'Visibilité renforcée',
        visibilityBoost: 1.4,
        recommendationWeight: 24,
        color: 'Doré',
      );

      final data = listing.toFirestore();

      expect(data['currency'], 'XOF');
      expect(data['sellerId'], 'client-1');
      expect(data['status'], 'available');
      expect(data['visibilityTierId'], 'curator');
      expect(data['visibilityBoost'], 1.4);
      expect(data['recommendationWeight'], 24);
      expect(data['searchText'], contains('sac cérémonie'));
      expect(data['searchText'], contains('abidjan'));
      expect(data['searchText'], contains('doré'));
    },
  );

  test('conserve les transitions douces disponible réservé vendu', () {
    const listing = SecondhandListing(
      id: 'listing-1',
      title: 'Foulard',
      description: 'Soie légère',
      category: 'Accessoires',
      condition: 'Bon état',
      price: 5000,
      currency: 'XOF',
      city: 'Ouaga',
      sellerId: 'client-1',
      sellerName: 'Client ElegantFaso',
      sellerPhotoUrl: '',
      imageUrls: [],
      status: 'available',
      likedBy: [],
    );

    final reserved = listing.copyWith(
      status: 'reserved',
      reservedBy: 'client-2',
    );
    final sold = reserved.copyWith(status: 'sold');

    expect(listing.isAvailable, isTrue);
    expect(reserved.isReserved, isTrue);
    expect(reserved.reservedBy, 'client-2');
    expect(sold.isSold, isTrue);
    expect(sold.statusLabel, 'Vendu');
  });

  test('prépare le choix retrait ou points Style après une vente', () {
    const listing = SecondhandListing(
      id: 'listing-2',
      title: 'Sac perlé',
      description: 'Vente finalisée',
      category: 'Sacs',
      condition: 'Très bon état',
      price: 18000,
      currency: 'XOF',
      city: 'Abidjan',
      sellerId: 'client-1',
      sellerName: 'Awa',
      sellerPhotoUrl: '',
      imageUrls: [],
      status: 'sold',
      likedBy: [],
      secondhandBalanceStatus: 'available',
      secondhandAvailableBalance: 18000,
    );

    expect(listing.hasSettlementAvailable, isTrue);
    expect(
      SecondhandSettlementPolicy.stylePointsFor(
        amount: listing.secondhandAvailableBalance,
        currency: listing.currency,
      ),
      180,
    );

    final converted = listing.copyWith(
      secondhandBalanceStatus: 'converted_to_style_points',
      secondhandAvailableBalance: 0,
      secondhandConvertedBalance: 18000,
      stylePointsAwarded: 180,
      settlementChoice: 'style_points',
    );

    expect(converted.hasSettlementAvailable, isFalse);
    expect(converted.isConvertedToStylePoints, isTrue);
    expect(converted.stylePointsAwarded, 180);

    final withdrawn = listing.copyWith(
      secondhandBalanceStatus: 'withdrawn',
      secondhandAvailableBalance: 0,
      secondhandWithdrawnBalance: 18000,
      settlementChoice: 'withdrawal',
    );
    expect(withdrawn.isWithdrawn, isTrue);
    expect(withdrawn.hasSettlementHistory, isTrue);

    final disputed = listing.copyWith(secondhandBalanceStatus: 'disputed');
    expect(disputed.isDisputed, isTrue);
  });
}
