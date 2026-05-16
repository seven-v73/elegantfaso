class EventFilter {
  const EventFilter({this.label = 'Tous', this.query = '', this.city = ''});

  final String label;
  final String query;
  final String city;

  EventFilter copyWith({String? label, String? query, String? city}) {
    return EventFilter(
      label: label ?? this.label,
      query: query ?? this.query,
      city: city ?? this.city,
    );
  }
}
