import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../client/home/home_screen.dart';
import 'login_screen.dart';
import '../createur/createur_dashboard_screen.dart';
import '../admin/main_admin.dart';
import '../boutique/dashboard/boutique_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const Scaffold(
                  body: Center(child: Text("Aucun rôle défini pour cet utilisateur.")),
                );
              }

              final data = userSnapshot.data!.data() as Map<String, dynamic>;
              final role = data['role'];

              switch (role) {
                case 'client':
                  return const HomeScreen();
                case 'createur':
                  return const CreateurDashboardScreen();
                case 'boutique':
                  return const BoutiqueDashboard();
                case 'admin':
                  return AdminApp();

                default:
                  return Scaffold(
                    body: Center(child: Text("Rôle non reconnu: $role")),
                  );
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
