import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegantfaso/models/global/cart_item.dart';
import 'package:elegantfaso/services/commerce/stock_inventory_service.dart';
import 'package:elegantfaso/services/global/cart_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sépare le panier par fournisseur pour finaliser individuellement', () {
    final boutiqueItem = _item(
      id: 'cart-boutique',
      productId: 'robe-1',
      sellerId: 'boutique-1',
      role: 'boutique',
      currency: 'XOF',
    );
    final creationItem = _item(
      id: 'cart-creation',
      productId: 'creation-1',
      sellerId: 'createur-1',
      role: 'createur',
      currency: 'EUR',
    );

    final grouped = CartService.groupItemsByVendor([
      boutiqueItem,
      creationItem,
    ]);

    expect(grouped, hasLength(2));
    expect(grouped[boutiqueItem.vendorKey], [boutiqueItem]);
    expect(grouped[creationItem.vendorKey], [creationItem]);
  });

  test('refuse une finalisation qui mélange plusieurs fournisseurs', () {
    final items = [
      _item(sellerId: 'boutique-1', role: 'boutique'),
      _item(sellerId: 'createur-1', role: 'createur'),
    ];

    expect(
      () => CartService.validateSingleVendorCart(items),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('plusieurs fournisseurs'),
        ),
      ),
    );
  });

  test('refuse une commande fournisseur avec plusieurs devises', () {
    final items = [
      _item(id: 'xof', sellerId: 'boutique-1', currency: 'XOF'),
      _item(id: 'eur', sellerId: 'boutique-1', currency: 'EUR'),
    ];

    expect(
      () => CartService.currencyForOrder(items),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('plusieurs devises'),
        ),
      ),
    );
  });

  test('normalise la devise de commande et la conserve dans les lignes', () {
    final item = _item(currency: 'fcfa');

    expect(CartService.currencyForOrder([item]), 'XOF');

    final orderLine = item.toOrderMap();
    expect(orderLine['sellerRole'], 'boutique');
    expect(orderLine['currency'], 'fcfa');
    expect(orderLine['metadata'], containsPair('currency', 'fcfa'));
  });

  test('prépare une timeline commande sans sentinel dans un tableau', () {
    final at = Timestamp.fromDate(DateTime(2026, 5, 4, 12));
    final entry = CartService.initialPaymentTimelineEntry(at: at);

    expect(entry['status'], 'client_marked_paid');
    expect(entry['label'], 'Client marqué payé');
    expect(entry['at'], isA<Timestamp>());
    expect(entry['at'], at);
    expect(entry.values.any((value) => value is FieldValue), isFalse);
  });

  test(
    'reconstruit un ancien article panier avec devise et rôle top-level',
    () {
      final item = CartItem.fromMap('legacy-cart', {
        'productId': 'sac-1',
        'name': 'Sac perlé',
        'imageUrl': '',
        'price': 15000,
        'quantity': 1,
        'sellerId': 'createur-7',
        'sellerName': 'Atelier Kadi',
        'sellerImage': '',
        'sellerRole': 'createur',
        'currency': 'EUR',
        'metadata': <String, dynamic>{},
        'addedAt': Timestamp.now(),
      });

      expect(item.sellerRole, 'createur');
      expect(item.currency, 'EUR');
      expect(item.metadata['role'], 'createur');
      expect(item.metadata['currency'], 'EUR');
    },
  );

  test('prépare une décrémentation stock par produit et création', () {
    final entries = StockInventoryService.previewEntries([
      _item(productId: 'p1', role: 'boutique').toOrderMap(),
      _item(
        productId: 'c1',
        role: 'createur',
      ).copyWith(quantity: 2).toOrderMap(),
      _item(productId: 'c1', role: 'createur').toOrderMap(),
    ]);

    expect(entries, hasLength(2));
    expect(
      entries.map((entry) => entry.toMap()),
      containsAll([
        {'collection': 'products', 'id': 'p1', 'quantity': 1},
        {'collection': 'creations', 'id': 'c1', 'quantity': 3},
      ]),
    );
  });

  test('relit les lignes de stock réservées pour livraison finale', () {
    final entries = StockInventoryService.previewEntries([
      {'collection': 'products', 'id': 'p1', 'quantity': 2},
      {'collection': 'creations', 'id': 'c1', 'quantity': 1},
      {'collection': 'products', 'id': 'p1', 'quantity': 1},
    ]);

    expect(entries, hasLength(2));
    expect(
      entries.map((entry) => entry.toMap()),
      containsAll([
        {'collection': 'products', 'id': 'p1', 'quantity': 3},
        {'collection': 'creations', 'id': 'c1', 'quantity': 1},
      ]),
    );
  });

  test('préserve taille et couleur dans les réservations stock', () {
    final entries = StockInventoryService.previewEntries([
      _item(productId: 'p1', role: 'boutique')
          .copyWith(
            metadata: {'role': 'boutique', 'size': 'M', 'color': 'Noir'},
          )
          .toOrderMap(),
      _item(productId: 'p1', role: 'boutique')
          .copyWith(
            quantity: 2,
            metadata: {'role': 'boutique', 'size': 'M', 'color': 'Noir'},
          )
          .toOrderMap(),
      _item(productId: 'p1', role: 'boutique')
          .copyWith(
            metadata: {'role': 'boutique', 'size': 'L', 'color': 'Noir'},
          )
          .toOrderMap(),
    ]);

    expect(entries, hasLength(2));
    expect(
      entries.map((entry) => entry.toMap()),
      containsAll([
        {
          'collection': 'products',
          'id': 'p1',
          'quantity': 3,
          'size': 'M',
          'color': 'Noir',
          'variantKey': 'm|noir',
        },
        {
          'collection': 'products',
          'id': 'p1',
          'quantity': 1,
          'size': 'L',
          'color': 'Noir',
          'variantKey': 'l|noir',
        },
      ]),
    );
  });
}

CartItem _item({
  String id = 'cart-1',
  String productId = 'product-1',
  String sellerId = 'boutique-1',
  String role = 'boutique',
  String currency = 'XOF',
}) {
  return CartItem(
    id: id,
    productId: productId,
    name: 'Article test',
    imageUrl: '',
    price: 12000,
    quantity: 1,
    sellerId: sellerId,
    sellerName: 'Vendeur test',
    sellerImage: '',
    metadata: {'role': role, 'currency': currency},
    addedAt: Timestamp.now(),
  );
}
