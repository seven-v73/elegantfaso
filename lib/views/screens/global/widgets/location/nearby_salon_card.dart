import 'package:flutter/material.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/location/salon_place.dart';
import '../../../../../models/salon/salon_context.dart';
import '../../../../../services/location/salon_location_service.dart';
import '../salon/salon_scope_switcher.dart';
import 'salon_map_screen.dart';

class NearbySalonCard extends StatefulWidget {
  final void Function(SalonPlace place)? onOpenPlace;
  final SalonDiscoveryScope scope;

  const NearbySalonCard({
    super.key,
    this.onOpenPlace,
    this.scope = SalonDiscoveryScope.world,
  });

  @override
  State<NearbySalonCard> createState() => _NearbySalonCardState();
}

class _NearbySalonCardState extends State<NearbySalonCard> {
  final SalonLocationService _service = SalonLocationService();
  late SalonDiscoveryScope _scope;
  late Future<SalonLocationSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _scope = widget.scope;
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant NearbySalonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope && widget.scope != _scope) {
      _scope = widget.scope;
      _future = _load();
    }
  }

  Future<SalonLocationSnapshot> _load() {
    return _service.loadNearby(limit: 30, scope: _scope);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SalonLocationSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final data = snapshot.data;
        final places = data?.places ?? const <SalonPlace>[];

        return AppCard(
          padding: EdgeInsets.zero,
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 154,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(ModernRadius.lg),
                  ),
                  child: _MiniMapPreview(places: places, loading: loading),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: ModernColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.near_me_rounded,
                            color: ModernColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Carte mode',
                                style: TextStyle(
                                  color: ModernColors.ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                              Text(
                                loading
                                    ? 'Recherche des adresses mode...'
                                    : _summary(data),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ModernColors.inkSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (data?.message.isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      Text(
                        data!.message,
                        style: const TextStyle(
                          color: ModernColors.inkSoft,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SalonScopeSwitcher(
                      value: _scope,
                      compact: true,
                      onChanged: (scope) {
                        setState(() {
                          _scope = scope;
                          _future = _load();
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Carte',
                            onPressed:
                                loading ? null : () => _openMap(data, places),
                            icon: Icons.map_rounded,
                            expand: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        AppIconAction(
                          icon: Icons.my_location_rounded,
                          tooltip: 'Actualiser',
                          onPressed: () {
                            setState(() {
                              _future = _load();
                            });
                          },
                        ),
                      ],
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

  void _openMap(SalonLocationSnapshot? snapshot, List<SalonPlace> places) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SalonMapScreen(
              initialSnapshot: snapshot,
              initialPlaces: places,
              initialScope: _scope,
              onOpenPlace: widget.onOpenPlace,
            ),
      ),
    );
  }

  String _summary(SalonLocationSnapshot? snapshot) {
    if (snapshot == null || snapshot.places.isEmpty) {
      return switch (_scope) {
        SalonDiscoveryScope.nearby =>
          'Activez la localisation pour les distances',
        SalonDiscoveryScope.country =>
          'Boutiques, talents et événements de votre pays',
        SalonDiscoveryScope.world =>
          'Boutiques, talents et événements du monde',
      };
    }
    final shops = snapshot.countByType(SalonPlaceType.boutique);
    final creators = snapshot.countByType(SalonPlaceType.createur);
    final events = snapshot.countByType(SalonPlaceType.event);
    return '$shops boutiques • $creators talents • $events événements';
  }
}

class _MiniMapPreview extends StatelessWidget {
  final List<SalonPlace> places;
  final bool loading;

  const _MiniMapPreview({required this.places, required this.loading});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniMapPainter(places: places),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ModernColors.primary.withValues(alpha: 0.08),
              ModernColors.client.withValues(alpha: 0.08),
              ModernColors.accent.withValues(alpha: 0.08),
            ],
          ),
        ),
        child:
            loading
                ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: ModernColors.primary,
                  ),
                )
                : Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: ModernColors.line),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.salon,
                            size: 16,
                            color: ModernColors.primary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Autour de moi • Monde entier',
                            style: TextStyle(
                              color: ModernColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  final List<SalonPlace> places;

  const _MiniMapPainter({required this.places});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
    final thinRoadPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.44)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

    final path =
        Path()
          ..moveTo(-10, size.height * 0.7)
          ..cubicTo(
            size.width * 0.25,
            size.height * 0.52,
            size.width * 0.42,
            size.height * 0.88,
            size.width + 10,
            size.height * 0.36,
          );
    canvas.drawPath(path, roadPaint);

    canvas.drawLine(
      Offset(size.width * 0.12, 0),
      Offset(size.width * 0.72, size.height),
      thinRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.88, 0),
      Offset(size.width * 0.2, size.height),
      thinRoadPaint,
    );

    final visible = places.take(8).toList();
    for (var i = 0; i < visible.length; i++) {
      final place = visible[i];
      final dx = (0.16 + (i * 0.17) % 0.72) * size.width;
      final dy = (0.18 + (i * 0.23) % 0.62) * size.height;
      final markerPaint = Paint()..color = place.color;
      canvas.drawCircle(Offset(dx, dy), 8, markerPaint);
      canvas.drawCircle(
        Offset(dx, dy),
        12,
        Paint()..color = place.color.withValues(alpha: 0.18),
      );
      canvas.drawCircle(Offset(dx, dy), 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) {
    return oldDelegate.places != places;
  }
}
