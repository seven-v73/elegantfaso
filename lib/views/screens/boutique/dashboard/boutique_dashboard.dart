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
import '../../auth/role_guard.dart';
import 'package:elegantfaso/views/screens/boutique/dashboard/boutique_home_screen.dart';
import '../../global/salon_mode_burkinabe.dart';
import 'app_enums.dart';

class BoutiqueDashboard extends StatefulWidget {
  const BoutiqueDashboard({Key? key}) : super(key: key);

  @override
  State<BoutiqueDashboard> createState() => _BoutiqueDashboardState();
}

class _BoutiqueDashboardState extends State<BoutiqueDashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _pages = [
       BoutiqueHomeScreen(onTabSelected: _changeTab),
      const BoutiqueProductsScreen(),
      const BoutiqueOrdersScreen(),
      const BoutiqueAppointmentsScreen(),
      const SalonModeBurkinabeScreen(),
      const BoutiqueProfileScreen(),
    ];

    _animationController.forward();
  }

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
      _animationController.reset();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      expectedRole: 'boutique',
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8F9FA),
        extendBody: true,
        appBar: _buildAppBar(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
        drawer: _buildAppDrawer(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'ELEGANT',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            TextSpan(
              text: ' FASO',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(FeatherIcons.menu, color: Colors.white, size: 26),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        IconButton(
          icon: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: currentUser?.uid)
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Icon(FeatherIcons.bell, color: Colors.white, size: 24);
              }

              final count = snapshot.data?.docs.length ?? 0;
              return Badge(
                isLabelVisible: count > 0,
                label: Text(
                  count.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: const Color(0xFFF93963),
                child: const Icon(FeatherIcons.bell, color: Colors.white, size: 24),
              );
            },
          ),
          onPressed: _handleNotifications,
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2A2D3E),
              const Color(0xFF1E202E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      elevation: 10,
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF2A2D3E),
            unselectedItemColor: const Color(0xFFA6A6A6).withOpacity(0.7),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            showUnselectedLabels: true,
            backgroundColor: Colors.white,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 0
                        ? const Color(0xFF2A2D3E).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: const Icon(FeatherIcons.home, size: 24),
                ),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 1
                        ? const Color(0xFF2A2D3E).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: const Icon(FeatherIcons.shoppingBag, size: 24),
                ),
                label: 'Produits',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 2
                        ? const Color(0xFF2A2D3E).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: const Icon(FeatherIcons.shoppingCart, size: 24),
                ),
                label: 'Commandes',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 3
                        ? const Color(0xFF2A2D3E).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: const Icon(FeatherIcons.calendar, size: 24),
                ),
                label: 'Rendez-vous',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 4
                        ? const Color(0xFF2A2D3E).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: const Icon(FeatherIcons.feather, size: 24),
                ),
                label: 'Salon',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == 5
                        ? const Color(0xFF2A2D3E).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: const Icon(FeatherIcons.user, size: 24),
                ),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xF9433D3D).withOpacity(0.95),
              const Color(0xFF0F1B65).withOpacity(0.95),
            ],
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerDrawer();
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text('Boutique non trouvée',
                    style: TextStyle(
                        color: Colors.grey[300],
                        fontStyle: FontStyle.italic
                    )
                ),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final boutiqueName = userData['name']?.toString() ?? 'Boutique';
            final boutiqueEmail = userData['email']?.toString() ?? 'Email';
            final imageUrl = userData['photoUrl']?.toString() ??
                userData['photoURL']?.toString();
            final followers = List<String>.from(userData['followers'] ?? []);
            final followersCount = followers.length;

            return Column(
              children: [
                Container(
                  height: 220,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                          image: imageUrl != null && imageUrl.isNotEmpty
                              ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: imageUrl == null || imageUrl.isEmpty
                            ? const Center(
                          child: Icon(
                            FeatherIcons.shoppingBag,
                            color: Colors.white,
                            size: 30,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              boutiqueName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              boutiqueEmail,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    FeatherIcons.users,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$followersCount followers',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                      ),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.only(top: 30, bottom: 20),
                      children: [
                        _buildDrawerItem(FeatherIcons.home, 'Accueil', 0),
                        const SizedBox(height: 5),
                        _buildDrawerSectionTitle('GESTION'),
                        _buildDrawerItem(FeatherIcons.shoppingBag, 'Produits', 1),
                        _buildDrawerItem(FeatherIcons.shoppingCart, 'Commandes', 2),
                        _buildDrawerItem(FeatherIcons.calendar, 'Rendez-vous', 3),
                        const SizedBox(height: 5),
                        const Divider(height: 1, indent: 20, endIndent: 20),
                        _buildDrawerSectionTitle('COMPTE'),
                        _buildDrawerItem(FeatherIcons.user, 'Profil', 5),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Divider(
                            color: Colors.white.withOpacity(0.2),
                            thickness: 1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerDrawer() {
    return Column(
      children: [
        Container(
          height: 220,
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[700]!,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 15),
                      Container(
                        width: 120,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 100,
                        height: 30,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.only(top: 30, bottom: 20),
              children: [
                _buildShimmerDrawerItem(),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Container(
                    width: 80,
                    height: 16,
                    color: Colors.white,
                  ),
                ),
                _buildShimmerDrawerItem(),
                _buildShimmerDrawerItem(),
                _buildShimmerDrawerItem(),
                const SizedBox(height: 5),
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Container(
                    width: 80,
                    height: 16,
                    color: Colors.white,
                  ),
                ),
                _buildShimmerDrawerItem(),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Divider(
                    color: Colors.white.withOpacity(0.2),
                    thickness: 1,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[700]!,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 15),
                          Container(
                            width: 100,
                            height: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerDrawerItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              color: Colors.white,
            ),
            const SizedBox(width: 20),
            Container(
              width: 100,
              height: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[300],
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: _currentIndex == index
            ? Colors.white.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, size: 22, color: Colors.white),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: _currentIndex == index ? FontWeight.w600 : FontWeight.normal,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        trailing: _currentIndex == index
            ? const Icon(FeatherIcons.chevronRight, color: Colors.white, size: 18)
            : null,
        selected: _currentIndex == index,
        onTap: () {
          _onTabTapped(index);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: const Color(0xFFF93963).withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          leading: const Icon(FeatherIcons.logOut, color: Color(0xFFF93963), size: 22),
          title: const Text('Déconnexion',
            style: TextStyle(
              color: Color(0xFFF93963),
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: _handleLogout,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _handleNotifications() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BoutiqueNotificationsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: const Color(0xFFF93963),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
    }
  }
}