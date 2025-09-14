import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animations/animations.dart';
import 'package:elegantfaso/views/screens/boutique/products/boutique_products_screen.dart';
import 'package:elegantfaso/views/screens/boutique/orders/boutique_orders_screen.dart';
import 'package:elegantfaso/views/screens/boutique/customers/boutique_customers_screen.dart';
import 'package:elegantfaso/views/screens/boutique/features/stats_screen.dart';
import 'package:elegantfaso/views/screens/boutique/features/galerie.dart';
import 'package:elegantfaso/views/screens/boutique/features/avis.dart';
import 'package:elegantfaso/views/screens/boutique/features/settings.dart';
import 'package:elegantfaso/views/screens/boutique/features/help.dart';
import 'package:shimmer/shimmer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GreetingService {
  // Modèle pour une période de salutation
  static const Map<String, dynamic> _greetingPeriods = {
    'earlyMorning': {
      'start': 5,
      'end': 8,
      'greeting': 'Bonjour tôt',
      'emoji': '🌅',
      'description': 'Lever du soleil',
      'color': Color(0xFFFFA726),
    },
    'morning': {
      'start': 8,
      'end': 12,
      'greeting': 'Bonjour',
      'emoji': '☀️',
      'description': 'Matinée',
      'color': Color(0xFFFFD54F),
    },
    'afternoon': {
      'start': 12,
      'end': 17,
      'greeting': 'Bon après-midi',
      'emoji': '🌤️',
      'description': 'Après-midi',
      'color': Color(0xFF42A5F5),
    },
    'evening': {
      'start': 17,
      'end': 21,
      'greeting': 'Bonsoir',
      'emoji': '🌆',
      'description': 'Soirée',
      'color': Color(0xFFFF7043),
    },
    'night': {
      'start': 21,
      'end': 5,
      'greeting': 'Bonne nuit',
      'emoji': '🌙',
      'description': 'Nuit',
      'color': Color(0xFF7986CB),
    },
  };

  // Fonction principale de salutation dynamique
  static String getDynamicGreeting({
    bool includeEmoji = false,
    bool includeDescription = false,
    String? customName,
  }) {
    final now = DateTime.now();
    final hour = now.hour;
    final period = _getCurrentPeriod(hour);

    String greeting = period['greeting'];

    if (customName != null && customName.isNotEmpty) {
      greeting = '$greeting, $customName';
    }

    if (includeEmoji) {
      greeting = '${period['emoji']} $greeting';
    }

    if (includeDescription) {
      greeting = '$greeting - ${period['description']}';
    }

    return greeting;
  }

  // Obtenir la période actuelle
  static Map<String, dynamic> _getCurrentPeriod(int hour) {
    if (hour >= 5 && hour < 8) return _greetingPeriods['earlyMorning']!;
    if (hour >= 8 && hour < 12) return _greetingPeriods['morning']!;
    if (hour >= 12 && hour < 17) return _greetingPeriods['afternoon']!;
    if (hour >= 17 && hour < 21) return _greetingPeriods['evening']!;
    return _greetingPeriods['night']!;
  }

  // Obtenir des informations complètes sur la période
  static Map<String, dynamic> getGreetingInfo() {
    final hour = DateTime.now().hour;
    final period = _getCurrentPeriod(hour);

    return {
      'greeting': period['greeting'],
      'emoji': period['emoji'],
      'description': period['description'],
      'color': period['color'],
      'hour': hour,
      'periodName': _getPeriodName(hour),
    };
  }

  // Obtenir le nom de la période
  static String _getPeriodName(int hour) {
    if (hour >= 5 && hour < 8) return 'earlyMorning';
    if (hour >= 8 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }
}

class BoutiqueHomeScreen extends StatefulWidget {
  final Function(int) onTabSelected;

  const BoutiqueHomeScreen({
    Key? key,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  State<BoutiqueHomeScreen> createState() => _BoutiqueHomeScreenState();
}

class _BoutiqueHomeScreenState extends State<BoutiqueHomeScreen>
    with TickerProviderStateMixin {
  final String boutiqueId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _navigateToProducts() => widget.onTabSelected(1);
  void _navigateToOrders() => widget.onTabSelected(2);

  void _navigateToPendingOrders() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const BoutiqueOrdersScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
                CurveTween(curve: Curves.easeInOut),
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToCustomers() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const BoutiqueCustomersScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
                CurveTween(curve: Curves.easeInOut),
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }

  Future<int> _getProductCount() async {
    try {
      final query = FirebaseFirestore.instance
          .collection('products')
          .where('boutiqueId', isEqualTo: boutiqueId);
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Erreur comptage produits: $e');
      return 0;
    }
  }

  Future<int> _getOrderCount() async {
    try {
      final query = FirebaseFirestore.instance
          .collection('orders')
          .where('boutiqueId', isEqualTo: boutiqueId);
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Erreur comptage commandes: $e');
      return 0;
    }
  }

  Future<int> _getPendingOrders() async {
    try {
      final query = FirebaseFirestore.instance
          .collection('orders')
          .where('boutiqueId', isEqualTo: boutiqueId)
          .where('status', isEqualTo: 'pending');
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Erreur commandes en attente: $e');
      return 0;
    }
  }

  Future<int> _getFollowerCount() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(boutiqueId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final followers = data['followers'] as List<dynamic>?;
        return followers?.length ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Erreur comptage followers: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final greetingInfo = GreetingService.getGreetingInfo();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          _fadeController.reset();
          _slideController.reset();
          _fadeController.forward();
          _slideController.forward();
        },
        color: greetingInfo['color'],
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildModernAppBar(greetingInfo),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildWelcomeSection(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildStatsGrid(greetingInfo),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildRecentActivity(),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildQuickActions(greetingInfo),
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildModernAppBar(Map<String, dynamic> greetingInfo) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                greetingInfo['color'].withOpacity(0.7),
                greetingInfo['color'].withOpacity(0.9),
                const Color(0xFF667EEA).withOpacity(0.8),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: greetingInfo['color'].withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 30, right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            greetingInfo['emoji'],
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            GreetingService.getDynamicGreeting(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(boutiqueId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final boutiqueName = snapshot.data?['name']?.toString() ?? 'Ma Boutique';
                        return Text(
                          boutiqueName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${greetingInfo['description']} • Gérez votre boutique facilement',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(boutiqueId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerWelcome();
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildErrorCard('Erreur de chargement des données');
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        return _buildModernBoutiqueCard(userData);
      },
    );
  }

  Widget _buildModernBoutiqueCard(Map<String, dynamic>? userData) {
    final String? imageUrl = userData?['photoUrl']?.toString() ??
        userData?['photoURL']?.toString();
    final boutiqueLocation = userData?['address']?.toString() ?? 'Adresse non spécifiée';
    final status = userData?['status']?.toString() ?? 'active';
    final greetingInfo = GreetingService.getGreetingInfo();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Hero(
              tag: 'boutique_avatar',
              child: Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: imageUrl != null && imageUrl.isNotEmpty
                      ? null
                      : LinearGradient(
                    colors: [
                      greetingInfo['color'].withOpacity(0.8),
                      greetingInfo['color'].withOpacity(0.6),
                    ],
                  ),
                  image: imageUrl != null && imageUrl.isNotEmpty
                      ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: greetingInfo['color'].withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: imageUrl == null || imageUrl.isEmpty
                    ? Icon(
                  FontAwesomeIcons.store,
                  size: 35,
                  color: Colors.white,
                )
                    : null,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'active'
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: status == 'active'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status == 'active' ? 'En ligne' : 'Hors ligne',
                              style: TextStyle(
                                color: status == 'active'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDate(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    boutiqueLocation,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<int>(
                    future: _getFollowerCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.users,
                            size: 14,
                            color: greetingInfo['color'],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$count ${count == 1 ? 'client' : 'clients'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: greetingInfo['color'],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> greetingInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu des performances',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: greetingInfo['color'],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Suivez vos statistiques en temps réel',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildModernStatCard(
              title: 'Produits',
              future: _getProductCount(),
              icon: FontAwesomeIcons.boxOpen,
              gradientColors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
              onTap: _navigateToProducts,
            ),
            _buildModernStatCard(
              title: 'Commandes',
              future: _getOrderCount(),
              icon: FontAwesomeIcons.shoppingCart,
              gradientColors: [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
              onTap: _navigateToOrders,
            ),
            _buildModernStatCard(
              title: 'En attente',
              future: _getPendingOrders(),
              icon: FontAwesomeIcons.clock,
              gradientColors: [const Color(0xFFFA709A), const Color(0xFFFEE140)],
              onTap: _navigateToPendingOrders,
            ),
            _buildModernStatCard(
              title: 'Clients',
              future: _getFollowerCount(),
              icon: FontAwesomeIcons.users,
              gradientColors: [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
              onTap: _navigateToCustomers,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required Future<int> future,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;

        final isSmallScreen = cardWidth < 160 || cardHeight < 120;
        final isMediumScreen = cardWidth < 200 || cardHeight < 150;

        final iconSize = isSmallScreen ? 16.0 : isMediumScreen ? 20.0 : 24.0;
        final titleFontSize = isSmallScreen ? 10.0 : isMediumScreen ? 12.0 : 14.0;
        final countFontSize = isSmallScreen ? 16.0 : isMediumScreen ? 20.0 : 24.0;
        final actionFontSize = isSmallScreen ? 10.0 : isMediumScreen ? 12.0 : 14.0;
        final actionIconSize = isSmallScreen ? 8.0 : isMediumScreen ? 10.0 : 12.0;
        final cardPadding = isSmallScreen ? 12.0 : isMediumScreen ? 16.0 : 20.0;
        final iconPadding = isSmallScreen ? 8.0 : isMediumScreen ? 10.0 : 12.0;
        final mainSpacing = isSmallScreen ? 4.0 : isMediumScreen ? 6.0 : 8.0;
        final smallSpacing = isSmallScreen ? 2.0 : 4.0;
        final borderRadius = isSmallScreen ? 16.0 : isMediumScreen ? 20.0 : 24.0;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.15),
                  blurRadius: isSmallScreen ? 10 : 20,
                  offset: Offset(0, isSmallScreen ? 4 : 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Stack(
                children: [
                  if (!isSmallScreen)
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: isSmallScreen ? 60 : isMediumScreen ? 80 : 100,
                        height: isSmallScreen ? 60 : isMediumScreen ? 80 : 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: gradientColors.map((c) => c.withOpacity(0.1)).toList(),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.all(iconPadding),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: gradientColors),
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gradientColors[0].withOpacity(0.3),
                                      blurRadius: isSmallScreen ? 5 : 10,
                                      offset: Offset(0, isSmallScreen ? 2 : 4),
                                    ),
                                  ],
                                ),
                                child: Icon(icon, color: Colors.white, size: iconSize),
                              ),
                              FutureBuilder<int>(
                                future: future,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return SizedBox(
                                      width: isSmallScreen ? 12 : 16,
                                      height: isSmallScreen ? 12 : 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: isSmallScreen ? 1.5 : 2,
                                        color: gradientColors[0],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: mainSpacing),
                        Flexible(
                          flex: 1,
                          child: Text(
                            title,
                            style: TextStyle(
                              color: const Color(0xFF6B7280),
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: isSmallScreen ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: smallSpacing),
                        Flexible(
                          flex: 1,
                          child: FutureBuilder<int>(
                            future: future,
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  count.toString(),
                                  style: TextStyle(
                                    color: const Color(0xFF1F2937),
                                    fontSize: countFontSize,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: mainSpacing),
                        Flexible(
                          flex: 1,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Gérer',
                                  style: TextStyle(
                                    color: gradientColors[0],
                                    fontSize: actionFontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: smallSpacing),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: gradientColors[0],
                                  size: actionIconSize,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activité récente',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('Voir tout'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF667EEA),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('activities')
                  .where('boutiqueId', isEqualTo: boutiqueId)
                  .orderBy('timestamp', descending: true)
                  .limit(4)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerActivityItem();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyActivity();
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[100],
                  ),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final type = data['type'] as String? ?? 'default';
                    final message = data['message'] as String? ?? 'Nouvelle activité';
                    final timestamp = data['timestamp'] as Timestamp?;

                    return _buildModernActivityItem(
                      message,
                      _getActivityIcon(type),
                      _getActivityGradient(type),
                      time: timestamp != null
                          ? _formatTime(timestamp.toDate())
                          : 'maintenant',
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyActivity() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
            ),
            child: Icon(
              FontAwesomeIcons.chartLine,
              size: 32,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune activité récente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos activités apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Map<String, dynamic> greetingInfo) {
    final List<Map<String, dynamic>> actions = [
      {
        'icon': FontAwesomeIcons.plus,
        'label': 'Ajouter',
        'page': const BoutiqueProductsScreen(),
        'color': greetingInfo['color'],
      },
      {
        'icon': FontAwesomeIcons.chartLine,
        'label': 'Stats',
        'page': const BoutiqueStatsScreen(),
        'color': const Color(0xFF4FACFE),
      },
      {
        'icon': FontAwesomeIcons.image,
        'label': 'Galerie',
        'page': const BoutiqueGalleryScreen(),
        'color': const Color(0xFF43E97B),
      },
      {
        'icon': FontAwesomeIcons.star,
        'label': 'Avis',
        'page': const BoutiqueReviewsScreen(),
        'color': const Color(0xFFFA709A),
      },
      {
        'icon': FontAwesomeIcons.cog,
        'label': 'Réglages',
        'page': const BoutiqueSettingsScreen(),
        'color': const Color(0xFF764BA2),
      },
      {
        'icon': FontAwesomeIcons.questionCircle,
        'label': 'Aide',
        'page':  BoutiqueHelpScreen(),
        'color': const Color(0xFFFEE140),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: greetingInfo['color'],
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 1.1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: actions.map((action) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                    action['page'],
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: animation.drive(
                            Tween(begin: const Offset(0.0, 0.2), end: Offset.zero)
                                .chain(CurveTween(curve: Curves.easeInOut)),
                          ),
                          child: child,
                        ),
                      );
                    },
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: action['color'].withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: action['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        action['icon'],
                        color: action['color'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      action['label'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModernActivityItem(
      String message,
      IconData icon,
      List<Color> gradientColors, {
        required String time,
      }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerWelcome() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Row(
            children: [
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerActivityItem() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              FontAwesomeIcons.exclamationTriangle,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'order':
        return FontAwesomeIcons.shoppingCart;
      case 'product':
        return FontAwesomeIcons.boxOpen;
      case 'customer':
        return FontAwesomeIcons.user;
      case 'review':
        return FontAwesomeIcons.star;
      case 'payment':
        return FontAwesomeIcons.creditCard;
      case 'delivery':
        return FontAwesomeIcons.truck;
      default:
        return FontAwesomeIcons.bell;
    }
  }

  List<Color> _getActivityGradient(String type) {
    switch (type) {
      case 'order':
        return [const Color(0xFF4FACFE), const Color(0xFF00F2FE)];
      case 'product':
        return [const Color(0xFF667EEA), const Color(0xFF764BA2)];
      case 'customer':
        return [const Color(0xFF43E97B), const Color(0xFF38F9D7)];
      case 'review':
        return [const Color(0xFFFA709A), const Color(0xFFFEE140)];
      case 'payment':
        return [const Color(0xFF667EEA), const Color(0xFF764BA2)];
      case 'delivery':
        return [const Color(0xFF4FACFE), const Color(0xFF00F2FE)];
      default:
        return [const Color(0xFF667EEA), const Color(0xFF764BA2)];
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }
}