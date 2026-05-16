import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/boutique/shop_order.dart';
import '../../../../models/commerce/managed_payment.dart';
import '../../../../services/boutique/boutique_order_service.dart';
import '../../../../services/commerce/seller_balance_service.dart';
import '../../../../services/preferences/currency_service.dart';
import '../../../widgets/common/app_action_empty_state.dart';
import '../../global/salon_mode_burkinabe.dart';
import '../widgets/order_pipeline_card.dart';

enum OrderStatus {
  all,
  pending,
  confirmed,
  processing,
  ready,
  delivered,
  withdrawals,
  cancelled;

  String get label {
    return switch (this) {
      OrderStatus.all => 'Toutes',
      OrderStatus.pending => 'Nouvelles',
      OrderStatus.confirmed => 'OK',
      OrderStatus.processing => 'Prépa',
      OrderStatus.ready => 'Prêtes',
      OrderStatus.delivered => 'Livrées',
      OrderStatus.withdrawals => 'Retraits',
      OrderStatus.cancelled => 'Annulées',
    };
  }
}

class BoutiqueOrdersScreen extends StatefulWidget {
  const BoutiqueOrdersScreen({super.key, this.initialFilter = OrderStatus.all});

  final OrderStatus initialFilter;

  @override
  State<BoutiqueOrdersScreen> createState() => _BoutiqueOrdersScreenState();
}

class _BoutiqueOrdersScreenState extends State<BoutiqueOrdersScreen> {
  final BoutiqueOrderService _service = BoutiqueOrderService();
  final SellerBalanceService _sellerBalanceService = SellerBalanceService();
  final String _boutiqueId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late OrderStatus _selected = widget.initialFilter;
  final Set<String> _withdrawingOrderIds = <String>{};

  List<ShopOrder> _filter(List<ShopOrder> orders) {
    return orders.where((order) {
      return switch (_selected) {
        OrderStatus.pending => order.isPending || order.needsPaymentReview,
        OrderStatus.confirmed => order.isConfirmed,
        OrderStatus.processing => order.isPreparing,
        OrderStatus.ready => order.isReady,
        OrderStatus.delivered => order.isDelivered,
        OrderStatus.withdrawals =>
          order.canRequestWithdrawal || order.hasWithdrawalRequest,
        OrderStatus.cancelled => order.isCancelled,
        OrderStatus.all => true,
      };
    }).toList();
  }

  Future<void> _next(ShopOrder order) async {
    try {
      await _service.updateStatus(order.id, order.nextStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Commande ${order.id.substring(0, 6)} mise à jour.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst('Bad state: ', '');
      final message =
          raw.contains('paiement doit être confirmé')
              ? 'Paiement en attente de validation admin. Vous pourrez préparer la commande juste après confirmation.'
              : raw;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _cancel(ShopOrder order) async {
    await _service.cancel(order.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Commande annulée.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _requestWithdrawal(ShopOrder order) async {
    if (_withdrawingOrderIds.contains(order.id)) return;
    final confirmed = await _confirmWithdrawal(order);
    if (!confirmed || !mounted) return;
    setState(() => _withdrawingOrderIds.add(order.id));
    try {
      final amount = await _sellerBalanceService.requestWithdrawal(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demande de retrait envoyée pour ${CurrencyService.format(amount, code: order.currency)}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Bad state: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _withdrawingOrderIds.remove(order.id));
      }
    }
  }

  Future<bool> _confirmWithdrawal(ShopOrder order) async {
    final amount = CurrencyService.format(
      order.sellerAvailableBalance,
      code: order.currency,
    );
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Demander le retrait ?'),
                content: Text(
                  '$amount sera envoyé en validation admin avec le moyen de retrait enregistré.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Demander'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _showDetail(ShopOrder order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(order: order),
    );
  }

  void _openSalon() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SalonModeBurkinabeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      body: StreamBuilder<List<ShopOrder>>(
        stream: _service.watchOrders(_boutiqueId),
        builder: (context, snapshot) {
          final allOrders = snapshot.data ?? const <ShopOrder>[];
          final orders = _filter(allOrders);
          final priorityOrder =
              _selected == OrderStatus.withdrawals
                  ? null
                  : _priorityOrder(allOrders);
          final visibleOrders =
              priorityOrder == null
                  ? orders
                  : orders
                      .where((order) => order.id != priorityOrder.id)
                      .toList();
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              cacheExtent: 900,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                const AppCard(
                  padding: EdgeInsets.all(16),
                  elevated: false,
                  child: Text(
                    'Commandes',
                    style: TextStyle(
                      color: ModernColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (allOrders.any((order) => order.hasSellerBalanceInfo)) ...[
                  _AvailableBalanceBanner(
                    orders: allOrders,
                    onTap:
                        () =>
                            setState(() => _selected = OrderStatus.withdrawals),
                  ),
                  const SizedBox(height: 12),
                ],
                if (priorityOrder != null) ...[
                  SectionHeader(padding: EdgeInsets.zero, title: 'À traiter'),
                  const SizedBox(height: 10),
                  OrderPipelineCard(
                    order: priorityOrder,
                    onTap: () => _showDetail(priorityOrder),
                    onNext: () => _next(priorityOrder),
                    onCancel: () => _cancel(priorityOrder),
                    onWithdraw: () => _requestWithdrawal(priorityOrder),
                    withdrawalLoading: _withdrawingOrderIds.contains(
                      priorityOrder.id,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _PipelineRail(
                  selected: _selected,
                  onSelected: (value) => setState(() => _selected = value),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const _LoadingOrders()
                else if (snapshot.hasError)
                  const _OrderState(
                    icon: Icons.error_outline_rounded,
                    title: 'Commandes indisponibles',
                    message: 'Réessayez.',
                  )
                else if (orders.isEmpty && priorityOrder == null)
                  _OrderState(
                    icon: Icons.receipt_long_outlined,
                    title:
                        _selected == OrderStatus.withdrawals
                            ? 'Aucun retrait'
                            : _selected == OrderStatus.all
                            ? 'Aucune commande'
                            : 'Aucune commande pour ce filtre',
                    message:
                        _selected == OrderStatus.withdrawals
                            ? 'Disponible après réception client.'
                            : _selected == OrderStatus.all
                            ? 'Aucune vente pour le moment.'
                            : 'Aucun résultat.',
                    actionLabel:
                        _selected == OrderStatus.all
                            ? 'Voir le Salon'
                            : 'Voir toutes',
                    onAction:
                        _selected == OrderStatus.all
                            ? _openSalon
                            : () => setState(() => _selected = OrderStatus.all),
                  )
                else
                  for (final order in visibleOrders) ...[
                    OrderPipelineCard(
                      order: order,
                      onTap: () => _showDetail(order),
                      onNext: () => _next(order),
                      onCancel: () => _cancel(order),
                      onWithdraw: () => _requestWithdrawal(order),
                      withdrawalLoading: _withdrawingOrderIds.contains(
                        order.id,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                if (allOrders.any((order) => order.hasSellerBalanceInfo)) ...[
                  const SizedBox(height: 8),
                  _SellerBalanceOverview(orders: allOrders),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  ShopOrder? _priorityOrder(List<ShopOrder> orders) {
    for (final order in orders) {
      if (order.needsPaymentReview || order.isPending || order.isConfirmed) {
        return order;
      }
    }
    for (final order in orders) {
      if (order.isPreparing || order.isReady || order.canRequestWithdrawal) {
        return order;
      }
    }
    return null;
  }
}

class _PipelineRail extends StatelessWidget {
  const _PipelineRail({required this.selected, required this.onSelected});

  final OrderStatus selected;
  final ValueChanged<OrderStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: OrderStatus.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = OrderStatus.values[index];
          return ChoiceChip(
            label: Text(status.label),
            selected: status == selected,
            onSelected: (_) => onSelected(status),
          );
        },
      ),
    );
  }
}

class _AvailableBalanceBanner extends StatelessWidget {
  const _AvailableBalanceBanner({required this.orders, required this.onTap});

  final List<ShopOrder> orders;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final totals = _SellerBalanceTotals.fromOrders(orders);
    final availableTotals =
        totals.where((total) => total.available > 0).toList();
    if (totals.isEmpty) return const SizedBox.shrink();

    final hasAvailable = availableTotals.isNotEmpty;
    final displayTotals = hasAvailable ? availableTotals : totals;
    final value = displayTotals
        .map(
          (total) => CurrencyService.format(
            hasAvailable ? total.available : total.pending,
            code: total.currency,
          ),
        )
        .where((value) => !value.startsWith('0'))
        .join(' · ');

    return AppCard(
      onTap: hasAvailable ? onTap : null,
      padding: const EdgeInsets.all(14),
      elevated: hasAvailable,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (hasAvailable
                      ? ModernColors.creator
                      : ModernColors.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasAvailable
                  ? Icons.account_balance_wallet_rounded
                  : Icons.lock_clock_rounded,
              color: hasAvailable ? ModernColors.creator : ModernColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAvailable ? 'Solde disponible' : 'Solde à venir',
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Disponible après réception client' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (hasAvailable)
            const Icon(
              Icons.chevron_right_rounded,
              color: ModernColors.inkSoft,
            ),
        ],
      ),
    );
  }
}

class _SellerBalanceOverview extends StatelessWidget {
  const _SellerBalanceOverview({required this.orders});

  final List<ShopOrder> orders;

  @override
  Widget build(BuildContext context) {
    final totals = _SellerBalanceTotals.fromOrders(orders);
    if (totals.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde vendeur',
            style: TextStyle(
              color: ModernColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 10),
          for (final total in totals) ...[
            if (totals.length > 1) ...[
              Text(
                total.currency,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (total.expected > 0)
                  _BalancePill(
                    icon: Icons.hourglass_top_rounded,
                    label: 'Attendu',
                    value: CurrencyService.format(
                      total.expected,
                      code: total.currency,
                    ),
                    color: ModernColors.accent,
                  ),
                if (total.pending > 0)
                  _BalancePill(
                    icon: Icons.local_shipping_rounded,
                    label: 'En attente',
                    value: CurrencyService.format(
                      total.pending,
                      code: total.currency,
                    ),
                    color: ModernColors.primary,
                  ),
                if (total.available > 0)
                  _BalancePill(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Retirable',
                    value: CurrencyService.format(
                      total.available,
                      code: total.currency,
                    ),
                    color: ModernColors.creator,
                  ),
                if (total.requested > 0)
                  _BalancePill(
                    icon: Icons.schedule_send_rounded,
                    label: 'Demandé',
                    value: CurrencyService.format(
                      total.requested,
                      code: total.currency,
                    ),
                    color: ModernColors.warning,
                  ),
                if (total.disputed > 0)
                  _BalancePill(
                    icon: Icons.gpp_maybe_rounded,
                    label: 'Litige',
                    value: CurrencyService.format(
                      total.disputed,
                      code: total.currency,
                    ),
                    color: ModernColors.rose,
                  ),
              ],
            ),
            if (total != totals.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SellerBalanceTotals {
  const _SellerBalanceTotals({
    required this.currency,
    required this.expected,
    required this.pending,
    required this.available,
    required this.requested,
    required this.disputed,
  });

  final String currency;
  final double expected;
  final double pending;
  final double available;
  final double requested;
  final double disputed;

  static List<_SellerBalanceTotals> fromOrders(List<ShopOrder> orders) {
    final buckets = <String, _MutableSellerBalanceTotals>{};
    for (final order in orders.where((order) => order.hasSellerBalanceInfo)) {
      final currency = order.currency.isEmpty ? 'XOF' : order.currency;
      final bucket = buckets.putIfAbsent(
        currency,
        () => _MutableSellerBalanceTotals(currency),
      );
      switch (order.sellerBalanceStatus) {
        case 'available':
          bucket.available += order.visibleSellerBalance;
        case 'pending_delivery':
          bucket.pending += order.visibleSellerBalance;
        case 'withdrawal_requested':
          bucket.requested += order.visibleSellerBalance;
        case 'disputed':
          bucket.disputed += order.visibleSellerBalance;
        case 'withdrawn':
          break;
        default:
          bucket.expected += order.visibleSellerBalance;
      }
    }

    final totals =
        buckets.values.map((bucket) => bucket.freeze()).where((total) {
          return total.expected > 0 ||
              total.pending > 0 ||
              total.available > 0 ||
              total.requested > 0 ||
              total.disputed > 0;
        }).toList();
    totals.sort((a, b) => a.currency.compareTo(b.currency));
    return totals;
  }
}

class _MutableSellerBalanceTotals {
  _MutableSellerBalanceTotals(this.currency);

  final String currency;
  double expected = 0;
  double pending = 0;
  double available = 0;
  double requested = 0;
  double disputed = 0;

  _SellerBalanceTotals freeze() {
    return _SellerBalanceTotals(
      currency: currency,
      expected: expected,
      pending: pending,
      available: available,
      requested: requested,
      disputed: disputed,
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label · $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ModernColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Commande #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${order.clientName} • ${order.clientPhone.isEmpty ? 'Téléphone absent' : order.clientPhone}',
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              SectionHeader(
                padding: EdgeInsets.zero,
                title: 'Articles',
                subtitle: '${order.items.length} article(s)',
              ),
              const SizedBox(height: 10),
              for (final item in order.items) ...[
                AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 52,
                          height: 52,
                          color: ModernColors.canvas,
                          child:
                              item.imageUrl.isEmpty
                                  ? const Icon(Icons.image_rounded)
                                  : Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${item.name} x${item.quantity}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _DetailRow(label: 'Paiement', value: order.paymentMethod),
                    _DetailRow(
                      label: 'Statut paiement',
                      value: order.paymentStatusLabel,
                    ),
                    _DetailRow(
                      label: 'Référence',
                      value: order.paymentReference,
                    ),
                    _DetailRow(
                      label: 'Solde vendeur',
                      value:
                          order.hasSellerBalanceInfo
                              ? '${order.visibleSellerBalanceLabel} • ${CurrencyService.format(order.visibleSellerBalance, code: order.currency)}'
                              : order.sellerBalanceLabel,
                    ),
                    _DetailRow(
                      label: 'Action attendue',
                      value: order.sellerActionHint,
                    ),
                    _DetailRow(
                      label: 'Disponible',
                      value:
                          order.sellerAvailableBalance > 0
                              ? CurrencyService.format(
                                order.sellerAvailableBalance,
                                code: order.currency,
                              )
                              : '',
                    ),
                    _DetailRow(label: 'Livraison', value: order.deliveryMode),
                    _DetailRow(
                      label: 'Frais livraison',
                      value:
                          order.deliveryFee > 0
                              ? CurrencyService.format(
                                order.deliveryFee,
                                code: order.currency,
                              )
                              : 'Aucun frais',
                    ),
                    _DetailRow(label: 'Adresse', value: order.deliveryAddress),
                    _DetailRow(label: 'Note', value: order.sellerNote),
                  ],
                ),
              ),
              if (order.timeline.isNotEmpty) ...[
                const SizedBox(height: 14),
                SectionHeader(
                  padding: EdgeInsets.zero,
                  title: 'Journal transaction',
                  subtitle: '${order.timeline.length} étape(s)',
                ),
                const SizedBox(height: 10),
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children:
                        order.timeline
                            .map((entry) => _TimelineRow(entry: entry))
                            .toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry});

  final ManagedPaymentTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final time =
        entry.at == null
            ? ''
            : '${entry.at!.day.toString().padLeft(2, '0')}/${entry.at!.month.toString().padLeft(2, '0')} ${entry.at!.hour.toString().padLeft(2, '0')}:${entry.at!.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.radio_button_checked_rounded,
            color: ModernColors.primary,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: ModernColors.inkSoft),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: ModernColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingOrders extends StatelessWidget {
  const _LoadingOrders();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 156,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderState extends StatelessWidget {
  const _OrderState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppActionEmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      accent: ModernColors.creator,
    );
  }
}
