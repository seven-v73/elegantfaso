part of 'garde_robe.dart';

class _WardrobeSummary {
  final int totalItems;
  final String dominantCategory;
  final int outfitIdeas;
  final WardrobeItem? lastAdded;

  const _WardrobeSummary({
    required this.totalItems,
    required this.dominantCategory,
    required this.outfitIdeas,
    this.lastAdded,
  });

  factory _WardrobeSummary.fromItems(List<WardrobeItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    final dominant =
        counts.entries.isEmpty
            ? 'Aucune'
            : (counts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .first
                .key;
    return _WardrobeSummary(
      totalItems: items.length,
      dominantCategory: dominant,
      outfitIdeas: (items.length / 3).floor(),
      lastAdded: items.isEmpty ? null : items.first,
    );
  }
}

class _OutfitIdea {
  final String name;
  final String occasion;
  final List<WardrobeItem> items;
  final int score;

  const _OutfitIdea({
    required this.name,
    required this.occasion,
    required this.items,
    required this.score,
  });
}
