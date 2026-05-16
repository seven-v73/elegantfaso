import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/events/event_registration.dart';
import '../../models/events/salon_event.dart';

class EventRegistrationService {
  EventRegistrationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUserId => _auth.currentUser?.uid;
  bool get isSignedIn => currentUserId != null;

  Stream<EventRegistration?> watchRegistration(String eventId) {
    final userId = currentUserId;
    if (userId == null) return Stream.value(null);
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? EventRegistration.fromDoc(doc) : null);
  }

  Future<void> register(SalonEvent event, {String note = ''}) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Connexion requise');
    if (event.isFull) throw StateError('Événement complet');

    final eventRef = _firestore.collection('events').doc(event.id);
    final registrationRef = eventRef.collection('registrations').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final eventDoc = await transaction.get(eventRef);
      final data = eventDoc.data() ?? {};
      final capacity = (data['capacity'] as num?)?.toInt();
      final registered = (data['registeredCount'] as num?)?.toInt() ?? 0;
      final existing = await transaction.get(registrationRef);

      if (existing.exists) return;
      if (capacity != null && registered >= capacity) {
        throw StateError('Événement complet');
      }

      transaction.set(registrationRef, {
        'eventId': event.id,
        'userId': userId,
        'status': 'registered',
        'note': note.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(eventRef, {
        'registeredCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> cancel(String eventId) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Connexion requise');

    final eventRef = _firestore.collection('events').doc(eventId);
    final registrationRef = eventRef.collection('registrations').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(registrationRef);
      if (!existing.exists) return;
      transaction.delete(registrationRef);
      transaction.set(eventRef, {
        'registeredCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
