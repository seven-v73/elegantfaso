import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'home_content_screen.dart';
import '../features/trends_screen.dart';
import '../features/virtual_try_on_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../features/style/style_hub_screen.dart';
import '../../global/salon_mode_burkinabe.dart';
import '../../base/client_profile_screen.dart';
import '../../auth/login_screen.dart';
import '../../auth/role_guard.dart';
import 'user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  User? _user;
  int _currentIndex = 0;
  bool _initialPositionSet = false;

  // Contrôleurs d'animation
  late AnimationController _navBubbleController;
  late AnimationController _navExpandController;
  late AnimationController _pulseController;
  late AnimationController _profileMenuController;
  late AnimationController _backgroundColorController;
  late AnimationController _screenTransitionController;

  // Position et état de la bulle
  Offset _navPosition = Offset.zero;
  bool _isNavExpanded = false;
  bool _isDragging = false;
  bool _isProfileMenuOpen = false;
  Size _screenSize = Size.zero;
  EdgeInsets _screenPadding = EdgeInsets.zero;

  late List<NavItem> _navItems;
  late UserService _userService;
  Widget _currentScreen = Container();

  // Palette de couleurs optimisée
  static const _primaryColor = Color(0xFF6A11CB);
  static const _secondaryColor = Color(0xFF2575FC);
  static const _accentColor = Color(0xFF8E2DE2);
  static const _backgroundColor = Color(0xFFF8F9FA);
  static const _textColor = Color(0xFF2C3E50);
  static const _salonColor = Color(0xFF00BFA6);
  static const _profileColor = Color(0xFF8E24AA);
  static const _profileGradient = LinearGradient(
    colors: [Color(0xFF8E24AA), Color(0xFFAB47BC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cache pour les données utilisateur
  Map<String, dynamic>? _cachedUserData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeControllers();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) {
      _updateScreenDimensions();
      _constrainBubblePosition();
    }
  }

  void _initializeApp() {
    _user = FirebaseAuth.instance.currentUser;
    _userService = UserService();
    _initializeNavItems();
    _initializeAnimations();
    _setupAuthListener();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateScreenDimensions();
        _initializeBubblePosition();
        _precacheUserData();
      }
    });
  }

  void _disposeControllers() {
    _navBubbleController.dispose();
    _navExpandController.dispose();
    _pulseController.dispose();
    _profileMenuController.dispose();
    _backgroundColorController.dispose();
    _screenTransitionController.dispose();
  }

  void _initializeAnimations() {
    const animationDuration = Duration(milliseconds: 800);

    _navBubbleController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );

    _navExpandController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _profileMenuController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );

    _backgroundColorController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );

    _screenTransitionController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );

    _navBubbleController.forward();
    _backgroundColorController.forward();
  }

  void _initializeNavItems() {
    _navItems = [
      NavItem(
        icon: Icons.home_rounded,
        label: 'Accueil',
        screen:  HomeScreenContent(),
        color: _primaryColor,
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      NavItem(
        icon: Icons.trending_up_rounded,
        label: 'Tendances',
        screen: TrendScreen(),
        color: const Color(0xFFE91E63),
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFF06292)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      NavItem(
        icon: Icons.camera_rounded,
        label: 'Essayage',
        screen: const VirtualTryOnScreen(),
        color: const Color(0xFF9C27B0),
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      NavItem(
        icon: Icons.brush_rounded,
        label: 'Mon Style',
        screen: const StyleHubScreen(),
        color: const Color(0xFF673AB7),
        gradient: const LinearGradient(
          colors: [Color(0xFF673AB7), Color(0xFF9575CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      NavItem(
        icon: Icons.handshake,
        label: 'Réseau Mode',
        screen: const MarketplaceScreen(),
        color: const Color(0xFF2196F3),
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      NavItem(
        icon: Icons.lightbulb_rounded,
        label: 'Salon',
        screen: const SalonModeBurkinabeScreen(),
        color: _salonColor,
        gradient: const LinearGradient(
          colors: [Color(0xFF00BFA6), Color(0xFF64FFDA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ];
    _currentScreen = _navItems.first.screen;
  }

  void _updateScreenDimensions() {
    final mediaQuery = MediaQuery.of(context);
    if (mounted) {
      setState(() {
        _screenSize = mediaQuery.size;
        _screenPadding = mediaQuery.padding;
      });
    }
  }

  void _initializeBubblePosition() {
    if (!_initialPositionSet && _screenSize.width > 0 && _screenSize.height > 0) {
      if (mounted) {
        setState(() {
          _navPosition = Offset(
            _screenSize.width - 90 - _screenPadding.right,
            _screenSize.height * 0.7 - _screenPadding.bottom,
          );
          _initialPositionSet = true;
        });
        _constrainBubblePosition();
      }
    }
  }

  void _constrainBubblePosition() {
    const double bubbleSize = 70.0;
    double safeLeft = _screenPadding.left + 10;
    double safeTop = _screenPadding.top + 10;
    double safeRight = _screenSize.width - bubbleSize - _screenPadding.right - 10;
    double safeBottom = _screenSize.height - bubbleSize - _screenPadding.bottom - 10;

    if (mounted) {
      setState(() {
        _navPosition = Offset(
          _navPosition.dx.clamp(safeLeft, safeRight),
          _navPosition.dy.clamp(safeTop, safeBottom),
        );
      });
    }
  }

  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _user = user;
          if (user == null) {
            _cachedUserData = null;
          }
        });
      }
    });
  }

  void _precacheUserData() async {
    if (_user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user?.uid)
          .get();

      if (mounted) {
        setState(() {
          _cachedUserData = doc.data();
        });
      }
    }
  }

  void _updateDynamicBackground() {
    if (!mounted) return;

    _backgroundColorController.reverse().then((_) {
      if (mounted && _navItems.isNotEmpty) {
        _backgroundColorController.forward();
      }
    });
  }

  void _toggleNavExpansion() {
    if (!mounted) return;

    setState(() {
      _isNavExpanded = !_isNavExpanded;
      if (_isNavExpanded && _isProfileMenuOpen) {
        _isProfileMenuOpen = false;
        _profileMenuController.reverse();
      }
    });

    if (_isNavExpanded) {
      _navExpandController.forward();
      HapticFeedback.mediumImpact();
    } else {
      _navExpandController.reverse();
    }
  }

  void _toggleProfileMenu() {
    if (!mounted) return;

    setState(() {
      _isProfileMenuOpen = !_isProfileMenuOpen;
      if (_isProfileMenuOpen && _isNavExpanded) {
        _isNavExpanded = false;
        _navExpandController.reverse();
      }
    });

    if (_isProfileMenuOpen) {
      _profileMenuController.forward();
      HapticFeedback.mediumImpact();
    } else {
      _profileMenuController.reverse();
    }
  }

  void _changeScreen(int index, Widget screen) {
    if (index == _currentIndex || index < 0 || index >= _navItems.length) return;
    if (!mounted) return;

    setState(() {
      _currentIndex = index;
      _currentScreen = screen;
      _isNavExpanded = false;
    });

    _updateDynamicBackground();
    _navExpandController.reverse();
    _screenTransitionController.forward(from: 0.0);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Arrière-plan dynamique
                AnimatedBuilder(
                  animation: _backgroundColorController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topRight,
                          radius: 1.5,
                          colors: [
                            _backgroundColor,
                            _backgroundColor.withOpacity(0.9),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Écran principal
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: _currentScreen,
                ),

                // Overlay pour les menus
                _buildOverlay(),

                // Bulle de navigation
                if (_initialPositionSet) _buildFloatingNavigation(),

                // Menu étendu
                if (_isNavExpanded) _buildExpandedMenuOverlay(),

                // Menu profil
                if (_isProfileMenuOpen) _buildProfileMenuOverlay(),
              ],
            );
          }
      ),
    );
  }

  Widget _buildOverlay() {
    return IgnorePointer(
      ignoring: !_isNavExpanded && !_isProfileMenuOpen,
      child: AnimatedOpacity(
        opacity: _isNavExpanded || _isProfileMenuOpen ? 0.4 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(color: Colors.black),
      ),
    );
  }

  Widget _buildExpandedMenuOverlay() {
    return Positioned.fill(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildExpandedMenu(),
        ),
      ),
    );
  }

  Widget _buildProfileMenuOverlay() {
    return Positioned.fill(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildProfileMenu(),
        ),
      ),
    );
  }

  Widget _buildFloatingNavigation() {
    const double bubbleSize = 70.0;

    return Positioned(
      left: _navPosition.dx,
      top: _navPosition.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) {
          setState(() => _isDragging = true);
          HapticFeedback.selectionClick();
        },
        onPanUpdate: (details) {
          setState(() {
            _navPosition += details.delta;
            _constrainBubblePosition();
          });
        },
        onPanEnd: (details) {
          setState(() => _isDragging = false);
          HapticFeedback.lightImpact();

          final centerX = _screenSize.width / 2;
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && !_isDragging) {
              setState(() {
                _navPosition = Offset(
                  _navPosition.dx < centerX
                      ? _screenPadding.left + 10
                      : _screenSize.width - bubbleSize - _screenPadding.right - 10,
                  _navPosition.dy,
                );
                _constrainBubblePosition();
              });
            }
          });
        },
        onTap: _toggleNavExpansion,
        child: AnimatedScale(
          scale: _isDragging ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Bulle principale
              Container(
                width: bubbleSize,
                height: bubbleSize,
                decoration: BoxDecoration(
                  gradient: _navItems[_currentIndex].gradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _navItems[_currentIndex].color.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 2,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isNavExpanded ? Icons.close_rounded : Icons.apps_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

              // Indicateur de page
              if (!_isNavExpanded && !_isProfileMenuOpen)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: _navItems[_currentIndex].color,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${_currentIndex + 1}',
                        style: TextStyle(
                          color: _navItems[_currentIndex].color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildExpandedMenu() {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _navItems[_currentIndex].color.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 5,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuHeader(),
                    const SizedBox(height: 20),
                    _buildNavGrid(),
                    const SizedBox(height: 20),
                    _buildProfileButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _navItems.length,
      itemBuilder: (context, index) {
        final item = _navItems[index];
        final isActive = _currentIndex == index;

        return GestureDetector(
          onTap: () => _changeScreen(index, item.screen),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            decoration: BoxDecoration(
              gradient: isActive
                  ? item.gradient
                  : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isActive
                    ? item.color.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? item.color.withOpacity(0.2)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: isActive ? 15 : 8,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: isActive ? Colors.white : item.color,
                  size: 26,
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : item.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuHeader() {
    final userName = _cachedUserData?['name'] ??
        _user?.displayName ??
        'Utilisateur';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: _navItems[_currentIndex].gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _navItems[_currentIndex].color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SvgPicture.asset(
              'assets/logo/logo.svg',
              height: 24,
              width: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ElegantFaso',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _navItems[_currentIndex].color,
                  ),
                ),
                Text(
                  'Bonjour, $userName !',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    return GestureDetector(
      onTap: _toggleProfileMenu,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: _profileGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _profileColor.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Mon Espace',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu() {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _profileColor.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 5,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    _buildProfileOption(
                      icon: Icons.person_outline_rounded,
                      title: 'Mon Profil',
                      subtitle: 'Gérer les informations',
                      onTap: () {
                        _toggleProfileMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ClientProfileScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildProfileOption(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Gérer vos alertes',
                      onTap: () {
                        _toggleProfileMenu();
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen()));
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final userName = _cachedUserData?['name'] ??
        _user?.displayName ??
        'Utilisateur';
    final userEmail = _cachedUserData?['email'] ??
        _user?.email ??
        'email@example.com';
    final userAvatar = _cachedUserData?['avatar'] ?? _user?.photoURL;

    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _profileGradient,
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _profileColor.withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(37),
            child: userAvatar != null
                ? CachedNetworkImage(
              imageUrl: userAvatar,
              width: 74,
              height: 74,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: Icon(
                  Icons.person_rounded,
                  size: 36,
                  color: Colors.grey[400],
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: Icon(
                  Icons.person_rounded,
                  size: 36,
                  color: Colors.grey[400],
                ),
              ),
            )
                : Container(
              decoration: BoxDecoration(
                gradient: _profileGradient,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          userName,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          userEmail,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _profileColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: _profileColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              'Déconnexion',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
            content: Text(
              'Êtes-vous sûr de vouloir vous déconnecter ?',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Déconnecter',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ) ?? false;

        if (shouldLogout) {
          _toggleProfileMenu();
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.red.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.red[600],
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Se déconnecter',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  final Widget screen;
  final Color color;
  final LinearGradient gradient;

  NavItem({
    required this.icon,
    required this.label,
    required this.screen,
    required this.color,
    required this.gradient,
  });
}