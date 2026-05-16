import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/events/event_registration.dart';
import '../../../../../models/events/salon_event.dart';
import '../../../../../services/events/event_registration_service.dart';
import '../../../../../services/events/event_reminder_service.dart';
import '../../salon_search_screen.dart';
import 'event_registration_sheet.dart';

class EventDetailSheet extends StatelessWidget {
  const EventDetailSheet({
    super.key,
    required this.event,
    required this.registrationService,
    required this.reminderService,
    required this.onLoginRequired,
  });

  final SalonEvent event;
  final EventRegistrationService registrationService;
  final EventReminderService reminderService;
  final VoidCallback onLoginRequired;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ModernColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _Poster(event: event),
              const SizedBox(height: 16),
              Text(
                event.type.toUpperCase(),
                style: const TextStyle(
                  color: ModernColors.shop,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                event.title,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 24,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.calendar_month_rounded,
                    label: event.dateLabel,
                  ),
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label: event.timeLabel,
                  ),
                  _InfoChip(icon: Icons.place_rounded, label: event.placeLabel),
                  _InfoChip(
                    icon: Icons.payments_rounded,
                    label: event.priceLabel,
                  ),
                  _InfoChip(
                    icon: Icons.event_seat_rounded,
                    label: event.capacityLabel,
                  ),
                  _InfoChip(
                    icon: Icons.public_rounded,
                    label: event.formatLabel,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ActionPanel(
                event: event,
                registrationService: registrationService,
                reminderService: reminderService,
                onLoginRequired: onLoginRequired,
              ),
              const SizedBox(height: 18),
              _DetailBlock(
                title: 'À propos',
                child: Text(
                  event.description,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _DetailBlock(
                title: 'Organisateur',
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: ModernColors.creator.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        AppIcons.talents,
                        color: ModernColors.creator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.organizerName,
                        style: const TextStyle(
                          color: ModernColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (event.organizerPhone.isNotEmpty)
                      AppIconAction(
                        icon: Icons.call_rounded,
                        tooltip: 'Appeler',
                        onPressed: () => _call(context, event.organizerPhone),
                      ),
                    const SizedBox(width: 8),
                    AppButton(
                      label: 'Voir',
                      onPressed: () => _openOrganizer(context),
                      variant: AppButtonVariant.tertiary,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de lancer l’appel.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openOrganizer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SalonSearchScreen(
              initialQuery:
                  event.organizerName.isEmpty
                      ? event.title
                      : event.organizerName,
            ),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.event,
    required this.registrationService,
    required this.reminderService,
    required this.onLoginRequired,
  });

  final SalonEvent event;
  final EventRegistrationService registrationService;
  final EventReminderService reminderService;
  final VoidCallback onLoginRequired;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EventRegistration?>(
      stream: registrationService.watchRegistration(event.id),
      builder: (context, registrationSnapshot) {
        final registration = registrationSnapshot.data;
        return StreamBuilder<bool>(
          stream: reminderService.watchReminder(event.id),
          builder: (context, reminderSnapshot) {
            final hasReminder = reminderSnapshot.data ?? false;
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label:
                            registration != null
                                ? 'Réservé'
                                : event.isFull
                                ? 'Complet'
                                : 'Participer',
                        onPressed:
                            registration != null || event.isFull
                                ? null
                                : () => _register(context),
                        icon: Icons.confirmation_number_rounded,
                        expand: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    AppIconAction(
                      onPressed: () => _toggleReminder(context, hasReminder),
                      tooltip: hasReminder ? 'Rappel activé' : 'Ajouter rappel',
                      icon:
                          hasReminder
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                      selected: hasReminder,
                    ),
                    const SizedBox(width: 8),
                    AppIconAction(
                      onPressed: () => _share(context),
                      tooltip: 'Partager',
                      icon: Icons.ios_share_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Itinéraire',
                        onPressed: () => _openMap(context),
                        icon: Icons.map_rounded,
                        variant: AppButtonVariant.outline,
                        expand: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Live',
                        onPressed:
                            event.onlineUrl.isEmpty
                                ? null
                                : () => _openUrl(context, event.onlineUrl),
                        icon: Icons.live_tv_rounded,
                        variant: AppButtonVariant.outline,
                        expand: true,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _register(BuildContext context) async {
    if (!registrationService.isSignedIn) {
      onLoginRequired();
      return;
    }
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => EventRegistrationSheet(
              event: event,
              onSubmit:
                  (note) => registrationService.register(event, note: note),
            ),
      );
      if (ok == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place réservée dans le Salon.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _toggleReminder(BuildContext context, bool hasReminder) async {
    if (reminderService.currentUserId == null) {
      onLoginRequired();
      return;
    }
    try {
      if (hasReminder) {
        await reminderService.removeReminder(event.id);
      } else {
        await reminderService.addReminder(event);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasReminder ? 'Rappel retiré.' : 'Rappel activé.'),
            action:
                hasReminder
                    ? null
                    : SnackBarAction(
                      label: 'Annuler',
                      onPressed: () => reminderService.removeReminder(event.id),
                    ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) onLoginRequired();
    }
  }

  Future<void> _share(BuildContext context) async {
    final data = event.toShareMap();
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Événement ElegantStyle',
          text:
              '${data['title']}\n${data['date']}\n${data['place']}\n${data['price']}',
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partage indisponible sur cet appareil.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openMap(BuildContext context) async {
    if (event.isOnline && event.onlineUrl.isNotEmpty) {
      await _openUrl(context, event.onlineUrl);
      return;
    }
    if (event.placeLabel == 'Lieu à confirmer') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le lieu sera confirmé par l’organisateur.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final query = Uri.encodeComponent(event.placeLabel);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir la carte.')),
      );
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lien indisponible pour cet événement.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.event});

  final SalonEvent event;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.55,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child:
            event.hasImage
                ? Image.network(
                  event.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _FallbackPoster(),
                )
                : const _FallbackPoster(),
      ),
    );
  }
}

class _FallbackPoster extends StatelessWidget {
  const _FallbackPoster();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ModernGradients.warm),
      child: const Center(
        child: Icon(
          Icons.event_available_rounded,
          color: Colors.white,
          size: 52,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: ModernColors.inkSoft),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: ModernColors.inkSoft,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
