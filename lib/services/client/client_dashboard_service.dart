import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/client/client_dashboard_summary.dart';
import '../../models/client/client_saved_item.dart';
import '../../models/measurements/measurement_profile.dart';
import '../../models/wardrobe/wardrobe_item.dart';
import '../measurements/measurement_service.dart';
import '../wardrobe/wardrobe_service.dart';
import 'client_saved_service.dart';

class ClientDashboardService {
  ClientDashboardService({
    FirebaseFirestore? firestore,
    WardrobeService? wardrobeService,
    MeasurementService? measurementService,
    ClientSavedService? savedService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _wardrobeService = wardrobeService ?? WardrobeService(),
       _measurementService = measurementService ?? MeasurementService(),
       _savedService = savedService ?? ClientSavedService();

  final FirebaseFirestore _firestore;
  final WardrobeService _wardrobeService;
  final MeasurementService _measurementService;
  final ClientSavedService _savedService;
  String? _cachedUserId;
  DateTime? _cachedAt;
  List<dynamic>? _cachedResults;

  static const _summaryCacheDuration = Duration(seconds: 45);
  static const _optionalQueryTimeout = Duration(seconds: 5);

  Stream<ClientDashboardSummary> watchSummary(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().asyncMap((
      userDoc,
    ) async {
      final userData = userDoc.data() ?? const {};
      final results = await _loadSummaryParts(userId);

      return ClientDashboardSummary(
        userId: userId,
        displayName:
            userData['name']?.toString() ??
            userData['displayName']?.toString() ??
            'Client',
        email: userData['email']?.toString() ?? '',
        phone: userData['phone']?.toString() ?? '',
        bio: userData['bio']?.toString() ?? '',
        photoUrl:
            userData['photoUrl']?.toString() ??
            userData['photoURL']?.toString() ??
            userData['avatar']?.toString() ??
            '',
        coverPhoto: userData['coverPhoto']?.toString() ?? '',
        city:
            userData['city']?.toString() ??
            userData['ville']?.toString() ??
            userData['location']?.toString() ??
            '',
        paymentMethods: _paymentMethodsFrom(userData),
        followersCount: (userData['followers'] as List?)?.length ?? 0,
        followingCount: (userData['following'] as List?)?.length ?? 0,
        wardrobeItems: results[0] as List<WardrobeItem>,
        savedItems: results[1] as List<ClientSavedItem>,
        measurementProfile: results[2] as MeasurementProfile,
        activeOrdersCount: results[3] as int,
        unreadMessagesCount: results[4] as int,
        upcomingEventsCount: results[5] as int,
        activeAppointmentsCount: results[6] as int,
      );
    });
  }

  Future<List<dynamic>> _loadSummaryParts(String userId) async {
    final cachedAt = _cachedAt;
    final cachedResults = _cachedResults;
    if (_cachedUserId == userId &&
        cachedAt != null &&
        cachedResults != null &&
        DateTime.now().difference(cachedAt) < _summaryCacheDuration) {
      return cachedResults;
    }

    final results = await Future.wait<dynamic>([
      _loadWardrobe(userId),
      _loadSavedItems(userId),
      _loadMeasurement(userId),
      _countActiveOrders(userId),
      _countUnreadMessages(userId),
      _countUpcomingEvents(userId),
      _countActiveAppointments(userId),
    ]);
    _cachedUserId = userId;
    _cachedAt = DateTime.now();
    _cachedResults = results;
    return results;
  }

  Future<List<WardrobeItem>> _loadWardrobe(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wardrobe')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get()
          .timeout(_optionalQueryTimeout);
      return snapshot.docs
          .map(WardrobeItem.fromFirestore)
          .where((item) => !item.isArchived)
          .toList();
    } catch (_) {
      return _wardrobeService
          .watchItems(userId)
          .first
          .timeout(_optionalQueryTimeout, onTimeout: () => const []);
    }
  }

  Future<List<ClientSavedItem>> _loadSavedItems(String userId) async {
    try {
      return _savedService
          .watchSavedItems(userId)
          .first
          .timeout(_optionalQueryTimeout, onTimeout: () => const []);
    } catch (_) {
      return const [];
    }
  }

  Future<MeasurementProfile> _loadMeasurement(String userId) async {
    try {
      return _measurementService
          .getProfile(userId)
          .timeout(
            _optionalQueryTimeout,
            onTimeout: () => MeasurementProfile.empty(userId),
          );
    } catch (_) {
      return MeasurementProfile.empty(userId);
    }
  }

  Future<int> _countActiveOrders(String userId) async {
    final docs = <String>{};
    await Future.wait([
      _collectIds(
        docs,
        _firestore.collection('orders').where('userId', isEqualTo: userId),
      ),
      _collectIds(
        docs,
        _firestore.collection('orders').where('clientId', isEqualTo: userId),
      ),
      _collectIds(
        docs,
        _firestore
            .collection('salon_orders')
            .where('userId', isEqualTo: userId),
      ),
    ]);
    return docs.length;
  }

  Future<int> _countUnreadMessages(String userId) async {
    final docs = <String>{};
    await Future.wait([
      _collectIds(
        docs,
        _firestore
            .collection('conversations')
            .where('participants', arrayContains: userId),
      ),
      _collectIds(
        docs,
        _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .where('read', isEqualTo: false),
      ),
    ]);
    return docs.length;
  }

  Future<int> _countUpcomingEvents(String userId) async {
    final docs = <String>{};
    await Future.wait([
      _collectIds(
        docs,
        _firestore
            .collectionGroup('registrations')
            .where('userId', isEqualTo: userId)
            .where('status', whereIn: ['registered', 'confirmed']),
      ),
      _collectIds(
        docs,
        _firestore
            .collection('users')
            .doc(userId)
            .collection('event_reminders'),
      ),
    ]);
    return docs.length;
  }

  Future<int> _countActiveAppointments(String userId) async {
    final docs = <String>{};
    await Future.wait([
      _collectIds(
        docs,
        _firestore
            .collection('appointments')
            .where('clientId', isEqualTo: userId)
            .where('status', whereIn: ['pending', 'confirmed']),
      ),
      _collectIds(
        docs,
        _firestore
            .collection('rendez_vous')
            .where('clientId', isEqualTo: userId)
            .where('status', whereIn: ['pending', 'confirmed']),
      ),
    ]);
    return docs.length;
  }

  Future<void> _collectIds(
    Set<String> target,
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      final snapshot = await query
          .limit(40)
          .get()
          .timeout(_optionalQueryTimeout);
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? '';
        if (status == 'cancelled' ||
            status == 'canceled' ||
            status == 'delivered' ||
            status == 'completed' ||
            status == 'done') {
          continue;
        }
        target.add(doc.reference.path);
      }
    } catch (_) {
      // Queries may require indexes in some projects; the dashboard should
      // remain usable even when an optional data source is not ready yet.
    }
  }

  static Map<String, String> _paymentMethodsFrom(Map<String, dynamic> data) {
    final clientProfile = Map<String, dynamic>.from(
      data['clientProfile'] ?? const {},
    );
    final methods = <String, String>{
      ..._stringMap(data['paymentMethods']),
      ..._stringMap(clientProfile['paymentMethods']),
    };
    final method = data['paymentMethod']?.toString() ?? '';
    final number = data['paymentNumber']?.toString() ?? '';
    if (method.trim().isNotEmpty && number.trim().isNotEmpty) {
      methods[_paymentMethodLabel(method)] = number.trim();
    }
    return methods;
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    return value.map(
      (key, entry) => MapEntry(key.toString(), entry?.toString() ?? ''),
    )..removeWhere((key, entry) => key.trim().isEmpty || entry.trim().isEmpty);
  }

  static String _paymentMethodLabel(String value) {
    return switch (value.trim().toLowerCase()) {
      'orange_money' => 'Orange Money',
      'moov_money' => 'Moov Money',
      'wave' => 'Wave',
      'mobile_money' => 'Mobile Money',
      _ => value.trim().isEmpty ? 'Paiement mobile' : value.trim(),
    };
  }
}
