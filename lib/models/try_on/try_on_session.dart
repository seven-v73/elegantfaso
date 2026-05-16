import 'package:cloud_firestore/cloud_firestore.dart';

import 'try_on_source.dart';

class TryOnSession {
  const TryOnSession({
    required this.id,
    required this.userId,
    required this.personImageUrl,
    required this.garmentImageUrl,
    required this.resultImageUrl,
    required this.garmentSourceType,
    this.garmentSourceId = '',
    this.status = 'completed',
    this.createdAt,
  });

  final String id;
  final String userId;
  final String personImageUrl;
  final String garmentImageUrl;
  final String resultImageUrl;
  final TryOnSourceType garmentSourceType;
  final String garmentSourceId;
  final String status;
  final DateTime? createdAt;

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'personImageUrl': personImageUrl,
      'garmentImageUrl': garmentImageUrl,
      'resultImageUrl': resultImageUrl,
      'garmentSourceType': garmentSourceType.name,
      'garmentSourceId': garmentSourceId,
      'status': status,
      'createdAt':
          createdAt == null
              ? FieldValue.serverTimestamp()
              : Timestamp.fromDate(createdAt!),
    };
  }
}
