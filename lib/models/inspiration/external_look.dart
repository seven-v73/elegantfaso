import 'dart:convert';

class ExternalLook {
  const ExternalLook({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.source,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String source;
  final List<String> tags;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'source': source,
      'tags': tags,
    };
  }

  factory ExternalLook.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['imageUrl']?.toString() ?? '';
    return ExternalLook(
      id:
          json['id']?.toString().isNotEmpty == true
              ? json['id'].toString()
              : idFromImage(imageUrl),
      title: json['title']?.toString() ?? 'Inspiration mode',
      subtitle: json['subtitle']?.toString() ?? 'Souhait de garde-robe',
      imageUrl: imageUrl,
      source: json['source']?.toString() ?? 'Inspiration',
      tags: List<String>.from(json['tags'] ?? const []),
    );
  }

  static String idFromImage(String imageUrl) {
    final encoded = base64Url.encode(utf8.encode(imageUrl)).replaceAll('=', '');
    return encoded.length <= 360 ? encoded : encoded.substring(0, 360);
  }
}
