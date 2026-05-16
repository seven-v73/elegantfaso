import 'package:flutter/material.dart';

import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../widgets/shop/category_rail.dart';
import '../widgets/shop/floating_cart_bar.dart';
import '../widgets/shop/product_grid.dart';
import '../widgets/secondhand/secondhand_marketplace.dart';

class BoutiqueTab extends StatefulWidget {
  const BoutiqueTab({super.key, this.initialQuery = '', this.initialCategory});

  final String initialQuery;
  final String? initialCategory;

  @override
  State<BoutiqueTab> createState() => _BoutiqueTabState();
}

class _BoutiqueTabState extends State<BoutiqueTab>
    with AutomaticKeepAliveClientMixin {
  String _query = '';
  String _selectedFilter = 'Nouveautés';
  ShopAdvancedFilters _advancedFilters = const ShopAdvancedFilters();

  static const _categories = [
    ShopCategory('Nouveautés', AppIcons.shop),
    ShopCategory('Créations', AppIcons.creations),
    ShopCategory('Tenues', Icons.checkroom_rounded),
    ShopCategory('Coiffures', Icons.content_cut_rounded),
    ShopCategory('Chaussures', Icons.directions_walk_rounded),
    ShopCategory('Accessoires', AppIcons.save),
    ShopCategory('Mariage', Icons.favorite_rounded),
    ShopCategory('Hommes', Icons.man_rounded),
    ShopCategory('Clients', Icons.recycling_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _selectedFilter = widget.initialCategory ?? _categoryFor(_query);
  }

  String _categoryFor(String query) {
    final text = query.toLowerCase();
    if (text.contains('coiff')) return 'Coiffures';
    if (text.contains('chauss')) return 'Chaussures';
    if (text.contains('accessoire')) return 'Accessoires';
    if (text.contains('mariage')) return 'Mariage';
    if (text.contains('homme')) return 'Hommes';
    if (text.contains('client') ||
        text.contains('occasion') ||
        text.contains('vide-dressing') ||
        text.contains('vide dressing')) {
      return 'Clients';
    }
    if (text.contains('tenue') || text.contains('robe')) return 'Tenues';
    return 'Nouveautés';
  }

  void _selectIntent(_ShopIntent intent) {
    setState(() {
      _query = intent.query;
      _selectedFilter = intent.category;
      _advancedFilters = intent.filters ?? const ShopAdvancedFilters();
    });
  }

  void _openFilters() async {
    final filters = await showModalBottomSheet<ShopAdvancedFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShopFiltersSheet(initial: _advancedFilters),
    );
    if (filters != null) {
      setState(() => _advancedFilters = filters);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        SingleChildScrollView(
          key: const PageStorageKey('salon_boutique_tab'),
          padding: const EdgeInsets.only(bottom: 92),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: _ShopDiscoveryHeader(
                  activeQuery: _query,
                  onIntentSelected: _selectIntent,
                  onOpenFilters: _openFilters,
                  onReset:
                      () => setState(() {
                        _query = '';
                        _selectedFilter = 'Nouveautés';
                        _advancedFilters = const ShopAdvancedFilters();
                      }),
                ),
              ),
              const SizedBox(height: 14),
              CategoryRail(
                categories: _categories,
                selected: _selectedFilter,
                onSelected: (value) => setState(() => _selectedFilter = value),
              ),
              const SizedBox(height: 14),
              if (_selectedFilter != 'Clients') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(
                    padding: EdgeInsets.zero,
                    title: 'Sélection du Salon',
                    subtitle:
                        _query.isEmpty
                            ? 'Produits, créations et vide-dressing'
                            : 'Résultats pour "$_query"',
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ProductGrid(
                    searchQuery: _query,
                    categoryFilter: _selectedFilter,
                    advancedFilters: _advancedFilters,
                  ),
                ),
              ] else
                SecondhandMarketplace(initialQuery: _query),
            ],
          ),
        ),
        if (_selectedFilter != 'Clients') const FloatingCartBar(),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _ShopDiscoveryHeader extends StatelessWidget {
  const _ShopDiscoveryHeader({
    required this.activeQuery,
    required this.onIntentSelected,
    required this.onOpenFilters,
    required this.onReset,
  });

  final String activeQuery;
  final ValueChanged<_ShopIntent> onIntentSelected;
  final VoidCallback onOpenFilters;
  final VoidCallback onReset;

  static const _intents = [
    _ShopIntent(
      label: 'Acheter',
      query: 'produits disponibles',
      category: 'Nouveautés',
      icon: AppIcons.shop,
    ),
    _ShopIntent(
      label: 'Tenues',
      query: 'robe tenue ensemble',
      category: 'Tenues',
      icon: Icons.checkroom_rounded,
    ),
    _ShopIntent(
      label: 'Mariage',
      query: 'mariage cérémonie',
      category: 'Mariage',
      icon: Icons.favorite_rounded,
    ),
    _ShopIntent(
      label: 'Sur mesure',
      query: 'sur mesure création',
      category: 'Créations',
      icon: Icons.straighten_rounded,
      filters: ShopAdvancedFilters(madeToMeasureOnly: true),
    ),
    _ShopIntent(
      label: 'Vide-dressing',
      query: 'occasion client vide-dressing',
      category: 'Clients',
      icon: Icons.recycling_rounded,
      filters: ShopAdvancedFilters(sellerType: 'Client'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ModernColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  AppIcons.shop,
                  color: ModernColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  activeQuery.isEmpty ? 'Shopping Salon' : activeQuery,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Filtres',
                onPressed: onOpenFilters,
                icon: const Icon(Icons.tune_rounded),
              ),
              if (activeQuery.isNotEmpty)
                IconButton(
                  tooltip: 'Réinitialiser',
                  onPressed: onReset,
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _intents
                    .map(
                      (intent) => ActionChip(
                        avatar: Icon(intent.icon, size: 16),
                        label: Text(intent.label),
                        onPressed: () => onIntentSelected(intent),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

class _ShopIntent {
  const _ShopIntent({
    required this.label,
    required this.query,
    required this.category,
    required this.icon,
    this.filters,
  });

  final String label;
  final String query;
  final String category;
  final IconData icon;
  final ShopAdvancedFilters? filters;
}

class _ShopFiltersSheet extends StatefulWidget {
  const _ShopFiltersSheet({required this.initial});

  final ShopAdvancedFilters initial;

  @override
  State<_ShopFiltersSheet> createState() => _ShopFiltersSheetState();
}

class _ShopFiltersSheetState extends State<_ShopFiltersSheet> {
  late RangeValues _price;
  late TextEditingController _locationController;
  late String _sellerType;
  late String _occasion;
  late bool _availableOnly;
  late bool _fastDeliveryOnly;
  late bool _madeToMeasureOnly;

  @override
  void initState() {
    super.initState();
    _price = RangeValues(widget.initial.minPrice, widget.initial.maxPrice);
    _locationController = TextEditingController(text: widget.initial.location);
    _sellerType = widget.initial.sellerType;
    _occasion = widget.initial.occasion;
    _availableOnly = widget.initial.availableOnly;
    _fastDeliveryOnly = widget.initial.fastDeliveryOnly;
    _madeToMeasureOnly = widget.initial.madeToMeasureOnly;
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ModernColors.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: ModernShadows.elevated,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filtres shopping',
                style: TextStyle(
                  color: ModernColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              const _FilterLabel('Budget'),
              RangeSlider(
                values: _price,
                min: 0,
                max: 1000000,
                divisions: 20,
                labels: RangeLabels(
                  '${_price.start.round()}',
                  '${_price.end.round()}',
                ),
                onChanged: (value) => setState(() => _price = value),
              ),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Localisation',
                  hintText: 'Paris, Dakar, Tokyo, Abidjan...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place_rounded),
                ),
              ),
              const SizedBox(height: 12),
              const _FilterLabel('Vendeur'),
              Wrap(
                spacing: 8,
                children:
                    ['Tous', 'Boutique', 'Créateur', 'Client']
                        .map(
                          (type) => ChoiceChip(
                            label: Text(type),
                            selected: _sellerType == type,
                            onSelected:
                                (_) => setState(() => _sellerType = type),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 12),
              const _FilterLabel('Occasion'),
              DropdownButtonFormField<String>(
                initialValue: _occasion,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items:
                    ['Toutes', 'Mariage', 'Bureau', 'Soirée', 'Quotidien']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                onChanged:
                    (value) => setState(() => _occasion = value ?? 'Toutes'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _availableOnly,
                onChanged: (value) => setState(() => _availableOnly = value),
                title: const Text('Disponible maintenant'),
              ),
              SwitchListTile(
                value: _fastDeliveryOnly,
                onChanged: (value) => setState(() => _fastDeliveryOnly = value),
                title: const Text('Livraison rapide'),
              ),
              SwitchListTile(
                value: _madeToMeasureOnly,
                onChanged:
                    (value) => setState(() => _madeToMeasureOnly = value),
                title: const Text('Sur mesure'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      ShopAdvancedFilters(
                        minPrice: _price.start,
                        maxPrice: _price.end,
                        location: _locationController.text.trim(),
                        sellerType: _sellerType,
                        occasion: _occasion,
                        availableOnly: _availableOnly,
                        fastDeliveryOnly: _fastDeliveryOnly,
                        madeToMeasureOnly: _madeToMeasureOnly,
                      ),
                    );
                  },
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: ModernColors.ink,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
