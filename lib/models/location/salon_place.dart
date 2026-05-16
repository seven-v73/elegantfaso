import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../design/modern_design_system.dart';

enum SalonPlaceType { boutique, createur, coiffeur, cordonnier, event, other }

class SalonPlace {
  final String id;
  final String ownerId;
  final SalonPlaceType type;
  final String name;
  final String subtitle;
  final String imageUrl;
  final String city;
  final String country;
  final double? latitude;
  final double? longitude;
  final List<String> tags;
  final bool verified;
  final bool openNow;
  final double? rating;
  final double? distanceKm;
  final Map<String, dynamic> data;

  const SalonPlace({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.tags,
    required this.verified,
    required this.openNow,
    required this.rating,
    required this.data,
    this.distanceKm,
  });

  factory SalonPlace.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    double? userLat,
    double? userLng,
  }) {
    return SalonPlace.fromData(
      id: doc.id,
      data: doc.data() ?? const {},
      userLat: userLat,
      userLng: userLng,
    );
  }

  factory SalonPlace.fromData({
    required String id,
    required Map<String, dynamic> data,
    double? userLat,
    double? userLng,
  }) {
    final type = _typeFromData(data);
    final isShop = type == SalonPlaceType.boutique;
    final isCreator = type == SalonPlaceType.createur;
    final geo = data['geo'];
    final location = data['location'];
    final lat = _doubleFrom(
      data['latitude'] ??
          data['lat'] ??
          (geo is Map ? geo['latitude'] : null) ??
          (location is Map ? location['latitude'] : null),
    );
    final lng = _doubleFrom(
      data['longitude'] ??
          data['lng'] ??
          (geo is Map ? geo['longitude'] : null) ??
          (location is Map ? location['longitude'] : null),
    );
    return SalonPlace(
      id: id,
      ownerId: data['ownerId']?.toString() ?? data['userId']?.toString() ?? '',
      type: type,
      name:
          isShop
              ? _first(data, const [
                'name',
                'boutiqueName',
                'shopProfile.name',
                'displayName',
              ], 'Boutique mode')
              : isCreator
              ? _first(data, const [
                'name',
                'creatorName',
                'creatorProfile.name',
                'displayName',
              ], 'Créateur mode')
              : _first(data, const [
                'name',
                'displayName',
                'boutiqueName',
                'creatorName',
              ], 'Adresse mode'),
      subtitle: _first(data, const [
        'subtitle',
        'speciality',
        'specialty',
        'category',
        'profession',
        'shopProfile.category',
        'creatorProfile.specialty',
      ], 'Adresse mode'),
      imageUrl:
          isShop
              ? _first(data, const [
                'boutiqueLogoUrl',
                'boutiquePhotoUrl',
                'shopProfile.logoUrl',
                'shopProfile.photoUrl',
                'shopProfile.imageUrl',
                'imageUrl',
                'logoUrl',
              ], '')
              : isCreator
              ? _first(data, const [
                'creatorPhotoUrl',
                'creatorProfile.photoUrl',
                'creatorProfile.imageUrl',
                'creatorProfile.coverImage',
                'imageUrl',
              ], '')
              : _first(data, const [
                'imageUrl',
                'photoUrl',
                'photoURL',
                'logoUrl',
              ], ''),
      city: _first(data, const [
        'city',
        'ville',
        'address',
        'boutiqueAddress',
        'shopProfile.address',
        'creatorProfile.location',
      ], ''),
      country: data['country']?.toString() ?? data['pays']?.toString() ?? '',
      latitude: lat,
      longitude: lng,
      tags: _list(data['tags'] ?? data['skills'] ?? data['categories']),
      verified: data['verified'] == true || data['isVerified'] == true,
      openNow: data['openNow'] == true || data['availableNow'] == true,
      rating: _doubleFrom(data['rating']),
      distanceKm:
          lat != null && lng != null && userLat != null && userLng != null
              ? _distanceKm(userLat, userLng, lat, lng)
              : null,
      data: Map<String, dynamic>.from(data),
    );
  }

  SalonPlace copyWithDistance(double? distanceKm) {
    return SalonPlace(
      id: id,
      ownerId: ownerId,
      type: type,
      name: name,
      subtitle: subtitle,
      imageUrl: imageUrl,
      city: city,
      country: country,
      latitude: latitude,
      longitude: longitude,
      tags: tags,
      verified: verified,
      openNow: openNow,
      rating: rating,
      data: data,
      distanceKm: distanceKm,
    );
  }

  String get typeLabel {
    return switch (type) {
      SalonPlaceType.boutique => 'Boutique',
      SalonPlaceType.createur => 'Atelier',
      SalonPlaceType.coiffeur => 'Coiffure',
      SalonPlaceType.cordonnier => 'Chaussures',
      SalonPlaceType.event => 'Événement',
      SalonPlaceType.other => 'Mode',
    };
  }

  IconData get icon {
    return switch (type) {
      SalonPlaceType.boutique => Icons.storefront_rounded,
      SalonPlaceType.createur => Icons.palette_rounded,
      SalonPlaceType.coiffeur => Icons.content_cut_rounded,
      SalonPlaceType.cordonnier => Icons.directions_walk_rounded,
      SalonPlaceType.event => Icons.event_available_rounded,
      SalonPlaceType.other => Icons.place_rounded,
    };
  }

  Color get color {
    return switch (type) {
      SalonPlaceType.boutique => ModernColors.shop,
      SalonPlaceType.createur => ModernColors.creator,
      SalonPlaceType.coiffeur => ModernColors.client,
      SalonPlaceType.cordonnier => ModernColors.rose,
      SalonPlaceType.event => ModernColors.accent,
      SalonPlaceType.other => ModernColors.primary,
    };
  }

  String get locationLabel {
    final parts = [city, country].where((item) => item.trim().isNotEmpty);
    return parts.isEmpty ? 'Localisation à préciser' : parts.join(', ');
  }

  String get distanceLabel {
    final value = distanceKm;
    if (value == null) return locationLabel;
    if (value < 1) return '${(value * 1000).round()} m';
    return '${value.toStringAsFixed(value < 10 ? 1 : 0)} km';
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  static SalonPlaceType _typeFrom(dynamic value) {
    final text = value?.toString().toLowerCase() ?? '';
    if (text.contains('boutique') || text.contains('shop')) {
      return SalonPlaceType.boutique;
    }
    if (text.contains('coiff') || text.contains('beaut')) {
      return SalonPlaceType.coiffeur;
    }
    if (text.contains('chauss') || text.contains('cordonn')) {
      return SalonPlaceType.cordonnier;
    }
    if (text.contains('event') || text.contains('événement')) {
      return SalonPlaceType.event;
    }
    if (text.contains('creat') ||
        text.contains('créat') ||
        text.contains('styliste') ||
        text.contains('tailleur')) {
      return SalonPlaceType.createur;
    }
    return SalonPlaceType.other;
  }

  static SalonPlaceType _typeFromData(Map<String, dynamic> data) {
    final direct = _typeFrom(
      data['type'] ??
          data['publicRole'] ??
          data['primaryRole'] ??
          data['activeRole'],
    );
    if (direct != SalonPlaceType.other) return direct;

    final roles = data['roles'];
    if (roles is Iterable) {
      final text = roles.join(' ').toLowerCase();
      final fromRoles = _typeFrom(text);
      if (fromRoles != SalonPlaceType.other) return fromRoles;
    }
    if (roles is Map) {
      if (roles['boutique'] == true || roles['shop'] == true) {
        return SalonPlaceType.boutique;
      }
      if (roles['createur'] == true || roles['creator'] == true) {
        return SalonPlaceType.createur;
      }
    }

    final flags = data['roleFlags'];
    if (flags is Map) {
      if (flags['isShop'] == true) return SalonPlaceType.boutique;
      if (flags['isCreator'] == true) return SalonPlaceType.createur;
    }

    final onboarding = data['businessOnboarding'];
    if (onboarding is Map) {
      final shop = onboarding['boutique'];
      final creator = onboarding['createur'];
      if (shop is Map && shop['status'] == 'active') {
        return SalonPlaceType.boutique;
      }
      if (creator is Map && creator['status'] == 'active') {
        return SalonPlaceType.createur;
      }
    }

    return _typeFrom(
      '${data['role']} ${data['activeRole']} ${data['speciality']} '
      '${data['specialty']} ${data['profession']} ${data['category']} '
      '${data['boutiqueName']} ${data['creatorName']} '
      '${data['shopProfile']} ${data['creatorProfile']}',
    );
  }

  static List<String> _list(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static double? _doubleFrom(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String _first(
    Map<String, dynamic> data,
    List<String> fields,
    String fallback,
  ) {
    for (final field in fields) {
      final value = _valueAt(data, field)?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  static Object? _valueAt(Map<String, dynamic> data, String path) {
    Object? current = data;
    for (final part in path.split('.')) {
      if (current is! Map) return null;
      current = current[part];
    }
    return current;
  }

  static double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _radians(lat2 - lat1);
    final dLon = _radians(lon2 - lon1);
    final a =
        _sin2(dLat / 2) +
        _cos(_radians(lat1)) * _cos(_radians(lat2)) * _sin2(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _radians(double degrees) => degrees * 3.141592653589793 / 180;

  static double _sin2(double value) {
    final sin = _sin(value);
    return sin * sin;
  }

  static double _sin(double value) => math.sin(value);
  static double _cos(double value) => math.cos(value);
  static double _sqrt(double value) => math.sqrt(value);
  static double _atan2(double y, double x) => math.atan2(y, x);
}
