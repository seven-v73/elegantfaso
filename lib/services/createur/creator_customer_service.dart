import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/createur/creator_appointment.dart';
import '../../models/createur/creator_customer.dart';

class CreatorCustomerService {
  CreatorCustomerService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<CreatorCustomer>> loadCustomers({
    required String creatorId,
    required List<CreatorAppointment> appointments,
  }) async {
    final creatorDoc =
        await _firestore.collection('users').doc(creatorId).get();
    final creatorData = creatorDoc.data() ?? {};
    final ids = <String>{
      ...List<String>.from(
        (creatorData['followers'] as Iterable? ?? const []).map(
          (item) => item.toString(),
        ),
      ),
      ...appointments
          .map((appointment) => appointment.clientId)
          .where((id) => id.isNotEmpty),
    };
    if (ids.isEmpty) return const [];

    final users = <String, Map<String, dynamic>>{};
    final idList = ids.toList();
    for (var i = 0; i < idList.length; i += 10) {
      final chunk = idList.skip(i).take(10).toList();
      final snapshot =
          await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
      for (final doc in snapshot.docs) {
        users[doc.id] = doc.data();
      }
    }

    return ids.map((id) {
      final data = users[id] ?? {};
      final userAppointments =
          appointments
              .where((appointment) => appointment.clientId == id)
              .toList();
      final isFollower = (creatorData['followers'] as Iterable? ?? const [])
          .map((item) => item.toString())
          .contains(id);
      final firstAppointment =
          userAppointments.isEmpty ? null : userAppointments.first;
      return CreatorCustomer(
        id: id,
        name:
            data['displayName']?.toString() ??
            data['name']?.toString() ??
            firstAppointment?.clientName ??
            'Client',
        email: data['email']?.toString() ?? firstAppointment?.clientEmail ?? '',
        phone:
            data['phone']?.toString() ?? data['phoneNumber']?.toString() ?? '',
        photoUrl:
            data['photoUrl']?.toString() ?? firstAppointment?.clientPhoto ?? '',
        typeLabel:
            userAppointments.isNotEmpty
                ? 'Rendez-vous'
                : isFollower
                ? 'Abonné'
                : 'Client',
        appointmentsCount: userAppointments.length,
        ordersCount: (data['ordersCount'] as num?)?.toInt() ?? 0,
        hasMeasurements:
            data['measurementsShared'] == true ||
            data['measurementProfileId'] != null,
      );
    }).toList();
  }
}
