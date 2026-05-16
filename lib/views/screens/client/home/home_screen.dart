import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/account_roles.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/modern_design_system.dart';
import '../../../widgets/account/account_space_switcher.dart';
import '../../../widgets/notifications/notification_bell_button.dart';
import '../../about/about_screen.dart';
import '../../auth/login_screen.dart';
import '../../base/client_profile_screen.dart';
import '../../global/salon_mode_burkinabe.dart';
import '../../messages/messages_entry_screen.dart';
import '../../notifications/notifications_screen.dart';
import '../features/style/garde_robe.dart';
import '../features/style/style_hub_screen.dart';
import '../secondhand/client_secondhand_screen.dart';
import 'client_today_screen.dart';

enum _ClientTab { salon, today, style, wardrobe, profile }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  _ClientTab _currentTab = _ClientTab.salon;

  User? get _user => FirebaseAuth.instance.currentUser;

  late final List<Widget> _pages = [
    const SalonModeBurkinabeScreen(embeddedInClientShell: true),
    ClientTodayScreen(
      onOpenSalon: () => _selectTab(_ClientTab.salon),
      onOpenStyle: () => _selectTab(_ClientTab.style),
      onOpenWardrobe: () => _selectTab(_ClientTab.wardrobe),
      onOpenMessages: _openMessages,
      onOpenSecondhand: _openSecondhand,
    ),
    const StyleHubScreen(),
    const WardrobeScreen(embeddedInClientShell: true),
    const ClientProfileScreen(showBackButton: false),
  ];

  int get _currentIndex => _ClientTab.values.indexOf(_currentTab);

  void _selectTab(_ClientTab tab) {
    if (_currentTab == tab) return;
    setState(() => _currentTab = tab);
  }

  void _openMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => const MessagesEntryScreen(roleOverride: AccountRoles.client),
      ),
    );
  }

  void _openSecondhand() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClientSecondhandScreen()),
    );
  }

  void _openAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const LoginScreen();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ModernColors.canvas,
      appBar:
          _currentTab == _ClientTab.salon || _currentTab == _ClientTab.profile
              ? null
              : _buildAppBar(),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNavigation(),
      endDrawer: _buildAccountDrawer(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final tabCopy = _ClientTabCopy.forTab(_currentTab);
    return AppBar(
      backgroundColor: ModernColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleSpacing: 16,
      title: Row(
        children: [
          Tooltip(
            message: 'À propos de ElegantStyle',
            child: InkWell(
              onTap: _openAbout,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: ModernColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(
                  'assets/logo/logo.svg',
                  colorFilter: const ColorFilter.mode(
                    ModernColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tabCopy.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                if (tabCopy.subtitle.isNotEmpty)
                  Text(
                    tabCopy.subtitle,
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
          ),
        ],
      ),
      actions: [
        NotificationBellButton(
          userId: _user?.uid,
          iconColor: ModernColors.ink,
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
          tooltip: 'Compte',
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          icon: const Icon(AppIcons.profile, color: ModernColors.ink),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    const items = [
      (AppIcons.salon, 'Salon', _ClientTab.salon),
      (AppIcons.today, 'Aujourd’hui', _ClientTab.today),
      (AppIcons.style, 'Style', _ClientTab.style),
      (AppIcons.wardrobe, 'Garde-robe', _ClientTab.wardrobe),
      (AppIcons.profile, 'Profil', _ClientTab.profile),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ModernColors.surface,
        border: Border(top: BorderSide(color: ModernColors.line, width: 0.7)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              for (final item in items)
                Expanded(
                  child: _ClientNavItem(
                    icon: item.$1,
                    label: item.$2,
                    selected: _currentTab == item.$3,
                    onTap: () => _selectTab(item.$3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountDrawer() {
    final user = _user;
    return Drawer(
      backgroundColor: ModernColors.canvas,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AccountHeader(user: user),
            const SizedBox(height: 16),
            AccountSpaceSwitcher(
              currentSpace: AccountRoles.client,
              onBeforeNavigate: () => Navigator.maybePop(context),
            ),
            const SizedBox(height: 14),
            _DrawerTile(
              icon: Icons.sell_rounded,
              title: 'Vide-dressing',
              subtitle: '',
              onTap: () {
                Navigator.pop(context);
                _openSecondhand();
              },
            ),
            const SizedBox(height: 10),
            _DrawerTile(
              icon: Icons.info_outline_rounded,
              title: 'Aide',
              subtitle: '',
              onTap: () {
                Navigator.pop(context);
                _openAbout();
              },
            ),
            const SizedBox(height: 10),
            _DrawerTile(
              icon: AppIcons.logout,
              title: 'Se déconnecter',
              subtitle: '',
              danger: true,
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientTabCopy {
  const _ClientTabCopy({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  static _ClientTabCopy forTab(_ClientTab tab) {
    return switch (tab) {
      _ClientTab.salon => const _ClientTabCopy(title: 'Salon', subtitle: ''),
      _ClientTab.today => const _ClientTabCopy(
        title: 'Aujourd’hui',
        subtitle: '',
      ),
      _ClientTab.style => const _ClientTabCopy(title: 'Style', subtitle: ''),
      _ClientTab.wardrobe => const _ClientTabCopy(
        title: 'Garde-robe',
        subtitle: '',
      ),
      _ClientTab.profile => const _ClientTabCopy(title: 'Profil', subtitle: ''),
    };
  }
}

class _ClientNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ClientNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? ModernColors.primary : ModernColors.inkSoft;
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 3 : 5),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: compact ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? ModernColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: compact ? 18 : 20),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 9.5 : 10.8,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  final User? user;

  const _AccountHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName?.trim();
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: ModernColors.primary.withValues(alpha: 0.1),
            foregroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
            child:
                photoUrl.isEmpty
                    ? const Icon(AppIcons.profile, color: ModernColors.primary)
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name?.isNotEmpty == true ? name! : 'Espace client',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
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

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? ModernColors.rose : ModernColors.primary;
    return Material(
      color: ModernColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ModernColors.line),
          ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ModernColors.inkSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
