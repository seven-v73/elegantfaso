import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/location/salon_place.dart';
import '../../../../../models/salon/salon_context.dart';
import '../../../../../services/location/salon_location_service.dart';
import 'salon_place_sheet.dart';

class SalonMapScreen extends StatefulWidget {
  final SalonLocationSnapshot? initialSnapshot;
  final List<SalonPlace> initialPlaces;
  final void Function(SalonPlace place)? onOpenPlace;
  final SalonDiscoveryScope initialScope;

  const SalonMapScreen({
    super.key,
    this.initialSnapshot,
    this.initialPlaces = const [],
    this.onOpenPlace,
    this.initialScope = SalonDiscoveryScope.world,
  });

  @override
  State<SalonMapScreen> createState() => _SalonMapScreenState();
}

class _SalonMapScreenState extends State<SalonMapScreen> {
  final SalonLocationService _service = SalonLocationService();

  SalonPlaceType? _filter;
  SalonPlace? _selected;
  final _MapIntent _intent = _MapIntent.discover;
  final bool _showRoutes = false;
  late SalonDiscoveryScope _scope = widget.initialScope;
  late Future<SalonLocationSnapshot> _future =
      widget.initialSnapshot == null
          ? _load()
          : Future.value(widget.initialSnapshot);

  Future<SalonLocationSnapshot> _load() {
    return _service.loadNearby(limit: 220, scope: _scope);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      body: FutureBuilder<SalonLocationSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final allPlaces =
              data?.places.isNotEmpty == true
                  ? data!.places
                  : widget.initialPlaces;
          final places = _filteredPlaces(allPlaces);
          final routePlaces = _routePlaces(places);
          final selected =
              places.any((place) => place.id == _selected?.id)
                  ? _selected
                  : places.isNotEmpty
                  ? places.first
                  : null;

          if (_selected?.id != selected?.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selected = selected);
            });
          }

          return Stack(
            children: [
              Positioned.fill(
                child: _ImmersiveMapCanvas(
                  places: places,
                  routePlaces: routePlaces,
                  selected: selected,
                  showRoutes: _showRoutes,
                  loading:
                      snapshot.connectionState == ConnectionState.waiting &&
                      allPlaces.isEmpty,
                  onTapPlace: (place) => setState(() => _selected = place),
                  onOpenPlace: _showPlace,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Column(
                    children: [
                      _MapSearchBar(
                        scope: _scope,
                        count: places.length,
                        onRefresh:
                            () => setState(() {
                              _selected = null;
                              _future = _load();
                            }),
                      ),
                      const SizedBox(height: 10),
                      _PrimaryFilterRail(
                        selected: _filter,
                        onSelected: (type) {
                          setState(() {
                            _filter = _filter == type ? null : type;
                            _selected = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: MediaQuery.paddingOf(context).top + 132,
                child: _FloatingMapTools(
                  nearbySelected: _scope == SalonDiscoveryScope.nearby,
                  onNearby: () {
                    setState(() {
                      _scope = SalonDiscoveryScope.nearby;
                      _selected = null;
                      _future = _load();
                    });
                  },
                  onBrowse: () => _showAllPlaces(places),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 16 + MediaQuery.paddingOf(context).bottom,
                child:
                    places.isEmpty
                        ? _MapEmptyState(
                          onExpand: () {
                            setState(() {
                              _filter = null;
                              _scope = SalonDiscoveryScope.world;
                              _future = _load();
                            });
                          },
                          onShowBoutiques: () {
                            setState(() {
                              _filter = SalonPlaceType.boutique;
                              _scope = SalonDiscoveryScope.world;
                              _future = _load();
                            });
                          },
                          onShowAteliers: () {
                            setState(() {
                              _filter = SalonPlaceType.createur;
                              _scope = SalonDiscoveryScope.world;
                              _future = _load();
                            });
                          },
                        )
                        : _SelectedPlacePreview(
                          place: selected!,
                          nearbyLabel: _nearbyLabel(data),
                          insight: _placeInsight(selected),
                          onOpen: () => _showPlace(selected),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<SalonPlace> _routePlaces(List<SalonPlace> places) {
    if (places.isEmpty) return const [];
    final preferred = _intent.preferredTypes;
    final byType = <SalonPlaceType, List<SalonPlace>>{};
    for (final place in places) {
      byType.putIfAbsent(place.type, () => []).add(place);
    }
    final route = <SalonPlace>[];
    for (final type in preferred) {
      final candidate = byType[type]?.firstWhere(
        (place) => !route.any((item) => item.id == place.id),
        orElse: () => places.first,
      );
      if (candidate != null && !route.any((item) => item.id == candidate.id)) {
        route.add(candidate);
      }
    }
    for (final place in places) {
      if (route.length >= 4) break;
      if (!route.any((item) => item.id == place.id)) route.add(place);
    }
    return route.take(4).toList();
  }

  List<SalonPlace> _filteredPlaces(List<SalonPlace> places) {
    return places.where((place) {
      final filterOk = _filter == null || place.type == _filter;
      return filterOk;
    }).toList();
  }

  String _nearbyLabel(SalonLocationSnapshot? data) {
    if (_scope == SalonDiscoveryScope.nearby && data?.position != null) {
      return 'Autour de vous';
    }
    if (_scope == SalonDiscoveryScope.country) return 'Dans votre pays';
    return 'Salon monde';
  }

  String _placeInsight(SalonPlace place) {
    if (place.openNow) return 'Disponible maintenant';
    if (place.verified) return 'Profil vérifié';
    if (place.tags.isNotEmpty) return place.tags.first;
    if (place.type == SalonPlaceType.event) return 'À voir aujourd’hui';
    return place.subtitle;
  }

  void _showPlace(SalonPlace place) {
    SalonPlaceSheet.show(
      context,
      place: place,
      onOpenPlace:
          widget.onOpenPlace == null
              ? null
              : () {
                Navigator.pop(context);
                widget.onOpenPlace!(place);
              },
    );
  }

  void _showAllPlaces(List<SalonPlace> places) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _AllPlacesSheet(
            places: places,
            onSelected: (place) {
              Navigator.pop(context);
              setState(() => _selected = place);
              _showPlace(place);
            },
          ),
    );
  }
}

class _ImmersiveMapCanvas extends StatelessWidget {
  final List<SalonPlace> places;
  final List<SalonPlace> routePlaces;
  final SalonPlace? selected;
  final bool showRoutes;
  final bool loading;
  final ValueChanged<SalonPlace> onTapPlace;
  final ValueChanged<SalonPlace> onOpenPlace;

  const _ImmersiveMapCanvas({
    required this.places,
    required this.routePlaces,
    required this.selected,
    required this.showRoutes,
    required this.loading,
    required this.onTapPlace,
    required this.onOpenPlace,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final visible = places.take(34).toList();
        final clusters = _clustersFor(places.length);
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MapBackgroundPainter(showRoutes: showRoutes),
              ),
            ),
            if (showRoutes && routePlaces.length > 1)
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoutePainter(
                    points:
                        routePlaces
                            .map(
                              (place) => _positionFor(
                                place,
                                constraints.biggest,
                                places.indexOf(place),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            for (final cluster in clusters)
              _MapCluster(
                label: cluster.label,
                left: cluster.left * constraints.maxWidth,
                top: cluster.top * constraints.maxHeight,
              ),
            for (var i = 0; i < visible.length; i++)
              _MapMarker(
                place: visible[i],
                position: _positionFor(visible[i], constraints.biggest, i),
                selected: selected?.id == visible[i].id,
                onTap: () => onTapPlace(visible[i]),
                onDoubleTap: () => onOpenPlace(visible[i]),
              ),
            if (loading)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: ModernColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Offset _positionFor(SalonPlace place, Size size, int index) {
    final lat = place.latitude;
    final lng = place.longitude;
    if (lat != null && lng != null) {
      final x = ((lng + 180) / 360).clamp(0.08, 0.88);
      final y = ((90 - lat) / 180).clamp(0.18, 0.74);
      final nudge = _typeNudge(place.type);
      return Offset(
        (x * size.width + nudge.dx).clamp(26, size.width - 26),
        (y * size.height + nudge.dy).clamp(120, size.height - 90),
      );
    }
    final seed = place.id.codeUnits.fold<int>(index + 7, (sum, c) => sum + c);
    final x = 0.1 + ((seed * 37) % 76) / 100;
    final y = 0.22 + ((seed * 53) % 48) / 100;
    final nudge = _typeNudge(place.type);
    return Offset(
      (x * size.width + nudge.dx).clamp(26, size.width - 26),
      (y * size.height + nudge.dy).clamp(120, size.height - 90),
    );
  }

  Offset _typeNudge(SalonPlaceType type) {
    return switch (type) {
      SalonPlaceType.boutique => const Offset(-10, -8),
      SalonPlaceType.createur => const Offset(12, 8),
      SalonPlaceType.coiffeur => const Offset(10, -10),
      SalonPlaceType.cordonnier => const Offset(-12, 10),
      SalonPlaceType.event => const Offset(0, -14),
      SalonPlaceType.other => Offset.zero,
    };
  }

  List<_MapClusterData> _clustersFor(int count) {
    if (count < 9) return const [];
    return [
      _MapClusterData(
        label: count > 24 ? '${count ~/ 3}' : '8',
        left: .18,
        top: .38,
      ),
      if (count > 18)
        _MapClusterData(label: '${count ~/ 4}', left: .74, top: .31),
      if (count > 30)
        _MapClusterData(label: '${count ~/ 5}', left: .62, top: .62),
    ];
  }
}

class _MapSearchBar extends StatelessWidget {
  final SalonDiscoveryScope scope;
  final int count;
  final VoidCallback onRefresh;

  const _MapSearchBar({
    required this.scope,
    required this.count,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
        boxShadow: ModernShadows.elevated,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ModernColors.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.map_rounded,
                color: ModernColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Carte Salon',
                    style: TextStyle(
                      color: ModernColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${_scopeLabel(scope)} • $count lieux',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AppIconAction(
              icon: Icons.refresh_rounded,
              tooltip: 'Actualiser',
              onPressed: onRefresh,
            ),
          ],
        ),
      ),
    );
  }

  String _scopeLabel(SalonDiscoveryScope scope) {
    return switch (scope) {
      SalonDiscoveryScope.nearby => 'Autour de moi',
      SalonDiscoveryScope.country => 'Pays',
      SalonDiscoveryScope.world => 'Salon',
    };
  }
}

class _PrimaryFilterRail extends StatelessWidget {
  final SalonPlaceType? selected;
  final ValueChanged<SalonPlaceType?> onSelected;

  const _PrimaryFilterRail({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const filters = [
      (SalonPlaceType.boutique, 'Boutiques', AppIcons.boutique),
      (SalonPlaceType.createur, 'Ateliers', AppIcons.creator),
      (SalonPlaceType.event, 'Events', Icons.event_available_rounded),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          return _MiniMapChip(
            label: item.$2,
            icon: item.$3,
            selected: selected == item.$1,
            onTap: () => onSelected(item.$1),
          );
        },
      ),
    );
  }
}

class _MiniMapChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MiniMapChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected ? ModernColors.primary : Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 42, minWidth: 42),
          padding: EdgeInsets.symmetric(horizontal: label.isEmpty ? 11 : 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? ModernColors.primary : ModernColors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : ModernColors.primary,
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : ModernColors.ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingMapTools extends StatelessWidget {
  final bool nearbySelected;
  final VoidCallback onNearby;
  final VoidCallback onBrowse;

  const _FloatingMapTools({
    required this.nearbySelected,
    required this.onNearby,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MapIconButton(
          icon: Icons.my_location_rounded,
          tooltip: 'Autour de moi',
          selected: nearbySelected,
          onPressed: onNearby,
        ),
        const SizedBox(height: 10),
        _MapIconButton(
          icon: Icons.format_list_bulleted_rounded,
          tooltip: 'Tous les lieux',
          onPressed: onBrowse,
        ),
      ],
    );
  }
}

class _MapMarker extends StatelessWidget {
  final SalonPlace place;
  final Offset position;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const _MapMarker({
    required this.place,
    required this.position,
    required this.selected,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = selected ? 54.0 : 42.0;
    final multiRole = _isMultiRole(place);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: place.color.withValues(alpha: selected ? 0.2 : 0.12),
            shape: BoxShape.circle,
            boxShadow: selected ? ModernShadows.elevated : ModernShadows.card,
          ),
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: selected ? 38 : 30,
                  height: selected ? 38 : 30,
                  decoration: BoxDecoration(
                    color: place.color,
                    borderRadius: BorderRadius.circular(selected ? 15 : 12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    place.icon,
                    color: Colors.white,
                    size: selected ? 20 : 16,
                  ),
                ),
                if (multiRole)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: ModernColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isMultiRole(SalonPlace place) {
    final roles = place.data['roles'];
    final flags = place.data['roleFlags'];
    if (roles is Iterable) {
      final values = roles.map((role) => role.toString()).toSet();
      return values.contains('boutique') && values.contains('createur');
    }
    if (roles is Map) {
      return roles['boutique'] == true && roles['createur'] == true;
    }
    if (flags is Map) {
      return flags['isShop'] == true && flags['isCreator'] == true;
    }
    return false;
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      style: IconButton.styleFrom(
        backgroundColor:
            selected ? ModernColors.primary : ModernColors.surfaceRaised,
        foregroundColor: selected ? Colors.white : ModernColors.primary,
        disabledBackgroundColor: ModernColors.line.withValues(alpha: .45),
        disabledForegroundColor: ModernColors.muted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color:
              selected
                  ? ModernColors.primary.withValues(alpha: .4)
                  : ModernColors.line,
        ),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
    final style =
        outlined
            ? OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              foregroundColor: ModernColors.ink,
              side: const BorderSide(color: ModernColors.line),
            )
            : FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              backgroundColor: ModernColors.primary,
              foregroundColor: Colors.white,
            );
    return SizedBox(
      width: double.infinity,
      child:
          outlined
              ? OutlinedButton(onPressed: onPressed, style: style, child: child)
              : FilledButton(onPressed: onPressed, style: style, child: child),
    );
  }
}

class _RoleDualBadge extends StatelessWidget {
  final SalonPlace place;

  const _RoleDualBadge({required this.place});

  @override
  Widget build(BuildContext context) {
    final roles = place.data['roles'];
    final flags = place.data['roleFlags'];
    final roleValues =
        roles is Iterable
            ? roles.map((role) => role.toString()).toSet()
            : <String>{};
    final isDual =
        (roles is Iterable &&
            roleValues.contains('boutique') &&
            roleValues.contains('createur')) ||
        (roles is Map &&
            roles['boutique'] == true &&
            roles['createur'] == true) ||
        (flags is Map && flags['isShop'] == true && flags['isCreator'] == true);
    if (!isDual) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: ModernColors.accent.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hub_rounded, color: ModernColors.accent, size: 13),
          SizedBox(width: 5),
          Text(
            'Multi-rôle',
            style: TextStyle(
              color: ModernColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCluster extends StatelessWidget {
  final String label;
  final double left;
  final double top;

  const _MapCluster({
    required this.label,
    required this.left,
    required this.top,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: ModernColors.ink.withValues(alpha: .84),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: ModernShadows.card,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedPlacePreview extends StatelessWidget {
  final SalonPlace place;
  final String nearbyLabel;
  final String insight;
  final VoidCallback onOpen;

  const _SelectedPlacePreview({
    required this.place,
    required this.nearbyLabel,
    required this.insight,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      color: Colors.white.withValues(alpha: .96),
      elevated: true,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: place.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(place.icon, color: place.color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (place.verified)
                      const Icon(
                        Icons.verified_rounded,
                        color: ModernColors.primary,
                        size: 17,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${place.typeLabel} • ${place.distanceLabel} • $nearbyLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TinyInsightPill(
                      icon:
                          place.openNow
                              ? Icons.bolt_rounded
                              : place.verified
                              ? Icons.verified_rounded
                              : Icons.place_rounded,
                      label: insight,
                      color:
                          place.openNow
                              ? ModernColors.success
                              : place.verified
                              ? ModernColors.primary
                              : place.color,
                    ),
                    _RoleDualBadge(place: place),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _MapActionButton(
                        label: 'Voir',
                        onPressed: onOpen,
                        icon: Icons.open_in_new_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyInsightPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TinyInsightPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapEmptyState extends StatelessWidget {
  final VoidCallback onExpand;
  final VoidCallback onShowBoutiques;
  final VoidCallback onShowAteliers;

  const _MapEmptyState({
    required this.onExpand,
    required this.onShowBoutiques,
    required this.onShowAteliers,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: Colors.white.withValues(alpha: .96),
      elevated: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Aucun lieu proche pour ce filtre.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MapActionButton(
                  label: 'Élargir',
                  onPressed: onExpand,
                  icon: Icons.zoom_out_map_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MapActionButton(
                  label: 'Boutiques',
                  onPressed: onShowBoutiques,
                  icon: AppIcons.boutique,
                  outlined: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MapActionButton(
            label: 'Ateliers',
            onPressed: onShowAteliers,
            icon: AppIcons.creator,
            outlined: true,
          ),
        ],
      ),
    );
  }
}

class _AllPlacesSheet extends StatelessWidget {
  final List<SalonPlace> places;
  final ValueChanged<SalonPlace> onSelected;

  const _AllPlacesSheet({required this.places, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .72,
      minChildSize: .42,
      maxChildSize: .92,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView.separated(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: places.length + 1,
            separatorBuilder:
                (_, index) => SizedBox(height: index == 0 ? 12 : 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tous les lieux',
                            style: TextStyle(
                              color: ModernColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${places.length}',
                          style: const TextStyle(
                            color: ModernColors.inkSoft,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              final place = places[index - 1];
              return AppCard(
                onTap: () => onSelected(place),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: place.color.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(place.icon, color: place.color, size: 22),
                    ),
                    const SizedBox(width: 12),
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
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (place.verified)
                                const Icon(
                                  Icons.verified_rounded,
                                  color: ModernColors.primary,
                                  size: 17,
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${place.typeLabel} • ${place.distanceLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ModernColors.inkSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: ModernColors.muted,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

enum _MapIntent { shopping, eventLook, discover, beauty }

extension _MapIntentUi on _MapIntent {
  List<SalonPlaceType> get preferredTypes {
    return switch (this) {
      _MapIntent.shopping => [
        SalonPlaceType.boutique,
        SalonPlaceType.createur,
        SalonPlaceType.cordonnier,
      ],
      _MapIntent.eventLook => [
        SalonPlaceType.createur,
        SalonPlaceType.boutique,
        SalonPlaceType.coiffeur,
        SalonPlaceType.event,
      ],
      _MapIntent.discover => [
        SalonPlaceType.event,
        SalonPlaceType.boutique,
        SalonPlaceType.createur,
        SalonPlaceType.other,
      ],
      _MapIntent.beauty => [
        SalonPlaceType.coiffeur,
        SalonPlaceType.createur,
        SalonPlaceType.cordonnier,
      ],
    };
  }
}

class _MapClusterData {
  const _MapClusterData({
    required this.label,
    required this.left,
    required this.top,
  });

  final String label;
  final double left;
  final double top;
}

class _MapBackgroundPainter extends CustomPainter {
  final bool showRoutes;

  const _MapBackgroundPainter({required this.showRoutes});

  @override
  void paint(Canvas canvas, Size size) {
    final bg =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEAF6F3),
              const Color(0xFFF8FAFC),
              const Color(0xFFFFF7ED),
            ],
          ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final district =
        Paint()
          ..style = PaintingStyle.fill
          ..color = ModernColors.primary.withValues(alpha: .055);
    final warmDistrict =
        Paint()
          ..style = PaintingStyle.fill
          ..color = ModernColors.accent.withValues(alpha: .07);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .08,
          size.height * .28,
          size.width * .38,
          size.height * .22,
        ),
        const Radius.circular(42),
      ),
      district,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .55,
          size.height * .38,
          size.width * .34,
          size.height * .24,
        ),
        const Radius.circular(48),
      ),
      warmDistrict,
    );

    final road =
        Paint()
          ..color = Colors.white.withValues(alpha: .92)
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final roadEdge =
        Paint()
          ..color = ModernColors.line.withValues(alpha: .55)
          ..strokeWidth = 16
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final smallRoad =
        Paint()
          ..color = Colors.white.withValues(alpha: .66)
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final mainA =
        Path()
          ..moveTo(-30, size.height * .25)
          ..cubicTo(
            size.width * .22,
            size.height * .10,
            size.width * .45,
            size.height * .64,
            size.width + 30,
            size.height * .36,
          );
    final mainB =
        Path()
          ..moveTo(size.width * .03, size.height + 30)
          ..cubicTo(
            size.width * .18,
            size.height * .60,
            size.width * .72,
            size.height * .73,
            size.width * .88,
            -30,
          );
    canvas.drawPath(mainA, roadEdge);
    canvas.drawPath(mainA, road);
    canvas.drawPath(mainB, roadEdge);
    canvas.drawPath(mainB, road);

    for (var i = 0; i < 7; i++) {
      final y = size.height * (.18 + i * .095);
      canvas.drawLine(
        Offset(size.width * .06, y),
        Offset(size.width * .94, y + math.sin(i) * 28),
        smallRoad,
      );
    }
    for (var i = 0; i < 5; i++) {
      final x = size.width * (.16 + i * .17);
      canvas.drawLine(
        Offset(x, size.height * .12),
        Offset(x + math.cos(i) * 34, size.height * .82),
        smallRoad,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapBackgroundPainter oldDelegate) {
    return oldDelegate.showRoutes != showRoutes;
  }
}

class _RoutePainter extends CustomPainter {
  final List<Offset> points;

  const _RoutePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint =
        Paint()
          ..color = ModernColors.accent
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
