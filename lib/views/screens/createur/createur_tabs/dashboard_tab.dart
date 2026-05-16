import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/createur/creator_dashboard_summary.dart';
import '../../../../services/createur/creator_dashboard_service.dart';
import '../../../../services/createur/creator_visibility_service.dart';
import '../createur_dashboard_screen.dart';
import '../widgets/creator_action_card.dart';
import '../widgets/creator_today_panel.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({
    super.key,
    required this.user,
    required this.onTabSelected,
    required this.onOpenSalon,
    required this.onAddCreation,
  });

  final User user;
  final ValueChanged<CreateurTab> onTabSelected;
  final VoidCallback onOpenSalon;
  final VoidCallback onAddCreation;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final CreatorDashboardService _service = CreatorDashboardService();
  final CreatorVisibilityService _visibilityService =
      CreatorVisibilityService();

  Future<void> _setOnline(bool value) {
    return _visibilityService.updateOnlineStatus(
      creatorId: widget.user.uid,
      isOnline: value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CreatorDashboardSummary>(
      stream: _service.watchSummary(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _DashboardLoading();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _DashboardState(
            icon: Icons.error_outline_rounded,
            title: 'Atelier indisponible',
            message: 'Impossible de charger les informations créateur.',
            onRetry: () => setState(() {}),
          );
        }

        final summary = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              CreatorTodayPanel(
                summary: summary,
                onCreations: () => widget.onTabSelected(CreateurTab.creations),
                onPrimaryAction: widget.onAddCreation,
                onAppointments:
                    () => widget.onTabSelected(CreateurTab.appointments),
                onClients: () => widget.onTabSelected(CreateurTab.clients),
                onSalon: widget.onOpenSalon,
                onStatusChanged: _setOnline,
              ),
              if (summary.pendingAppointmentsCount > 0 ||
                  summary.draftCount > 0) ...[
                const SizedBox(height: 14),
                _TodoStrip(
                  pendingAppointments: summary.pendingAppointmentsCount,
                  drafts: summary.draftCount,
                  onAppointments:
                      () => widget.onTabSelected(CreateurTab.appointments),
                  onCreations:
                      () => widget.onTabSelected(CreateurTab.creations),
                ),
              ],
              const SizedBox(height: 22),
              SectionHeader(
                padding: EdgeInsets.zero,
                title: 'Visibilité Salon',
                subtitle:
                    '${summary.publishedCount}/${summary.creationsCount} visibles · ${summary.profileViewsCount} vues profil',
                action: TextButton(
                  onPressed: widget.onOpenSalon,
                  child: const Text('Voir'),
                ),
              ),
              const SizedBox(height: 12),
              if (summary.topCreations.isEmpty)
                _DashboardState(
                  icon: Icons.checkroom_outlined,
                  title: 'Aucune création publiée',
                  message: 'Ajoutez vos premières créations.',
                  onRetry: widget.onAddCreation,
                  actionLabel: 'Publier',
                )
              else
                for (final creation in summary.topCreations) ...[
                  AppCard(
                    onTap: () => widget.onTabSelected(CreateurTab.creations),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 56,
                            height: 56,
                            color: ModernColors.canvas,
                            child:
                                creation.coverImage.isEmpty
                                    ? const Icon(Icons.image_rounded)
                                    : Image.network(
                                      creation.coverImage,
                                      fit: BoxFit.cover,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                creation.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ModernColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${creation.viewsCount} vues • ${creation.savesCount} souhaits',
                                style: const TextStyle(
                                  color: ModernColors.inkSoft,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 14),
              if (summary.todayAppointments.isNotEmpty) ...[
                SectionHeader(
                  padding: EdgeInsets.zero,
                  title: 'Rendez-vous du jour',
                  subtitle: '${summary.todayAppointments.length} à préparer',
                ),
                const SizedBox(height: 12),
                for (final appointment in summary.todayAppointments) ...[
                  CreatorActionCard(
                    title: appointment.clientName,
                    subtitle:
                        '${appointment.statusLabel} • ${appointment.reason}',
                    icon: Icons.today_rounded,
                    color: ModernColors.client,
                    onTap: () => widget.onTabSelected(CreateurTab.appointments),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TodoStrip extends StatelessWidget {
  const _TodoStrip({
    required this.pendingAppointments,
    required this.drafts,
    required this.onAppointments,
    required this.onCreations,
  });

  final int pendingAppointments;
  final int drafts;
  final VoidCallback onAppointments;
  final VoidCallback onCreations;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (pendingAppointments > 0)
          Expanded(
            child: _TodoTile(
              icon: Icons.event_available_rounded,
              label: '$pendingAppointments RDV',
              color: ModernColors.accent,
              onTap: onAppointments,
            ),
          ),
        if (pendingAppointments > 0 && drafts > 0) const SizedBox(width: 10),
        if (drafts > 0)
          Expanded(
            child: _TodoTile(
              icon: Icons.edit_note_rounded,
              label: '$drafts brouillon${drafts > 1 ? 's' : ''}',
              color: ModernColors.creator,
              onTap: onCreations,
            ),
          ),
      ],
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      elevated: false,
      color: color.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        6,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 96,
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

class _DashboardState extends StatelessWidget {
  const _DashboardState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Réessayer',
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(icon, color: ModernColors.inkSoft, size: 38),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ModernColors.inkSoft),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
