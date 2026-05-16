import 'package:flutter/material.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/createur/creator_dashboard_summary.dart';
import 'creator_status_chip.dart';

class CreatorTodayPanel extends StatelessWidget {
  const CreatorTodayPanel({
    super.key,
    required this.summary,
    required this.onCreations,
    required this.onPrimaryAction,
    required this.onAppointments,
    required this.onClients,
    required this.onSalon,
    required this.onStatusChanged,
  });

  final CreatorDashboardSummary summary;
  final VoidCallback onCreations;
  final VoidCallback onPrimaryAction;
  final VoidCallback onAppointments;
  final VoidCallback onClients;
  final VoidCallback onSalon;
  final ValueChanged<bool> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: ModernColors.creator.withValues(alpha: 0.12),
                backgroundImage:
                    summary.photoUrl.isEmpty
                        ? null
                        : NetworkImage(summary.photoUrl),
                child:
                    summary.photoUrl.isEmpty
                        ? const Icon(
                          Icons.brush_rounded,
                          color: ModernColors.creator,
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, ${summary.creatorName.split(' ').first}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        CreatorStatusChip(
                          label: summary.isOnline ? 'En ligne' : 'Hors ligne',
                          color:
                              summary.isOnline
                                  ? ModernColors.success
                                  : ModernColors.inkSoft,
                          icon: Icons.circle,
                        ),
                        const CreatorStatusChip(
                          label: 'Créateur',
                          color: ModernColors.creator,
                          icon: Icons.verified_rounded,
                        ),
                        if (summary.specialty.isNotEmpty)
                          CreatorStatusChip(
                            label: summary.specialty,
                            color: ModernColors.accent,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(value: summary.isOnline, onChanged: onStatusChanged),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.08,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _MetricTile(
                label: 'À confirmer',
                value: '${summary.pendingAppointmentsCount}',
                color: ModernColors.accent,
              ),
              _MetricTile(
                label: 'Clients',
                value: '${summary.followersCount}',
                color: ModernColors.client,
              ),
              _MetricTile(
                label: 'Profil',
                value: '${summary.profileViewsCount}',
                color: ModernColors.primary,
              ),
              _MetricTile(
                label: 'Créations',
                value: '${summary.totalViews}',
                color: ModernColors.creator,
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Publier',
            icon: Icons.add_rounded,
            onPressed: onPrimaryAction,
            expand: true,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 22,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
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
    );
  }
}
