import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/events/event_filter.dart';
import '../../models/events/salon_event.dart';
import '../preferences/currency_service.dart';

class SalonEventService {
  SalonEventService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<SalonEvent>> watchEvents(EventFilter filter) {
    return _firestore
        .collection('events')
        .orderBy('startAt', descending: false)
        .limit(80)
        .snapshots()
        .map((snapshot) {
          final events =
              snapshot.docs
                  .map(SalonEvent.fromDoc)
                  .where((event) => _isVisible(event))
                  .where((event) => !event.isPast || event.isToday)
                  .where((event) => _matches(event, filter))
                  .toList();
          events.sort((a, b) => a.startAt.compareTo(b.startAt));
          return events;
        });
  }

  Future<List<SalonEvent>> loadEvents({int limit = 80}) async {
    final snapshot =
        await _firestore
            .collection('events')
            .orderBy('startAt', descending: false)
            .limit(limit)
            .get();
    return snapshot.docs
        .map(SalonEvent.fromDoc)
        .where((event) => _isVisible(event))
        .where((event) => !event.isPast || event.isToday)
        .toList();
  }

  Future<String> createProfessionalEvent({
    required String ownerId,
    required String plan,
    required String title,
    required String description,
    required String type,
    required DateTime startAt,
    DateTime? endAt,
    required String city,
    required String venue,
    required bool isOnline,
    required String onlineUrl,
    required double price,
    String currency = CurrencyService.defaultCode,
    int? capacity,
    String organizerName = '',
    String organizerPhone = '',
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError('Ajoutez un titre pour l’événement.');
    }
    if (startAt.isBefore(DateTime.now())) {
      throw ArgumentError('Choisissez une date à venir.');
    }

    final isSignature = plan == 'signature' || plan == 'premium';
    final doc = _firestore.collection('events').doc();
    await doc.set({
      'title': title.trim(),
      'description': description.trim(),
      'type': type.trim().isEmpty ? 'Événement' : type.trim(),
      'startAt': Timestamp.fromDate(startAt),
      if (endAt != null) 'endAt': Timestamp.fromDate(endAt),
      'city': city.trim(),
      'venue': venue.trim(),
      'isOnline': isOnline,
      'onlineUrl': onlineUrl.trim(),
      'organizerId': ownerId,
      'organizerName': organizerName.trim(),
      'organizerPhone': organizerPhone.trim(),
      'price': price,
      'currency': currency,
      if (capacity != null && capacity > 0) 'capacity': capacity,
      'registeredCount': 0,
      'status': 'published',
      'isPublic': true,
      'requiresSignature': isSignature,
      'requiresPremium': isSignature,
      'requiresPro': true,
      'visibilityTier': isSignature ? 'signature' : 'pro',
      'isFeatured': isSignature,
      'source': isSignature ? 'signature_agenda' : 'pro_agenda',
      'audience': const ['clients', 'createurs', 'boutiques'],
      'tags': [type.trim(), city.trim()].where((e) => e.isNotEmpty).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<String> createPremiumEvent({
    required String ownerId,
    required String title,
    required String description,
    required String type,
    required DateTime startAt,
    DateTime? endAt,
    required String city,
    required String venue,
    required bool isOnline,
    required String onlineUrl,
    required double price,
    int? capacity,
    String organizerName = '',
    String organizerPhone = '',
  }) {
    return createProfessionalEvent(
      ownerId: ownerId,
      plan: 'signature',
      title: title,
      description: description,
      type: type,
      startAt: startAt,
      endAt: endAt,
      city: city,
      venue: venue,
      isOnline: isOnline,
      onlineUrl: onlineUrl,
      price: price,
      capacity: capacity,
      organizerName: organizerName,
      organizerPhone: organizerPhone,
    );
  }

  bool _isVisible(SalonEvent event) {
    final status = event.status.toLowerCase();
    final isPublic = event.raw['isPublic'] != false;
    return isPublic &&
        (status == 'published' ||
            status == 'approved' ||
            status == 'active' ||
            status == 'validated');
  }

  bool _matches(SalonEvent event, EventFilter filter) {
    final query = filter.query.trim().toLowerCase();
    final queryOk = query.isEmpty || event.searchText.contains(query);
    final city = filter.city.trim().toLowerCase();
    final cityOk = city.isEmpty || event.searchText.contains(city);

    return queryOk && cityOk && _matchesLabel(event, filter.label);
  }

  bool _matchesLabel(SalonEvent event, String label) {
    final text = event.searchText;
    return switch (label) {
      'Défilés' => text.contains('défil') || text.contains('fashion week'),
      'Ateliers' => text.contains('atelier') || text.contains('formation'),
      'Pop-up' => text.contains('pop') || text.contains('vente'),
      'Casting' => text.contains('casting') || text.contains('mannequin'),
      'Aujourd’hui' => event.isToday,
      'Cette semaine' => event.isThisWeek,
      'Ce week-end' => event.isThisWeekend,
      'Gratuit' => event.isFree,
      'Payant' => event.isPaid,
      'Près de moi' => event.city.isNotEmpty,
      'Mode' =>
        text.contains('défil') ||
            text.contains('atelier') ||
            text.contains('mode') ||
            text.contains('fashion') ||
            text.contains('pop') ||
            event.isShopping,
      'Beauté' => event.isBeauty,
      'Live' =>
        event.isOnline || text.contains('live') || text.contains('online'),
      'En ligne' =>
        event.isOnline || text.contains('live') || text.contains('online'),
      'Places disponibles' => event.hasPlaces,
      'Pour créateurs' => event.targetsCreators,
      'Pour clients' => event.targetsClients,
      'Beauté / coiffure' => event.isBeauty,
      'Shopping / vente privée' => event.isShopping,
      _ => true,
    };
  }
}
