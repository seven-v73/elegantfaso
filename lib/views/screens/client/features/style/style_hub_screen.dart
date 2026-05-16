import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../models/client/client_dashboard_summary.dart';
import '../../../../../services/client/client_dashboard_service.dart';
import '../../../global/salon_search_screen.dart';
import '../../widgets/client_saved_rail.dart';
import '../virtual_try_on_screen.dart';
import 'chat_screen.dart';
import 'fashion_assistant.dart';
import 'garde_robe.dart';
import 'mesurement.dart';

class StyleHubScreen extends StatefulWidget {
  const StyleHubScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<StyleHubScreen> createState() => _StyleHubScreenState();
}

class _StyleHubScreenState extends State<StyleHubScreen>
    with SingleTickerProviderStateMixin {
  static const Color _background = Color(0xFFF5F6F8);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF667085);
  static const Color _line = Color(0xFFE4E7EC);
  static const Color _primary = Color(0xFF0F766E);
  static const Color _rose = Color(0xFFE11D48);
  static const Color _blue = Color(0xFF2563EB);

  late final AnimationController _introController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  final ClientDashboardService _dashboardService = ClientDashboardService();

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      duration: const Duration(milliseconds: 520),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );
    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 380;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 16 : 20,
                      18,
                      isCompact ? 16 : 20,
                      18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 14),
                        _buildHeroCard(isCompact),
                        const SizedBox(height: 12),
                        _buildToolRail(),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildFavoritesStarter(isCompact)),
                const SliverToBoxAdapter(child: SizedBox(height: 92)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _IconButtonSurface(
          icon: widget.showBackButton ? Icons.arrow_back : AppIcons.style,
          onTap: () {
            HapticFeedback.selectionClick();
            if (widget.showBackButton && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Style',
                style: TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Conseil · Tailles · Dressing',
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A111827),
            offset: Offset(0, 14),
            blurRadius: 24,
            spreadRadius: -16,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -18,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(
                width: 112,
                height: 56,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -22,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isCompact ? 18 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(AppIcons.style, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'Studio Style',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 27 : 31,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Composer, essayer, ajuster.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: () => _navigateToOutfits(context),
                          icon: const Icon(AppIcons.recommendations, size: 18),
                          label: const Text('Composer'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _ink,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: FilledButton.tonalIcon(
                          onPressed: () => _navigateToTryOn(context),
                          icon: const Icon(Icons.view_in_ar_rounded, size: 18),
                          label: const Text('Essayage'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolRail() {
    return Row(
      children: [
        Expanded(
          child: _StyleToolButton(
            icon: AppIcons.messages,
            label: 'Avis',
            color: _primary,
            onTap: () => _navigateToChat(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StyleToolButton(
            icon: AppIcons.measurements,
            label: 'Tailles',
            color: _blue,
            onTap: () => _navigateToMeasurements(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StyleToolButton(
            icon: AppIcons.wardrobe,
            label: 'Dressing',
            color: _rose,
            onTap: () => _navigateToWardrobe(context),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyFavorites(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(AppIcons.salon, color: _primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ajoutez des favoris depuis le Salon.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Salon',
            onPressed: () => _openSalonSearch(context, ''),
            icon: const Icon(AppIcons.salon),
            style: IconButton.styleFrom(
              backgroundColor: _primary.withValues(alpha: 0.1),
              foregroundColor: _primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title}) {
    return Text(
      title,
      style: const TextStyle(
        color: _ink,
        fontSize: 20,
        height: 1.15,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }

  Widget _buildFavoritesStarter(bool isCompact) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<ClientDashboardSummary>(
      stream: _dashboardService.watchSummary(user.uid),
      builder: (context, snapshot) {
        final items = snapshot.data?.savedItems.take(6).toList() ?? const [];

        return Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 16 : 20,
            20,
            isCompact ? 16 : 20,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(title: 'Favoris'),
              const SizedBox(height: 12),
              if (items.isEmpty)
                _buildEmptyFavorites(context)
              else
                ClientSavedRail(
                  items: items,
                  onSeeAll: () => _navigateToWardrobe(context),
                  onTapItem: (_) => _navigateToWardrobe(context),
                  onTryOn: (_) => _navigateToTryOn(context),
                  onFindVendor: (item) => _openSalonSearch(context, item.title),
                  onAskAdvice: (_) => _navigateToChat(context),
                  onCreateLook: (_) => _navigateToOutfits(context),
                ),
            ],
          ),
        );
      },
    );
  }

  static BoxDecoration _cardDecoration({double radius = 14}) {
    return BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F0F172A),
          offset: Offset(0, 8),
          blurRadius: 18,
          spreadRadius: -12,
        ),
      ],
    );
  }

  void _navigateToChat(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      _showLoginSnackBar(context);
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder:
            (context, animation, secondaryAnimation) => const ChatScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToOutfits(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        pageBuilder:
            (context, animation, _) => const BurkinabeFashionAssistant(),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToMeasurements(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const ProfileMeasurementsPage(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToTryOn(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const VirtualTryOnScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _navigateToWardrobe(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, _) => WardrobeScreen(),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showLoginSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Connectez-vous pour ouvrir le conseil style.'),
        backgroundColor: _rose,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openSalonSearch(BuildContext context, String query) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SalonSearchScreen(initialQuery: query)),
    );
  }
}

class _StyleToolButton extends StatelessWidget {
  const _StyleToolButton({
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
    return Material(
      color: _StyleHubScreenState._surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _StyleHubScreenState._line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _StyleHubScreenState._ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButtonSurface extends StatelessWidget {
  const _IconButtonSurface({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: _StyleHubScreenState._cardDecoration(radius: 14),
          child: Icon(icon, color: _StyleHubScreenState._ink, size: 21),
        ),
      ),
    );
  }
}
