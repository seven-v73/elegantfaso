import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/createur/creator_appointment.dart';

class CreatorAppointmentService {
  CreatorAppointmentService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<CreatorAppointment>> watchAppointments(String creatorId) {
    if (creatorId.isEmpty) return Stream.value(const []);
    final byCreator =
        _firestore
            .collection('appointments')
            .where('creatorId', isEqualTo: creatorId)
            .snapshots();
    final byCreateur =
        _firestore
            .collection('appointments')
            .where('createurId', isEqualTo: creatorId)
            .snapshots();

    return Rx.combineLatest2(byCreator, byCreateur, (
      QuerySnapshot<Map<String, dynamic>> creatorSnapshot,
      QuerySnapshot<Map<String, dynamic>> createurSnapshot,
    ) {
      final docs =
          {
            for (final doc in creatorSnapshot.docs) doc.id: doc,
            for (final doc in createurSnapshot.docs) doc.id: doc,
          }.values;
      final appointments = docs.map(CreatorAppointment.fromDoc).toList();
      appointments.sort((a, b) {
        final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });
      return appointments;
    });
  }

  Future<List<CreatorAppointment>> loadAppointments(String creatorId) async {
    final docs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final field in const ['creatorId', 'createurId']) {
      final snapshot =
          await _firestore
              .collection('appointments')
              .where(field, isEqualTo: creatorId)
              .limit(80)
              .get();
      for (final doc in snapshot.docs) {
        docs[doc.id] = doc;
      }
    }
    return docs.values.map(CreatorAppointment.fromDoc).toList();
  }

  Future<void> updateStatus(String appointmentId, String status) {
    return _firestore.collection('appointments').doc(appointmentId).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> createAppointment({
    required String creatorId,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required DateTime date,
    required String reason,
  }) {
    return _firestore.collection('appointments').add({
      'creatorId': creatorId,
      'createurId': creatorId,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'date': Timestamp.fromDate(date),
      'reason': reason,
      'status': 'pending',
      'source': 'creator_crm',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setAvailability({
    required String creatorId,
    required String dayKey,
    required String timeKey,
    required bool available,
  }) {
    return _firestore
        .collection('availability')
        .doc(creatorId)
        .collection('days')
        .doc(dayKey)
        .collection('slots')
        .doc(timeKey)
        .set({
          'startTime': timeKey,
          'available': available,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Stream<Map<String, bool>> watchAvailability(String creatorId, String dayKey) {
    if (creatorId.isEmpty) return Stream.value(const {});
    return _firestore
        .collection('availability')
        .doc(creatorId)
        .collection('days')
        .doc(dayKey)
        .collection('slots')
        .snapshots()
        .map((snapshot) {
          return {
            for (final doc in snapshot.docs)
              doc.id: doc.data()['available'] == true,
          };
        });
  }
}
