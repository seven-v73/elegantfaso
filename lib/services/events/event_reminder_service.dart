import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/events/salon_event.dart';

class EventReminderService {
  EventReminderService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<bool> watchReminder(String eventId) {
    final userId = currentUserId;
    if (userId == null) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('event_reminders')
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> addReminder(SalonEvent event) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Connexion requise');
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('event_reminders')
        .doc(event.id)
        .set({
          'eventId': event.id,
          'title': event.title,
          'startAt': Timestamp.fromDate(event.startAt),
          'place': event.placeLabel,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> removeReminder(String eventId) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Connexion requise');
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('event_reminders')
        .doc(eventId)
        .delete();
  }
}
