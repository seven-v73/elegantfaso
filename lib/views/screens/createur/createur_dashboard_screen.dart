import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/account_roles.dart';
import '../../../design/app_icons.dart';
import '../../../design/modern_design_system.dart';
import '../auth/role_guard.dart';
import '../auth/login_screen.dart';
import '../about/about_screen.dart';
import '../commerce/plan_visibility_screen.dart';
import '../commerce/catalogue_express_screen.dart';
import '../commerce/pro_style_guide_composer_screen.dart';
import '../commerce/pro_story_publish_screen.dart';
import '../global/salon_mode_burkinabe.dart';
import '../messages/messages_entry_screen.dart';
import '../notifications/notifications_screen.dart';
import '../base/createur_profile_screen.dart';
import '../../widgets/commerce/pro_growth_banner.dart';
import '../../widgets/account/account_space_switcher.dart';
import '../../widgets/notifications/notification_bell_button.dart';
import 'createur_tabs/appointments_tab.dart';
import 'createur_tabs/clients_tab.dart';
import 'createur_tabs/creations_tabs.dart';
import 'createur_tabs/dashboard_tab.dart';
import 'createur_tabs/stats_tab.dart';

enum CreateurTab { dashboard, creations, appointments, clients, stats }

class CreateurDashboardScreen extends StatefulWidget {
  const CreateurDashboardScreen({super.key});

  @override
  State<CreateurDashboardScreen> createState() =>
      _CreateurDashboardScreenState();
}

class _CreateurDashboardScreenState extends State<CreateurDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  CreateurTab _currentTab = CreateurTab.dashboard;

  void _onTabTapped(CreateurTab tab) {
    if (_currentTab == tab) return;
    setState(() => _currentTab = tab);
  }

  void _openSalon() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SalonModeBurkinabeScreen()),
    );
  }

  void _openCatalogueExpress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => const CatalogueExpressScreen(role: AccountRoles.createur),
      ),
    );
  }

  void _openMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                const MessagesEntryScreen(roleOverride: AccountRoles.createur),
      ),
    );
  }

  void _openStoryPublisher() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => const ProStoryPublishScreen(role: AccountRoles.createur),
      ),
    );
  }

  void _openGuidePublisher() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                const ProStyleGuideComposerScreen(role: AccountRoles.createur),
      ),
    );
  }

  void _openPlanVisibility() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => const PlanVisibilityScreen(
              role: AccountRoles.createur,
              accent: ModernColors.creator,
            ),
      ),
    );
  }

  void _openAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateurProfileScreen()),
    );
  }

  void _handlePublishAction(String value) {
    switch (value) {
      case 'catalogue':
        _openCatalogueExpress();
      case 'story':
        _openStoryPublisher();
      case 'guide':
        _openGuidePublisher();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginScreen();

    return RoleGuard(
      expectedRole: AccountRoles.createur,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: ModernColors.canvas,
        appBar: _buildAppBar(),
        endDrawer: _buildSpaceDrawer(user),
        body: SafeArea(
          child: Column(
            children: [
              const ProGrowthBanner(
                role: AccountRoles.createur,
                accent: ModernColors.creator,
              ),
              Expanded(
                child: IndexedStack(
                  index: CreateurTab.values.indexOf(_currentTab),
                  children: [
                    DashboardTab(
                      user: user,
                      onTabSelected: _onTabTapped,
                      onOpenSalon: _openSalon,
                      onAddCreation: _openCatalogueExpress,
                    ),
                    CreationsTab(
                      user: user,
                      onOpenSalon: _openSalon,
                      showFloatingActionButton: false,
                    ),
                    AppointmentsTab(user: user),
                    ClientsTab(user: user),
                    StatsTab(user: user),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
        floatingActionButton:
            _currentTab == CreateurTab.creations
                ? FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: _openCatalogueExpress,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Publier'),
                )
                : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: ModernColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Tooltip(
            message: 'À propos de ElegantStyle',
            child: InkWell(
              onTap: _openAbout,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset(
                  'assets/logo/logo.svg',
                  height: 28,
                  colorFilter: const ColorFilter.mode(
                    ModernColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ElegantStyle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ModernColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Atelier créateur certifié',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Publier',
          icon: const Icon(
            Icons.add_circle_outline_rounded,
            color: ModernColors.creator,
          ),
          color: ModernColors.surface,
          onSelected: _handlePublishAction,
          itemBuilder:
              (context) => const [
                PopupMenuItem(
                  value: 'catalogue',
                  child: ListTile(
                    leading: Icon(Icons.add_photo_alternate_rounded),
                    title: Text('Ajout rapide'),
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: 'story',
                  child: ListTile(
                    leading: Icon(Icons.auto_stories_rounded),
                    title: Text('Story 24h'),
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: 'guide',
                  child: ListTile(
                    leading: Icon(Icons.school_rounded),
                    title: Text('Guide Style'),
                    dense: true,
                  ),
                ),
              ],
        ),
        NotificationBellButton(
          userId: FirebaseAuth.instance.currentUser?.uid,
          icon: AppIcons.notifications,
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
        ),
        IconButton(
          tooltip: 'Messages',
          onPressed: _openMessages,
          icon: const Icon(AppIcons.messages, color: ModernColors.ink),
        ),
        IconButton(
          tooltip: 'Espaces',
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          icon: const Icon(Icons.apps_rounded, color: ModernColors.ink),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildSpaceDrawer(User user) {
    final displayName =
        (user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName!.trim()
            : 'Atelier créateur';
    final email = user.email ?? '';

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.84,
      backgroundColor: ModernColors.canvas,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CreatorDrawerHeader(displayName: displayName, email: email),
            const SizedBox(height: 16),
            AccountSpaceSwitcher(
              currentSpace: AccountRoles.createur,
              onBeforeNavigate: () => Navigator.maybePop(context),
            ),
            const SizedBox(height: 16),
            const _DrawerSectionLabel('Atelier'),
            const SizedBox(height: 8),
            _CreatorDrawerTile(
              icon: AppIcons.salon,
              title: 'Salon',
              onTap: () {
                Navigator.pop(context);
                _openSalon();
              },
            ),
            const SizedBox(height: 10),
            _CreatorDrawerTile(
              icon: Icons.workspace_premium_rounded,
              title: 'Plan & visibilité',
              onTap: () {
                Navigator.pop(context);
                _openPlanVisibility();
              },
            ),
            const SizedBox(height: 10),
            _CreatorDrawerTile(
              icon: Icons.person_outline_rounded,
              title: 'Profil créateur',
              onTap: () {
                Navigator.pop(context);
                _openProfile();
              },
            ),
            const SizedBox(height: 10),
            _CreatorDrawerTile(
              icon: Icons.info_outline_rounded,
              title: 'À propos',
              onTap: () {
                Navigator.pop(context);
                _openAbout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    const items = [
      (AppIcons.today, 'Aujourd’hui', CreateurTab.dashboard),
      (AppIcons.creations, 'Créations', CreateurTab.creations),
      (AppIcons.appointments, 'RDV', CreateurTab.appointments),
      (AppIcons.clients, 'Clients', CreateurTab.clients),
      (AppIcons.stats, 'Stats', CreateurTab.stats),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: ModernColors.surface,
        border: Border(top: BorderSide(color: ModernColors.line, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children:
                items.map((item) {
                  final selected = _currentTab == item.$3;
                  return Expanded(
                    child: InkWell(
                      onTap: () => _onTabTapped(item.$3),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    selected
                                        ? ModernColors.creator.withValues(
                                          alpha: 0.12,
                                        )
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.$1,
                                size: 22,
                                color:
                                    selected
                                        ? ModernColors.creator
                                        : ModernColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    selected
                                        ? ModernColors.creator
                                        : ModernColors.inkSoft,
                                fontSize: 10.5,
                                fontWeight:
                                    selected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}

class _CreatorDrawerHeader extends StatelessWidget {
  const _CreatorDrawerHeader({required this.displayName, required this.email});

  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ModernColors.line),
        boxShadow: [
          BoxShadow(
            color: ModernColors.creator.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ModernColors.creator.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              AppIcons.creator,
              color: ModernColors.creator,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: ModernColors.inkSoft,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _CreatorDrawerTile extends StatelessWidget {
  const _CreatorDrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ModernColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ModernColors.line),
          ),
          child: Row(
            children: [
              Icon(icon, color: ModernColors.creator, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ModernColors.inkSoft,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
