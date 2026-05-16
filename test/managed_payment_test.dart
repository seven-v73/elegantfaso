import 'package:elegantfaso/models/commerce/managed_payment.dart';
import 'package:elegantfaso/models/commerce/platform_revenue.dart';
import 'package:elegantfaso/models/boutique/shop_order.dart';
import 'package:elegantfaso/services/global/cart_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'définit les avances maximales selon le niveau de confiance vendeur',
    () {
      expect(
        SellerAdvancePolicy.maxAdvancePercent(SellerTrustTier.newSeller),
        0,
      );
      expect(
        SellerAdvancePolicy.maxAdvancePercent(SellerTrustTier.verified),
        30,
      );
      expect(
        SellerAdvancePolicy.maxAdvancePercent(
          SellerTrustTier.signatureReliable,
        ),
        50,
      );
      expect(
        SellerAdvancePolicy.maxAdvanceAmount(
          sellerAmount: 20000,
          tier: SellerTrustTier.verified,
        ),
        6000,
      );
    },
  );

  test('déplace le solde vendeur de en attente vers disponible', () {
    final pending = SellerBalanceLedger.afterAdminPaymentConfirmed(
      sellerAmount: 18500,
      currency: 'XOF',
      now: 'now',
    );
    final pendingBalance = pending['sellerBalance'] as Map<String, dynamic>;

    expect(pending['managedPaymentStatus'], 'payment_confirmed_by_admin');
    expect(pending['sellerBalanceStatus'], 'pending_delivery');
    expect(pendingBalance['pendingBalance'], 18500);
    expect(pendingBalance['availableBalance'], 0);

    final available = SellerBalanceLedger.afterCustomerReceived(
      sellerAmount: 18500,
      currency: 'XOF',
      now: 'later',
    );
    final availableBalance = available['sellerBalance'] as Map<String, dynamic>;

    expect(available['managedPaymentStatus'], 'withdrawal_available');
    expect(available['sellerBalanceStatus'], 'available');
    expect(availableBalance['pendingBalance'], 0);
    expect(availableBalance['availableBalance'], 18500);
  });

  test('rend le solde vendeur perceptible dès la commande créée', () {
    final order = ShopOrder.fromMap(
      id: 'order_1',
      data: {
        'clientName': 'Client',
        'status': 'awaiting_admin_payment_confirmation',
        'paymentStatus': 'client_marked_paid',
        'total': 20000,
        'currency': 'XOF',
        'sellerPayout': 18500,
        'sellerBalanceStatus': 'not_funded',
        'sellerBalance': {
          'pendingBalance': 0,
          'availableBalance': 0,
          'expectedSellerAmount': 18500,
          'status': 'not_funded',
        },
      },
    );

    expect(order.hasSellerBalanceInfo, isTrue);
    expect(order.visibleSellerBalanceLabel, 'Solde attendu');
    expect(order.visibleSellerBalance, 18500);
  });

  test(
    'récupère le solde vendeur des anciennes commandes après validation',
    () {
      final order = ShopOrder.fromMap(
        id: 'order_legacy',
        data: {
          'clientName': 'Client',
          'status': 'pending_seller_confirmation',
          'paymentStatus': 'paid',
          'total': 20000,
          'currency': 'XOF',
          'sellerPayout': 18500,
          'sellerBalanceStatus': 'pending_delivery',
        },
      );

      expect(order.sellerPendingBalance, 18500);
      expect(
        order.visibleSellerBalanceLabel,
        'Disponible après réception client',
      );
      expect(order.visibleSellerBalance, 18500);
    },
  );

  test('trace une demande de retrait puis un retrait payé', () {
    final requested = SellerBalanceLedger.withdrawalRequested(
      sellerAmount: 18500,
      currency: 'XOF',
      now: 'requested',
    );
    final requestedBalance = requested['sellerBalance'] as Map<String, dynamic>;

    expect(requested['managedPaymentStatus'], 'withdrawal_requested');
    expect(requested['sellerBalanceStatus'], 'withdrawal_requested');
    expect(requestedBalance['availableBalance'], 18500);
    expect(requestedBalance['withdrawnBalance'], 0);

    final settled = SellerBalanceLedger.afterWithdrawalSettled(
      sellerAmount: 18500,
      currency: 'XOF',
      now: 'paid',
    );
    final settledBalance = settled['sellerBalance'] as Map<String, dynamic>;

    expect(settled['managedPaymentStatus'], 'completed');
    expect(settled['sellerBalanceStatus'], 'withdrawn');
    expect(settledBalance['availableBalance'], 0);
    expect(settledBalance['withdrawnBalance'], 18500);
  });

  test('expose des libellés humains pour les statuts sensibles', () {
    expect(
      ManagedPaymentCopy.paymentStatusLabel('client_marked_paid'),
      'Preuve envoyée',
    );
    expect(
      ManagedPaymentCopy.orderStatusLabel(
        'awaiting_admin_payment_confirmation',
      ),
      'Paiement en vérification',
    );
    expect(
      ManagedPaymentCopy.sellerBalanceLabel('withdrawal_requested'),
      'Retrait demandé',
    );
    expect(
      ManagedPaymentCopy.clientActionHint('delivered_by_seller'),
      contains('Confirmez seulement'),
    );
    expect(
      ManagedPaymentCopy.sellerActionHint(
        orderStatus: 'ready',
        balanceStatus: 'pending_delivery',
      ),
      contains('Disponible après réception client'),
    );
  });

  test('centralise les devis livraison et le suivi stock', () {
    final delivery = DeliveryQuoteLedger.initial(
      deliveryMode: 'Livraison',
      amount: 2200,
      currency: 'XOF',
      addressOrInstruction: 'Cocody, près du marché',
      note: 'Appeler avant départ',
      now: 'now',
    );
    final quote = delivery['deliveryQuote'] as Map<String, dynamic>;

    expect(delivery['deliveryFee'], 2200);
    expect(delivery['deliveryFeeSource'], 'checkout_dynamic_estimate');
    expect(delivery['deliveryQuoteStatus'], 'estimated');
    expect(quote['requiresSellerOrAdminConfirmation'], isTrue);
    expect(DeliveryQuoteLedger.statusLabel('estimated'), 'Frais estimés');

    final pickup = DeliveryQuoteLedger.initial(
      deliveryMode: 'Retrait',
      amount: 5000,
      currency: 'XOF',
      addressOrInstruction: '',
      note: '',
      now: 'now',
    );

    expect(pickup['deliveryFee'], 0);
    expect(pickup['deliveryQuoteStatus'], 'not_required');
    expect(DeliveryQuoteLedger.clientHint('not_required'), contains('Aucun'));

    final awaiting = InventoryFlowLedger.awaitingPayment();
    expect(awaiting['inventoryFlowStatus'], 'awaiting_payment');
    expect(awaiting['inventoryDeducted'], isFalse);

    final reserved = InventoryFlowLedger.reserved(
      items: const [
        {'collection': 'products', 'id': 'prod_1', 'quantity': 2},
      ],
      now: 'reserved',
    );
    expect(reserved['inventoryFlowStatus'], 'reserved');
    expect(reserved['inventoryReserved'], isTrue);
    expect(InventoryFlowLedger.statusLabel('reserved'), 'Stock réservé');

    final deducted = InventoryFlowLedger.deducted(
      items: const [
        {'collection': 'products', 'id': 'prod_1', 'quantity': 2},
      ],
      now: 'later',
    );
    expect(deducted['inventoryFlowStatus'], 'deducted');
    expect(deducted['inventoryDeducted'], isTrue);
    expect(InventoryFlowLedger.statusLabel('deducted'), 'Stock décrémenté');

    final released = InventoryFlowLedger.released(now: 'released');
    expect(released['inventoryFlowStatus'], 'released');
    expect(released['inventoryReserved'], isFalse);
  });

  test('normalise un journal transactionnel dans l’ordre chronologique', () {
    final timeline = ManagedPaymentTimelineEntry.listFrom([
      {
        'status': 'received_by_customer',
        'label': 'Réception',
        'at': Timestamp.fromDate(DateTime(2026, 5, 4)),
      },
      {
        'status': 'client_marked_paid',
        'at': Timestamp.fromDate(DateTime(2026, 5, 3)),
      },
    ]);

    expect(timeline, hasLength(2));
    expect(timeline.first.status, 'client_marked_paid');
    expect(timeline.first.label, 'Paiement en vérification');
    expect(timeline.last.label, 'Réception');
  });

  test('lit les moyens de paiement admin depuis la configuration commerce', () {
    final config = CommerceRevenueConfig.fromMap({
      'platformPaymentMethods': {
        'Orange Money ElegantStyle': '+2250700000000',
        'Wave ElegantStyle': '+2250500000000',
      },
    });

    expect(config.platformPaymentMethods, {
      'Orange Money ElegantStyle': '+2250700000000',
      'Wave ElegantStyle': '+2250500000000',
    });
  });

  test('génère une référence de paiement traçable', () {
    final reference = CartService.generatePaymentReference(
      now: DateTime(2026, 5, 3, 14, 9, 8, 7),
    );

    expect(reference, 'EF-20260503-140908007');
  });
}
