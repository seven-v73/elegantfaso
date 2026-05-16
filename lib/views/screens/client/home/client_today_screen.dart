import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/client/client_action.dart';
import '../../../../models/client/client_dashboard_summary.dart';
import '../../../../models/client/gamification/style_progress_model.dart';
import '../../../../services/client/client_dashboard_service.dart';
import '../../../../services/client/client_gamification_service.dart';
import '../../../../services/client/client_recommendation_service.dart';
import '../features/style/chat_screen.dart';
import '../features/style/mesurement.dart';
import '../features/style/style_journey_screen.dart';
import '../features/virtual_try_on_screen.dart';
import '../purchases/client_purchase_history_screen.dart';
import '../secondhand/client_secondhand_screen.dart';
import '../widgets/client_action_card.dart';
import '../widgets/client_daily_challenge_card.dart';
import '../widgets/client_saved_rail.dart';
import '../widgets/client_style_progress_panel.dart';
import '../widgets/client_today_panel.dart';
import '../../global/widgets/inspiration/community_screen.dart';

class ClientTodayScreen extends StatelessWidget {
  final VoidCallback onOpenSalon;
  final VoidCallback onOpenStyle;
  final VoidCallback onOpenWardrobe;
  final VoidCallback onOpenMessages;
  final VoidCallback onOpenSecondhand;

  const ClientTodayScreen({
    super.key,
    required this.onOpenSalon,
    required this.onOpenStyle,
    required this.onOpenWardrobe,
    required this.onOpenMessages,
    required this.onOpenSecondhand,
  });

  static final ClientDashboardService _dashboardService =
      ClientDashboardService();
  static final ClientRecommendationService _recommendationService =
      ClientRecommendationService();
  static final ClientGamificationService _gamificationService =
      ClientGamificationService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _GuestClientToday(onOpenSalon: onOpenSalon);
    }

    return StreamBuilder<ClientDashboardSummary>(
      stream: _dashboardService.watchSummary(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _ClientTodaySkeleton();
        }

        if (snapshot.hasError) {
          return _ClientTodayError(onRetry: onOpenSalon);
        }

        final summary = snapshot.data;
        if (summary == null) {
          return const _ClientTodaySkeleton();
        }

        final actions =
            _recommendationService
                .buildActions(summary)
                .where((action) => action.intent != 'messages')
                .toList();
        return StreamBuilder(
          stream: _gamificationService.watchProgress(
            userId: user.uid,
            summary: summary,
          ),
          builder: (context, progressSnapshot) {
            final progress = progressSnapshot.data;
            return RefreshIndicator(
              color: ModernColors.primary,
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 500));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    sliver: SliverList.list(
                      children: [
                        ClientTodayPanel(
                          summary: summary,
                          onOpenSalon: onOpenSalon,
                          onOpenStyle: onOpenStyle,
                        ),
                        if (progress != null) ...[
                          const SizedBox(height: 14),
                          ClientStyleProgressPanel(
                            progress: progress,
                            onOpenDetails:
                                () => _openStyleJourney(
                                  context,
                                  summary,
                                  progress,
                                ),
                          ),
                          const SizedBox(height: 14),
                          ClientDailyChallengeCard(
                            summary: summary,
                            progress: progress,
                            gamificationService: _gamificationService,
                            onOpenSalon: onOpenSalon,
                            onOpenStyle: onOpenStyle,
                            onOpenWardrobe: onOpenWardrobe,
                            onOpenMessages: onOpenMessages,
                            onOpenCommunity: () => _openCommunity(context),
                            onOpenMeasurements:
                                () => _openMeasurements(context),
                            onOpenTryOn: () => _openTryOn(context),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _ClientEssentialsGrid(
                          summary: summary,
                          onOpenOrders: () => _openPurchaseHistory(context),
                          onOpenWardrobe: onOpenWardrobe,
                          onOpenSecondhand: onOpenSecondhand,
                          onOpenMeasurements: () => _openMeasurements(context),
                        ),
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          ClientActionCard(
                            action: actions.first,
                            onTap: () => _handleAction(context, actions.first),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SectionHeader(
                          padding: EdgeInsets.zero,
                          title: 'Favoris',
                          action: TextButton(
                            onPressed: onOpenWardrobe,
                            child: const Text('Voir'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClientSavedRail(
                          items: summary.savedItems,
                          onSeeAll: onOpenWardrobe,
                          onTapItem: (_) => onOpenWardrobe(),
                          onTryOn: (_) => _openTryOn(context),
                          onFindVendor: (_) => onOpenSalon(),
                          onAskAdvice: (_) => _openCommunity(context),
                          onCreateLook: (_) => onOpenStyle(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleAction(BuildContext context, ClientAction action) {
    switch (action.intent) {
      case 'salon':
        onOpenSalon();
        break;
      case 'style':
        onOpenStyle();
        break;
      case 'wardrobe':
        onOpenWardrobe();
        break;
      case 'messages':
        onOpenMessages();
        break;
      case 'measurements':
        _openMeasurements(context);
        break;
      case 'try_on':
        _openTryOn(context);
        break;
      case 'secondhand':
        _openSecondhand(context);
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
    }
  }

  void _openMeasurements(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileMeasurementsPage()),
    );
  }

  void _openTryOn(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VirtualTryOnScreen()),
    );
  }

  void _openSecondhand(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClientSecondhandScreen()),
    );
  }

  void _openPurchaseHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClientPurchaseHistoryScreen()),
    );
  }

  void _openCommunity(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityScreen()),
    );
  }

  void _openStyleJourney(
    BuildContext context,
    ClientDashboardSummary summary,
    StyleProgressModel progress,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => StyleJourneyScreen(
              summary: summary,
              progress: progress,
              gamificationService: _gamificationService,
              onOpenSalon: onOpenSalon,
              onOpenStyle: onOpenStyle,
              onOpenWardrobe: onOpenWardrobe,
              onOpenMessages: onOpenMessages,
              onOpenCommunity: () => _openCommunity(context),
              onOpenMeasurements: () => _openMeasurements(context),
              onOpenTryOn: () => _openTryOn(context),
            ),
      ),
    );
  }
}

class _ClientEssentialsGrid extends StatelessWidget {
  const _ClientEssentialsGrid({
    required this.summary,
    required this.onOpenOrders,
    required this.onOpenWardrobe,
    required this.onOpenSecondhand,
    required this.onOpenMeasurements,
  });

  final ClientDashboardSummary summary;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenWardrobe;
  final VoidCallback onOpenSecondhand;
  final VoidCallback onOpenMeasurements;

  @override
  Widget build(BuildContext context) {
    final eventsAndAppointments =
        summary.activeAppointmentsCount + summary.upcomingEventsCount;
    final items = [
      _EssentialItem(
        icon: Icons.local_mall_rounded,
        label: 'Achats',
        value: summary.activeOrdersCount.toString(),
        color: ModernColors.accent,
        onTap: onOpenOrders,
      ),
      _EssentialItem(
        icon: Icons.recycling_rounded,
        label: 'Dressing',
        value: summary.wardrobeCount.toString(),
        color: ModernColors.ink,
        onTap: onOpenWardrobe,
      ),
      _EssentialItem(
        icon: Icons.sell_rounded,
        label: 'Vendre',
        value: 'Articles',
        color: ModernColors.rose,
        onTap: onOpenSecondhand,
      ),
      _EssentialItem(
        icon: Icons.straighten_rounded,
        label: 'Tailles',
        value: '${(summary.measurementCompletion * 100).round()}%',
        color: ModernColors.primary,
        onTap: onOpenMeasurements,
      ),
      if (eventsAndAppointments > 0)
        _EssentialItem(
          icon: Icons.event_available_rounded,
          label: 'Agenda',
          value: eventsAndAppointments.toString(),
          color: ModernColors.creator,
          onTap: onOpenOrders,
        ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.take(4).length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.84,
      ),
      itemBuilder: (context, index) => _EssentialTile(item: items[index]),
    );
  }
}

class _EssentialItem {
  const _EssentialItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
}

class _EssentialTile extends StatelessWidget {
  const _EssentialTile({required this.item});

  final _EssentialItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ModernColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ModernColors.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontSize: 10,
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

class _GuestClientToday extends StatelessWidget {
  const _GuestClientToday({required this.onOpenSalon});

  final VoidCallback onOpenSalon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: ModernColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: ModernColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Connectez-vous pour personnaliser votre espace',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ModernColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Le Salon reste libre, mais les souhaits, commandes, messages et mensurations demandent un compte.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ModernColors.inkSoft,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Salon',
                onPressed: onOpenSalon,
                icon: AppIcons.salon,
                variant: AppButtonVariant.outline,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientTodaySkeleton extends StatelessWidget {
  const _ClientTodaySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder:
          (_, index) => Container(
            height: index == 0 ? 176 : 78,
            decoration: BoxDecoration(
              color: ModernColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ModernColors.line),
            ),
          ),
    );
  }
}

class _ClientTodayError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ClientTodayError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: ModernColors.rose,
                size: 34,
              ),
              const SizedBox(height: 12),
              const Text(
                'Impossible de charger le cockpit client',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ModernColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Réessayer',
                onPressed: onRetry,
                variant: AppButtonVariant.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
