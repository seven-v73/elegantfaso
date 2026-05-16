import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/account_roles.dart';
import '../../models/location/salon_place.dart';
import '../../models/salon/salon_context.dart';

class SalonLocationSnapshot {
  final List<SalonPlace> places;
  final Position? position;
  final bool permissionDenied;
  final String message;

  const SalonLocationSnapshot({
    required this.places,
    required this.position,
    this.permissionDenied = false,
    this.message = '',
  });

  int countByType(SalonPlaceType type) {
    return places.where((place) => place.type == type).length;
  }
}

class SalonLocationService {
  SalonLocationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<SalonLocationSnapshot> loadNearby({
    int limit = 40,
    SalonDiscoveryScope scope = SalonDiscoveryScope.world,
  }) async {
    final position =
        scope == SalonDiscoveryScope.nearby ? await _tryGetPosition() : null;
    final area =
        scope == SalonDiscoveryScope.country ? await _loadUserArea() : null;
    final sourceLimit = limit < 120 ? 120 : limit;
    final sources = await Future.wait([
      _loadSalonPlaces(position: position, limit: sourceLimit),
      _loadUsersAsPlaces(position: position, limit: sourceLimit),
      _loadCreatorsFromCreationsAsPlaces(
        position: position,
        limit: sourceLimit,
      ),
      _loadEventsAsPlaces(position: position, limit: 60),
    ]);
    final places = sources.expand((source) => source).toList();

    final unique = <String, SalonPlace>{};
    for (final place in places) {
      final ownerKey = place.ownerId.isNotEmpty ? place.ownerId : place.id;
      final key = '${place.type.name}-$ownerKey';
      final existing = unique[key];
      unique[key] =
          existing == null || _rank(place) > _rank(existing) ? place : existing;
    }

    var sorted = unique.values.toList();
    if (scope == SalonDiscoveryScope.country &&
        (area?.country.isNotEmpty ?? false)) {
      final country = area!.country.toLowerCase();
      final filtered =
          sorted.where((place) {
            return place.country.toLowerCase().contains(country) ||
                place.locationLabel.toLowerCase().contains(country) ||
                place.data.values.join(' ').toLowerCase().contains(country);
          }).toList();
      if (filtered.isNotEmpty) sorted = filtered;
    }

    sorted.sort((a, b) {
      final ad = a.distanceKm ?? 999999;
      final bd = b.distanceKm ?? 999999;
      if (ad != bd) return ad.compareTo(bd);
      if (a.verified != b.verified) return a.verified ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return SalonLocationSnapshot(
      places: sorted.take(limit).toList(),
      position: position,
      permissionDenied: scope == SalonDiscoveryScope.nearby && position == null,
      message: _messageFor(scope, position: position, area: area),
    );
  }

  int _rank(SalonPlace place) {
    var score = 0;
    if (place.hasCoordinates) score += 8;
    if (place.imageUrl.isNotEmpty) score += 4;
    if (place.verified) score += 3;
    if (place.tags.isNotEmpty) score += 2;
    if (place.openNow) score += 1;
    return score;
  }

  String _messageFor(
    SalonDiscoveryScope scope, {
    required Position? position,
    required _UserArea? area,
  }) {
    return switch (scope) {
      SalonDiscoveryScope.nearby =>
        position == null
            ? 'Activez la localisation pour voir les distances autour de vous.'
            : 'Adresses mode proches de votre position, avec ouverture vers le monde.',
      SalonDiscoveryScope.country =>
        (area?.country.isNotEmpty ?? false)
            ? 'Boutiques, talents et événements dans ${area!.country}.'
            : 'Ajoutez votre pays au profil pour personnaliser cette vue.',
      SalonDiscoveryScope.world =>
        'Boutiques, talents et événements visibles dans le monde entier.',
    };
  }

  Future<_UserArea?> _loadUserArea() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? const {};
      return _UserArea(
        city: data['city']?.toString() ?? data['ville']?.toString() ?? '',
        country: data['country']?.toString() ?? data['pays']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  Future<Position?> _tryGetPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } on TimeoutException {
        return lastKnown;
      }
    } catch (_) {
      return null;
    }
  }

  Future<List<SalonPlace>> _loadSalonPlaces({
    required Position? position,
    required int limit,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection('salon_places')
              .where('isPublic', isEqualTo: true)
              .limit(limit)
              .get();
      return snapshot.docs
          .map(
            (doc) => SalonPlace.fromFirestore(
              doc,
              userLat: position?.latitude,
              userLng: position?.longitude,
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<SalonPlace>> _loadUsersAsPlaces({
    required Position? position,
    required int limit,
  }) async {
    final docsById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    final queries = [
      _firestore.collection('users').limit(limit),
      _firestore
          .collection('users')
          .where('roleFlags.isCreator', isEqualTo: true)
          .limit(limit),
      _firestore
          .collection('users')
          .where('roleFlags.isShop', isEqualTo: true)
          .limit(limit),
      _firestore
          .collection('users')
          .where('publicRole', isEqualTo: AccountRoles.createur)
          .limit(limit),
      _firestore
          .collection('users')
          .where('roles', arrayContains: AccountRoles.createur)
          .limit(limit),
      _firestore
          .collection('users')
          .where('roles', arrayContains: 'creator')
          .limit(limit),
    ];
    for (final queryRef in queries) {
      try {
        final snapshot = await queryRef.get();
        for (final doc in snapshot.docs) {
          docsById[doc.id] = doc;
        }
      } catch (_) {
        // Keep rendering from the sources that are allowed/indexed.
      }
    }
    return docsById.values
        .where(_looksPublic)
        .expand(
          (doc) => _placesFromUserDoc(
            doc,
            userLat: position?.latitude,
            userLng: position?.longitude,
          ),
        )
        .toList();
  }

  List<SalonPlace> _placesFromUserDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    double? userLat,
    double? userLng,
  }) {
    final data = doc.data();
    final roles =
        _businessRolesFrom(
          data,
        ).where((role) => AccountRoles.businessRoles.contains(role)).toList();
    if (roles.isEmpty) return const [];
    return roles.map((role) {
      final roleData = _roleSpecificData(data, role, ownerId: doc.id);
      return SalonPlace.fromData(
        id: '${doc.id}_$role',
        data: roleData,
        userLat: userLat,
        userLng: userLng,
      );
    }).toList();
  }

  Map<String, dynamic> _roleSpecificData(
    Map<String, dynamic> data,
    String role, {
    required String ownerId,
  }) {
    final profile =
        role == AccountRoles.boutique
            ? data['shopProfile']
            : data['creatorProfile'];
    final roleData =
        profile is Map ? Map<String, dynamic>.from(profile) : const {};
    final roleLocation = roleData['location'];
    final rootLocation = data['location'];
    final rootGeo = data['geo'];
    final lat =
        roleData['latitude'] ??
        (roleLocation is Map ? roleLocation['latitude'] : null) ??
        data['latitude'] ??
        (rootLocation is Map ? rootLocation['latitude'] : null) ??
        (rootGeo is Map ? rootGeo['latitude'] : null);
    final lng =
        roleData['longitude'] ??
        (roleLocation is Map ? roleLocation['longitude'] : null) ??
        data['longitude'] ??
        (rootLocation is Map ? rootLocation['longitude'] : null) ??
        (rootGeo is Map ? rootGeo['longitude'] : null);
    final specialty =
        role == AccountRoles.boutique
            ? _firstText([
              data['boutiqueDescription'],
              roleData['description'],
              roleData['category'],
              data['specialty'],
            ])
            : _firstText([
              data['specialty'],
              roleData['specialty'],
              roleData['description'],
              roleData['bio'],
              data['bio'],
            ]);
    final description =
        role == AccountRoles.boutique
            ? _firstText([
              data['boutiqueDescription'],
              roleData['description'],
              data['description'],
            ])
            : _firstText([
              roleData['bio'],
              roleData['description'],
              data['bio'],
              data['description'],
            ]);
    final imageUrl =
        role == AccountRoles.boutique
            ? _firstText([
              data['boutiqueLogoUrl'],
              data['boutiquePhotoUrl'],
              roleData['logoUrl'],
              roleData['photoUrl'],
              data['photoUrl'],
            ])
            : _firstText([
              data['creatorPhotoUrl'],
              roleData['photoUrl'],
              data['photoUrl'],
              data['media.profileImage.thumbnailUrl'],
            ]);
    return {
      ...data,
      ...roleData,
      'ownerId': data['ownerId'] ?? data['userId'] ?? data['id'] ?? ownerId,
      'userId': data['userId'] ?? data['id'] ?? ownerId,
      'type': role,
      'role': role,
      'publicRole': role,
      'primaryRole': role,
      'activeRole': role,
      'isPublic': true,
      'publicProfile': true,
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
      if (lat != null && lng != null)
        'geo': {'latitude': lat, 'longitude': lng},
      'name':
          role == AccountRoles.boutique
              ? data['boutiqueName'] ??
                  roleData['shopName'] ??
                  roleData['name'] ??
                  data['displayName']
              : data['creatorName'] ??
                  roleData['name'] ??
                  data['displayName'] ??
                  data['name'],
      'displayName':
          role == AccountRoles.boutique
              ? data['boutiqueName'] ??
                  roleData['shopName'] ??
                  roleData['name'] ??
                  data['displayName']
              : data['creatorName'] ??
                  roleData['name'] ??
                  data['displayName'] ??
                  data['name'],
      'subtitle':
          specialty.isEmpty
              ? (role == AccountRoles.boutique
                  ? 'Boutique mode'
                  : 'Créateur mode')
              : specialty,
      'specialty': specialty,
      'speciality': specialty,
      'description': description,
      'bio': description,
      'imageUrl': imageUrl,
      'photoUrl': imageUrl,
      'city':
          roleData['city'] ??
          data['city'] ??
          data['ville'] ??
          roleData['address'],
      'country': roleData['country'] ?? data['country'] ?? data['pays'],
      'openNow': data['isOnline'] == true || data['openNow'] == true,
      'verified':
          data['verifiedBadge'] == true ||
          data['isVerified'] == true ||
          data['verified'] == true,
      'isVerified':
          data['verifiedBadge'] == true ||
          data['isVerified'] == true ||
          data['verified'] == true,
      'tags': [
        role,
        if (specialty.isNotEmpty) specialty,
        if ((roleData['category']?.toString() ?? '').isNotEmpty)
          roleData['category'].toString(),
        if ((roleData['specialty']?.toString() ?? '').isNotEmpty)
          roleData['specialty'].toString(),
        ..._stringList(data['competences']),
        ..._stringList(data['specialities']),
        ..._stringList(data['tags']),
      ],
    };
  }

  String _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  List<String> _stringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  Future<List<SalonPlace>> _loadEventsAsPlaces({
    required Position? position,
    required int limit,
  }) async {
    try {
      final snapshot = await _firestore.collection('events').limit(limit).get();
      return snapshot.docs
          .map(
            (doc) => SalonPlace.fromFirestore(
              doc,
              userLat: position?.latitude,
              userLng: position?.longitude,
            ),
          )
          .where((place) => place.city.isNotEmpty || place.hasCoordinates)
          .map((place) => _asEvent(place))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<SalonPlace>> _loadCreatorsFromCreationsAsPlaces({
    required Position? position,
    required int limit,
  }) async {
    try {
      final snapshot =
          await _firestore.collection('creations').limit(limit).get();
      final creationDocs =
          snapshot.docs.where((doc) => _isPublicContent(doc.data())).toList();
      final creatorIds =
          creationDocs
              .map((doc) => _creatorIdFromCreation(doc.data()))
              .where((id) => id.isNotEmpty)
              .toSet();
      if (creatorIds.isEmpty) return const [];
      final users = await _loadUserDataByIds(creatorIds);
      return users.entries.map((entry) {
        final roleData = _roleSpecificData(
          entry.value,
          AccountRoles.createur,
          ownerId: entry.key,
        );
        return SalonPlace.fromData(
          id: '${entry.key}_${AccountRoles.createur}',
          data: roleData,
          userLat: position?.latitude,
          userLng: position?.longitude,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, Map<String, dynamic>>> _loadUserDataByIds(
    Set<String> ids,
  ) async {
    final cleaned = ids.where((id) => id.trim().isNotEmpty).toList();
    final result = <String, Map<String, dynamic>>{};
    for (var start = 0; start < cleaned.length; start += 10) {
      final end = start + 10 > cleaned.length ? cleaned.length : start + 10;
      final chunk = cleaned.sublist(start, end);
      try {
        final snapshot =
            await _firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: chunk)
                .get();
        for (final doc in snapshot.docs) {
          result[doc.id] = doc.data();
        }
      } catch (_) {
        for (final id in chunk) {
          try {
            final doc = await _firestore.collection('users').doc(id).get();
            final data = doc.data();
            if (data != null) result[id] = data;
          } catch (_) {}
        }
      }
    }
    return result;
  }

  bool _looksPublic(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final text =
        '${data['role']} ${data['activeRole']} ${data['publicRole']} ${data['roles']} ${data['businessOnboarding']} ${data['shopProfile']} ${data['creatorProfile']} ${data['boutiqueName']} ${data['creatorName']} ${data['speciality']} ${data['specialty']} ${data['profession']} ${data['category']} ${data['bio']}'
            .toLowerCase();
    final roleFlags = data['roleFlags'];
    final roleText =
        '${data['role']} ${data['activeRole']} ${data['publicRole']} ${data['roles']}'
            .toLowerCase();
    if (data['admin'] == true ||
        data['isAdmin'] == true ||
        roleText.split(RegExp(r'\s+')).contains('admin') ||
        (roleFlags is Map && roleFlags['isAdmin'] == true)) {
      return false;
    }
    final hasBusinessRole = _businessRolesFrom(data).isNotEmpty;
    return data['isPublic'] == true ||
        data['publicProfile'] == true ||
        hasBusinessRole ||
        text.contains('boutique') ||
        text.contains('createur') ||
        text.contains('creator') ||
        text.contains('coiff') ||
        text.contains('tailleur') ||
        text.contains('styliste') ||
        text.contains('chauss');
  }

  String _creatorIdFromCreation(Map<String, dynamic> data) {
    return data['createurId']?.toString() ??
        data['creatorId']?.toString() ??
        data['sellerId']?.toString() ??
        data['ownerId']?.toString() ??
        '';
  }

  bool _isPublicContent(Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? '';
    final visibility = data['visibility']?.toString().toLowerCase() ?? '';
    final moderation = data['moderationStatus']?.toString().toLowerCase() ?? '';
    if (data['deleted'] == true || data['isDeleted'] == true) return false;
    if (data['isPublic'] == false || data['public'] == false) return false;
    if (status == 'draft' || status == 'hidden' || status == 'archived') {
      return false;
    }
    if (visibility == 'private' || visibility == 'hidden') return false;
    if (moderation == 'rejected' || moderation == 'blocked') return false;
    return true;
  }

  Set<String> _businessRolesFrom(Map<String, dynamic> data) {
    final roles = <String>{...AccountRoles.normalize(data)};

    void addRole(dynamic value) {
      final canonical = AccountRoles.canonical(value?.toString());
      if (canonical != null) roles.add(canonical);
    }

    addRole(data['publicRole']);
    addRole(data['primaryRole']);
    final onboarding = data['businessOnboarding'];
    if (onboarding is Map) {
      final creator = onboarding['createur'] ?? onboarding['creator'];
      final shop = onboarding['boutique'] ?? onboarding['shop'];
      if (creator is Map && _businessRoleEnabled(creator)) {
        roles.add(AccountRoles.createur);
      }
      if (shop is Map && _businessRoleEnabled(shop)) {
        roles.add(AccountRoles.boutique);
      }
    }

    final text =
        '${data['creatorProfile']} ${data['creatorName']} ${data['specialty']} ${data['speciality']} ${data['profession']}'
            .toLowerCase();
    if (text.contains('createur') ||
        text.contains('creator') ||
        text.contains('créateur') ||
        text.contains('styliste') ||
        text.contains('tailleur')) {
      roles.add(AccountRoles.createur);
    }
    return roles
        .where((role) => AccountRoles.businessRoles.contains(role))
        .toSet();
  }

  bool _businessRoleEnabled(Map<dynamic, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? '';
    return status == 'active' ||
        status == 'approved' ||
        status == 'enabled' ||
        data['enabled'] == true;
  }

  SalonPlace _asEvent(SalonPlace place) {
    return SalonPlace(
      id: place.id,
      ownerId: place.ownerId,
      type: SalonPlaceType.event,
      name: place.name,
      subtitle: place.subtitle,
      imageUrl: place.imageUrl,
      city: place.city,
      country: place.country,
      latitude: place.latitude,
      longitude: place.longitude,
      tags: place.tags,
      verified: place.verified,
      openNow: place.openNow,
      rating: place.rating,
      distanceKm: place.distanceKm,
      data: place.data,
    );
  }
}

class _UserArea {
  const _UserArea({required this.city, required this.country});

  final String city;
  final String country;
}
