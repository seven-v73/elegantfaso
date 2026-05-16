import 'package:flutter/material.dart';

import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../widgets/inspiration/inspiration_feed.dart';
import '../widgets/inspiration/moodboard_section.dart';

class InspirationTab extends StatefulWidget {
  const InspirationTab({super.key, this.initialQuery = '', this.initialTopic});

  final String initialQuery;
  final String? initialTopic;

  @override
  State<InspirationTab> createState() => _InspirationTabState();
}

class _InspirationTabState extends State<InspirationTab> {
  String _selectedTopic = 'Tous';
  String _searchQuery = '';

  static const _topics = [
    _InspirationTopic('Tous', AppIcons.inspiration),
    _InspirationTopic('Mariage', Icons.favorite_rounded),
    _InspirationTopic('Tenues', Icons.checkroom_rounded),
    _InspirationTopic('Coiffures', Icons.content_cut_rounded),
    _InspirationTopic('Chaussures', Icons.directions_walk_rounded),
    _InspirationTopic('Hommes', Icons.man_rounded),
    _InspirationTopic('Accessoires', AppIcons.save),
  ];

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery.trim();
    _selectedTopic = widget.initialTopic ?? _topicFor(_searchQuery);
  }

  String _topicFor(String query) {
    final text = query.toLowerCase();
    if (text.contains('coiff')) return 'Coiffures';
    if (text.contains('chauss')) return 'Chaussures';
    if (text.contains('mariage')) return 'Mariage';
    if (text.contains('homme')) return 'Hommes';
    if (text.contains('accessoire')) return 'Accessoires';
    if (text.contains('tenue') || text.contains('robe')) return 'Tenues';
    return 'Tous';
  }

  void _exploreRelated(String query) {
    setState(() {
      _searchQuery = query.trim();
      _selectedTopic = _topicFor(_searchQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('salon_inspiration_tab'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        _InspirationDiscoveryHeader(
          activeQuery: _searchQuery,
          onReset:
              _searchQuery.isEmpty
                  ? null
                  : () => setState(() {
                    _searchQuery = '';
                    _selectedTopic = 'Tous';
                  }),
        ),
        const SizedBox(height: 14),
        _TopicRail(
          topics: _topics,
          selected: _selectedTopic,
          onSelected: (value) => setState(() => _selectedTopic = value),
        ),
        const SizedBox(height: 18),
        SectionHeader(
          padding: EdgeInsets.zero,
          title: _searchQuery.isEmpty ? 'Inspirations' : 'Résultats',
          subtitle:
              _searchQuery.isEmpty
                  ? 'Looks, créations et pièces du Salon'
                  : '"$_searchQuery"',
        ),
        const SizedBox(height: 12),
        InspirationFeed(
          topic: _selectedTopic,
          searchQuery: _searchQuery,
          onFindTutorials: _exploreRelated,
        ),
        const SizedBox(height: 22),
        MoodboardSection(
          searchQuery: _searchQuery,
          onFindTutorials: _exploreRelated,
        ),
      ],
    );
  }
}

class _InspirationDiscoveryHeader extends StatelessWidget {
  const _InspirationDiscoveryHeader({required this.activeQuery, this.onReset});

  final String activeQuery;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ModernColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              AppIcons.inspiration,
              color: ModernColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeQuery.isEmpty ? 'Inspirations Salon' : activeQuery,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Parcourir les idées et moodboards',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ModernColors.inkSoft, fontSize: 12),
                ),
              ],
            ),
          ),
          if (onReset != null)
            IconButton(
              tooltip: 'Réinitialiser',
              onPressed: onReset,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

class _TopicRail extends StatelessWidget {
  const _TopicRail({
    required this.topics,
    required this.selected,
    required this.onSelected,
  });

  final List<_InspirationTopic> topics;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: topics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final topic = topics[index];
          final isSelected = selected == topic.label;
          return ChoiceChip(
            avatar: Icon(
              topic.icon,
              size: 17,
              color: isSelected ? ModernColors.primary : ModernColors.inkSoft,
            ),
            label: Text(topic.label),
            selected: isSelected,
            onSelected: (_) => onSelected(topic.label),
            selectedColor: ModernColors.primary.withValues(alpha: 0.14),
            labelStyle: TextStyle(
              color: isSelected ? ModernColors.primary : ModernColors.inkSoft,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            side: BorderSide(
              color:
                  isSelected
                      ? ModernColors.primary.withValues(alpha: 0.25)
                      : ModernColors.line,
            ),
          );
        },
      ),
    );
  }
}

class _InspirationTopic {
  const _InspirationTopic(this.label, this.icon);

  final String label;
  final IconData icon;
}
