import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elegantfaso/models/boutique/boutique_product.dart';

class BoutiqueProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<BoutiqueProduct>> getProducts(String boutiqueId) {
    return _firestore
        .collection('products')
        .where('boutiqueId', isEqualTo: boutiqueId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BoutiqueProduct.fromFirestore(doc))
        .toList());
  }

  Future<void> addProduct(BoutiqueProduct product) async {
    await _firestore.collection('products').add(product.toMap());
  }

  Future<void> updateProduct(BoutiqueProduct product) async {
    await _firestore.collection('products').doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }
}