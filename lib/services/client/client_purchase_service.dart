import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/commerce/product_review.dart';
import '../../models/commerce/purchase_history_item.dart';
import '../../models/commerce/managed_payment.dart';
import '../../models/global/cart_item.dart';
import '../../models/wardrobe/wardrobe_item.dart';
import '../commerce/stock_inventory_service.dart';
import '../wardrobe/wardrobe_service.dart';

class ClientPurchaseService {
  ClientPurchaseService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    WardrobeService? wardrobeService,
    StockInventoryService? stockInventoryService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _wardrobeService = wardrobeService ?? WardrobeService(),
       _stockInventoryService =
           stockInventoryService ?? StockInventoryService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final WardrobeService _wardrobeService;
  final StockInventoryService _stockInventoryService;

  CollectionReference<Map<String, dynamic>> _historyRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('purchase_history');
  }

  Stream<List<PurchaseHistoryItem>> watchHistory(String userId) {
    return _historyRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(PurchaseHistoryItem.fromDoc).toList(),
        );
  }

  Future<void> recordCheckout({
    required String userId,
    required String orderId,
    required List<CartItem> items,
    required String recipientType,
    String recipientName = '',
    String paymentReference = '',
  }) async {
    for (final item in items) {
      final category = _categoryFor(item);

      final historyDoc = _historyRef(userId).doc('${orderId}_${item.id}');
      await historyDoc.set({
        'orderId': orderId,
        'productId': item.productId,
        'productName': item.name,
        'productImageUrl': item.imageUrl,
        'category': category,
        'price': item.price,
        'currency': item.currency,
        'quantity': item.quantity,
        'sellerId': item.sellerId,
        'sellerName': item.sellerName,
        'recipientType': recipientType,
        'recipientName': recipientName,
        'wardrobeItemId': '',
        'status': 'client_marked_paid',
        'paymentReference': paymentReference,
        'canReview': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> confirmReceipt(PurchaseHistoryItem item) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Connectez-vous pour confirmer la réception.');
    }
    if (item.orderId.isEmpty) {
      throw StateError('Commande introuvable.');
    }

    final orderRef = _firestore.collection('orders').doc(item.orderId);
    final orderDoc = await orderRef.get();
    final orderData = orderDoc.data();
    if (!orderDoc.exists || orderData == null) {
      throw StateError('Commande introuvable.');
    }
    if (orderData['userId']?.toString() != user.uid) {
      throw StateError('Cette commande ne vous appartient pas.');
    }
    if (!ManagedPaymentValues.paymentIsConfirmed(
      orderData['paymentStatus']?.toString() ?? '',
    )) {
      throw StateError(
        'Le paiement doit être confirmé par l’admin avant la réception.',
      );
    }
    final status = orderData['status']?.toString() ?? '';
    if (!ManagedPaymentValues.clientCanConfirmReceipt(status)) {
      throw StateError(
        'Attendez que le vendeur marque la commande prête ou livrée.',
      );
    }

    await _stockInventoryService.deductForDeliveredOrder(item.orderId);

    final refreshedOrderDoc = await orderRef.get();
    final refreshedOrderData = refreshedOrderDoc.data() ?? orderData;
    final sellerAmount =
        (refreshedOrderData['sellerPayout'] as num?)?.toDouble() ??
        (refreshedOrderData['sellerBalance'] is Map
            ? ((refreshedOrderData['sellerBalance']['expectedSellerAmount']
                        as num?)
                    ?.toDouble() ??
                0)
            : 0);
    final currency =
        refreshedOrderData['currency']?.toString() ?? item.currency;
    final historySnapshot =
        await _historyRef(
          user.uid,
        ).where('orderId', isEqualTo: item.orderId).get();

    final wardrobeIds = <String, String>{};
    for (final doc in historySnapshot.docs) {
      final purchase = PurchaseHistoryItem.fromDoc(doc);
      if (purchase.isForSelf && purchase.wardrobeItemId.isEmpty) {
        final wardrobeItem = WardrobeItem(
          id: '',
          userId: user.uid,
          name: purchase.productName,
          category: purchase.category,
          brand: purchase.sellerName,
          occasion: _occasionFor(purchase.category),
          season: 'Toutes saisons',
          description:
              'Reçu depuis le Salon ElegantFaso. Commande ${purchase.orderId}.',
          images:
              purchase.productImageUrl.isEmpty
                  ? const []
                  : [purchase.productImageUrl],
          media: [
            if (purchase.productImageUrl.isNotEmpty)
              {
                'url': purchase.productImageUrl,
                'optimizedUrl': purchase.productImageUrl,
                'usage': 'purchase',
              },
          ],
        );
        wardrobeIds[doc.id] = await _wardrobeService.addItem(wardrobeItem);
      }
    }

    final batch = _firestore.batch();
    batch.set(orderRef, {
      ...SellerBalanceLedger.afterCustomerReceived(
        sellerAmount: sellerAmount,
        currency: currency,
      ),
      'status': 'received_by_customer',
      'orderStatus': 'received_by_customer',
      'paymentTimeline': FieldValue.arrayUnion([
        {
          'status': ManagedPaymentValues.statusId(
            ManagedPaymentStatus.receivedByCustomer,
          ),
          'label': 'Réception confirmée par le client',
          'at': Timestamp.now(),
        },
      ]),
    }, SetOptions(merge: true));
    for (final doc in historySnapshot.docs) {
      batch.set(doc.reference, {
        'status': 'received_by_customer',
        'canReview': true,
        if (wardrobeIds.containsKey(doc.id))
          'wardrobeItemId': wardrobeIds[doc.id],
        'receivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> submitReview({
    required PurchaseHistoryItem item,
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Connectez-vous pour laisser un avis.');
    final reviewId = '${user.uid}_${item.productId}_${item.orderId}';
    final review = ProductReview(
      id: reviewId,
      productId: item.productId,
      userId: user.uid,
      userName:
          user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Client ElegantFaso',
      rating: rating,
      comment: comment,
      productName: item.productName,
      productImageUrl: item.productImageUrl,
      sellerId: item.sellerId,
      sellerName: item.sellerName,
      orderId: item.orderId,
    );

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('product_reviews').doc(reviewId),
      review.toFirestore(),
      SetOptions(merge: true),
    );
    batch.set(_historyRef(user.uid).doc(item.id), {
      'reviewId': reviewId,
      'reviewRating': rating.clamp(1, 5),
      'reviewComment': comment.trim(),
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  static String _categoryFor(CartItem item) {
    final raw =
        [
          item.metadata['category'],
          item.metadata['type'],
          item.name,
        ].whereType<Object>().join(' ').toLowerCase();
    if (raw.contains('chauss')) return 'Chaussures';
    if (raw.contains('sac')) return 'Sacs';
    if (raw.contains('bijou') || raw.contains('collier')) return 'Bijoux';
    if (raw.contains('accessoire')) return 'Accessoires';
    if (raw.contains('robe') ||
        raw.contains('tenue') ||
        raw.contains('habit')) {
      return 'Tenues';
    }
    if (raw.contains('coiff')) return 'Coiffures';
    return 'Autre';
  }

  static String _occasionFor(String category) {
    return switch (category) {
      'Tenues' => 'Quotidien',
      'Chaussures' => 'Sortie',
      'Sacs' || 'Bijoux' || 'Accessoires' => 'Accessoires',
      _ => 'Polyvalent',
    };
  }
}
