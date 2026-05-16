import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/commerce/managed_payment.dart';

class SellerBalanceService {
  SellerBalanceService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<double> requestWithdrawal(String orderId) async {
    final sellerId = _auth.currentUser?.uid;
    if (sellerId == null || sellerId.isEmpty) {
      throw StateError('Connectez-vous pour demander un retrait.');
    }
    if (orderId.isEmpty) {
      throw ArgumentError.value(orderId, 'orderId', 'Commande introuvable.');
    }

    final orderRef = _firestore.collection('orders').doc(orderId);
    final requestRef = _firestore
        .collection('seller_withdrawal_requests')
        .doc(orderId);

    return _firestore.runTransaction<double>((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);
      if (!orderSnapshot.exists) {
        throw StateError('Commande introuvable.');
      }
      final orderData = orderSnapshot.data() ?? const <String, dynamic>{};
      if (!_isSeller(orderData, sellerId)) {
        throw StateError(
          'Vous ne pouvez pas retirer le solde de cette commande.',
        );
      }

      final balance = _map(orderData['sellerBalance']);
      final balanceStatus =
          orderData['sellerBalanceStatus']?.toString() ??
          balance['status']?.toString() ??
          '';
      if (balanceStatus == 'withdrawal_requested') {
        throw StateError('Une demande de retrait est déjà en cours.');
      }
      if (balanceStatus != 'available') {
        throw StateError(
          'Le retrait sera disponible après confirmation de réception client.',
        );
      }

      final available = _availableBalance(orderData, balance);
      if (available <= 0) {
        throw StateError('Aucun solde disponible pour cette commande.');
      }

      final currency =
          balance['currency']?.toString() ??
          orderData['currency']?.toString() ??
          'XOF';
      final now = FieldValue.serverTimestamp();
      final paymentReference = orderData['paymentReference']?.toString() ?? '';
      var sellerPaymentMethods = _stringMap(orderData['sellerPaymentMethods']);
      if (sellerPaymentMethods.isEmpty) {
        final sellerSnapshot = await transaction.get(
          _firestore.collection('users').doc(sellerId),
        );
        sellerPaymentMethods = _paymentMethodsFromUser(
          sellerSnapshot.data() ?? const <String, dynamic>{},
        );
      }
      if (sellerPaymentMethods.isEmpty) {
        throw StateError(
          'Ajoutez un moyen de retrait dans votre profil boutique.',
        );
      }

      transaction.set(requestRef, {
        'orderId': orderId,
        'sellerId': sellerId,
        'sellerName': orderData['sellerName']?.toString() ?? '',
        'sellerRole': orderData['sellerRole']?.toString() ?? '',
        'sellerPhone':
            orderData['sellerPaymentRouting'] is Map
                ? ((orderData['sellerPaymentRouting'] as Map)['sellerPhone']
                        ?.toString() ??
                    '')
                : '',
        'clientId':
            orderData['userId']?.toString() ??
            orderData['clientId']?.toString() ??
            '',
        'amount': available,
        'currency': currency,
        'paymentReference': paymentReference,
        'sellerPaymentMethods': sellerPaymentMethods,
        'preferredPayoutMethod':
            sellerPaymentMethods.isEmpty ? '' : sellerPaymentMethods.keys.first,
        'preferredPayoutAccount':
            sellerPaymentMethods.isEmpty
                ? ''
                : sellerPaymentMethods.values.first,
        'status': 'pending_admin_transfer',
        'requestType': 'managed_order_withdrawal',
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      transaction.set(orderRef, {
        ...SellerBalanceLedger.withdrawalRequested(
          sellerAmount: available,
          currency: currency,
          now: now,
        ),
        'paymentTimeline': FieldValue.arrayUnion([
          {
            'status': ManagedPaymentValues.statusId(
              ManagedPaymentStatus.withdrawalRequested,
            ),
            'label': 'Retrait demandé par le vendeur',
            'at': Timestamp.now(),
          },
        ]),
      }, SetOptions(merge: true));

      return available;
    });
  }

  static double _availableBalance(
    Map<String, dynamic> orderData,
    Map<String, dynamic> balance,
  ) {
    final available = (balance['availableBalance'] as num?)?.toDouble() ?? 0.0;
    if (available > 0) return available;

    final expected =
        (balance['expectedSellerAmount'] as num?)?.toDouble() ??
        (orderData['sellerPayout'] as num?)?.toDouble() ??
        0.0;
    return expected;
  }

  static bool _isSeller(Map<String, dynamic> orderData, String sellerId) {
    return orderData['sellerId']?.toString() == sellerId ||
        orderData['boutiqueId']?.toString() == sellerId ||
        orderData['creatorId']?.toString() == sellerId;
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    return value.map(
      (key, entry) => MapEntry(key.toString(), entry?.toString() ?? ''),
    )..removeWhere((key, entry) => key.trim().isEmpty || entry.trim().isEmpty);
  }

  static Map<String, String> _paymentMethodsFromUser(
    Map<String, dynamic> data,
  ) {
    final methods = <String, String>{
      ..._stringMap(data['paymentMethods']),
      ..._stringMap(_valueForPath(data, 'shopProfile.paymentMethods')),
      ..._stringMap(_valueForPath(data, 'creatorProfile.paymentMethods')),
    };
    return methods..removeWhere((key, value) => key.isEmpty || value.isEmpty);
  }

  static Object? _valueForPath(Map<String, dynamic> data, String path) {
    if (data.containsKey(path)) return data[path];
    Object? current = data;
    for (final segment in path.split('.')) {
      if (current is! Map) return null;
      current = current[segment];
    }
    return current;
  }
}
