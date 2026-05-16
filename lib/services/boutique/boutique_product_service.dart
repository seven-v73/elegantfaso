import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/boutique/shop_product.dart';

class BoutiqueProductService {
  BoutiqueProductService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<ShopProduct>> watchProducts(String boutiqueId) {
    if (boutiqueId.isEmpty) return Stream.value(const []);
    final byBoutique =
        _firestore
            .collection('products')
            .where('boutiqueId', isEqualTo: boutiqueId)
            .snapshots();
    final bySeller =
        _firestore
            .collection('products')
            .where('sellerId', isEqualTo: boutiqueId)
            .snapshots();

    return Rx.combineLatest2(byBoutique, bySeller, (
      QuerySnapshot<Map<String, dynamic>> boutiqueSnapshot,
      QuerySnapshot<Map<String, dynamic>> sellerSnapshot,
    ) {
      final docs =
          {
            for (final doc in boutiqueSnapshot.docs) doc.id: doc,
            for (final doc in sellerSnapshot.docs) doc.id: doc,
          }.values;
      final products =
          docs
              .where((doc) {
                final data = doc.data();
                final status = data['status']?.toString() ?? '';
                return status != 'archived' &&
                    status != 'deleted' &&
                    data['deletedAt'] == null;
              })
              .map(ShopProduct.fromDoc)
              .toList();
      products.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return products;
    });
  }

  Future<void> updateStatus(String productId, String status) {
    return _firestore.collection('products').doc(productId).set({
      'status': status,
      'visibility': status == 'hidden' ? 'private' : 'salon',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteProduct(String productId) {
    return _firestore.collection('products').doc(productId).set({
      'status': 'archived',
      'visibility': 'private',
      'archivedAt': FieldValue.serverTimestamp(),
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> restoreProduct(ShopProduct product) {
    return _firestore.collection('products').doc(product.id).set({
      ...product.raw,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> duplicateProduct(ShopProduct product) {
    return _firestore.collection('products').add({
      ...product.raw,
      'name': '${product.name} copie',
      'status': 'draft',
      'visibility': 'private',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
