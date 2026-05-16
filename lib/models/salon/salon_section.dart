import 'salon_item.dart';

class SalonSection {
  const SalonSection({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<SalonItem> items;

  bool get isEmpty => items.isEmpty;
}
