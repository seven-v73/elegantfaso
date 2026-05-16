enum SalonDiscoveryScope {
  nearby,
  country,
  world;

  String get label {
    return switch (this) {
      SalonDiscoveryScope.nearby => 'Autour',
      SalonDiscoveryScope.country => 'Mon pays',
      SalonDiscoveryScope.world => 'Monde',
    };
  }

  String get fullLabel {
    return switch (this) {
      SalonDiscoveryScope.nearby => 'Autour de moi',
      SalonDiscoveryScope.country => 'Mon pays',
      SalonDiscoveryScope.world => 'Monde entier',
    };
  }
}

class SalonContext {
  const SalonContext({
    this.query = '',
    this.type = '',
    this.occasion = '',
    this.city = '',
    this.country = '',
    this.scope = SalonDiscoveryScope.world,
    this.source = '',
  });

  final String query;
  final String type;
  final String occasion;
  final String city;
  final String country;
  final SalonDiscoveryScope scope;
  final String source;

  bool get isEmpty =>
      query.trim().isEmpty &&
      type.trim().isEmpty &&
      occasion.trim().isEmpty &&
      city.trim().isEmpty &&
      country.trim().isEmpty;

  String get displayQuery {
    final parts =
        [query, type, occasion, city, country]
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();
    return parts.join(' ');
  }

  SalonContext copyWith({
    String? query,
    String? type,
    String? occasion,
    String? city,
    String? country,
    SalonDiscoveryScope? scope,
    String? source,
  }) {
    return SalonContext(
      query: query ?? this.query,
      type: type ?? this.type,
      occasion: occasion ?? this.occasion,
      city: city ?? this.city,
      country: country ?? this.country,
      scope: scope ?? this.scope,
      source: source ?? this.source,
    );
  }

  factory SalonContext.fromQuery(String rawQuery, {String source = ''}) {
    final query = rawQuery.trim();
    final text = query.toLowerCase();
    String type = '';
    String occasion = '';

    if (text.contains('coiff')) type = 'coiffure';
    if (text.contains('chauss')) type = 'chaussure';
    if (text.contains('tenue') || text.contains('robe')) type = 'tenue';
    if (text.contains('accessoire')) type = 'accessoire';
    if (text.contains('mariage')) occasion = 'mariage';
    if (text.contains('bureau')) occasion = 'bureau';
    if (text.contains('soir')) occasion = 'soirée';
    if (text.contains('quotidien')) occasion = 'quotidien';

    return SalonContext(
      query: query,
      type: type,
      occasion: occasion,
      source: source,
    );
  }
}
