import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/boutique/shop_order.dart';
import '../../../../services/preferences/currency_service.dart';
import 'boutique_status_chip.dart';

class OrderPipelineCard extends StatelessWidget {
  const OrderPipelineCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onNext,
    required this.onCancel,
    required this.onWithdraw,
    this.withdrawalLoading = false,
  });

  final ShopOrder order;
  final VoidCallback onTap;
  final VoidCallback onNext;
  final VoidCallback onCancel;
  final VoidCallback onWithdraw;
  final bool withdrawalLoading;

  @override
  Widget build(BuildContext context) {
    final color =
        order.isCancelled
            ? ModernColors.rose
            : order.isDelivered
            ? ModernColors.creator
            : order.needsPaymentReview
            ? ModernColors.accent
            : ModernColors.primary;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _OrderPipelineBadges(order: order, color: color)),
              const SizedBox(width: 10),
              Flexible(
                flex: 0,
                child: Text(
                  CurrencyService.format(order.total, code: order.currency),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            order.clientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${order.items.length} article(s) • ${order.deliveryMode.isEmpty ? 'Réception à préciser' : order.deliveryMode}${order.deliveryFee > 0 ? ' • livraison ${CurrencyService.format(order.deliveryFee, code: order.currency)}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.inkSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (order.sellerNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              order.sellerNote,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: ModernColors.inkSoft, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ModernColors.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ModernColors.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_rounded, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.sellerActionHint,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (order.hasSellerBalanceInfo) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ModernColors.canvas,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    order.canRequestWithdrawal
                        ? Icons.account_balance_wallet_rounded
                        : Icons.payments_rounded,
                    color:
                        order.canRequestWithdrawal
                            ? ModernColors.creator
                            : ModernColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${order.visibleSellerBalanceLabel} : ${CurrencyService.format(order.visibleSellerBalance, code: order.currency)}',
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
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label:
                      order.canRequestWithdrawal
                          ? withdrawalLoading
                              ? 'Demande...'
                              : 'Demander retrait'
                          : order.nextActionLabel,
                  onPressed:
                      order.canRequestWithdrawal
                          ? withdrawalLoading
                              ? null
                              : onWithdraw
                          : order.isCancelled ||
                              order.isDelivered ||
                              order.isAwaitingAdminPayment
                          ? null
                          : onNext,
                  loading: order.canRequestWithdrawal && withdrawalLoading,
                  expand: true,
                ),
              ),
              const SizedBox(width: 8),
              AppIconAction(
                icon: Icons.chat_rounded,
                tooltip: 'Message',
                onPressed: order.clientPhone.isEmpty ? null : _contactClient,
              ),
              const SizedBox(width: 8),
              AppOverflowMenu(
                actions: [
                  AppOverflowAction(
                    label: 'Annuler',
                    icon: Icons.close_rounded,
                    danger: true,
                    onPressed:
                        order.isCancelled || order.isDelivered
                            ? null
                            : onCancel,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _contactClient() async {
    final phone = order.clientPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) return;
    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent('Bonjour, concernant votre commande ${order.id}.')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _OrderPipelineBadges extends StatelessWidget {
  const _OrderPipelineBadges({required this.order, required this.color});

  final ShopOrder order;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        BoutiqueStatusChip(label: order.statusLabel, color: color),
        if (order.hasProof)
          const BoutiqueStatusChip(
            label: 'Preuve reçue',
            color: ModernColors.accent,
            icon: Icons.verified_rounded,
          ),
        if (order.sellerBalanceStatus.isNotEmpty)
          BoutiqueStatusChip(
            label: order.sellerBalanceLabel,
            color:
                order.canRequestWithdrawal
                    ? ModernColors.success
                    : order.hasWithdrawalRequest
                    ? ModernColors.warning
                    : ModernColors.inkSoft,
            icon: Icons.account_balance_wallet_rounded,
          ),
      ],
    );
  }
}
