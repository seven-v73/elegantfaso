import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/commerce/platform_revenue.dart';
import '../../models/commerce/managed_payment.dart';
import '../../models/global/cart_item.dart';
import '../commerce/commerce_revenue_service.dart';
import '../preferences/currency_service.dart';

class CartService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? get userId => _auth.currentUser?.uid;
  static bool get isSignedIn => userId != null;

  static CollectionReference<Map<String, dynamic>>? get _cartRef {
    final id = userId;
    if (id == null) return null;
    return _firestore.collection('users').doc(id).collection('cart');
  }

  static Stream<List<CartItem>> getCartStream() {
    final ref = _cartRef;
    if (ref == null) return Stream.value([]);

    return ref.orderBy('addedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CartItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  static Future<void> addToCart(CartItem item) async {
    final ref = _cartRef;
    if (ref == null) throw StateError('Utilisateur non connecté');

    final docId = item.variantKey;
    final docRef = ref.doc(docId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        final current = (snapshot.data()?['quantity'] as num?)?.toInt() ?? 1;
        final nextQuantity = (current + item.quantity).clamp(
          1,
          item.stockLimit,
        );
        transaction.update(docRef, {
          'quantity': nextQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(docRef, {
          ...item
              .copyWith(
                id: docId,
                quantity: item.quantity.clamp(1, item.stockLimit),
              )
              .toMap(),
          'addedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  static Future<void> restoreItem(CartItem item) async {
    final ref = _cartRef;
    if (ref == null) throw StateError('Utilisateur non connecté');
    await ref.doc(item.id).set({
      ...item.toMap(),
      'restoredAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateQuantity(String itemId, int quantity) async {
    final ref = _cartRef;
    if (ref == null) throw StateError('Utilisateur non connecté');

    if (quantity <= 0) {
      await removeFromCart(itemId);
      return;
    }

    final doc = await ref.doc(itemId).get();
    final item = doc.exists ? CartItem.fromMap(doc.id, doc.data()!) : null;
    final safeQuantity =
        item == null
            ? quantity.clamp(1, 99)
            : quantity.clamp(1, item.stockLimit);

    await ref.doc(itemId).update({
      'quantity': safeQuantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeFromCart(String itemId) async {
    final ref = _cartRef;
    if (ref == null) throw StateError('Utilisateur non connecté');
    await ref.doc(itemId).delete();
  }

  static Future<void> clearCart({Iterable<String>? itemIds}) async {
    final ref = _cartRef;
    if (ref == null) throw StateError('Utilisateur non connecté');

    final batch = _firestore.batch();
    if (itemIds == null) {
      final cartItems = await ref.get();
      for (final doc in cartItems.docs) {
        batch.delete(doc.reference);
      }
    } else {
      for (final id in itemIds) {
        batch.delete(ref.doc(id));
      }
    }
    await batch.commit();
  }

  static Future<String> createOrder({
    required List<CartItem> items,
    required Vendor vendor,
    required String paymentMethod,
    required String customerPhone,
    required String proofImageUrl,
    required CartTotals totals,
    String paymentReference = '',
    Map<String, dynamic>? proofMedia,
    Map<String, String> platformPaymentMethods = const {},
    Map<String, String> sellerPaymentMethods = const {},
    String selectedPaymentAccount = '',
    String deliveryAddress = '',
    String deliveryMode = 'Livraison',
    String sellerNote = '',
    String recipientType = 'self',
    String recipientName = '',
    String recipientNote = '',
  }) async {
    final id = userId;
    if (id == null) throw StateError('Utilisateur non connecté');
    validateSingleVendorCart(items);
    final currency = currencyForOrder(items);
    final reference =
        paymentReference.trim().isEmpty
            ? generatePaymentReference()
            : paymentReference.trim().toUpperCase();
    final managedSellerPayout =
        (totals.grandTotal - totals.serviceFee)
            .clamp(0, double.infinity)
            .toDouble();

    final orderRef = _firestore.collection('orders').doc();
    await orderRef.set({
      'userId': id,
      'sellerId': vendor.id,
      'sellerName': vendor.name,
      'sellerRole': vendor.role,
      'items': items.map((item) => item.toOrderMap()).toList(),
      'total': totals.grandTotal,
      'currency': currency,
      'totals': totals.toMap(),
      ...DeliveryQuoteLedger.initial(
        deliveryMode: deliveryMode,
        amount: totals.deliveryFee,
        currency: currency,
        addressOrInstruction: deliveryAddress,
        note: sellerNote,
      ),
      'platformCommission': 0,
      'sellerPayout': managedSellerPayout,
      'commissionRatePercent': 0,
      'managedPayment': {
        'commissionWaived': true,
        'serviceFee': totals.serviceFee,
        'legacyCommissionEstimate': totals.platformCommission,
      },
      'paymentMethod': paymentMethod,
      'paymentAccount': selectedPaymentAccount,
      'paymentReference': reference,
      'paymentFlow': ManagedPaymentValues.paymentFlow,
      'paymentRecipient': ManagedPaymentValues.paymentRecipient,
      'platformPaymentMethods': platformPaymentMethods,
      'sellerPaymentMethods':
          sellerPaymentMethods.isNotEmpty
              ? sellerPaymentMethods
              : vendor.paymentMethods,
      'sellerPaymentRouting': {
        'sellerId': vendor.id,
        'sellerName': vendor.name,
        'sellerRole': vendor.role,
        'sellerPhone': vendor.phone,
        'clientPaidTo':
            platformPaymentMethods.isNotEmpty ? 'platform_admin' : 'seller',
        'selectedPaymentMethod': paymentMethod,
        'selectedPaymentAccount': selectedPaymentAccount,
        'sellerMethodsForPayout':
            sellerPaymentMethods.isNotEmpty
                ? sellerPaymentMethods
                : vendor.paymentMethods,
      },
      'managedPaymentStatus': ManagedPaymentValues.statusId(
        ManagedPaymentStatus.clientMarkedPaid,
      ),
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'deliveryMode': deliveryMode,
      'sellerNote': sellerNote,
      'recipientType': recipientType,
      'recipientName': recipientName,
      'recipientNote': recipientNote,
      'proofImageUrl': proofImageUrl,
      if (proofMedia != null) 'paymentProofMedia': proofMedia,
      'paymentStatus': 'client_marked_paid',
      'sellerBalanceStatus': ManagedPaymentValues.balanceStatusId(
        SellerBalanceStatus.notFunded,
      ),
      'sellerBalance': SellerBalanceLedger.initial(
        sellerAmount: managedSellerPayout,
        currency: currency,
      ),
      ...InventoryFlowLedger.awaitingPayment(),
      'status': 'awaiting_admin_payment_confirmation',
      'paymentTimeline': [initialPaymentTimelineEntry()],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await clearCart(itemIds: items.map((item) => item.id));
    return orderRef.id;
  }

  static Map<String, dynamic> initialPaymentTimelineEntry({Timestamp? at}) {
    return {
      'status': ManagedPaymentValues.statusId(
        ManagedPaymentStatus.clientMarkedPaid,
      ),
      'label': 'Client marqué payé',
      'at': at ?? Timestamp.now(),
    };
  }

  static String generatePaymentReference({
    DateTime? now,
    String prefix = 'EF',
  }) {
    final value = now ?? DateTime.now();
    final date =
        '${value.year}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';
    final time =
        '${value.hour.toString().padLeft(2, '0')}${value.minute.toString().padLeft(2, '0')}${value.second.toString().padLeft(2, '0')}';
    final suffix = value.millisecond.toString().padLeft(3, '0');
    return '$prefix-$date-$time$suffix';
  }

  static Map<String, List<CartItem>> groupItemsByVendor(List<CartItem> items) {
    final grouped = <String, List<CartItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.vendorKey, () => []).add(item);
    }
    return grouped;
  }

  static void validateSingleVendorCart(List<CartItem> items) {
    if (items.isEmpty) throw StateError('Aucun article à commander');

    final vendorKeys = items.map((item) => item.vendorKey).toSet();
    if (vendorKeys.length > 1) {
      throw StateError(
        'Cette commande contient plusieurs fournisseurs. Finalisez chaque fournisseur séparément.',
      );
    }

    currencyForOrder(items);
  }

  static String currencyForOrder(List<CartItem> items) {
    if (items.isEmpty) throw StateError('Aucun article à commander');

    final currencies =
        items
            .map((item) => CurrencyService.normalize(item.currency))
            .where((currency) => currency.isNotEmpty)
            .toSet();
    if (currencies.length > 1) {
      throw StateError(
        'Cette commande contient plusieurs devises. Finalisez chaque devise séparément.',
      );
    }
    return currencies.isEmpty ? CurrencyService.defaultCode : currencies.first;
  }

  static double calculateSubtotal(List<CartItem> items) {
    return items.fold(0, (total, item) => total + item.price * item.quantity);
  }

  static CartTotals calculateTotals(
    List<CartItem> items, {
    String couponCode = '',
    double couponDiscountAmount = 0,
    double commissionRatePercent = 8,
    CommerceRevenueConfig? revenueConfig,
    double? deliveryFeeOverride,
  }) {
    final subtotal = calculateSubtotal(items);
    final config = revenueConfig ?? CommerceRevenueService.fallbackConfig;
    final deliveryFee =
        deliveryFeeOverride != null
            ? deliveryFeeOverride.clamp(0, double.infinity).toDouble()
            : subtotal >= config.freeDeliveryThreshold || subtotal == 0
            ? 0.0
            : config.baseDeliveryFee;
    final serviceFee =
        subtotal == 0
            ? 0.0
            : (subtotal * config.serviceFeeRatePercent / 100).roundToDouble();
    final normalizedCoupon = couponCode.trim().toUpperCase();
    final couponDiscount = couponDiscountAmount.clamp(0, subtotal).toDouble();
    final discount = couponDiscount.clamp(0, subtotal).toDouble();
    final netMerchandise = (subtotal - discount).clamp(0, double.infinity);
    final platformCommission =
        (netMerchandise * commissionRatePercent.clamp(0, 30) / 100 + serviceFee)
            .roundToDouble();
    final grandTotal =
        (subtotal + deliveryFee + serviceFee - discount)
            .clamp(0, double.infinity)
            .toDouble();
    final sellerPayout =
        (grandTotal - platformCommission).clamp(0, double.infinity).toDouble();
    return CartTotals(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      discount: discount,
      couponCode: normalizedCoupon,
      couponDiscount: couponDiscount,
      commissionRatePercent: commissionRatePercent.clamp(0, 30).toDouble(),
      platformCommission: platformCommission,
      sellerPayout: sellerPayout,
    );
  }

  static int getTotalItemCount(List<CartItem> items) {
    return items.fold(0, (total, item) => total + item.quantity);
  }
}
