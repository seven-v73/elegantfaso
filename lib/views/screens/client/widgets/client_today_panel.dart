import 'package:flutter/material.dart';

import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/client/client_dashboard_summary.dart';

class ClientTodayPanel extends StatelessWidget {
  final ClientDashboardSummary summary;
  final VoidCallback? onOpenSalon;
  final VoidCallback? onOpenStyle;

  const ClientTodayPanel({
    super.key,
    required this.summary,
    this.onOpenSalon,
    this.onOpenStyle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(18),
      color: ModernColors.surface,
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
                    Text(
                      'Bonjour ${summary.firstName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontSize: 22,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: ModernColors.client.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(AppIcons.style, color: ModernColors.client),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Garde-robe',
                  value: summary.wardrobeCount.toString(),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Souhaits',
                  value: summary.wishlistCount.toString(),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Tailles',
                  value: '${(summary.measurementCompletion * 100).round()}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Look du jour',
                  icon: AppIcons.salon,
                  onPressed: onOpenSalon,
                ),
              ),
              const SizedBox(width: 10),
              AppIconAction(
                icon: AppIcons.style,
                tooltip: 'Style',
                onPressed: onOpenStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.inkSoft,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
