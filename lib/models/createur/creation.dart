class Creation {
  final String? id;
  final String title;
  final String description;
  final String category;
  final List<String> images;
  final DateTime createdAt;

  Creation({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.images,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Creation.fromJson(Map<String, dynamic> json, String id) {
    return Creation(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}