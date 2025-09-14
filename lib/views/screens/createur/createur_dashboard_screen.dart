import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../auth/login_screen.dart';
import 'createur_model.dart';
import 'firestore_service.dart';
import 'createur_tabs/dashboard_tab.dart';
import 'createur_tabs/clients_tab.dart';
import 'createur_tabs/appointments_tab.dart';
import 'createur_tabs/stats_tab.dart';
import 'widgets/custom_nav_bar.dart';
import 'widgets/notification_manager.dart';
import 'widgets/profile_manager.dart';
import 'creations/add_creation_screen.dart';
import 'createur_tabs/creations_tabs.dart';
import '../global/salon_mode_burkinabe.dart';

enum CreateurTab { dashboard, creations, appointments, clients,salon, stats }

class CreateurDashboardScreen extends StatefulWidget {
  const CreateurDashboardScreen({Key? key}) : super(key: key);

  @override
  State<CreateurDashboardScreen> createState() => _CreateurDashboardScreenState();
}

class _CreateurDashboardScreenState extends State<CreateurDashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  // Constants
  static const _backgroundColor = Color(0xFFF8F9FA);

  // State
  CreateurTab _currentTab = CreateurTab.dashboard;
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _isOnline = state == AppLifecycleState.resumed);
  }

  void _onTabTapped(CreateurTab tab) {
    setState(() => _currentTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginScreen();

    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBody: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          SafeArea(child: _buildContent(user)),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF4A6FA5),
                Color(0xFF6B4E71),
                Color(0xFFE76F51),
                Colors.white
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentTab == CreateurTab.creations
          ? _buildFloatingActionButton()
          : null,
      bottomNavigationBar: CustomNavBar(
        currentTab: _currentTab,
        onTabSelected: _onTabTapped,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Colors.white,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: 24,
      title: Row(
        children: [
          SvgPicture.asset(
            'assets/logo/logo.svg',
            height: 32,
          ),
          const SizedBox(width: 12),
          const Text(
            'Artisan Local',
            style: TextStyle(
              color: Color(0xFF2D3436),
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        const NotificationIcon(),
        const SizedBox(width: 12),
        ProfileButton(
          onProfilePressed: () => ProfileManager.showProfileMenu(context),
        ),
        const SizedBox(width: 8),
      ],
    );

  }

  Widget _buildContent(User user) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _buildCurrentTabContent(user),
    );
  }

  Widget _buildCurrentTabContent(User user) {
    switch (_currentTab) {
      case CreateurTab.dashboard:
        return DashboardTab(
          user: user,
          confettiController: _confettiController,
          isOnline: _isOnline,
          onStatusChanged: (value) => setState(() => _isOnline = value),
        );
      case CreateurTab.creations:
        return CreationsTab(user: user);
      case CreateurTab.appointments:
        return AppointmentsTab(user: user);
      case CreateurTab.clients:
        return ClientsTab(user: user);
      case CreateurTab.salon:
        return const SalonModeBurkinabeScreen();
      case CreateurTab.stats:
        return StatsTab();

    }
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, _, __) => AddCreationScreen(),
          transitionsBuilder: (context, animation, _, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      backgroundColor: const Color(0xFF4A6FA5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }
}