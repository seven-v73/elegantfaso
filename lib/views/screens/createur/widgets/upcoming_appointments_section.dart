import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UpcomingAppointmentsSection extends StatelessWidget {
  final String userId;

  const UpcomingAppointmentsSection({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('createurId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: DateTime.now())
          .orderBy('date')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Aucun RDV à venir', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final appointment = snapshot.data!.docs[index];
            final data = appointment.data() as Map<String, dynamic>? ?? {};
            final date = data['date'] != null ? (data['date'] as Timestamp).toDate() : null;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: const Icon(Icons.calendar_today, color: Color(0xFF4A6FA5)),
                title: Text(data['clientName'] ?? 'Client inconnu'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (date != null)
                      Text(DateFormat('EEE dd MMM yyyy, HH:mm').format(date)),
                    Text(
                      data['type'] ?? 'Type non spécifié',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}