import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design/app_icons.dart';
import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _supportEmail = 'support@elegantstyle.app';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        title: const Text('À propos'),
        backgroundColor: ModernColors.canvas,
        foregroundColor: ModernColors.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            const _IdentityCard(),
            const SizedBox(height: 14),
            const _JourneyCard(),
            const SizedBox(height: 14),
            const _PossibilitiesCard(),
            const SizedBox(height: 14),
            const _AudienceCard(),
            const SizedBox(height: 14),
            const _CommitmentsCard(),
            const SizedBox(height: 14),
            _ContactCard(onEmail: _openEmail),
            const SizedBox(height: 14),
            const _VersionCard(),
          ],
        ),
      ),
    );
  }

  static Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'Contact ElegantStyle'},
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ModernColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: ModernColors.primary.withValues(alpha: 0.16),
              ),
            ),
            child: SvgPicture.asset(
              'assets/logo/logo.svg',
              colorFilter: const ColorFilter.mode(
                ModernColors.primary,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ElegantStyle',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Découvrez votre style, rencontrez les bons talents, donnez plus de sens à chaque pièce.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ModernColors.inkSoft,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _ManifestPill(label: 'Découvrir'),
              _ManifestPill(label: 'Composer'),
              _ManifestPill(label: 'Transmettre'),
            ],
          ),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (AppIcons.inspiration, 'Inspiration'),
      (Icons.face_retouching_natural_rounded, 'Essayage'),
      (AppIcons.cart, 'Achat'),
      (AppIcons.wardrobe, 'Garde-robe'),
      (Icons.recycling_rounded, 'Revente'),
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: AppIcons.salon,
            title: 'Pourquoi ElegantStyle',
          ),
          const SizedBox(height: 10),
          const Text(
            'ElegantStyle relie votre style personnel au Salon : créations, boutiques, essayages, garde-robe, vide-dressing et conseils du quotidien.',
            style: TextStyle(
              color: ModernColors.inkSoft,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: steps.length,
              separatorBuilder:
                  (_, index) => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: ModernColors.inkSoft,
                        size: 20,
                      ),
                    ),
                  ),
              itemBuilder: (context, index) {
                final step = steps[index];
                return _JourneyStep(icon: step.$1, label: step.$2);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PossibilitiesCard extends StatelessWidget {
  const _PossibilitiesCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        Icons.checkroom_rounded,
        'Composer un look',
        'Partir d’une pièce, d’une occasion ou d’une envie.',
      ),
      (
        AppIcons.creator,
        'Trouver un talent',
        'Créateurs, ateliers et pros adaptés à votre besoin.',
      ),
      (
        AppIcons.shop,
        'Acheter mieux',
        'Boutiques, créations et pièces prêtes à porter.',
      ),
      (
        Icons.recycling_rounded,
        'Revendre',
        'Donner une nouvelle vie aux pièces de votre garde-robe.',
      ),
      (
        AppIcons.calendar,
        'Préparer un moment',
        'Looks, lieux et pros liés à vos événements.',
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.touch_app_rounded,
            title: 'Ici, vous pouvez',
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.$1, color: ModernColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            color: ModernColors.inkSoft,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  const _AudienceCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      (AppIcons.profile, 'Clients', 'Découvrir, apprendre et mieux choisir.'),
      (
        AppIcons.boutique,
        'Boutiques',
        'Vendre, fidéliser et suivre les commandes.',
      ),
      (
        AppIcons.creator,
        'Créateurs',
        'Publier, rencontrer et préparer les RDV.',
      ),
      (
        Icons.admin_panel_settings_rounded,
        'Admin',
        'Sécuriser les paiements et la confiance.',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return AppCard(
          padding: const EdgeInsets.all(12),
          elevated: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.$1, color: ModernColors.primary),
              const SizedBox(height: 10),
              Text(
                item.$2,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.$3,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommitmentsCard extends StatelessWidget {
  const _CommitmentsCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        Icons.verified_user_rounded,
        'Confiance',
        'Des profils, paiements et avis mieux encadrés.',
      ),
      (
        Icons.recycling_rounded,
        'Circularité',
        'Chaque pièce peut continuer son histoire.',
      ),
      (
        Icons.palette_rounded,
        'Créativité locale',
        'Les talents et boutiques gagnent en visibilité.',
      ),
      (
        Icons.accessibility_new_rounded,
        'Style personnel',
        'Des choix adaptés aux envies, budgets et morphologies.',
      ),
      (
        Icons.lock_rounded,
        'Sécurité',
        'Les données utiles restent contrôlées et lisibles.',
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.favorite_rounded, title: 'Engagements'),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.$1, color: ModernColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: ModernColors.inkSoft,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: '${item.$2} · ',
                            style: const TextStyle(
                              color: ModernColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(text: item.$3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.onEmail});

  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.support_agent_rounded, title: 'Contact'),
          const SizedBox(height: 10),
          const Text(
            'Une question, un signalement ou une demande professionnelle ? L’équipe vous répond.',
            style: TextStyle(
              color: ModernColors.inkSoft,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEmail,
              icon: const Icon(Icons.mail_outline_rounded),
              label: const Text('Écrire à l’équipe'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManifestPill extends StatelessWidget {
  const _ManifestPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: ModernColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ModernColors.primary.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: ModernColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ModernColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: ModernColors.primary, size: 21),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ModernColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final version =
            info == null
                ? 'Version en cours'
                : 'Version ${info.version}+${info.buildNumber}';
        return AppCard(
          padding: const EdgeInsets.all(16),
          elevated: false,
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: ModernColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  version,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Text(
                '2026',
                style: TextStyle(
                  color: ModernColors.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: ModernColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: ModernColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
