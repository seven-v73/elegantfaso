import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/location/salon_place.dart';

class SalonPlaceSheet extends StatelessWidget {
  final SalonPlace place;
  final VoidCallback? onOpenPlace;

  const SalonPlaceSheet({super.key, required this.place, this.onOpenPlace});

  static Future<void> show(
    BuildContext context, {
    required SalonPlace place,
    VoidCallback? onOpenPlace,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SalonPlaceSheet(place: place, onOpenPlace: onOpenPlace),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.56,
      minChildSize: 0.34,
      maxChildSize: 0.84,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
              const SizedBox(height: 16),
              _PlaceHero(place: place),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: place.color.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(place.icon, color: place.color, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                place.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ModernColors.ink,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            if (place.verified)
                              const Icon(
                                Icons.verified_rounded,
                                color: ModernColors.primary,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${place.typeLabel} • ${place.distanceLabel} • $_statusLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.inkSoft,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(
                    icon:
                        place.openNow
                            ? Icons.bolt_rounded
                            : Icons.schedule_rounded,
                    label: _statusLabel,
                    color:
                        place.openNow
                            ? ModernColors.success
                            : ModernColors.primary,
                  ),
                  if (place.verified)
                    const _StatusChip(
                      icon: Icons.verified_rounded,
                      label: 'Vérifié',
                      color: ModernColors.primary,
                    ),
                  _StatusChip(
                    icon: place.icon,
                    label: place.typeLabel,
                    color: place.color,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PlaceMeta(place: place),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: _openLabel,
                      onPressed:
                          onOpenPlace == null
                              ? null
                              : () {
                                Navigator.pop(context);
                                onOpenPlace?.call();
                              },
                      icon: Icons.open_in_new_rounded,
                      expand: true,
                    ),
                  ),
                  if (place.hasCoordinates) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 52,
                      child: AppIconAction(
                        icon: Icons.directions_rounded,
                        tooltip: 'Itinéraire',
                        onPressed: () => _openDirections(context),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIconAction(
                    icon: Icons.ios_share_rounded,
                    tooltip: 'Partager',
                    onPressed: _share,
                  ),
                  const SizedBox(width: 10),
                  AppIconAction(
                    icon: Icons.phone_rounded,
                    tooltip: 'Appeler',
                    onPressed:
                        _phoneNumber.isEmpty ? null : () => _call(context),
                  ),
                  const SizedBox(width: 10),
                  AppIconAction(
                    icon: Icons.chat_rounded,
                    tooltip: 'Message',
                    onPressed:
                        onOpenPlace == null
                            ? null
                            : () {
                              Navigator.pop(context);
                              onOpenPlace?.call();
                            },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String get _openLabel {
    return switch (place.type) {
      SalonPlaceType.boutique => 'Voir boutique',
      SalonPlaceType.createur ||
      SalonPlaceType.coiffeur ||
      SalonPlaceType.cordonnier => 'Voir profil',
      SalonPlaceType.event => 'Voir agenda',
      SalonPlaceType.other => 'Explorer',
    };
  }

  String get _statusLabel {
    if (place.type == SalonPlaceType.event) return 'À venir';
    if (place.openNow) return 'Disponible';
    return 'Sur RDV';
  }

  String get _phoneNumber {
    for (final key in const [
      'phone',
      'telephone',
      'whatsapp',
      'ownerPhone',
      'shopProfile.phone',
      'creatorProfile.phone',
    ]) {
      final value = _valueAt(place.data, key)?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Object? _valueAt(Map<String, dynamic> data, String path) {
    Object? current = data;
    for (final part in path.split('.')) {
      if (current is! Map) return null;
      current = current[part];
    }
    return current;
  }

  Future<void> _call(BuildContext context) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: _phoneNumber));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appel indisponible.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _share() {
    return SharePlus.instance.share(
      ShareParams(
        subject: 'Adresse Salon',
        text: '${place.name} • ${place.typeLabel} • ${place.locationLabel}',
      ),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    final lat = place.latitude;
    final lng = place.longitude;
    if (lat == null || lng == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir l’itinéraire.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _PlaceMeta extends StatelessWidget {
  final SalonPlace place;

  const _PlaceMeta({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.place_rounded,
            size: 18,
            color: ModernColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              place.locationLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.ink,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          if (place.tags.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              place.tags.first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: place.color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaceHero extends StatelessWidget {
  final SalonPlace place;

  const _PlaceHero({required this.place});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 8,
        child:
            place.imageUrl.isEmpty
                ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: place.color.withValues(alpha: .12),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -24,
                        top: -26,
                        child: Icon(
                          place.icon,
                          size: 130,
                          color: place.color.withValues(alpha: .16),
                        ),
                      ),
                      Center(
                        child: Icon(place.icon, color: place.color, size: 42),
                      ),
                    ],
                  ),
                )
                : Image.network(
                  place.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, _, _) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: place.color.withValues(alpha: .12),
                        ),
                        child: Icon(place.icon, color: place.color, size: 42),
                      ),
                ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
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
