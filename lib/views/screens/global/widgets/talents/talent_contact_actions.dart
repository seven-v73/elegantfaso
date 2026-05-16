import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../models/talent/talent_profile.dart';
import '../../salon_search_screen.dart';

class TalentContactActions extends StatelessWidget {
  const TalentContactActions({
    super.key,
    required this.talent,
    required this.onAppointment,
  });

  final TalentProfile talent;
  final VoidCallback onAppointment;

  Future<void> _call(BuildContext context) async {
    if (talent.phone.isEmpty) {
      _snack(context, 'Numéro indisponible pour ce profil.');
      return;
    }
    final ok = await launchUrl(Uri.parse('tel:${talent.phone}'));
    if (!ok && context.mounted) _snack(context, 'Appel indisponible.');
  }

  Future<void> _whatsapp(BuildContext context) async {
    final phone = (talent.whatsapp.isNotEmpty ? talent.whatsapp : talent.phone)
        .replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) {
      _snack(context, 'Message direct indisponible pour ce profil.');
      return;
    }
    final ok = await launchUrl(
      Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent('Bonjour ${talent.displayName}, je vous ai découvert sur ElegantStyle.')}',
      ),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) _snack(context, 'Discussion indisponible.');
  }

  Future<void> _share(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: '${talent.displayName} · ${talent.speciality}',
          subject: 'Talent ElegantStyle',
        ),
      );
    } catch (_) {
      if (context.mounted) _snack(context, 'Partage indisponible.');
    }
  }

  void _openShowcase(BuildContext context) {
    final isShop = talent.primaryRole == 'Boutique';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SalonSearchScreen(
              initialQuery:
                  '${talent.displayName} ${isShop ? 'produits boutique' : 'créations atelier'}',
            ),
      ),
    );
  }

  Future<void> _openMap(BuildContext context) async {
    final place = talent.place.trim();
    if (place.isEmpty || place == 'En ligne') {
      _snack(context, 'Adresse indisponible pour cette vitrine.');
      return;
    }
    final query = Uri.encodeComponent('${talent.displayName} $place');
    final ok = await launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) _snack(context, 'Carte indisponible.');
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isShop = talent.primaryRole == 'Boutique';
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            constraints.maxWidth < 360
                ? constraints.maxWidth
                : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: itemWidth,
              child: AppButton(
                label: isShop ? 'Acheter' : 'Créations',
                onPressed: () => _openShowcase(context),
                icon: isShop ? AppIcons.shop : AppIcons.creations,
                expand: true,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AppButton(
                label: 'Message',
                onPressed: () => _whatsapp(context),
                icon: Icons.chat_rounded,
                variant: AppButtonVariant.secondary,
                expand: true,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AppButton(
                label: isShop ? 'Carte' : 'RDV',
                onPressed: isShop ? () => _openMap(context) : onAppointment,
                icon:
                    isShop ? Icons.map_rounded : Icons.event_available_rounded,
                variant: AppButtonVariant.secondary,
                expand: true,
              ),
            ),
            if (talent.phone.isNotEmpty)
              SizedBox(
                width: itemWidth,
                child: AppButton(
                  label: 'Appeler',
                  onPressed: () => _call(context),
                  icon: Icons.phone_rounded,
                  variant: AppButtonVariant.secondary,
                  expand: true,
                ),
              )
            else
              SizedBox(
                width: itemWidth,
                child: AppButton(
                  label: 'Partager',
                  onPressed: () => _share(context),
                  icon: Icons.ios_share_rounded,
                  variant: AppButtonVariant.secondary,
                  expand: true,
                ),
              ),
          ],
        );
      },
    );
  }
}
