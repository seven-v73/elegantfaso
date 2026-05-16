import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/boutique/boutique_product.dart';
import '../../../../models/boutique/shop_product.dart';
import '../../../../services/boutique/boutique_product_service.dart';
import '../../../widgets/common/app_action_empty_state.dart';
import '../../commerce/catalogue_express_screen.dart';
import '../../global/salon_mode_burkinabe.dart';
import '../widgets/product_inventory_card.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class BoutiqueProductsScreen extends StatefulWidget {
  const BoutiqueProductsScreen({super.key});

  @override
  State<BoutiqueProductsScreen> createState() => _BoutiqueProductsScreenState();
}

class _BoutiqueProductsScreenState extends State<BoutiqueProductsScreen> {
  final BoutiqueProductService _service = BoutiqueProductService();
  final TextEditingController _searchController = TextEditingController();
  final String _boutiqueId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String _query = '';
  String _filter = 'Tous';
  String _sort = 'Récent';

  static const _filters = [
    'Tous',
    'Visible',
    'Brouillon',
    'Rupture',
    'Stock faible',
    'Promotion',
    'Masqué',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ShopProduct> _applyFilters(List<ShopProduct> products) {
    final q = _query.toLowerCase();
    final filtered =
        products.where((product) {
          final matchesQuery =
              q.isEmpty ||
              '${product.name} ${product.category} ${product.description}'
                  .toLowerCase()
                  .contains(q);
          final matchesFilter = switch (_filter) {
            'Visible' => product.isPublished,
            'Brouillon' => product.isDraft,
            'Rupture' => product.isOutOfStock,
            'Stock faible' => product.isLowStock,
            'Promotion' => product.hasPromotion,
            'Masqué' => product.isHidden,
            _ => true,
          };
          return matchesQuery && matchesFilter;
        }).toList();

    filtered.sort((a, b) {
      return switch (_sort) {
        'Stock' => a.stock.compareTo(b.stock),
        'Prix' => b.price.compareTo(a.price),
        'Vues' => b.viewsCount.compareTo(a.viewsCount),
        'Ventes' => b.salesCount.compareTo(a.salesCount),
        _ => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
      };
    });
    return filtered;
  }

  Future<void> _deleteProduct(ShopProduct product) async {
    await _service.deleteProduct(product.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} archivé.'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () => _service.restoreProduct(product),
        ),
      ),
    );
  }

  void _openAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddProductScreen()),
    );
  }

  void _openCatalogueExpress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CatalogueExpressScreen(role: 'boutique'),
      ),
    );
  }

  Future<void> _showAddProductMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ModernColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ModernColors.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome_rounded),
                    title: const Text('Catalogue Express'),
                    subtitle: const Text('Depuis photos'),
                    onTap: () => Navigator.pop(context, 'express'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_note_rounded),
                    title: const Text('Fiche détaillée'),
                    subtitle: const Text('Prix, stock, détails'),
                    onTap: () => Navigator.pop(context, 'manual'),
                  ),
                ],
              ),
            ),
          ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'manual') {
      _openAddProduct();
    } else {
      _openCatalogueExpress();
    }
  }

  void _openSalon() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SalonModeBurkinabeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showAddProductMenu,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
      body: StreamBuilder<List<ShopProduct>>(
        stream: _service.watchProducts(_boutiqueId),
        builder: (context, snapshot) {
          final products = _applyFilters(snapshot.data ?? const []);
          final allProducts = snapshot.data ?? const <ShopProduct>[];
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
              children: [
                _InventoryHeader(
                  controller: _searchController,
                  query: _query,
                  sort: _sort,
                  onQueryChanged: (value) => setState(() => _query = value),
                  onSortChanged: (value) => setState(() => _sort = value),
                  onAddProduct: _showAddProductMenu,
                  onOpenSalon: _openSalon,
                  lowStockCount:
                      allProducts.where((product) => product.isLowStock).length,
                  hiddenCount:
                      allProducts.where((product) => product.isHidden).length,
                  missingImageCount:
                      allProducts
                          .where((product) => product.coverImage.isEmpty)
                          .length,
                ),
                const SizedBox(height: 12),
                _FilterRail(
                  filters: _filters,
                  selected: _filter,
                  onSelected: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const _LoadingProducts()
                else if (snapshot.hasError)
                  const _InventoryState(
                    icon: Icons.error_outline_rounded,
                    title: 'Inventaire indisponible',
                    message: 'Réessayez.',
                  )
                else if (products.isEmpty)
                  _InventoryState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Aucun produit',
                    message: 'Ajoutez votre première pièce.',
                    actionLabel: 'Catalogue Express',
                    onAction: _openCatalogueExpress,
                    secondaryActionLabel: 'Fiche détaillée',
                    onSecondaryAction: _openAddProduct,
                  )
                else
                  for (final product in products) ...[
                    ProductInventoryCard(
                      product: product,
                      onEdit:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => EditProductScreen(
                                    product: _legacyProduct(product),
                                  ),
                            ),
                          ),
                      onToggleVisibility:
                          () => _service.updateStatus(
                            product.id,
                            product.isHidden ? 'published' : 'hidden',
                          ),
                      onDuplicate: () => _service.duplicateProduct(product),
                      onDelete: () => _deleteProduct(product),
                      onPreview: _openSalon,
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  BoutiqueProduct _legacyProduct(ShopProduct product) {
    return BoutiqueProduct(
      id: product.id,
      name: product.name,
      category: product.category,
      price: product.price,
      description: product.description,
      stock: product.stock,
      boutiqueId: product.boutiqueId,
      imageUrl: product.coverImage,
      createdAt: product.createdAt ?? DateTime.now(),
    );
  }
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader({
    required this.controller,
    required this.query,
    required this.sort,
    required this.onQueryChanged,
    required this.onSortChanged,
    required this.onAddProduct,
    required this.onOpenSalon,
    required this.lowStockCount,
    required this.hiddenCount,
    required this.missingImageCount,
  });

  final TextEditingController controller;
  final String query;
  final String sort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onAddProduct;
  final VoidCallback onOpenSalon;
  final int lowStockCount;
  final int hiddenCount;
  final int missingImageCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventaire',
                      style: TextStyle(
                        color: ModernColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onOpenSalon,
                icon: const Icon(AppIcons.salon),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Ajouter',
                onPressed: onAddProduct,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (lowStockCount > 0 ||
              hiddenCount > 0 ||
              missingImageCount > 0) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (lowStockCount > 0)
                    _InventoryAlertChip(
                      label: '$lowStockCount stock faible',
                      color: ModernColors.rose,
                    ),
                  if (hiddenCount > 0)
                    _InventoryAlertChip(
                      label: '$hiddenCount masqué(s)',
                      color: ModernColors.inkSoft,
                    ),
                  if (missingImageCount > 0)
                    _InventoryAlertChip(
                      label: '$missingImageCount sans image',
                      color: ModernColors.accent,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon:
                  query.isEmpty
                      ? null
                      : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          controller.clear();
                          onQueryChanged('');
                        },
                      ),
              filled: true,
              fillColor: ModernColors.canvas,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Tri',
                style: TextStyle(
                  color: ModernColors.inkSoft,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: sort,
                underline: const SizedBox.shrink(),
                items:
                    const ['Récent', 'Stock', 'Prix', 'Vues', 'Ventes']
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) onSortChanged(value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterRail extends StatelessWidget {
  const _FilterRail({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return ChoiceChip(
            label: Text(filter),
            selected: filter == selected,
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _InventoryAlertChip extends StatelessWidget {
  const _InventoryAlertChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LoadingProducts extends StatelessWidget {
  const _LoadingProducts();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 128,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryState extends StatelessWidget {
  const _InventoryState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return AppActionEmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      secondaryActionLabel: secondaryActionLabel,
      onSecondaryAction: onSecondaryAction,
      accent: ModernColors.primary,
    );
  }
}
