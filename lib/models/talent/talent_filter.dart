class TalentFilter {
  const TalentFilter({
    this.role = 'Tous',
    this.location = '',
    this.availableOnly = false,
    this.verifiedOnly = false,
    this.withCreationsOnly = false,
    this.withProductsOnly = false,
    this.madeToMeasureOnly = false,
    this.appointmentOnly = false,
    this.language = '',
  });

  final String role;
  final String location;
  final bool availableOnly;
  final bool verifiedOnly;
  final bool withCreationsOnly;
  final bool withProductsOnly;
  final bool madeToMeasureOnly;
  final bool appointmentOnly;
  final String language;

  TalentFilter copyWith({
    String? role,
    String? location,
    bool? availableOnly,
    bool? verifiedOnly,
    bool? withCreationsOnly,
    bool? withProductsOnly,
    bool? madeToMeasureOnly,
    bool? appointmentOnly,
    String? language,
  }) {
    return TalentFilter(
      role: role ?? this.role,
      location: location ?? this.location,
      availableOnly: availableOnly ?? this.availableOnly,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      withCreationsOnly: withCreationsOnly ?? this.withCreationsOnly,
      withProductsOnly: withProductsOnly ?? this.withProductsOnly,
      madeToMeasureOnly: madeToMeasureOnly ?? this.madeToMeasureOnly,
      appointmentOnly: appointmentOnly ?? this.appointmentOnly,
      language: language ?? this.language,
    );
  }
}
