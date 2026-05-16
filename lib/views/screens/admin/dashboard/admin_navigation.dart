part of 'admin_dashboard.dart';

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation({
    required this.selectedIndex,
    required this.badgeCounts,
    required this.onSelect,
  });

  final int selectedIndex;
  final Map<int, int> badgeCounts;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final entries = _AdminMobileNavEntry.items;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ModernColors.surface,
        border: Border(top: BorderSide(color: ModernColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: entries.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final selected =
                  entry.targetIndex == null
                      ? !_AdminMobileNavEntry.primaryIndexes.contains(
                        selectedIndex,
                      )
                      : selectedIndex == entry.targetIndex;
              return _BottomNavPill(
                item: entry.item,
                selected: selected,
                badgeCount: entry.badgeCount(badgeCounts),
                onTap:
                    entry.targetIndex == null
                        ? () => _showMoreMenu(context)
                        : () => onSelect(entry.targetIndex!),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _AdminMobileMoreSheet(
            badgeCounts: badgeCounts,
            onSelect: (index) {
              Navigator.pop(context);
              onSelect(index);
            },
          ),
    );
  }
}

class _AdminMobileNavEntry {
  const _AdminMobileNavEntry(this.item, this.targetIndex);

  final _AdminNavItem item;
  final int? targetIndex;

  static final items = [
    _AdminMobileNavEntry(_AdminNavItem.items[0], 0),
    _AdminMobileNavEntry(_AdminNavItem.items[1], 1),
    _AdminMobileNavEntry(_AdminNavItem.items[4], 4),
    _AdminMobileNavEntry(_AdminNavItem.items[6], 6),
    _AdminMobileNavEntry(_AdminNavItem.items[7], 7),
    _AdminMobileNavEntry(
      _AdminNavItem(
        icon: Icons.more_horiz_rounded,
        selectedIcon: Icons.more_horiz_rounded,
        label: 'Plus',
        shortLabel: 'Plus',
      ),
      null,
    ),
  ];

  static const primaryIndexes = {0, 1, 4, 6, 7};

  int badgeCount(Map<int, int> counts) {
    final index = targetIndex;
    if (index != null) return counts[index] ?? 0;
    return (counts[2] ?? 0) +
        (counts[3] ?? 0) +
        (counts[5] ?? 0) +
        (counts[8] ?? 0);
  }
}

class _AdminMobileMoreSheet extends StatelessWidget {
  const _AdminMobileMoreSheet({
    required this.badgeCounts,
    required this.onSelect,
  });

  final Map<int, int> badgeCounts;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const entries = [8, 3, 2, 5];
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ModernColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ModernColors.line),
          boxShadow: ModernShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: ModernColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            ...entries.map((index) {
              final item = _AdminNavItem.items[index];
              final count = badgeCounts[index] ?? 0;
              return ListTile(
                leading: _AdminNavIconWithBadge(
                  icon: item.selectedIcon,
                  color: ModernColors.primary,
                  badgeCount: count,
                ),
                title: Text(
                  item.label,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onSelect(index),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BottomNavPill extends StatelessWidget {
  const _BottomNavPill({
    required this.item,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  final _AdminNavItem item;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ModernColors.primary : ModernColors.inkSoft;
    return Material(
      color:
          selected
              ? ModernColors.primary.withValues(alpha: 0.1)
              : ModernColors.surfaceRaised,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 98,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  selected
                      ? ModernColors.primary.withValues(alpha: 0.18)
                      : ModernColors.line,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AdminNavIconWithBadge(
                icon: selected ? item.selectedIcon : item.icon,
                color: color,
                badgeCount: badgeCount,
              ),
              const SizedBox(height: 3),
              Text(
                item.shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem {
  const _AdminNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.shortLabel,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String shortLabel;

  static const items = [
    _AdminNavItem(
      icon: AppIcons.today,
      selectedIcon: AppIcons.today,
      label: 'Vue d’ensemble',
      shortLabel: 'Accueil',
    ),
    _AdminNavItem(
      icon: AppIcons.clients,
      selectedIcon: AppIcons.clients,
      label: 'Utilisateurs',
      shortLabel: 'Comptes',
    ),
    _AdminNavItem(
      icon: AppIcons.salon,
      selectedIcon: AppIcons.salon,
      label: 'Salon',
      shortLabel: 'Salon',
    ),
    _AdminNavItem(
      icon: AppIcons.orders,
      selectedIcon: AppIcons.orders,
      label: 'Commandes',
      shortLabel: 'Commandes',
    ),
    _AdminNavItem(
      icon: AppIcons.revenue,
      selectedIcon: AppIcons.revenue,
      label: 'Transactions',
      shortLabel: 'Transactions',
    ),
    _AdminNavItem(
      icon: AppIcons.coupons,
      selectedIcon: AppIcons.coupons,
      label: 'Coupons',
      shortLabel: 'Coupons',
    ),
    _AdminNavItem(
      icon: AppIcons.moderation,
      selectedIcon: AppIcons.moderation,
      label: 'Modération',
      shortLabel: 'Modération',
    ),
    _AdminNavItem(
      icon: AppIcons.settings,
      selectedIcon: AppIcons.settings,
      label: 'Paramètres',
      shortLabel: 'Réglages',
    ),
    _AdminNavItem(
      icon: Icons.inbox_rounded,
      selectedIcon: Icons.mark_email_read_rounded,
      label: 'À traiter',
      shortLabel: 'À traiter',
    ),
  ];
}

class _AdminSideNavigation extends StatelessWidget {
  const _AdminSideNavigation({
    required this.selectedIndex,
    required this.extended,
    required this.badgeCounts,
    required this.onSelect,
    required this.onSignOut,
  });

  final int selectedIndex;
  final bool extended;
  final Map<int, int> badgeCounts;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      width: extended ? 276 : 92,
      color: ModernColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
      child: Column(
        crossAxisAlignment:
            extended ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          _SideHeader(extended: extended, user: user),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _AdminNavItem.items.length,
              itemBuilder: (context, index) {
                final item = _AdminNavItem.items[index];
                return _SideItem(
                  icon: item.selectedIcon,
                  label: item.label,
                  selected: selectedIndex == index,
                  extended: extended,
                  badgeCount: badgeCounts[index] ?? 0,
                  onTap: () => onSelect(index),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _SideItem(
            icon: AppIcons.logout,
            label: 'Déconnexion',
            selected: false,
            danger: true,
            extended: extended,
            badgeCount: 0,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _SideHeader extends StatelessWidget {
  const _SideHeader({required this.extended, required this.user});

  final bool extended;
  final User? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(extended ? 14 : 10),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ModernColors.line),
      ),
      child:
          extended
              ? Row(
                children: [
                  _AdminAvatar(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName?.trim().isNotEmpty == true
                              ? user!.displayName!
                              : 'Admin',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.inkSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
              : const _AdminAvatar(),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: ModernColors.admin.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.admin_panel_settings_rounded,
        color: ModernColors.admin,
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.extended,
    required this.badgeCount,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool extended;
  final int badgeCount;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        danger
            ? ModernColors.danger
            : selected
            ? ModernColors.primary
            : ModernColors.inkSoft;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color:
            selected
                ? ModernColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: extended ? 12 : 0,
              vertical: 12,
            ),
            child:
                extended
                    ? Row(
                      children: [
                        _AdminNavIconWithBadge(
                          icon: icon,
                          color: color,
                          badgeCount: badgeCount,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontWeight:
                                  selected ? FontWeight.w900 : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (badgeCount > 0) ...[
                          const SizedBox(width: 8),
                          _AdminNavCountPill(count: badgeCount),
                        ],
                      ],
                    )
                    : Center(
                      child: _AdminNavIconWithBadge(
                        icon: icon,
                        color: color,
                        badgeCount: badgeCount,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavIconWithBadge extends StatelessWidget {
  const _AdminNavIconWithBadge({
    required this.icon,
    required this.color,
    required this.badgeCount,
  });

  final IconData icon;
  final Color color;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: badgeCount > 0,
      backgroundColor: ModernColors.danger,
      label: Text(
        badgeCount > 99 ? '99+' : badgeCount.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _AdminNavCountPill extends StatelessWidget {
  const _AdminNavCountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: ModernColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ModernColors.danger.withValues(alpha: 0.16)),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: ModernColors.danger,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
