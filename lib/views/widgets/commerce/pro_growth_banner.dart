import 'package:flutter/material.dart';

import '../../../design/modern_design_system.dart';
import '../../../models/commerce/platform_revenue.dart';
import '../../../services/commerce/pro_access_service.dart';
import '../../../services/commerce/pro_growth_service.dart';
import '../../../services/preferences/currency_service.dart';
import '../../screens/commerce/plan_visibility_screen.dart';

class ProGrowthBanner extends StatefulWidget {
  const ProGrowthBanner({
    super.key,
    required this.role,
    required this.accent,
    this.margin = const EdgeInsets.fromLTRB(16, 12, 16, 8),
  });

  final String role;
  final Color accent;
  final EdgeInsetsGeometry margin;

  @override
  State<ProGrowthBanner> createState() => _ProGrowthBannerState();
}

class _ProGrowthBannerState extends State<ProGrowthBanner> {
  final ProGrowthService _growthService = ProGrowthService();
  final ProAccessService _accessService = ProAccessService();

  @override
  void initState() {
    super.initState();
    _accessService.syncCurrentAccessLifecycle().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProGrowthState>(
      stream: _growthService.watchCurrentState(),
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state == null || state.isGuest || !state.hasBusinessRole) {
          return const SizedBox.shrink();
        }

        final hasPlan = state.hasActivePlan;
        final hasSignature = state.hasSignaturePlan;
        final hasPlacement = state.hasActiveBoost;
        final pendingPlacement = state.pendingBoostCount > 0;
        final pendingPlan = state.hasPendingPlan;
        final expiredPlan = state.hasExpiredPlan;
        final daysLeft = state.subscription?.daysUntilExpiration;

        return Container(
          margin: widget.margin,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.accent.withValues(alpha: 0.14)),
            boxShadow: ModernShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  hasPlacement
                      ? Icons.trending_up_rounded
                      : expiredPlan
                      ? Icons.refresh_rounded
                      : hasSignature
                      ? Icons.diamond_rounded
                      : Icons.storefront_rounded,
                  color: widget.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPlan
                          ? _activePlanTitle(state, daysLeft)
                          : expiredPlan
                          ? '${state.planLabel} expiré'
                          : pendingPlan
                          ? 'Plan en attente'
                          : 'Développer ma vitrine',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pendingPlacement
                          ? 'Mise en avant en attente de validation pour vos espaces pro.'
                          : expiredPlan
                          ? 'Renouvelez pour retrouver vos avantages.'
                          : pendingPlan
                          ? 'Votre demande est enregistrée. Paiement et validation côté admin.'
                          : hasPlan && !hasSignature
                          ? 'Signature ajoute vitrine immersive, boosts et visibilité saisonnière.'
                          : state.hasSharedRoles
                          ? 'Un réglage pro profite à la boutique et au créateur.'
                          : 'Rendez vos produits et créations plus faciles à trouver.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 40,
                child: FilledButton(
                  onPressed:
                      () => _showGrowthSheet(
                        context,
                        service: _growthService,
                        state: state,
                        role: widget.role,
                        accent: widget.accent,
                      ),
                  style: FilledButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: widget.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
                    expiredPlan
                        ? 'Renouveler'
                        : hasSignature
                        ? 'Mettre en avant'
                        : hasPlan
                        ? 'Signature'
                        : 'Voir',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _activePlanTitle(ProGrowthState state, int? daysLeft) {
    if (daysLeft == null) return '${state.planLabel} actif';
    if (daysLeft <= 0) return '${state.planLabel} expire aujourd’hui';
    if (daysLeft <= 7) return '${state.planLabel} · $daysLeft j';
    return '${state.planLabel} actif';
  }

  static void _showGrowthSheet(
    BuildContext context, {
    required ProGrowthService service,
    required ProGrowthState state,
    required String role,
    required Color accent,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: ModernColors.surface,
      builder: (sheetContext) {
        return StreamBuilder<CommerceRevenueConfig>(
          stream: service.watchRevenueConfig(),
          builder: (context, snapshot) {
            final config = snapshot.data ?? CommerceRevenueConfig();
            final currentPlan = ProGrowthService.normalizePlanForStorage(
              state.subscription?.plan ?? '',
            );
            final pendingPlan = ProGrowthService.normalizePlanForStorage(
              state.pendingPlan ?? '',
            );
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.trending_up_rounded, color: accent),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Visibilité professionnelle',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ModernColors.ink,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Abonnements et mises en avant liés au compte.',
                                style: TextStyle(
                                  color: ModernColors.inkSoft,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _GrowthStatusPanel(state: state, accent: accent),
                    const SizedBox(height: 12),
                    _GrowthOption(
                      accent: accent,
                      icon: Icons.storefront_rounded,
                      title: 'Plan Pro',
                      subtitle:
                          'Plus de publications, suivi renforcé et meilleure présence.',
                      price:
                          '${CurrencyService.format(config.proMonthlyPrice, code: config.currency)} / mois',
                      statusLabel:
                          state.hasPendingPlan && pendingPlan == 'pro'
                              ? 'En attente'
                              : currentPlan == 'pro' && state.hasActivePlan
                              ? 'Actif'
                              : null,
                      enabled:
                          !(state.hasPendingPlan ||
                              (currentPlan == 'pro' && state.hasActivePlan)),
                      onTap:
                          () => _openPlanVisibility(sheetContext, role, accent),
                    ),
                    const SizedBox(height: 10),
                    _GrowthOption(
                      accent: ModernColors.creator,
                      icon: Icons.diamond_rounded,
                      title: 'Plan Signature',
                      subtitle:
                          'Vitrine immersive, boosts 7 jours, analytics avancés et packs saisonniers.',
                      price:
                          '${CurrencyService.format(config.premiumMonthlyPrice, code: config.currency)} / mois',
                      statusLabel:
                          state.hasPendingPlan && pendingPlan == 'premium'
                              ? 'En attente'
                              : state.hasSignaturePlan
                              ? 'Actif'
                              : null,
                      enabled:
                          !(state.hasPendingPlan || state.hasSignaturePlan),
                      onTap:
                          () => _openPlanVisibility(sheetContext, role, accent),
                    ),
                    const SizedBox(height: 10),
                    _GrowthOption(
                      accent: ModernColors.success,
                      icon: Icons.trending_up_rounded,
                      title: 'Mise en avant compte',
                      subtitle:
                          state.hasSharedRoles
                              ? 'Met en avant vos créations et produits boutique.'
                              : 'Place votre profil dans les zones les plus visibles.',
                      price:
                          '${CurrencyService.format(config.boostBasePrice, code: config.currency)} / 7 jours',
                      statusLabel:
                          state.hasActiveBoost
                              ? 'Actif'
                              : state.pendingBoostCount > 0
                              ? 'En attente'
                              : !state.hasSignaturePlan
                              ? 'Signature'
                              : null,
                      enabled:
                          state.hasSignaturePlan &&
                          !(state.hasActiveBoost ||
                              state.pendingBoostCount > 0),
                      onTap:
                          () => _openPlanVisibility(sheetContext, role, accent),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Les demandes Pro, Signature et Boost se font dans un formulaire unique avec moyen de paiement et capture obligatoire.',
                      style: TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void _openPlanVisibility(
    BuildContext context,
    String role,
    Color accent,
  ) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => PlanVisibilityScreen(role: role, accent: accent),
      ),
    );
  }
}

class ProCertificationBadge extends StatelessWidget {
  const ProCertificationBadge({
    super.key,
    this.compact = false,
    this.accent = ModernColors.primary,
  });

  final bool compact;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final service = ProGrowthService();
    return StreamBuilder<ProGrowthState>(
      stream: service.watchCurrentState(),
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state == null || !state.hasActivePlan) {
          return const SizedBox.shrink();
        }
        final isSignature = state.hasSignaturePlan;
        final color = isSignature ? ModernColors.creator : accent;
        return Container(
          margin: EdgeInsets.only(top: compact ? 3 : 0),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 9,
            vertical: compact ? 3 : 6,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_rounded,
                color: color,
                size: compact ? 13 : 15,
              ),
              SizedBox(width: compact ? 4 : 6),
              Flexible(
                child: Text(
                  isSignature ? 'Certifié Signature' : 'Certifié Pro',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GrowthOption extends StatelessWidget {
  const _GrowthOption({
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
    this.statusLabel,
    this.enabled = true,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onTap;
  final String? statusLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = enabled ? accent : ModernColors.muted;
    return Material(
      color: ModernColors.surfaceRaised,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ModernColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: effectiveAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: effectiveAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (statusLabel != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: effectiveAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel!,
                        style: TextStyle(
                          color: effectiveAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                  Text(
                    price,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: effectiveAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrowthStatusPanel extends StatelessWidget {
  const _GrowthStatusPanel({required this.state, required this.accent});

  final ProGrowthState state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _StatusChip(
        icon: Icons.workspace_premium_rounded,
        label:
            state.hasActivePlan
                ? '${state.planLabel} actif'
                : state.hasPendingPlan
                ? 'Plan en attente'
                : 'Plan libre',
        color:
            state.hasActivePlan
                ? ModernColors.success
                : state.hasPendingPlan
                ? ModernColors.warning
                : accent,
      ),
      _StatusChip(
        icon: Icons.trending_up_rounded,
        label:
            state.hasActiveBoost
                ? 'Boost actif'
                : state.pendingBoostCount > 0
                ? 'Boost en attente'
                : 'Boost disponible',
        color:
            state.hasActiveBoost
                ? ModernColors.success
                : state.pendingBoostCount > 0
                ? ModernColors.warning
                : accent,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ModernColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernColors.line),
      ),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
