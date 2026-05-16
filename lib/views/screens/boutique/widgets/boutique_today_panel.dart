import 'package:flutter/material.dart';

import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/boutique/shop_dashboard_summary.dart';
import '../../../../services/preferences/currency_service.dart';

class BoutiqueTodayPanel extends StatelessWidget {
  const BoutiqueTodayPanel({
    super.key,
    required this.summary,
    required this.onOrders,
    required this.onProducts,
    required this.onAddProduct,
    required this.onClients,
    required this.onSalon,
  });

  final ShopDashboardSummary summary;
  final VoidCallback onOrders;
  final VoidCallback onProducts;
  final VoidCallback onAddProduct;
  final VoidCallback onClients;
  final VoidCallback onSalon;

  @override
  Widget build(BuildContext context) {
    final priority = _BoutiquePriority.fromSummary(
      summary,
      onOrders: onOrders,
      onProducts: onProducts,
      onAddProduct: onAddProduct,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF4FBF9), Color(0xFFFFF7ED)],
          stops: [0, 0.62, 1],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            offset: Offset(0, 14),
            blurRadius: 28,
            spreadRadius: -16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: ModernColors.line),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatusPill(label: priority.statusLabel),
                            const SizedBox(height: 12),
                            Text(
                              summary.boutiqueName.isEmpty
                                  ? 'Ma boutique'
                                  : summary.boutiqueName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ModernColors.ink,
                                fontSize: 24,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              priority.headline,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ModernColors.inkSoft,
                                fontSize: 13,
                                height: 1.25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _HeroIconButton(
                        icon: AppIcons.salon,
                        tooltip: 'Salon',
                        onPressed: onSalon,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    label: priority.actionLabel,
                    icon: priority.icon,
                    onPressed: priority.onTap,
                    expand: true,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.inventory_2_rounded,
                          label: 'Produits',
                          onTap: onProducts,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.receipt_long_rounded,
                          label: 'Cmd',
                          onTap: onOrders,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.groups_rounded,
                          label: 'Clients',
                          onTap: onClients,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.22,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _MetricTile(
                        label: 'À traiter',
                        value: '${summary.pendingOrdersCount}',
                        icon: Icons.bolt_rounded,
                        color: ModernColors.accent,
                      ),
                      _MetricTile(
                        label: 'Stock',
                        value: '${summary.outOfStockCount}',
                        icon: Icons.inventory_rounded,
                        color:
                            summary.outOfStockCount > 0
                                ? ModernColors.rose
                                : ModernColors.success,
                      ),
                      _MetricTile(
                        label: 'Audience',
                        value: '${summary.followersCount}',
                        icon: Icons.favorite_rounded,
                        color: ModernColors.creator,
                      ),
                      _MetricTile(
                        label: 'Revenu',
                        value: CurrencyService.format(
                          summary.estimatedRevenue,
                          code: summary.currency,
                        ),
                        icon: Icons.payments_rounded,
                        color: ModernColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoutiquePriority {
  const _BoutiquePriority({
    required this.statusLabel,
    required this.headline,
    required this.actionLabel,
    required this.icon,
    required this.onTap,
  });

  final String statusLabel;
  final String headline;
  final String actionLabel;
  final IconData icon;
  final VoidCallback onTap;

  static _BoutiquePriority fromSummary(
    ShopDashboardSummary summary, {
    required VoidCallback onOrders,
    required VoidCallback onProducts,
    required VoidCallback onAddProduct,
  }) {
    if (summary.pendingOrdersCount > 0) {
      return _BoutiquePriority(
        statusLabel: 'Action requise',
        headline: '${summary.pendingOrdersCount} commande(s) à confirmer.',
        actionLabel: 'Voir commandes',
        icon: Icons.receipt_long_rounded,
        onTap: onOrders,
      );
    }
    if (summary.outOfStockCount > 0) {
      return _BoutiquePriority(
        statusLabel: 'Stock à surveiller',
        headline: '${summary.outOfStockCount} pièce(s) en rupture.',
        actionLabel: 'Corriger le stock',
        icon: Icons.inventory_2_rounded,
        onTap: onProducts,
      );
    }
    return _BoutiquePriority(
      statusLabel: 'Boutique prête',
      headline: 'Tout est calme. Vous pouvez publier une nouveauté.',
      actionLabel: 'Ajouter une pièce',
      icon: Icons.add_rounded,
      onTap: onAddProduct,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ModernColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ModernColors.primary.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: ModernColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filled(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: ModernColors.primary.withValues(alpha: 0.1),
          foregroundColor: ModernColors.primary,
          fixedSize: const Size(44, 44),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ModernColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 54,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: ModernColors.primary, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 10,
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
