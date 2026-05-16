import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../../../core/account_roles.dart';
import '../../../design/app_icons.dart';
import '../../screens/account/role_onboarding_screen.dart';

class AccountSpaceSwitcher extends StatelessWidget {
  final String currentSpace;
  final VoidCallback? onBeforeNavigate;
  final EdgeInsetsGeometry padding;

  const AccountSpaceSwitcher({
    super.key,
    required this.currentSpace,
    this.onBeforeNavigate,
    this.padding = EdgeInsets.zero,
  });

  static const _primary = Color(0xFF0F766E);
  static const _violet = Color(0xFF7C3AED);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _surface = Colors.white;

  @override
  Widget build(BuildContext context) {
    final roleService = AccountRoleService();

    return Padding(
      padding: padding,
      child: FutureBuilder<AccountRoleState?>(
        future: roleService.getCurrentState(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          final state = snapshot.data;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _primary.withValues(alpha: 0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(AppIcons.publicSpace, color: _primary, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Changer d’espace',
                        style: TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Un seul compte pour acheter, créer et vendre.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _spaceTile(
                  context: context,
                  service: roleService,
                  state: state,
                  role: AccountRoles.client,
                  icon: AppIcons.profile,
                  title: 'Espace Client',
                  subtitle: 'Shopping, inspirations et marketplace',
                  route: '/home',
                ),
                const SizedBox(height: 9),
                _spaceTile(
                  context: context,
                  service: roleService,
                  state: state,
                  role: AccountRoles.createur,
                  icon: AppIcons.creator,
                  title:
                      state?.canCreate == true
                          ? 'Espace Créateur'
                          : 'Devenir créateur',
                  subtitle:
                      state?.canCreate == true
                          ? 'Gérer créations, clients et rendez-vous'
                          : 'Créer votre profil créateur',
                  route: '/creator-dashboard',
                ),
                const SizedBox(height: 9),
                _spaceTile(
                  context: context,
                  service: roleService,
                  state: state,
                  role: AccountRoles.boutique,
                  icon: AppIcons.boutique,
                  title:
                      state?.canSell == true
                          ? 'Tableau Boutique'
                          : 'Ouvrir une boutique',
                  subtitle:
                      state?.canSell == true
                          ? 'Gérer produits, ventes et commandes'
                          : 'Créer votre vitrine de vente',
                  route: '/shop-dashboard',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: const LinearProgressIndicator(
        minHeight: 3,
        color: _primary,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _spaceTile({
    required BuildContext context,
    required AccountRoleService service,
    required AccountRoleState? state,
    required String role,
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    final enabled =
        role == AccountRoles.client || (state?.hasRole(role) ?? false);
    final isActive = (state?.activeRole ?? currentSpace) == role;
    final color = role == AccountRoles.boutique ? _violet : _primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _handleTap(context, service, role, route, enabled),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.1) : _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? color.withValues(alpha: 0.24) : _border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Actuel',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                enabled ? FeatherIcons.chevronRight : FeatherIcons.plus,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    AccountRoleService service,
    String role,
    String route,
    bool enabled,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    onBeforeNavigate?.call();

    if (!enabled && role != AccountRoles.client) {
      await navigator.push(
        MaterialPageRoute(
          builder: (context) => RoleOnboardingScreen(role: role),
        ),
      );
      return;
    }

    try {
      await service.switchActiveRole(role);
      if (!navigator.mounted) return;
      navigator.pushNamedAndRemoveUntil(route, (route) => false);
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Impossible de changer d’espace: $e')),
      );
    }
  }
}
