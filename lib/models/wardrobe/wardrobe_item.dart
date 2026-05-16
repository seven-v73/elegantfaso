import 'package:cloud_firestore/cloud_firestore.dart';

class WardrobeItem {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String brand;
  final String color;
  final String occasion;
  final String season;
  final String description;
  final List<String> images;
  final List<Map<String, dynamic>> media;
  final bool favorite;
  final bool isArchived;
  final int wearCount;
  final String tryOnExperience;
  final String tryOnExperienceLabel;
  final String tryOnKind;
  final String sourceType;
  final String sourceId;
  final String sourceImageUrl;
  final String sourceOwnerId;
  final Map<String, dynamic> sourceRaw;
  final DateTime? lastWornAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WardrobeItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.brand = '',
    this.color = '',
    this.occasion = '',
    this.season = '',
    this.description = '',
    this.images = const [],
    this.media = const [],
    this.favorite = false,
    this.isArchived = false,
    this.wearCount = 0,
    this.tryOnExperience = '',
    this.tryOnExperienceLabel = '',
    this.tryOnKind = '',
    this.sourceType = '',
    this.sourceId = '',
    this.sourceImageUrl = '',
    this.sourceOwnerId = '',
    this.sourceRaw = const {},
    this.lastWornAt,
    this.createdAt,
    this.updatedAt,
  });

  factory WardrobeItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return WardrobeItem.fromMap(doc.id, data);
  }

  factory WardrobeItem.fromMap(String id, Map<String, dynamic> data) {
    final images = _imagesFrom(data);
    return WardrobeItem(
      id: id,
      userId: data['userId']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Sans nom',
      category: data['category']?.toString() ?? 'Autre',
      brand: data['brand']?.toString() ?? '',
      color: data['color']?.toString() ?? '',
      occasion: data['occasion']?.toString() ?? '',
      season: data['season']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      images: images,
      media:
          (data['media'] as List? ?? const [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
      favorite: data['favorite'] == true,
      isArchived: data['isArchived'] == true,
      wearCount: (data['wearCount'] as num?)?.toInt() ?? 0,
      tryOnExperience: data['tryOnExperience']?.toString() ?? '',
      tryOnExperienceLabel: data['tryOnExperienceLabel']?.toString() ?? '',
      tryOnKind: data['tryOnKind']?.toString() ?? '',
      sourceType: data['sourceType']?.toString() ?? '',
      sourceId: data['sourceId']?.toString() ?? '',
      sourceImageUrl: data['sourceImageUrl']?.toString() ?? '',
      sourceOwnerId: data['sourceOwnerId']?.toString() ?? '',
      sourceRaw:
          data['sourceRaw'] is Map
              ? Map<String, dynamic>.from(data['sourceRaw'] as Map)
              : const {},
      lastWornAt: _dateFrom(data['lastWornAt']),
      createdAt: _dateFrom(data['createdAt']),
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool includeCreatedAt = false}) {
    return {
      'userId': userId,
      'name': name.trim(),
      'category': category,
      'brand': brand.trim(),
      'color': color.trim(),
      'occasion': occasion,
      'season': season,
      'description': description.trim(),
      'images': images,
      'media': media,
      'favorite': favorite,
      'isArchived': isArchived,
      'wearCount': wearCount,
      if (tryOnExperience.isNotEmpty) 'tryOnExperience': tryOnExperience,
      if (tryOnExperienceLabel.isNotEmpty)
        'tryOnExperienceLabel': tryOnExperienceLabel,
      if (tryOnKind.isNotEmpty) 'tryOnKind': tryOnKind,
      if (sourceType.isNotEmpty) 'sourceType': sourceType,
      if (sourceId.isNotEmpty) 'sourceId': sourceId,
      if (sourceImageUrl.isNotEmpty) 'sourceImageUrl': sourceImageUrl,
      if (sourceOwnerId.isNotEmpty) 'sourceOwnerId': sourceOwnerId,
      if (sourceRaw.isNotEmpty) 'sourceRaw': sourceRaw,
      'lastWornAt': lastWornAt == null ? null : Timestamp.fromDate(lastWornAt!),
      'updatedAt': FieldValue.serverTimestamp(),
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  WardrobeItem copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    String? brand,
    String? color,
    String? occasion,
    String? season,
    String? description,
    List<String>? images,
    List<Map<String, dynamic>>? media,
    bool? favorite,
    bool? isArchived,
    int? wearCount,
    String? tryOnExperience,
    String? tryOnExperienceLabel,
    String? tryOnKind,
    String? sourceType,
    String? sourceId,
    String? sourceImageUrl,
    String? sourceOwnerId,
    Map<String, dynamic>? sourceRaw,
    DateTime? lastWornAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WardrobeItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      color: color ?? this.color,
      occasion: occasion ?? this.occasion,
      season: season ?? this.season,
      description: description ?? this.description,
      images: images ?? this.images,
      media: media ?? this.media,
      favorite: favorite ?? this.favorite,
      isArchived: isArchived ?? this.isArchived,
      wearCount: wearCount ?? this.wearCount,
      tryOnExperience: tryOnExperience ?? this.tryOnExperience,
      tryOnExperienceLabel: tryOnExperienceLabel ?? this.tryOnExperienceLabel,
      tryOnKind: tryOnKind ?? this.tryOnKind,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceImageUrl: sourceImageUrl ?? this.sourceImageUrl,
      sourceOwnerId: sourceOwnerId ?? this.sourceOwnerId,
      sourceRaw: sourceRaw ?? this.sourceRaw,
      lastWornAt: lastWornAt ?? this.lastWornAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get coverImage => images.isEmpty ? '' : images.first;
  bool get isTryOnResult =>
      tryOnExperience.isNotEmpty || id.startsWith('try_on_');
  bool get canRetryTryOn => isTryOnResult && sourceImageUrl.trim().isNotEmpty;
  String get tryOnDisplayLabel {
    if (tryOnExperienceLabel.trim().isNotEmpty) {
      return tryOnExperienceLabel.trim();
    }
    return switch (tryOnExperience) {
      'faceAccessory' => 'Accessoire visage',
      'aiGarment' => 'Essayage IA',
      'freePreview' => 'Aperçu libre',
      _ => isTryOnResult ? 'Essayage' : '',
    };
  }

  static List<String> _imagesFrom(Map<String, dynamic> data) {
    final rawImages = data['images'];
    final images = <String>[];
    if (rawImages is List) {
      images.addAll(
        rawImages
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty),
      );
    }

    for (final key in const ['imageUrl', 'image', 'photoUrl', 'url']) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && !images.contains(value)) images.add(value);
    }

    final media = data['media'];
    if (media is List) {
      for (final item in media.whereType<Map>()) {
        final value =
            item['url']?.toString().trim() ??
            item['secureUrl']?.toString().trim() ??
            item['secure_url']?.toString().trim() ??
            item['optimizedUrl']?.toString().trim() ??
            item['thumbnailUrl']?.toString().trim() ??
            item['imageUrl']?.toString().trim() ??
            '';
        if (value.isNotEmpty && !images.contains(value)) images.add(value);
      }
    }

    return images;
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
