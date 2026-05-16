import 'package:cloud_firestore/cloud_firestore.dart';

class CreatorAppointment {
  const CreatorAppointment({
    required this.id,
    required this.creatorId,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhoto,
    required this.reason,
    required this.notes,
    required this.status,
    required this.date,
    required this.raw,
  });

  final String id;
  final String creatorId;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String clientPhoto;
  final String reason;
  final String notes;
  final String status;
  final DateTime? date;
  final Map<String, dynamic> raw;

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isPreparing => status == 'preparing';
  bool get isDone => status == 'completed' || status == 'done';
  bool get isCancelled => status == 'cancelled';
  bool get isToday {
    if (date == null) return false;
    final now = DateTime.now();
    return date!.year == now.year &&
        date!.month == now.month &&
        date!.day == now.day;
  }

  String get statusLabel {
    return switch (status) {
      'confirmed' => 'Confirmé',
      'preparing' => 'Préparation',
      'completed' || 'done' => 'Terminé',
      'cancelled' => 'Annulé',
      _ => 'Demande reçue',
    };
  }

  String get nextActionLabel {
    if (isPending) return 'Confirmer';
    if (isConfirmed) return 'Préparer';
    if (isPreparing) return 'Terminer';
    return 'Voir';
  }

  String get nextStatus {
    if (isPending) return 'confirmed';
    if (isConfirmed) return 'preparing';
    if (isPreparing) return 'completed';
    return status;
  }

  factory CreatorAppointment.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return CreatorAppointment(
      id: doc.id,
      creatorId:
          data['creatorId']?.toString() ??
          data['createurId']?.toString() ??
          data['boutiqueId']?.toString() ??
          '',
      clientId:
          data['clientId']?.toString() ?? data['userId']?.toString() ?? '',
      clientName:
          data['clientName']?.toString() ??
          data['customerName']?.toString() ??
          data['clientEmail']?.toString() ??
          'Client',
      clientEmail: data['clientEmail']?.toString() ?? '',
      clientPhoto:
          data['clientPhoto']?.toString() ??
          data['clientPhotoUrl']?.toString() ??
          '',
      reason:
          data['reason']?.toString() ??
          data['type']?.toString() ??
          'Rendez-vous',
      notes: data['notes']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      date: _date(data['date'] ?? data['startAt'] ?? data['scheduledAt']),
      raw: data,
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
