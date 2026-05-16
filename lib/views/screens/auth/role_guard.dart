import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../design/app_icons.dart';
import '../../../core/account_roles.dart';
import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';
import '../account/role_onboarding_screen.dart';

class RoleGuard extends StatefulWidget {
  final String expectedRole;
  final Widget child;
  final Widget? unauthorizedScreen;

  const RoleGuard({
    super.key,
    required this.expectedRole,
    required this.child,
    this.unauthorizedScreen,
  });

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  User? _user;
  Future<DocumentSnapshot<Map<String, dynamic>>>? _roleFuture;

  @override
  void initState() {
    super.initState();
    _primeRoleFuture();
  }

  @override
  void didUpdateWidget(covariant RoleGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (oldWidget.expectedRole != widget.expectedRole ||
        currentUser?.uid != _user?.uid) {
      _primeRoleFuture();
    }
  }

  void _primeRoleFuture() {
    _user = FirebaseAuth.instance.currentUser;
    final user = _user;
    _roleFuture =
        user == null
            ? null
            : FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Non connecté.")));
    }

    final roleFuture = _roleFuture;
    if (roleFuture == null) {
      return const Scaffold(body: Center(child: Text("Non connecté.")));
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text("Données introuvable")),
          );
        }

        final data = snapshot.data!.data();
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text("Format de données invalide")),
          );
        }

        final roles = AccountRoles.normalize(data);

        if (roles.contains(widget.expectedRole)) {
          return widget.child;
        }

        return widget.unauthorizedScreen ??
            _RoleAccessState(expectedRole: widget.expectedRole, roles: roles);
      },
    );
  }
}

class _RoleAccessState extends StatelessWidget {
  final String expectedRole;
  final List<String> roles;

  const _RoleAccessState({required this.expectedRole, required this.roles});

  @override
  Widget build(BuildContext context) {
    final isBusinessRole = AccountRoles.businessRoles.contains(expectedRole);
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: ModernColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      AppIcons.award,
                      color: ModernColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isBusinessRole ? 'Espace à activer' : 'Accès réservé',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ce compte possède actuellement: ${roles.join(', ')}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  if (isBusinessRole) ...[
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      RoleOnboardingScreen(role: expectedRole),
                            ),
                          ),
                      icon: const Icon(Icons.add_business_rounded),
                      label: Text(
                        expectedRole == AccountRoles.createur
                            ? 'Activer Créateur'
                            : 'Activer Boutique',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
