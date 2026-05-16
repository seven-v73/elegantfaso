import 'package:cloud_firestore/cloud_firestore.dart';

class StyleGuide {
  const StyleGuide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.steps,
    this.imageUrl = '',
    this.videoUrl = '',
    this.authorId = '',
    this.authorName = 'ElegantStyle',
    this.authorRole = 'editorial',
    this.linkedProducts = const [],
    this.linkedCreations = const [],
    this.tags = const [],
    this.featured = false,
  });

  factory StyleGuide.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return StyleGuide.fromMap(doc.data() ?? const {}, id: doc.id);
  }

  factory StyleGuide.fromMap(Map<String, dynamic> data, {String id = ''}) {
    return StyleGuide(
      id: id.isNotEmpty ? id : data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? 'Guide style',
      subtitle:
          data['subtitle']?.toString() ??
          data['description']?.toString() ??
          'Conseil pratique pour mieux composer ton look',
      category: data['category']?.toString() ?? 'Style',
      steps:
          (data['steps'] as Iterable?)
              ?.map((step) => step.toString())
              .where((step) => step.trim().isNotEmpty)
              .toList() ??
          const [],
      imageUrl: data['imageUrl']?.toString() ?? '',
      videoUrl: data['videoUrl']?.toString() ?? '',
      authorId: data['authorId']?.toString() ?? '',
      authorName: data['authorName']?.toString() ?? 'ElegantStyle',
      authorRole: data['authorRole']?.toString() ?? 'editorial',
      linkedProducts:
          (data['linkedProducts'] as Iterable?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      linkedCreations:
          (data['linkedCreations'] as Iterable?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      tags:
          (data['tags'] as Iterable?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      featured: data['featured'] == true,
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final List<String> steps;
  final String imageUrl;
  final String videoUrl;
  final String authorId;
  final String authorName;
  final String authorRole;
  final List<String> linkedProducts;
  final List<String> linkedCreations;
  final List<String> tags;
  final bool featured;

  bool get isProGuide => authorRole == 'boutique' || authorRole == 'createur';

  Map<String, dynamic> toFirestore({
    required String status,
    required String visibility,
  }) {
    return {
      'title': title,
      'subtitle': subtitle,
      'category': category,
      'steps': steps,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'linkedProducts': linkedProducts,
      'linkedCreations': linkedCreations,
      'tags': tags,
      'featured': featured,
      'status': status,
      'visibility': visibility,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
