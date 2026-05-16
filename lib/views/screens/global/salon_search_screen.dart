import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design/ecommerce_widgets.dart';
import '../../../design/app_icons.dart';
import '../../../design/modern_design_system.dart';
import '../../../models/salon/salon_context.dart';
import '../../../models/salon/salon_item.dart';
import '../../../models/salon/salon_section.dart';
import '../../../services/salon/salon_context_service.dart';
import '../../../services/salon/salon_unified_search_service.dart';
import 'widgets/salon/salon_empty_state.dart';
import 'widgets/salon/salon_section_rail.dart';
import 'widgets/salon/salon_universal_detail_sheet.dart';

class SalonSearchScreen extends StatefulWidget {
  const SalonSearchScreen({
    super.key,
    this.initialQuery = '',
    this.onExploreContext,
    this.onLoginRequired,
  });

  final String initialQuery;
  final ValueChanged<SalonContext>? onExploreContext;
  final VoidCallback? onLoginRequired;

  @override
  State<SalonSearchScreen> createState() => _SalonSearchScreenState();
}

class _SalonSearchScreenState extends State<SalonSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final SalonUnifiedSearchService _searchService = SalonUnifiedSearchService();
  final SalonContextService _contextService = SalonContextService();

  Future<List<SalonSection>>? _future;
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _controller.text = _query;
    if (_query.isNotEmpty) _search(_query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleSearch(String value) {
    final query = value.trim();
    _debounce?.cancel();
    setState(() {
      _query = query;
      if (query.isEmpty) _future = null;
    });
    if (query.length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 280), () => _search(query));
  }

  void _search(String value, {bool remember = false}) {
    final query = value.trim();
    final context = SalonContext.fromQuery(query, source: 'search_screen');
    setState(() {
      _query = query;
      _future = query.isEmpty ? null : _searchService.search(context);
    });
    if (remember) _contextService.remember(context);
  }

  void _openItem(SalonItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => SalonUniversalDetailSheet(
            item: item,
            onExploreContext: (context) {
              widget.onExploreContext?.call(context);
              Navigator.pop(this.context);
            },
            onLoginRequired:
                widget.onLoginRequired ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Connectez-vous pour continuer.'),
                    ),
                  );
                },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        title: const Text('Recherche Salon'),
        backgroundColor: ModernColors.canvas,
        foregroundColor: ModernColors.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevated: false,
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Produits, talents, inspirations, événements...',
                ),
                onSubmitted: (value) => _search(value, remember: true),
                onChanged: _scheduleSearch,
              ),
            ),
            const SizedBox(height: 18),
            if (_future == null)
              const SalonEmptyState(
                icon: AppIcons.salon,
                title: 'Recherche unifiée',
                message:
                    'Une seule recherche pour explorer produits, créations, talents, inspirations et événements.',
              )
            else
              FutureBuilder<List<SalonSection>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const SalonEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Recherche indisponible',
                      message: 'Impossible de charger les résultats.',
                    );
                  }
                  final sections = snapshot.data ?? const <SalonSection>[];
                  if (sections.isEmpty) {
                    return const SalonEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Aucun résultat',
                      message: 'Essaie une recherche plus large.',
                    );
                  }
                  return Column(
                    children: [
                      for (final section in sections) ...[
                        SalonSectionRail(
                          section: section,
                          onItemTap: _openItem,
                        ),
                        const SizedBox(height: 22),
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
