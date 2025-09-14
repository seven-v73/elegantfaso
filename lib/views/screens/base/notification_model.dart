import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Modèle de données pour une notification
class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? additionalData;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.additionalData,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      additionalData: data['additionalData'],
    );
  }
}
