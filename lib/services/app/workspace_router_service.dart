import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/account_roles.dart';
import '../../models/app/app_workspace.dart';
import '../../views/screens/admin/main_admin.dart';
import '../../views/screens/boutique/dashboard/boutique_dashboard.dart';
import '../../views/screens/client/home/home_screen.dart';
import '../../views/screens/createur/createur_dashboard_screen.dart';
import '../../views/screens/global/salon_mode_burkinabe.dart';

class WorkspaceRouterService {
  WorkspaceRouterService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<AppWorkspace> resolveCurrentWorkspace() async {
    final user = _auth.currentUser;
    if (user == null) return AppWorkspace.publicSalon;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    return AppWorkspaceX.fromRole(AccountRoles.activeRole(data));
  }

  Widget widgetFor(AppWorkspace workspace) {
    switch (workspace) {
      case AppWorkspace.publicSalon:
        return const SalonModeBurkinabeScreen();
      case AppWorkspace.client:
        return const HomeScreen();
      case AppWorkspace.creator:
        return const CreateurDashboardScreen();
      case AppWorkspace.boutique:
        return const BoutiqueDashboard();
      case AppWorkspace.admin:
        return AdminApp();
    }
  }

  String routeFor(AppWorkspace workspace) => workspace.route;

  String routeForRole(String role) {
    return AppWorkspaceX.fromRole(role).route;
  }
}
