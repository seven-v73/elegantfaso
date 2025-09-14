import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_item.dart';



class CartService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenir l'ID de l'utilisateur actuel
  static String? get currentUserId => _auth.currentUser?.uid;

  // Collection de référence du panier
  static CollectionReference get _cartCollection {
    if (currentUserId == null) throw Exception('Utilisateur non connecté');
    return _firestore.collection('users').doc(currentUserId).collection('cart');
  }

  // Stream des articles du panier
  static Stream<List<CartItem>> getCartItems() {
    if (currentUserId == null) return Stream.value([]);

    return _cartCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CartItem.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Ajouter un article au panier
  static Future<void> addToCart({
    required String productId,
    required String name,
    required String imageUrl,
    required double price,
    required String type,
    required String sellerId,
    required String sellerName,
    required String sellerImage,
    required Map<String, dynamic> metadata,
  }) async {
    if (currentUserId == null) throw Exception('Utilisateur non connecté');

    // Vérifier si l'utilisateur actuel n'est pas le vendeur
    if (sellerId == currentUserId) {
      throw Exception('Vous ne pouvez pas acheter votre propre produit');
    }

    try {
      // Vérifier si l'article existe déjà dans le panier
      final existingItem = await _cartCollection.doc(productId).get();

      if (existingItem.exists) {
        // Si l'article existe, augmenter la quantité
        final currentQuantity = existingItem.data() as Map<String, dynamic>;
        await _cartCollection.doc(productId).update({
          'quantity': (currentQuantity['quantity'] ?? 1) + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Sinon, ajouter un nouvel article
        final cartItem = CartItem(
          id: productId,
          productId: productId,
          name: name,
          imageUrl: imageUrl,
          price: price,
          quantity: 1,
          type: type,
          sellerId: sellerId,
          sellerName: sellerName,
          sellerImage: sellerImage,
          metadata: metadata,
        );

        await _cartCollection.doc(productId).set(cartItem.toMap());
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout au panier: $e');
    }
  }

  // Supprimer un article du panier
  static Future<void> removeFromCart(String productId) async {
    if (currentUserId == null) throw Exception('Utilisateur non connecté');

    try {
      await _cartCollection.doc(productId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  // Mettre à jour la quantité d'un article
  static Future<void> updateQuantity(String productId, int quantity) async {
    if (currentUserId == null) throw Exception('Utilisateur non connecté');

    try {
      if (quantity <= 0) {
        await removeFromCart(productId);
      } else {
        await _cartCollection.doc(productId).update({
          'quantity': quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  // Vider le panier
  static Future<void> clearCart() async {
    if (currentUserId == null) throw Exception('Utilisateur non connecté');

    try {
      final cartItems = await _cartCollection.get();
      for (final doc in cartItems.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Erreur lors du vidage du panier: $e');
    }
  }

  // Obtenir le nombre total d'articles dans le panier
  static Stream<int> getCartItemCount() {
    return getCartItems().map((items) {
      return items.fold(0, (sum, item) => sum + item.quantity);
    });
  }

  // Obtenir le total du panier
  static Stream<double> getCartTotal() {
    return getCartItems().map((items) {
      return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    });
  }

  // Vérifier si un produit peut être acheté par l'utilisateur actuel
  static bool canPurchaseProduct(String sellerId) {
    return currentUserId != null && sellerId != currentUserId;
  }

  // Vérifier si un produit est dans le panier
  static Future<bool> isInCart(String productId) async {
    if (currentUserId == null) return false;

    try {
      final doc = await _cartCollection.doc(productId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Obtenir un article spécifique du panier
  static Future<CartItem?> getCartItem(String productId) async {
    if (currentUserId == null) return null;

    try {
      final doc = await _cartCollection.doc(productId).get();
      if (doc.exists) {
        return CartItem.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
