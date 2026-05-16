import 'package:cloud_firestore/cloud_firestore.dart';

class EventRegistration {
  const EventRegistration({
    required this.eventId,
    required this.userId,
    required this.status,
    required this.createdAt,
  });

  final String eventId;
  final String userId;
  final String status;
  final DateTime? createdAt;

  factory EventRegistration.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawDate = data['createdAt'];
    return EventRegistration(
      eventId:
          data['eventId']?.toString() ?? doc.reference.parent.parent?.id ?? '',
      userId: data['userId']?.toString() ?? doc.id,
      status: data['status']?.toString() ?? 'registered',
      createdAt: rawDate is Timestamp ? rawDate.toDate() : null,
    );
  }
}
