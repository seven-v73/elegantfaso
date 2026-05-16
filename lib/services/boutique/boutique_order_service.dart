import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/boutique/shop_order.dart';
import '../../models/commerce/managed_payment.dart';
import '../commerce/stock_inventory_service.dart';

class BoutiqueOrderService {
  BoutiqueOrderService({
    FirebaseFirestore? firestore,
    StockInventoryService? stockInventoryService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _stockInventoryService =
           stockInventoryService ?? StockInventoryService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final StockInventoryService _stockInventoryService;

  Stream<List<ShopOrder>> watchOrders(String boutiqueId) {
    if (boutiqueId.isEmpty) return Stream.value(const []);
    final bySeller =
        _firestore
            .collection('orders')
            .where('sellerId', isEqualTo: boutiqueId)
            .limit(120)
            .snapshots();
    final byBoutique =
        _firestore
            .collection('orders')
            .where('boutiqueId', isEqualTo: boutiqueId)
            .limit(120)
            .snapshots();

    return Rx.combineLatest2(bySeller, byBoutique, (
      QuerySnapshot<Map<String, dynamic>> sellerSnapshot,
      QuerySnapshot<Map<String, dynamic>> boutiqueSnapshot,
    ) {
      final docs =
          {
            for (final doc in sellerSnapshot.docs) doc.id: doc,
            for (final doc in boutiqueSnapshot.docs) doc.id: doc,
          }.values;
      final orders = docs.map(ShopOrder.fromDoc).toList();
      orders.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return orders;
    });
  }

  Future<void> updateStatus(String orderId, String status) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    final snapshot = await orderRef.get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    if (ManagedPaymentValues.sellerCanProgressOrder(status) &&
        !ManagedPaymentValues.paymentIsConfirmed(
          data['paymentStatus']?.toString() ?? '',
        )) {
      throw StateError(
        'Le paiement doit être confirmé par l’admin avant de traiter cette commande.',
      );
    }

    final patch = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    var timelineStatus = status;
    var timelineLabel = ManagedPaymentCopy.orderStatusLabel(status);
    if (status == 'processing' || status == 'preparing') {
      timelineStatus = ManagedPaymentValues.statusId(
        ManagedPaymentStatus.preparing,
      );
      timelineLabel = 'Préparation démarrée par le vendeur';
      patch['managedPaymentStatus'] = timelineStatus;
    }
    if (status == 'ready') {
      timelineStatus = ManagedPaymentValues.statusId(
        ManagedPaymentStatus.readyOrShipped,
      );
      timelineLabel = 'Commande prête ou envoyée';
      patch['managedPaymentStatus'] = timelineStatus;
      patch['readyAt'] = FieldValue.serverTimestamp();
    }
    if (status == 'delivered') {
      timelineStatus = ManagedPaymentValues.statusId(
        ManagedPaymentStatus.deliveredBySeller,
      );
      timelineLabel = 'Livraison déclarée par le vendeur';
      patch['managedPaymentStatus'] = timelineStatus;
      patch['deliveredBySellerAt'] = FieldValue.serverTimestamp();
    }
    patch['paymentTimeline'] = FieldValue.arrayUnion([
      {'status': timelineStatus, 'label': timelineLabel, 'at': Timestamp.now()},
    ]);
    await orderRef.set(patch, SetOptions(merge: true));
    if (status == 'delivered') {
      await _stockInventoryService.deductForDeliveredOrder(orderId);
    } else if (status == 'cancelled') {
      await _stockInventoryService.releaseReservedOrder(orderId);
    }
  }

  Future<void> cancel(String orderId) => updateStatus(orderId, 'cancelled');
}
