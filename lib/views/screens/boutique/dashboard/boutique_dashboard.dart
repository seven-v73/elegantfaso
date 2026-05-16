import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegantfaso/views/screens/boutique/products/boutique_products_screen.dart';
import 'package:elegantfaso/views/screens/boutique/orders/boutique_orders_screen.dart';
import 'package:elegantfaso/views/screens/boutique/profile/boutique_profile_screen.dart';
import 'package:elegantfaso/views/screens/boutique/notifications/boutique_notifications_screen.dart';
import 'package:elegantfaso/views/screens/boutique/appointment/boutique_appointments_screen.dart';
import 'package:elegantfaso/views/screens/auth/login_screen.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/account_roles.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/modern_design_system.dart';
import '../../../widgets/account/account_space_switcher.dart';
import '../../../widgets/commerce/pro_growth_banner.dart';
import '../../../widgets/notifications/notification_bell_button.dart';
import '../../auth/role_guard.dart';
import '../../commerce/pro_style_guide_composer_screen.dart';
import '../../commerce/pro_story_publish_screen.dart';
import 'package:elegantfaso/views/screens/boutique/dashboard/boutique_home_screen.dart';
import 'package:elegantfaso/views/screens/boutique/customers/boutique_customers_screen.dart';
import '../../commerce/plan_visibility_screen.dart';
import '../../global/salon_mode_burkinabe.dart';
import '../../messages/messages_entry_screen.dart';

// ---- Palette moderne et cohérente ----
class _AppColors {
  static const primary = ModernColors.shop;
  static const accent = ModernColors.rose;
  static const background = ModernColors.canvas;
  static const surface = ModernColors.surface;
  static const textPrimary = ModernColors.ink;
  static const textSecondary = ModernColors.inkSoft;
  static const divider = ModernColors.line;
}

class BoutiqueDashboard extends StatefulWidget {
  const BoutiqueDashboard({super.key});

  @override
  State<BoutiqueDashboard> createState() => _BoutiqueDashboardState();
}

class _BoutiqueDashboardState extends State<BoutiqueDashboard> {
  static const int _pageCount = 5;

  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final List<Widget> _pages = [
    BoutiqueHomeScreen(onTabSelected: _changeTab),
    const BoutiqueProductsScreen(),
    const BoutiqueOrdersScreen(),
    const BoutiqueAppointmentsScreen(),
    const BoutiqueProfileScreen(),
  ];

  void _changeTab(int index) {
    if (!mounted ||
        index == _currentIndex ||
        index < 0 ||
        index >= _pageCount) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      expectedRole: 'boutique',
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _AppColors.background,
        // L'AppBar est fixe et propre
        appBar: _buildAppBar(),
        // IndexedStack sans animation superflue : plus fluide et immédiat
        body: Column(
          children: [
            const ProGrowthBanner(
              role: AccountRoles.boutique,
              accent: ModernColors.shop,
            ),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          ],
        ),
        // Barre inférieure moderne
        bottomNavigationBar: _buildBottomNavBar(),
        drawer: _buildAppDrawer(),
      ),
    );
  }

  // ---- APP BAR ----
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ModernColors.shop.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: ModernColors.shop,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
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
                    fontWeight: FontWeight.w900,
                    color: ModernColors.ink,
                    fontSize: 17,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Boutique',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
      centerTitle: false,
      backgroundColor: ModernColors.surface,
      foregroundColor: ModernColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: ModernColors.ink),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Publier',
          icon: const Icon(
            Icons.add_circle_outline_rounded,
            color: ModernColors.shop,
          ),
          color: ModernColors.surface,
          onSelected: _handlePublishAction,
          itemBuilder:
              (context) => const [
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
          userId: currentUser?.uid,
          badgeColor: _AppColors.accent,
          onPressed: _handleNotifications,
        ),
        IconButton(
          tooltip: 'Messages',
          onPressed: _openMessages,
          icon: const Icon(AppIcons.messages, color: ModernColors.ink),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ---- BOTTOM NAVIGATION ----
  Widget _buildBottomNavBar() {
    // Suppression de l'ombre lourde et des bordures arrondies exagérées
    return Container(
      decoration: const BoxDecoration(
        color: _AppColors.surface,
        border: Border(top: BorderSide(color: _AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_pageCount, (index) {
              const items = [
                (FeatherIcons.home, 'Accueil'),
                (AppIcons.shop, 'Produits'),
                (AppIcons.orders, 'Cmd'),
                (AppIcons.appointments, 'RDV'),
                (AppIcons.profile, 'Profil'),
              ];
              final isSelected = _currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTabTapped(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? _AppColors.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          items[index].$1,
                          size: 22,
                          color:
                              isSelected
                                  ? _AppColors.primary
                                  : _AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[index].$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color:
                              isSelected
                                  ? _AppColors.primary
                                  : _AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ---- DRAWER ----
  Widget _buildAppDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      child: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser?.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerDrawer();
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Boutique introuvable',
                style: TextStyle(color: _AppColors.textSecondary),
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final boutiqueName =
              userData['boutiqueName']?.toString() ??
              userData['shopProfile']?['name']?.toString() ??
              'Ma Boutique';
          final boutiqueEmail = userData['email']?.toString() ?? '';
          final imageUrl =
              userData['boutiquePhotoUrl']?.toString() ??
              userData['boutiqueLogoUrl']?.toString() ??
              userData['shopProfile']?['logoUrl']?.toString() ??
              userData['photoUrl']?.toString() ??
              userData['photoURL']?.toString();
          final followers = List<String>.from(userData['followers'] ?? []);

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête épuré
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: _AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        backgroundImage:
                            (imageUrl != null && imageUrl.isNotEmpty)
                                ? NetworkImage(imageUrl)
                                : null,
                        child:
                            (imageUrl == null || imageUrl.isEmpty)
                                ? const Icon(
                                  FeatherIcons.shoppingBag,
                                  color: _AppColors.primary,
                                  size: 24,
                                )
                                : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              boutiqueName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: _AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (boutiqueEmail.isNotEmpty)
                              Text(
                                boutiqueEmail,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _AppColors.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  FeatherIcons.users,
                                  size: 14,
                                  color: _AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${followers.length} followers',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: _AppColors.divider,
                ),
                // Liste des options
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 20, top: 16, bottom: 8),
                        child: Text(
                          'ESPACE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _AppColors.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      _buildDrawerAction(
                        FeatherIcons.compass,
                        'Salon',
                        _openSalonFromDrawer,
                      ),
                      _buildDrawerAction(
                        FeatherIcons.users,
                        'Clients',
                        _openCustomersFromDrawer,
                      ),
                      _buildDrawerAction(
                        Icons.workspace_premium_rounded,
                        'Plan & visibilité',
                        _openPlanFromDrawer,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 20, top: 16, bottom: 8),
                        child: Text(
                          'COMPTE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _AppColors.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      AccountSpaceSwitcher(
                        currentSpace: AccountRoles.boutique,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        onBeforeNavigate: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: _AppColors.divider,
                ),
                _buildLogoutButton(),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- SHIMMER DRAWER ----
  Widget _buildShimmerDrawer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  const CircleAvatar(radius: 28, backgroundColor: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 120, height: 16, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 80, height: 12, color: Colors.white),
                        const SizedBox(height: 10),
                        Container(width: 60, height: 12, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white),
            ...List.generate(
              6,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(width: 24, height: 24, color: Colors.white),
                    const SizedBox(width: 16),
                    Container(width: 100, height: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerAction(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: _AppColors.primary.withValues(alpha: 0.05),
        highlightColor: _AppColors.primary.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: _AppColors.textSecondary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: _AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                FeatherIcons.externalLink,
                size: 16,
                color: _AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(
          FeatherIcons.logOut,
          size: 20,
          color: _AppColors.accent,
        ),
        label: const Text(
          'Déconnexion',
          style: TextStyle(
            color: _AppColors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: _AppColors.accent.withValues(alpha: 0.08),
        ),
      ),
    );
  }

  // ---- ACTIONS ----
  void _onTabTapped(int index) {
    if (!mounted ||
        index == _currentIndex ||
        index < 0 ||
        index >= _pageCount) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleNotifications() {
    Navigator.push(
      context,
      PageRouteBuilder(
        settings: const RouteSettings(name: '/boutique/notifications'),
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const BoutiqueNotificationsScreen(),
        // Simple fondu au lieu d'un slide depuis le bas
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _handlePublishAction(String value) {
    switch (value) {
      case 'story':
        _openStoryPublisher();
      case 'guide':
        _openGuidePublisher();
    }
  }

  void _openSalon() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SalonModeBurkinabeScreen()),
    );
  }

  void _openMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                const MessagesEntryScreen(roleOverride: AccountRoles.boutique),
      ),
    );
  }

  void _openStoryPublisher() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => const ProStoryPublishScreen(role: AccountRoles.boutique),
      ),
    );
  }

  void _openGuidePublisher() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                const ProStyleGuideComposerScreen(role: AccountRoles.boutique),
      ),
    );
  }

  void _openPlanVisibility() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => const PlanVisibilityScreen(
              role: AccountRoles.boutique,
              accent: ModernColors.shop,
            ),
      ),
    );
  }

  void _openSalonFromDrawer() {
    Navigator.pop(context);
    _openSalon();
  }

  void _openPlanFromDrawer() {
    Navigator.pop(context);
    _openPlanVisibility();
  }

  void _openCustomersFromDrawer() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BoutiqueCustomersScreen()),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Erreur déconnexion boutique: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Déconnexion impossible pour le moment.'),
          backgroundColor: _AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
