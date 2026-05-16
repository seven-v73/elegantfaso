import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/account_roles.dart';
import '../../../design/app_icons.dart';
import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';
import '../../../models/global/cart_item.dart';
import '../../../models/salon/salon_context.dart';
import '../../../services/global/cart_service.dart';
import '../../../services/location/salon_place_publisher_service.dart';
import '../auth/login_screen.dart';
import '../about/about_screen.dart';
import '../boutique/dashboard/boutique_dashboard.dart';
import '../createur/createur_dashboard_screen.dart';
import 'cart_screen.dart';
import 'tabs/agenda_tab.dart';
import 'tabs/boutique_tab.dart';
import 'tabs/createurs_tab.dart';
import 'tabs/decouvrir_tab.dart';
import 'tabs/inspiration_tab.dart';
import 'widgets/salon/salon_global_search.dart';
import 'widgets/salon/pro_story_rail.dart';
import 'widgets/location/salon_map_screen.dart';

class SalonModeBurkinabeScreen extends StatefulWidget {
  final bool embeddedInClientShell;

  const SalonModeBurkinabeScreen({
    super.key,
    this.embeddedInClientShell = false,
  });

  @override
  State<SalonModeBurkinabeScreen> createState() =>
      _SalonModeBurkinabeScreenState();
}

class SalonScreen extends StatelessWidget {
  const SalonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SalonModeBurkinabeScreen();
  }
}

class _SalonModeBurkinabeScreenState extends State<SalonModeBurkinabeScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;
  late final Future<AccountRoleState?> _accountStateFuture;
  final AccountRoleService _roleService = AccountRoleService();
  final SalonPlacePublisherService _placePublisher =
      SalonPlacePublisherService();

  Stream<List<CartItem>>? _salonCartItemsStream;
  int _currentTabIndex = 0;
  int _shopSeed = 0;
  int _talentSeed = 0;
  int _inspirationSeed = 0;
  int _agendaSeed = 0;
  String _shopQuery = '';
  String? _shopCategory;
  String _talentQuery = '';
  String? _talentRole;
  String _inspirationQuery = '';
  String? _inspirationTopic;
  String _agendaQuery = '';

  static const List<_SalonDestination> _tabDestinations = [
    _SalonDestination(
      label: 'Découvrir',
      shortLabel: 'Salon',
      icon: AppIcons.discover,
      color: ModernColors.primary,
    ),
    _SalonDestination(
      label: 'Shopping',
      shortLabel: 'Shop',
      icon: AppIcons.shop,
      color: ModernColors.shop,
    ),
    _SalonDestination(
      label: 'Talents',
      shortLabel: 'Talents',
      icon: AppIcons.talents,
      color: ModernColors.creator,
    ),
    _SalonDestination(
      label: 'Idées',
      shortLabel: 'Idées',
      icon: AppIcons.inspiration,
      color: ModernColors.client,
    ),
    _SalonDestination(
      label: 'Agenda',
      shortLabel: 'Agenda',
      icon: Icons.event_available_rounded,
      color: ModernColors.accent,
    ),
    _SalonDestination(
      label: 'Carte',
      shortLabel: 'Carte',
      icon: Icons.map_rounded,
      color: ModernColors.primary,
    ),
  ];

  static const List<_SalonDestination> _mainDestinations = [
    _SalonDestination(
      label: 'Découvrir',
      shortLabel: 'Salon',
      icon: AppIcons.discover,
      color: ModernColors.primary,
    ),
    _SalonDestination(
      label: 'Shopping',
      shortLabel: 'Shop',
      icon: AppIcons.shop,
      color: ModernColors.shop,
    ),
    _SalonDestination(
      label: 'Talents',
      shortLabel: 'Talents',
      icon: AppIcons.talents,
      color: ModernColors.creator,
    ),
    _SalonDestination(
      label: 'Idées',
      shortLabel: 'Idées',
      icon: AppIcons.inspiration,
      color: ModernColors.client,
    ),
    _SalonDestination(
      label: 'Agenda',
      shortLabel: 'Agenda',
      icon: Icons.event_available_rounded,
      color: ModernColors.accent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabDestinations.length,
      vsync: this,
    );
    _salonCartItemsStream = CartService.getCartStream();
    _accountStateFuture = _roleService.getCurrentState();
    _placePublisher.publishCurrentUserPlaces().catchError((_) {});
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fadeIn);

    _tabController.addListener(() {
      if (_currentTabIndex != _tabController.index) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });

    _entranceController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _showCartScreen() {
    if (!CartService.isSignedIn) {
      _showLoginPrompt(
        title: 'Connectez-vous pour utiliser le panier',
        message:
            'Vous pouvez explorer librement le Salon. La connexion est nécessaire pour ajouter au panier, commander ou sauvegarder vos coups de coeur.',
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => const CartScreen(),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _openSearch() {
    SalonGlobalSearch.show(
      context,
      onExploreContext: _openSalonContext,
      onLoginRequired: _openLogin,
    );
  }

  void _openSalonContext(SalonContext salonContext) {
    final query = salonContext.displayQuery;
    final type = salonContext.type.toLowerCase();
    final text = query.toLowerCase();
    if (text.contains('agenda') ||
        text.contains('event') ||
        text.contains('événement') ||
        text.contains('evenement') ||
        text.contains('défil') ||
        text.contains('defil') ||
        type.contains('événement') ||
        type.contains('evenement') ||
        text.contains('live')) {
      _openAgendaContext(query: query);
    } else if (type.contains('boutique')) {
      _openTalentContext(query: query, role: 'Boutique');
    } else if (type.contains('créateur') || type.contains('createur')) {
      _openTalentContext(query: query, role: 'Créateur');
    } else if (type.contains('coiff')) {
      _openTalentContext(query: query, role: 'Coiffure');
    } else if (type.contains('produit') ||
        type.contains('chauss') ||
        type.contains('tenue') ||
        type.contains('accessoire')) {
      _openShopContext(query: query, category: _shopCategoryFor(query));
    } else {
      _openInspirationContext(query: query, topic: _topicFor(query));
    }
  }

  String _shopCategoryFor(String query) {
    final text = query.toLowerCase();
    if (text.contains('coiff')) return 'Coiffures';
    if (text.contains('chauss')) return 'Chaussures';
    if (text.contains('accessoire')) return 'Accessoires';
    if (text.contains('mariage')) return 'Mariage';
    if (text.contains('homme')) return 'Hommes';
    if (text.contains('tenue') || text.contains('robe')) return 'Tenues';
    return 'Nouveautés';
  }

  String _topicFor(String query) {
    final text = query.toLowerCase();
    if (text.contains('coiff')) return 'Coiffures';
    if (text.contains('chauss')) return 'Chaussures';
    if (text.contains('mariage')) return 'Mariage';
    if (text.contains('homme')) return 'Hommes';
    if (text.contains('accessoire')) return 'Accessoires';
    if (text.contains('tenue') || text.contains('robe')) return 'Tenues';
    return 'Tous';
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  void _showLoginPrompt({required String title, required String message}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SalonLoginSheet(title: title, message: message),
    );
  }

  void _returnToWorkspace(String role) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    final destination =
        role == AccountRoles.boutique
            ? const BoutiqueDashboard()
            : const CreateurDashboardScreen();
    Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
  }

  _SalonContextAction? _workspaceAction(AccountRoleState? state) {
    final role = state?.activeRole;
    if (role == AccountRoles.createur) {
      return _SalonContextAction(
        label: 'Retour créateur',
        compactLabel: 'Créateur',
        tooltip: 'Retour à l’espace créateur',
        icon: AppIcons.creator,
        color: ModernColors.creator,
        onPressed: () => _returnToWorkspace(AccountRoles.createur),
      );
    }
    if (role == AccountRoles.boutique) {
      return _SalonContextAction(
        label: 'Retour boutique',
        compactLabel: 'Boutique',
        tooltip: 'Retour à l’espace boutique',
        icon: AppIcons.boutique,
        color: ModernColors.shop,
        onPressed: () => _returnToWorkspace(AccountRoles.boutique),
      );
    }
    return null;
  }

  void _openTab(int index) {
    HapticFeedback.selectionClick();
    _tabController.animateTo(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    setState(() => _currentTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 720;
    final isSignedIn = FirebaseAuth.instance.currentUser != null;
    final selectedMainIndex =
        _currentTabIndex < _mainDestinations.length ? _currentTabIndex : 0;

    return Scaffold(
      backgroundColor: ModernColors.canvas,
      bottomNavigationBar:
          isMobile && !widget.embeddedInClientShell
              ? NavigationBar(
                selectedIndex: selectedMainIndex,
                onDestinationSelected: _openTab,
                backgroundColor: ModernColors.surface,
                indicatorColor: _mainDestinations[selectedMainIndex].color
                    .withValues(alpha: 0.14),
                destinations: [
                  for (final destination in _mainDestinations)
                    NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(
                        destination.icon,
                        color: destination.color,
                      ),
                      label: destination.shortLabel,
                    ),
                ],
              )
              : null,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F8FA), Color(0xFFF3F5F7), ModernColors.canvas],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideIn,
                  child: Column(
                    children: [
                      FutureBuilder<AccountRoleState?>(
                        future: _accountStateFuture,
                        builder: (context, snapshot) {
                          return _SalonTopBar(
                            itemCountStream: _effectiveSalonCartItemsStream,
                            title: 'Salon',
                            subtitle: _subtitleForDestination(
                              _tabDestinations[_currentTabIndex],
                            ),
                            onCartPressed: _showCartScreen,
                            onSearchPressed: _openSearch,
                            onLogoPressed: _openAbout,
                            onLoginPressed: isSignedIn ? null : _openLogin,
                            backAction:
                                Navigator.canPop(context)
                                    ? _SalonContextAction(
                                      label: 'Retour',
                                      compactLabel: 'Retour',
                                      tooltip: 'Retour',
                                      icon: Icons.arrow_back_rounded,
                                      color: ModernColors.primary,
                                      onPressed: () => Navigator.pop(context),
                                    )
                                    : null,
                            workspaceAction: _workspaceAction(snapshot.data),
                          );
                        },
                      ),
                      if (isSignedIn && _currentTabIndex == 0)
                        const ProStoryRail(),
                      if (!isMobile || widget.embeddedInClientShell)
                        _SalonCompactNavigation(
                          destinations: _mainDestinations,
                          selectedIndex: selectedMainIndex,
                          onSelected: _openTab,
                          onMapSelected: () => _openTab(5),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(10, isMobile ? 4 : 2, 10, 0),
                  decoration: BoxDecoration(
                    color: ModernColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border.all(color: Colors.white, width: 1.1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120F172A),
                        offset: Offset(0, -8),
                        blurRadius: 22,
                        spreadRadius: -16,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(23),
                    ),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        DecouvrirTab(
                          onOpenShop: _openShopContext,
                          onOpenCreators: _openTalentContext,
                          onOpenInspiration: _openInspirationContext,
                          onOpenAgenda: () => _openTab(4),
                          onOpenMap: () => _openTab(5),
                          onLogin: _openLogin,
                        ),
                        BoutiqueTab(
                          key: ValueKey('shop-$_shopSeed'),
                          initialQuery: _shopQuery,
                          initialCategory: _shopCategory,
                        ),
                        CreateursTab(
                          key: ValueKey('talents-$_talentSeed'),
                          initialQuery: _talentQuery,
                          initialRole: _talentRole,
                        ),
                        InspirationTab(
                          key: ValueKey('inspiration-$_inspirationSeed'),
                          initialQuery: _inspirationQuery,
                          initialTopic: _inspirationTopic,
                        ),
                        AgendaTab(
                          key: ValueKey('agenda-$_agendaSeed'),
                          initialQuery: _agendaQuery,
                        ),
                        const SalonMapScreen(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openShopContext({
    String? query,
    String? category,
    String? role,
    String? topic,
  }) {
    setState(() {
      _shopQuery = query ?? '';
      _shopCategory = category;
      _shopSeed++;
    });
    _openTab(1);
  }

  void _openTalentContext({
    String? query,
    String? category,
    String? role,
    String? topic,
  }) {
    setState(() {
      _talentQuery = query ?? '';
      _talentRole = role;
      _talentSeed++;
    });
    _openTab(2);
  }

  void _openInspirationContext({
    String? query,
    String? category,
    String? role,
    String? topic,
  }) {
    setState(() {
      _inspirationQuery = query ?? '';
      _inspirationTopic = topic;
      _inspirationSeed++;
    });
    _openTab(3);
  }

  void _openAgendaContext({String? query}) {
    setState(() {
      _agendaQuery = query ?? '';
      _agendaSeed++;
    });
    _openTab(4);
  }

  Stream<List<CartItem>> get _effectiveSalonCartItemsStream =>
      _salonCartItemsStream ??= CartService.getCartStream();

  static String _subtitleForDestination(_SalonDestination destination) {
    switch (destination.label) {
      case 'Shopping':
        return 'Produits et pièces du Salon';
      case 'Talents':
        return 'Ateliers, boutiques et savoir-faire';
      case 'Idées':
        return 'Inspirations et moodboards';
      case 'Agenda':
        return 'Événements et rendez-vous';
      case 'Carte':
        return 'Autour de vous';
      default:
        return 'Découvrir, acheter, rencontrer';
    }
  }
}

class _SalonDestination {
  const _SalonDestination({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
  });

  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;
}

class _SalonContextAction {
  const _SalonContextAction({
    required this.label,
    required this.compactLabel,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String compactLabel;
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
}

class _SalonTopBar extends StatelessWidget {
  const _SalonTopBar({
    required this.itemCountStream,
    required this.title,
    required this.subtitle,
    required this.onCartPressed,
    required this.onSearchPressed,
    required this.onLogoPressed,
    this.onLoginPressed,
    this.backAction,
    this.workspaceAction,
  });

  final Stream<List<CartItem>> itemCountStream;
  final String title;
  final String subtitle;
  final VoidCallback onCartPressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onLogoPressed;
  final VoidCallback? onLoginPressed;
  final _SalonContextAction? backAction;
  final _SalonContextAction? workspaceAction;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 430;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Row(
        children: [
          if (backAction != null)
            _SalonShortcutButton(action: backAction!, iconOnly: true)
          else
            Tooltip(
              message: 'À propos de ElegantStyle',
              child: InkWell(
                onTap: onLogoPressed,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: ModernColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 1.1),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (workspaceAction != null) ...[
            _SalonShortcutButton(action: workspaceAction!, iconOnly: isCompact),
            const SizedBox(width: 8),
          ],
          if (onLoginPressed != null) ...[
            _SalonLoginButton(onPressed: onLoginPressed!, iconOnly: isCompact),
            const SizedBox(width: 8),
          ],
          _SalonTopIconButton(
            icon: Icons.search_rounded,
            tooltip: 'Rechercher',
            onPressed: onSearchPressed,
          ),
          const SizedBox(width: 8),
          StreamBuilder<List<CartItem>>(
            stream: itemCountStream,
            builder: (context, snapshot) {
              final itemCount = CartService.getTotalItemCount(
                snapshot.data ?? const [],
              );
              return _CartActionButton(
                itemCount: itemCount,
                onPressed: onCartPressed,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SalonLoginButton extends StatelessWidget {
  const _SalonLoginButton({required this.onPressed, required this.iconOnly});

  final VoidCallback onPressed;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    if (iconOnly) {
      return _SalonTopIconButton(
        icon: Icons.login_rounded,
        tooltip: 'Connexion',
        selected: true,
        onPressed: onPressed,
      );
    }
    return AppButton(
      label: 'Connexion',
      icon: Icons.login_rounded,
      onPressed: onPressed,
      compact: true,
    );
  }
}

class _SalonTopIconButton extends StatelessWidget {
  const _SalonTopIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    this.color = ModernColors.primary,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      style: IconButton.styleFrom(
        backgroundColor: selected ? color : ModernColors.surfaceRaised,
        foregroundColor: selected ? Colors.white : color,
        disabledBackgroundColor: ModernColors.line.withValues(alpha: 0.45),
        disabledForegroundColor: ModernColors.muted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: selected ? color.withValues(alpha: 0.4) : ModernColors.line,
        ),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _SalonLoginSheet extends StatelessWidget {
  const _SalonLoginSheet({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ModernShadows.elevated,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: ModernColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.lock_open_rounded,
                    color: ModernColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: ModernColors.inkSoft,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalonShortcutButton extends StatelessWidget {
  const _SalonShortcutButton({required this.action, required this.iconOnly});

  final _SalonContextAction action;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    if (iconOnly) {
      return _SalonTopIconButton(
        icon: action.icon,
        tooltip: action.tooltip,
        color: action.color,
        onPressed: action.onPressed,
      );
    }
    return AppButton(
      label: action.compactLabel,
      icon: action.icon,
      variant: AppButtonVariant.secondary,
      compact: true,
      onPressed: action.onPressed,
    );
  }
}

class _CartActionButton extends StatelessWidget {
  const _CartActionButton({required this.itemCount, required this.onPressed});

  final int itemCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _SalonTopIconButton(
          icon: AppIcons.cart,
          tooltip: 'Panier',
          onPressed: onPressed,
        ),
        if (itemCount > 0)
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: ModernColors.accent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: ModernColors.surface, width: 2),
              ),
              child: Text(
                itemCount > 99 ? '99+' : '$itemCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SalonCompactNavigation extends StatelessWidget {
  const _SalonCompactNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.onMapSelected,
  });

  final List<_SalonDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onMapSelected;

  @override
  Widget build(BuildContext context) {
    final selected = destinations[selectedIndex];
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      decoration: BoxDecoration(
        color: ModernColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(selected.icon, color: selected.color, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${selected.label} · ${_hintFor(selected.label)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Tooltip(
                message: 'Carte',
                child: InkWell(
                  onTap: onMapSelected,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: ModernColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: ModernColors.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: ModernColors.primary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: destinations.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final destination = destinations[index];
                final isSelected = selectedIndex == index;
                return _SalonNavChip(
                  destination: destination,
                  selected: isSelected,
                  onTap: () => onSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _hintFor(String label) {
    return switch (label) {
      'Shopping' => 'acheter',
      'Talents' => 'rencontrer',
      'Idées' => 's’inspirer',
      'Agenda' => 'sortir',
      _ => 'explorer',
    };
  }
}

class _SalonNavChip extends StatelessWidget {
  const _SalonNavChip({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _SalonDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color:
            selected
                ? destination.color.withValues(alpha: 0.12)
                : ModernColors.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              selected
                  ? destination.color.withValues(alpha: 0.35)
                  : ModernColors.line,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  destination.icon,
                  color: selected ? destination.color : ModernColors.inkSoft,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  destination.shortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? destination.color : ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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
