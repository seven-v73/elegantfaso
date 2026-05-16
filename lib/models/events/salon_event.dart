import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/preferences/currency_service.dart';

class SalonEvent {
  const SalonEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.imageUrl,
    required this.startAt,
    required this.endAt,
    required this.city,
    required this.country,
    required this.venue,
    required this.isOnline,
    required this.onlineUrl,
    required this.organizerId,
    required this.organizerName,
    required this.organizerPhone,
    required this.price,
    this.currency = CurrencyService.defaultCode,
    required this.capacity,
    required this.registeredCount,
    required this.status,
    required this.tags,
    required this.audience,
    required this.createdAt,
    required this.raw,
  });

  final String id;
  final String title;
  final String description;
  final String type;
  final String imageUrl;
  final DateTime startAt;
  final DateTime? endAt;
  final String city;
  final String country;
  final String venue;
  final bool isOnline;
  final String onlineUrl;
  final String organizerId;
  final String organizerName;
  final String organizerPhone;
  final double price;
  final String currency;
  final int? capacity;
  final int registeredCount;
  final String status;
  final List<String> tags;
  final List<String> audience;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  bool get isFree => price <= 0;
  bool get isPaid => price > 0;
  bool get hasImage => imageUrl.trim().isNotEmpty;
  bool get isFull => capacity != null && registeredCount >= capacity!;
  bool get hasPlaces => !isFull;
  bool get isPast => startAt.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return startAt.year == now.year &&
        startAt.month == now.month &&
        startAt.day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final end = now.add(const Duration(days: 7));
    return startAt.isAfter(now.subtract(const Duration(days: 1))) &&
        startAt.isBefore(end);
  }

  bool get isThisWeekend {
    final weekday = startAt.weekday;
    final now = DateTime.now();
    final end = now.add(const Duration(days: 9));
    return (weekday == DateTime.saturday || weekday == DateTime.sunday) &&
        startAt.isAfter(now.subtract(const Duration(days: 1))) &&
        startAt.isBefore(end);
  }

  bool get targetsCreators =>
      audience.any((item) => item.toLowerCase().contains('createur')) ||
      searchText.contains('créateur') ||
      searchText.contains('createur') ||
      searchText.contains('boutique') ||
      searchText.contains('styliste');

  bool get targetsClients =>
      audience.any((item) => item.toLowerCase().contains('client')) ||
      searchText.contains('vente') ||
      searchText.contains('pop-up') ||
      searchText.contains('shopping');

  bool get isBeauty =>
      searchText.contains('coiff') ||
      searchText.contains('beauté') ||
      searchText.contains('beaute') ||
      searchText.contains('maquill');

  bool get isShopping =>
      searchText.contains('vente') ||
      searchText.contains('pop-up') ||
      searchText.contains('boutique') ||
      searchText.contains('shopping');

  String get dateLabel => DateFormat('EEE d MMM', 'fr').format(startAt);
  String get day => DateFormat('dd', 'fr').format(startAt);
  String get month =>
      DateFormat('MMM', 'fr').format(startAt).replaceAll('.', '');
  String get timeLabel {
    final start = DateFormat('HH:mm', 'fr').format(startAt);
    if (endAt == null) return start;
    return '$start - ${DateFormat('HH:mm', 'fr').format(endAt!)}';
  }

  String get placeLabel {
    if (isOnline && venue.isEmpty) return 'En ligne';
    final parts = [
      venue,
      city,
      country,
    ].where((item) => item.trim().isNotEmpty);
    return parts.isEmpty ? 'Lieu à confirmer' : parts.join(', ');
  }

  String get formatLabel {
    if (isOnline && venue.isNotEmpty) return 'Hybride';
    if (isOnline) return 'En ligne';
    return 'Présentiel';
  }

  String get priceLabel =>
      isFree ? 'Gratuit' : CurrencyService.format(price, code: currency);

  String get capacityLabel {
    if (capacity == null) return 'Places ouvertes';
    final remaining = (capacity! - registeredCount).clamp(0, capacity!);
    if (remaining == 0) return 'Complet';
    return '$remaining places restantes';
  }

  String get searchText =>
      '$title $description $type $city $country $venue $organizerName ${tags.join(' ')} ${audience.join(' ')}'
          .toLowerCase();

  factory SalonEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final start = _date(data['startAt'] ?? data['date'] ?? data['createdAt']);
    return SalonEvent(
      id: doc.id,
      title: _first(data, const ['title', 'name'], 'Événement mode'),
      description: _first(data, const [
        'description',
        'summary',
      ], 'Temps fort mode à découvrir dans le Salon.'),
      type: _first(data, const ['type', 'category'], 'Événement'),
      imageUrl: _first(data, const ['imageUrl', 'coverImage', 'posterUrl'], ''),
      startAt: start ?? DateTime.now(),
      endAt: _date(data['endAt']),
      city: _first(data, const ['city', 'ville'], ''),
      country: _first(data, const ['country', 'pays'], ''),
      venue: _first(data, const [
        'venue',
        'location',
        'address',
        'adresse',
      ], ''),
      isOnline: data['isOnline'] == true || data['online'] == true,
      onlineUrl: _first(data, const [
        'onlineUrl',
        'liveUrl',
        'link',
        'url',
      ], ''),
      organizerId: _first(data, const [
        'organizerId',
        'creatorId',
        'userId',
      ], ''),
      organizerName: _first(data, const [
        'organizerName',
        'creatorName',
        'hostName',
      ], 'Organisateur Salon'),
      organizerPhone: _first(data, const [
        'organizerPhone',
        'phone',
        'whatsapp',
      ], ''),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: data['currency']?.toString() ?? CurrencyService.defaultCode,
      capacity: (data['capacity'] as num?)?.toInt(),
      registeredCount: (data['registeredCount'] as num?)?.toInt() ?? 0,
      status: _first(data, const ['status'], 'published'),
      tags: _stringList(data['tags']),
      audience: _stringList(data['audience'] ?? data['targetAudience']),
      createdAt: _date(data['createdAt']),
      raw: data,
    );
  }

  Map<String, dynamic> toShareMap() {
    return {
      'title': title,
      'date': DateFormat('dd/MM/yyyy HH:mm', 'fr').format(startAt),
      'place': placeLabel,
      'price': priceLabel,
    };
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  static String _first(
    Map<String, dynamic> data,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  static List<String> _stringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
