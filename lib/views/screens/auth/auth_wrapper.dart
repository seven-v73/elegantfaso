import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app/workspace_router.dart';
import '../global/salon_mode_burkinabe.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const WorkspaceRouter();
        }

        return const SalonModeBurkinabeScreen();
      },
    );
  }
}
