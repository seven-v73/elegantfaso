import 'package:flutter/material.dart';

import '../createur_dashboard_screen.dart';

class CustomNavBar extends StatelessWidget {
  final CreateurTab currentTab;
  final Function(CreateurTab) onTabSelected;

  const CustomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 70,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Tableau',
                tab: CreateurTab.dashboard,
              ),
              _buildNavItem(
                context,
                icon: Icons.brush_outlined,
                activeIcon: Icons.brush_rounded,
                label: 'Créations',
                tab: CreateurTab.creations,
              ),
              _buildNavItem(
                context,
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today_rounded,
                label: 'RDV',
                tab: CreateurTab.appointments,
              ),
              _buildNavItem(
                context,
                icon: Icons.people_outline,
                activeIcon: Icons.people_rounded,
                label: 'Clients',
                tab: CreateurTab.clients,
              ),
              _buildNavItem(
                context,
                icon: Icons.local_mall_outlined,
                activeIcon: Icons.local_mall_rounded,
                label: 'Salon',
                tab: CreateurTab.salon,
              ),
              _buildNavItem(
                context,
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics_rounded,
                label: 'Stats',
                tab: CreateurTab.stats,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required IconData icon,
        required IconData activeIcon,
        required String label,
        required CreateurTab tab,
      }) {
    final isActive = currentTab == tab;

    return GestureDetector(
      onTap: () => onTabSelected(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: MediaQuery.of(context).size.width / 6 - 16,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4A6FA5).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                size: 24,
                color: isActive
                    ? const Color(0xFF4A6FA5)
                    : const Color(0xFF2D3436).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF4A6FA5)
                    : const Color(0xFF2D3436).withOpacity(0.6),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

}