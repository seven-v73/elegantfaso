import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/account_roles.dart';
import '../../../../services/account/account_closure_service.dart';
import '../../base/createur_profile_screen.dart';
import '../../../widgets/account/account_closure_sheet.dart';
import '../../../widgets/account/account_space_switcher.dart';
import 'sheet_handle.dart';

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
          color: const Color(0xFF4A6FA5).withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF4A6FA5).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
          builder: (context, snapshot) {
            final data =
                snapshot.data?.data() as Map<String, dynamic>? ?? const {};
            final photoUrl = data['photoUrl']?.toString() ?? '';

            return _SafeProfileAvatar(photoUrl: photoUrl);
          },
        ),
      ),
    );
  }
}

class _SafeProfileAvatar extends StatelessWidget {
  final String photoUrl;

  const _SafeProfileAvatar({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    const fallback = Icon(
      Icons.person_rounded,
      color: Color(0xFF2D3436),
      size: 22,
    );

    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFF4A6FA5).withValues(alpha: 0.2),
      child: ClipOval(
        child:
            photoUrl.isEmpty
                ? fallback
                : Image.network(
                  photoUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => fallback,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SheetHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                  child: AccountSpaceSwitcher(
                    currentSpace: AccountRoles.createur,
                    padding: EdgeInsets.zero,
                    onBeforeNavigate: () => Navigator.pop(context),
                  ),
                ),
                ProfileMenuItem(
                  icon: Icons.person_outline,
                  label: 'Mon Espace créateur',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateurProfileScreen(),
                      ),
                    );
                  },
                ),
                ProfileMenuItem(
                  icon: Icons.pause_circle_outline_rounded,
                  label: 'Fermer l’espace créateur',
                  color: Colors.red,
                  onTap: () async {
                    Navigator.pop(context);
                    final submitted = await showAccountClosureSheet(
                      context,
                      target: AccountClosureTarget.createur,
                    );
                    if (submitted == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Espace créateur fermé. Votre compte client reste actif.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/home', (route) => false);
                    }
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
                const SizedBox(height: 16),
              ],
            ),
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
      title: Text(
        label,
        style: TextStyle(color: color ?? const Color(0xFF2D3436)),
      ),
      onTap: onTap,
    );
  }
}
