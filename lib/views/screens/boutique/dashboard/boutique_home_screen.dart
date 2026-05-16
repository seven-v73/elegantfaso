import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/boutique/shop_dashboard_summary.dart';
import '../../../../models/boutique/shop_product.dart';
import '../../../../services/boutique/boutique_dashboard_service.dart';
import '../../commerce/catalogue_express_screen.dart';
import '../../global/salon_mode_burkinabe.dart';
import '../customers/boutique_customers_screen.dart';
import '../widgets/boutique_today_panel.dart';

class BoutiqueHomeScreen extends StatefulWidget {
  const BoutiqueHomeScreen({super.key, required this.onTabSelected});

  final ValueChanged<int> onTabSelected;

  @override
  State<BoutiqueHomeScreen> createState() => _BoutiqueHomeScreenState();
}

class _BoutiqueHomeScreenState extends State<BoutiqueHomeScreen> {
  final BoutiqueDashboardService _service = BoutiqueDashboardService();
  final String _boutiqueId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _openSalon() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SalonModeBurkinabeScreen()),
    );
  }

  void _openClients() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BoutiqueCustomersScreen()),
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShopDashboardSummary>(
      stream: _service.watchSummary(_boutiqueId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _DashboardLoading();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _DashboardState(
            icon: Icons.error_outline_rounded,
            title: 'Tableau de bord indisponible',
            message: 'Impossible de charger les informations boutique.',
            onRetry: () => setState(() {}),
          );
        }
        final summary = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              BoutiqueTodayPanel(
                summary: summary,
                onOrders: () => widget.onTabSelected(2),
                onProducts: () => widget.onTabSelected(1),
                onAddProduct: _openCatalogueExpress,
                onClients: _openClients,
                onSalon: _openSalon,
              ),
              const SizedBox(height: 16),
              _ShopHealthRail(
                summary: summary,
                onProducts: () => widget.onTabSelected(1),
              ),
              const SizedBox(height: 22),
              if (summary.topProducts.isNotEmpty) ...[
                SectionHeader(
                  padding: EdgeInsets.zero,
                  title: 'Vitrine Salon',
                  subtitle:
                      '${summary.publishedCount}/${summary.productsCount}',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 156,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: summary.topProducts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder:
                        (context, index) => _ProductSpotlightCard(
                          product: summary.topProducts[index],
                          onTap: () => widget.onTabSelected(1),
                        ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        5,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 96,
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

class _ShopHealthRail extends StatelessWidget {
  const _ShopHealthRail({required this.summary, required this.onProducts});

  final ShopDashboardSummary summary;
  final VoidCallback onProducts;

  @override
  Widget build(BuildContext context) {
    final items = [
      _HealthItem(
        icon: Icons.remove_red_eye_rounded,
        label: 'Produits',
        value: '${summary.productViewsCount}',
        color: ModernColors.accent,
      ),
      _HealthItem(
        icon: Icons.storefront_rounded,
        label: 'Profil',
        value: '${summary.profileViewsCount}',
        color: ModernColors.shop,
      ),
      _HealthItem(
        icon: Icons.visibility_rounded,
        label: 'Visibles',
        value: '${summary.publishedCount}',
        color: ModernColors.primary,
      ),
      _HealthItem(
        icon: Icons.image_not_supported_outlined,
        label: 'Sans photo',
        value: '${summary.missingImageCount}',
        color:
            summary.missingImageCount > 0
                ? ModernColors.warning
                : ModernColors.success,
      ),
      _HealthItem(
        icon: Icons.visibility_off_rounded,
        label: 'Masqués',
        value: '${summary.hiddenCount}',
        color:
            summary.hiddenCount > 0
                ? ModernColors.inkSoft
                : ModernColors.success,
      ),
    ];

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder:
            (context, index) =>
                _HealthTile(item: items[index], onTap: onProducts),
      ),
    );
  }
}

class _HealthItem {
  const _HealthItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _HealthTile extends StatelessWidget {
  const _HealthTile({required this.item, required this.onTap});

  final _HealthItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        elevated: false,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSpotlightCard extends StatelessWidget {
  const _ProductSpotlightCard({required this.product, required this.onTap});

  final ShopProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        elevated: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child:
                    product.coverImage.isEmpty
                        ? Container(
                          color: ModernColors.canvas,
                          child: const Icon(
                            Icons.image_rounded,
                            color: ModernColors.inkSoft,
                          ),
                        )
                        : Image.network(
                          product.coverImage,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, _, _) => Container(
                                color: ModernColors.canvas,
                                child: const Icon(Icons.image_not_supported),
                              ),
                        ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.68),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${product.viewsCount} vues · stock ${product.stock}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardState extends StatelessWidget {
  const _DashboardState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: ModernColors.inkSoft, size: 36),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ModernColors.inkSoft),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
