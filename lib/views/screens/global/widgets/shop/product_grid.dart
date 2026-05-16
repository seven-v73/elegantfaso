import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/global/cart_item.dart';
import '../../../../../models/secondhand/secondhand_listing.dart';
import '../../../../../models/shop/public_listing.dart';
import '../../../../../models/shop/seller_info.dart';
import '../../../../../services/global/cart_service.dart';
import '../../../../../services/secondhand/secondhand_listing_service.dart';
import '../../../../../services/salon/salon_boost_service.dart';
import '../../../../../services/shop/checkout_service.dart';
import '../../../../../services/shop/salon_product_service.dart';
import '../../../../../services/shop/seller_service.dart';
import '../../checkout_screen.dart';
import 'product_card.dart';
import 'product_detail_sheet.dart';
import 'variant_picker_sheet.dart';

class ProductGrid extends StatefulWidget {
  const ProductGrid({
    super.key,
    required this.searchQuery,
    required this.categoryFilter,
    required this.advancedFilters,
  });

  final String searchQuery;
  final String categoryFilter;
  final ShopAdvancedFilters advancedFilters;

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  final SalonProductService _productService = SalonProductService();
  final SellerService _sellerService = SellerService();
  final CheckoutService _checkoutService = CheckoutService();
  final SalonBoostService _boostService = SalonBoostService();
  final SecondhandListingService _secondhandService =
      SecondhandListingService();
  int _visibleCount = 12;
  String _sellerBatchSignature = '';
  Future<Map<String, SellerInfo>>? _sellerBatchFuture;
  Map<String, SellerInfo> _lastSellers = const {};

  @override
  void didUpdateWidget(covariant ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.categoryFilter != widget.categoryFilter ||
        oldWidget.advancedFilters != widget.advancedFilters) {
      _visibleCount = 12;
      _sellerBatchSignature = '';
      _sellerBatchFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PublicListing>>(
      stream: _productService.watchListings(limit: 48),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ProductsSkeleton();
        }
        if (snapshot.hasError) {
          return const _SectionState(
            icon: Icons.error_outline_rounded,
            title: 'Chargement impossible',
            subtitle: 'Réessayez dans quelques instants.',
          );
        }

        return StreamBuilder<SalonBoostIndex>(
          stream: _boostService.watchActiveBoostIndex(),
          builder: (context, boostSnapshot) {
            final items = _filterItems(
              snapshot.data ?? const [],
              boostSnapshot.data ?? const SalonBoostIndex(),
            );
            if (items.isEmpty) {
              return const _SectionState(
                icon: Icons.inventory_2_outlined,
                title: 'Aucun résultat',
                subtitle: 'Essayez une recherche ou un filtre différent.',
              );
            }

            final visible = items.take(_visibleCount).toList();
            final cachedSellers = {
              ..._lastSellers,
              ..._sellerService.cachedSellers(visible),
            };
            return Column(
              children: [
                FutureBuilder<Map<String, SellerInfo>>(
                  future: _sellerFutureFor(visible),
                  initialData: cachedSellers,
                  builder: (context, sellerSnapshot) {
                    final sellers = {...cachedSellers, ...?sellerSnapshot.data};
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount =
                            width < 560
                                ? 2
                                : width < 900
                                ? 3
                                : 4;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visible.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: width < 560 ? 0.62 : 0.7,
                              ),
                          itemBuilder: (context, index) {
                            final listing = visible[index];
                            final seller =
                                sellers[_sellerService.sellerKey(listing)] ??
                                SellerInfo.fallback(
                                  id: listing.sellerId,
                                  role:
                                      listing.isSecondhand
                                          ? 'client'
                                          : listing.isProduct
                                          ? 'boutique'
                                          : 'createur',
                                );
                            return RepaintBoundary(
                              child: ShopProductCard(
                                listing: listing,
                                seller: seller,
                                onTap:
                                    () => _openProductDetail(listing, seller),
                                onAdd: () => _addToCart(listing, seller),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                if (_visibleCount < items.length) ...[
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'Voir plus',
                    onPressed: () => setState(() => _visibleCount += 12),
                    icon: Icons.expand_more_rounded,
                    variant: AppButtonVariant.outline,
                    expand: true,
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  List<PublicListing> _filterItems(
    List<PublicListing> items,
    SalonBoostIndex boosts,
  ) {
    final query = widget.searchQuery.trim().toLowerCase();
    final filter = widget.categoryFilter.trim().toLowerCase();
    final advanced = widget.advancedFilters;

    return items.where((item) {
        final searchable = item.searchableText;
        final matchesQuery = query.isEmpty || searchable.contains(query);
        final matchesFilter = switch (filter) {
          'créations' || 'creations' => item.isCreation,
          'clients' || 'vide-dressing' || 'vide dressing' => item.isSecondhand,
          'tenues' =>
            searchable.contains('tenue') ||
                searchable.contains('look') ||
                searchable.contains('robe') ||
                searchable.contains('ensemble') ||
                searchable.contains('outfit'),
          'coiffures' =>
            searchable.contains('coiffure') ||
                searchable.contains('tresse') ||
                searchable.contains('braid') ||
                searchable.contains('hair') ||
                searchable.contains('barber'),
          'chaussures' =>
            searchable.contains('chaussure') ||
                searchable.contains('sneaker') ||
                searchable.contains('sandale') ||
                searchable.contains('mocassin') ||
                searchable.contains('shoe'),
          'accessoires' =>
            searchable.contains('accessoire') ||
                searchable.contains('bijou') ||
                searchable.contains('sac'),
          'mariage' =>
            searchable.contains('mariage') || searchable.contains('ceremon'),
          'hommes' =>
            searchable.contains('homme') || searchable.contains('mens'),
          _ => true,
        };
        final priceOk =
            item.price >= advanced.minPrice && item.price <= advanced.maxPrice;
        final originOk =
            advanced.sellerType == 'Tous' ||
            (advanced.sellerType == 'Boutique' && item.isProduct) ||
            (advanced.sellerType == 'Créateur' && item.isCreation) ||
            (advanced.sellerType == 'Client' && item.isSecondhand);
        final availabilityOk = !advanced.availableOnly || item.hasStock;
        final deliveryOk =
            !advanced.fastDeliveryOnly ||
            item.data['fastDelivery'] == true ||
            item.data['delivery'] == 'fast';
        final madeToMeasureOk =
            !advanced.madeToMeasureOnly ||
            item.data['madeToMeasure'] == true ||
            searchable.contains('sur mesure');
        final occasionOk =
            advanced.occasion == 'Toutes' ||
            searchable.contains(advanced.occasion.toLowerCase());
        final locationOk =
            advanced.location.trim().isEmpty ||
            searchable.contains(advanced.location.trim().toLowerCase());

        return matchesQuery &&
            matchesFilter &&
            priceOk &&
            originOk &&
            availabilityOk &&
            deliveryOk &&
            madeToMeasureOk &&
            occasionOk &&
            locationOk;
      }).toList()
      ..sort((a, b) {
        final aBoost = boosts.boostScore(
          id: a.id,
          ownerId: a.sellerId,
          data: a.data,
        );
        final bBoost = boosts.boostScore(
          id: b.id,
          ownerId: b.sellerId,
          data: b.data,
        );
        if (aBoost != bBoost) return bBoost.compareTo(aBoost);
        final aWeight = _listingWeight(a);
        final bWeight = _listingWeight(b);
        if (aWeight != bWeight) return bWeight.compareTo(aWeight);
        final aDate = a.data['createdAt'];
        final bDate = b.data['createdAt'];
        if (aDate is Timestamp && bDate is Timestamp) {
          return bDate.compareTo(aDate);
        }
        return 0;
      });
  }

  int _listingWeight(PublicListing listing) {
    final value = listing.data['recommendationWeight'];
    if (value is num) return value.toInt();
    return listing.isSecondhand ? 10 : 0;
  }

  Future<Map<String, SellerInfo>> _sellerFutureFor(
    List<PublicListing> listings,
  ) {
    final signature =
        listings.map(_sellerService.sellerKey).toSet().toList()..sort();
    final nextSignature = signature.join('|');
    if (_sellerBatchFuture != null && nextSignature == _sellerBatchSignature) {
      return _sellerBatchFuture!;
    }

    _sellerBatchSignature = nextSignature;
    _sellerBatchFuture = _sellerService.getSellers(listings).then((sellers) {
      _lastSellers = sellers;
      return sellers;
    });
    return _sellerBatchFuture!;
  }

  Future<VariantSelection?> _pickVariant(PublicListing listing) {
    if (!listing.needsVariant) {
      return Future.value(const VariantSelection(quantity: 1));
    }
    return showModalBottomSheet<VariantSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VariantPickerSheet(listing: listing),
    );
  }

  Future<void> _addToCart(PublicListing listing, SellerInfo seller) async {
    if (!CartService.isSignedIn) {
      _showLoginSheet();
      return;
    }
    if (FirebaseAuth.instance.currentUser?.uid == listing.sellerId) {
      _showSnack('Vous ne pouvez pas acheter votre propre article.');
      return;
    }
    if (listing.isSecondhand) {
      await _reserveSecondhand(listing);
      return;
    }
    final selection = await _pickVariant(listing);
    if (selection == null) return;

    final item = CartItem(
      id: '',
      productId: listing.id,
      name: listing.title,
      imageUrl: listing.imageUrl,
      price: listing.price,
      quantity: selection.quantity,
      sellerId: listing.sellerId,
      sellerName: seller.name,
      sellerImage: seller.imageUrl,
      metadata: {
        ...listing.data,
        ...selection.variant.toMap(),
        if (selection.note.isNotEmpty) 'note': selection.note,
        'type': listing.type,
        'currency': listing.currency,
        'role': listing.isProduct ? 'boutique' : 'createur',
        'phone': seller.phone,
        'speciality': seller.speciality,
        'followersCount': seller.followersCount,
        'paymentMethods': seller.paymentMethods,
      },
      addedAt: Timestamp.now(),
    );
    await CartService.addToCart(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${listing.title} ajouté au panier'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ModernColors.success,
      ),
    );
  }

  Future<void> _buyNow(PublicListing listing, SellerInfo seller) async {
    if (!CartService.isSignedIn) {
      _showLoginSheet();
      return;
    }
    if (FirebaseAuth.instance.currentUser?.uid == listing.sellerId) {
      _showSnack('Vous ne pouvez pas acheter votre propre article.');
      return;
    }
    if (listing.isSecondhand) {
      await _reserveSecondhand(listing);
      return;
    }
    final selection = await _pickVariant(listing);
    if (selection == null) return;
    final item = CartItem(
      id: CartItem.buildId(
        sellerId: listing.sellerId,
        productId: listing.id,
        size: selection.size,
        color: selection.color,
      ),
      productId: listing.id,
      name: listing.title,
      imageUrl: listing.imageUrl,
      price: listing.price,
      quantity: selection.quantity,
      sellerId: listing.sellerId,
      sellerName: seller.name,
      sellerImage: seller.imageUrl,
      metadata: {
        ...listing.data,
        ...selection.variant.toMap(),
        if (selection.note.isNotEmpty) 'note': selection.note,
        'type': listing.type,
        'currency': listing.currency,
        'role': listing.isProduct ? 'boutique' : 'createur',
        'phone': seller.phone,
        'speciality': seller.speciality,
        'followersCount': seller.followersCount,
        'paymentMethods': seller.paymentMethods,
      },
      addedAt: Timestamp.now(),
    );
    await _checkoutService.validateCartItems([item]);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CheckoutScreen(
              cartItems: [item],
              vendor: _checkoutService.vendorFromSeller(seller),
            ),
      ),
    );
  }

  Future<void> _reserveSecondhand(PublicListing listing) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('secondhand_listings')
              .doc(listing.id)
              .get();
      if (!doc.exists) {
        _showSnack('Cette pièce n’est plus disponible.');
        return;
      }
      final secondhand = SecondhandListing.fromFirestore(doc);
      if (!secondhand.isAvailable) {
        _showSnack('Cette pièce est déjà réservée ou vendue.');
        return;
      }
      await _secondhandService.reserve(secondhand);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pièce réservée. Le vendeur a été prévenu.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ModernColors.success,
        ),
      );
    } on StateError catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('Réservation impossible pour le moment.');
    }
  }

  void _openProductDetail(PublicListing listing, SellerInfo seller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => ProductDetailSheet(
            listing: listing,
            seller: seller,
            onAddToCart: () => _addToCart(listing, seller),
            onBuyNow: () => _buyNow(listing, seller),
          ),
    );
  }

  void _showLoginSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ModernColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: ModernShadows.elevated,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connectez-vous pour commander',
                    style: TextStyle(
                      color: ModernColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La commande, le panier et les souhaits synchronisés demandent une connexion.',
                    style: TextStyle(
                      color: ModernColors.inkSoft,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Continuer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class ShopAdvancedFilters {
  const ShopAdvancedFilters({
    this.minPrice = 0,
    this.maxPrice = 1000000,
    this.location = '',
    this.sellerType = 'Tous',
    this.occasion = 'Toutes',
    this.availableOnly = false,
    this.fastDeliveryOnly = false,
    this.madeToMeasureOnly = false,
  });

  final double minPrice;
  final double maxPrice;
  final String location;
  final String sellerType;
  final String occasion;
  final bool availableOnly;
  final bool fastDeliveryOnly;
  final bool madeToMeasureOnly;

  ShopAdvancedFilters copyWith({
    double? minPrice,
    double? maxPrice,
    String? location,
    String? sellerType,
    String? occasion,
    bool? availableOnly,
    bool? fastDeliveryOnly,
    bool? madeToMeasureOnly,
  }) {
    return ShopAdvancedFilters(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      location: location ?? this.location,
      sellerType: sellerType ?? this.sellerType,
      occasion: occasion ?? this.occasion,
      availableOnly: availableOnly ?? this.availableOnly,
      fastDeliveryOnly: fastDeliveryOnly ?? this.fastDeliveryOnly,
      madeToMeasureOnly: madeToMeasureOnly ?? this.madeToMeasureOnly,
    );
  }
}

class _ProductsSkeleton extends StatelessWidget {
  const _ProductsSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemBuilder:
          (_, _) => const AppCard(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
    );
  }
}

class _SectionState extends StatelessWidget {
  const _SectionState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, color: ModernColors.inkSoft),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: ModernColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ModernColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
