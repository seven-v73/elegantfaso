import 'package:cloud_firestore/cloud_firestore.dart';

enum ClientSavedType { owned, wishlist, inspiration, tryOn, project, favorite }

class ClientSavedItem {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final ClientSavedType type;
  final String sourceId;
  final String sourceType;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  const ClientSavedItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.type,
    this.sourceId = '',
    this.sourceType = '',
    this.createdAt,
    this.raw = const {},
  });

  factory ClientSavedItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return ClientSavedItem.fromMap(doc.id, data);
  }

  factory ClientSavedItem.fromMap(String id, Map<String, dynamic> data) {
    return ClientSavedItem(
      id: id,
      title:
          data['title']?.toString() ??
          data['name']?.toString() ??
          data['label']?.toString() ??
          'Inspiration sauvegardée',
      subtitle:
          data['subtitle']?.toString() ??
          data['category']?.toString() ??
          data['sourceType']?.toString() ??
          'Souhait',
      imageUrl:
          data['imageUrl']?.toString() ??
          data['image']?.toString() ??
          ((data['images'] as List?)?.isNotEmpty == true
              ? (data['images'] as List).first.toString()
              : ''),
      type: _typeFrom(data['type'] ?? data['savedType']),
      sourceId: data['sourceId']?.toString() ?? '',
      sourceType: data['sourceType']?.toString() ?? '',
      createdAt: _dateFrom(data['createdAt'] ?? data['savedAt']),
      raw: Map<String, dynamic>.from(data),
    );
  }

  static ClientSavedType _typeFrom(dynamic value) {
    final raw = value?.toString().toLowerCase() ?? '';
    return ClientSavedType.values.firstWhere(
      (type) => type.name.toLowerCase() == raw,
      orElse: () => ClientSavedType.wishlist,
    );
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
