class ConversationContextTypes {
  static const general = 'general';
  static const product = 'product';
  static const creation = 'creation';
  static const secondhand = 'secondhand';
  static const order = 'order';
  static const appointment = 'appointment';
  static const measurement = 'measurement';
  static const support = 'support';

  static const values = [
    general,
    product,
    creation,
    secondhand,
    order,
    appointment,
    measurement,
    support,
  ];
}

class ConversationStatuses {
  static const active = 'active';
  static const archived = 'archived';
  static const blocked = 'blocked';
  static const closed = 'closed';
}

class ConversationContext {
  const ConversationContext({
    this.type = ConversationContextTypes.general,
    this.id = '',
    this.title = '',
    this.subtitle = '',
    this.imageUrl = '',
    this.route = '',
    this.metadata = const {},
  });

  factory ConversationContext.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const ConversationContext();
    final type = map['type']?.toString() ?? ConversationContextTypes.general;
    return ConversationContext(
      type:
          ConversationContextTypes.values.contains(type)
              ? type
              : ConversationContextTypes.general,
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      route: map['route']?.toString() ?? '',
      metadata:
          map['metadata'] is Map
              ? Map<String, dynamic>.from(map['metadata'] as Map)
              : const {},
    );
  }

  final String type;
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String route;
  final Map<String, dynamic> metadata;

  bool get hasContent {
    return type != ConversationContextTypes.general ||
        title.isNotEmpty ||
        subtitle.isNotEmpty ||
        imageUrl.isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'route': route,
      'metadata': metadata,
    };
  }
}
