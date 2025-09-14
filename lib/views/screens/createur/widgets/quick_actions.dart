import 'package:flutter/material.dart';
import '../createur_tabs/add_appointment_screen.dart';
import '../createur_tabs/stats_tab.dart';
import '../creations/add_creation_screen.dart';
import '../createur_tabs/shared_looks_screen.dart';
import '../createur_tabs/creators_list_screen.dart';
import '../createur_tabs/shop_screen.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Actions Rapides',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _QuickActionButton(
              icon: Icons.add,
              label: 'Nouvelle création',
              color: const Color(0xFF4A6FA5),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCreationScreen()),
              ),
            ),
            _QuickActionButton(
              icon: Icons.calendar_today,
              label: 'Prendre RDV',
              color: const Color(0xFF2A9D8F),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddAppointmentScreen()),
              ),
            ),
            _QuickActionButton(
              icon: Icons.analytics,
              label: 'Statistiques',
              color: const Color(0xFFE76F51),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StatsTab()),
              ),
            ),
            _QuickActionButton(
              icon: Icons.people,
              label: 'Créateurs',
              color: const Color(0xFF9B5DE5),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreatorsListScreen()),
              ),
            ),
            _QuickActionButton(
              icon: Icons.accessibility,
              label: 'Mesures partagés',
              color: const Color(0xFF00BBF9),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SharedLooksScreen()),
              ),
            ),
            _QuickActionButton(
            icon: Icons.storefront, // Icône représentant une boutique
            label: 'Boutiques',
            color: const Color(0xFFE91E63), // Rose élégant
            onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BoutiqueUsersScreen ()),
            ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        elevation: 2,
        shadowColor: color.withOpacity(0.3),
      ),
    );
  }
}