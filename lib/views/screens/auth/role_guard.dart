import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RoleGuard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Non connecté.")));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text("Données introuvable")));
        }

        final data = snapshot.data!.data();

        // Vérification supplémentaire des données
        if (data == null || data is! Map<String, dynamic>) {
          return const Scaffold(body: Center(child: Text("Format de données invalide")));
        }

        final role = data['role'] as String?;

        if (role == expectedRole) {
          return child;
        } else {
          return unauthorizedScreen ??
              const Scaffold(
                body: Center(child: Text("Accès refusé")),
              );
        }
      },
    );
  }
}