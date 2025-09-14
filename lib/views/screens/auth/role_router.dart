import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../client/home/home_screen.dart';
import '../createur/createur_dashboard_screen.dart';
import '../boutique/dashboard/boutique_dashboard.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Center(child: Text("Utilisateur non connecté"));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Utilisateur introuvable"));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final role = data['role'];

        switch (role) {
          case 'client':
            return const HomeScreen();
          case 'createur':
            return const CreateurDashboardScreen();
          case 'boutique':
            return const BoutiqueDashboard();
          case 'admin':
            return Scaffold(
              body: Center(child: Text("Espace admin (à créer)")),
            );
          default:
            return Scaffold(
              body: Center(child: Text("Rôle non reconnu: $role")),
            );
        }
      },
    );
  }
}
