import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../base/createur_profile_screen.dart';
import 'sheet_handle.dart';
import 'empty_state.dart';
import '../../global/salon_mode_burkinabe.dart';

class ProfileButton extends StatelessWidget {
  final VoidCallback onProfilePressed;

  const ProfileButton({super.key, required this.onProfilePressed});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return GestureDetector(
      onTap: onProfilePressed,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFF4A6FA5).withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
              color: const Color(0xFF4A6FA5).withOpacity(0.3),
              width: 1.5
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final photoUrl = snapshot.data?['photoUrl'] ?? '';

            return CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF4A6FA5).withOpacity(0.2),
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? const Icon(Icons.person_rounded,
                  color: Color(0xFF2D3436),
                  size: 22)
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class ProfileManager {
  static void showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SheetHandle(),
              ProfileMenuItem(
                icon: Icons.person_outline,
                label: 'Mon Espace',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const CreateurProfileScreen()
                  ));
                },
              ),
              const Divider(),
              ProfileMenuItem(
                icon: Icons.logout,
                label: 'Déconnexion',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF4A6FA5)),
      title: Text(label, style: TextStyle(color: color ?? const Color(0xFF2D3436))),
      onTap: onTap,
    );
  }
}