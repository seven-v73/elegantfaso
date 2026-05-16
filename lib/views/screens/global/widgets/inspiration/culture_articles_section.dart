import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';

class CultureArticlesSection extends StatelessWidget {
  const CultureArticlesSection({super.key, required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final articles =
        FirebaseFirestore.instance
            .collection('inspiration_articles')
            .orderBy('publishedAt', descending: true)
            .limit(8)
            .get();
    final culture =
        FirebaseFirestore.instance
            .collection('fashion_culture')
            .orderBy('publishedAt', descending: true)
            .limit(8)
            .get();

    return FutureBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      future: Future.wait([articles, culture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppCard(
            child: SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final items =
            <Map<String, dynamic>>[
              ...?snapshot.data?[0].docs.map((doc) => doc.data()),
              ...?snapshot.data?[1].docs.map((doc) => doc.data()),
            ].where(_matchesSearch).toList();

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              padding: EdgeInsets.zero,
              title: 'Culture mode',
              subtitle: 'Histoires, matières et savoir-faire à découvrir',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return SizedBox(
                    width: 240,
                    child: AppCard(
                      onTap: () => _openArticle(context, item),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['category']?.toString() ?? 'Article',
                            style: const TextStyle(
                              color: ModernColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title']?.toString() ?? 'Culture mode',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ModernColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item['summary']?.toString() ??
                                item['description']?.toString() ??
                                'Lire le dossier',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ModernColors.inkSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  bool _matchesSearch(Map<String, dynamic> item) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    return item.values.join(' ').toLowerCase().contains(query);
  }

  void _openArticle(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.72,
            maxChildSize: 0.92,
            minChildSize: 0.42,
            builder:
                (context, controller) => DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    children: [
                      Text(
                        item['title']?.toString() ?? 'Culture mode',
                        style: const TextStyle(
                          color: ModernColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['content']?.toString() ??
                            item['summary']?.toString() ??
                            item['description']?.toString() ??
                            '',
                        style: const TextStyle(
                          color: ModernColors.inkSoft,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
