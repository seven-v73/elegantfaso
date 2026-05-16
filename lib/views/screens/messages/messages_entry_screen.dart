import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/account_roles.dart';
import '../auth/login_screen.dart';
import 'conversations_screen.dart';
import 'user_model.dart' as messaging;

class MessagesEntryScreen extends StatelessWidget {
  const MessagesEntryScreen({super.key, this.roleOverride});

  final String? roleOverride;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = Map<String, dynamic>.from(
          snapshot.data?.data() ?? <String, dynamic>{},
        );

        final requestedRole = roleOverride ?? '';
        if (AccountRoles.isValid(requestedRole)) {
          data['activeRole'] = requestedRole;
          data['role'] = requestedRole;
        }

        final currentUser = messaging.UserModel.fromMap(data, docId: user.uid);
        return ConversationsScreen(currentUser: currentUser);
      },
    );
  }
}
