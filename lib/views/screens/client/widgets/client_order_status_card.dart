import 'package:flutter/material.dart';

import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/client/client_dashboard_summary.dart';

class ClientOrderStatusCard extends StatelessWidget {
  final ClientDashboardSummary summary;
  final VoidCallback? onOpenMessages;
  final VoidCallback? onOpenOrders;
  final VoidCallback? onOpenAgenda;

  const ClientOrderStatusCard({
    super.key,
    required this.summary,
    this.onOpenMessages,
    this.onOpenOrders,
    this.onOpenAgenda,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _StatusRow(
            icon: AppIcons.orders,
            label: 'Commandes en cours',
            value: summary.activeOrdersCount.toString(),
            color: ModernColors.accent,
            onTap: onOpenOrders,
          ),
          const Divider(height: 22, color: ModernColors.line),
          _StatusRow(
            icon: Icons.event_available_rounded,
            label: 'RDV et événements',
            value:
                (summary.activeAppointmentsCount + summary.upcomingEventsCount)
                    .toString(),
            color: ModernColors.creator,
            onTap: onOpenAgenda,
          ),
          const Divider(height: 22, color: ModernColors.line),
          _StatusRow(
            icon: Icons.chat_bubble_rounded,
            label: 'Messages à suivre',
            value: summary.unreadMessagesCount.toString(),
            color: ModernColors.client,
            onTap: onOpenMessages,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: ModernColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
