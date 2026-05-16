import 'package:cloud_firestore/cloud_firestore.dart';

class ProStory {
  const ProStory({
    required this.id,
    required this.authorId,
    required this.authorRole,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.mediaType,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.ctaLabel = '',
    this.ctaRoute = '',
  });

  factory ProStory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return ProStory(
      id: doc.id,
      authorId: data['authorId']?.toString() ?? '',
      authorRole: data['authorRole']?.toString() ?? '',
      authorName: data['authorName']?.toString() ?? 'Compte certifié',
      authorPhotoUrl: data['authorPhotoUrl']?.toString() ?? '',
      mediaUrl: data['mediaUrl']?.toString() ?? '',
      thumbnailUrl: data['thumbnailUrl']?.toString() ?? '',
      mediaType: data['mediaType']?.toString() ?? 'image',
      caption: data['caption']?.toString() ?? '',
      createdAt: parseDate(data['createdAt']),
      expiresAt: parseDate(data['expiresAt']),
      ctaLabel: data['ctaLabel']?.toString() ?? '',
      ctaRoute: data['ctaRoute']?.toString() ?? '',
    );
  }

  final String id;
  final String authorId;
  final String authorRole;
  final String authorName;
  final String authorPhotoUrl;
  final String mediaUrl;
  final String thumbnailUrl;
  final String mediaType;
  final String caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String ctaLabel;
  final String ctaRoute;

  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get isShop => authorRole == 'boutique';
  bool get isCreator => authorRole == 'createur';
}
