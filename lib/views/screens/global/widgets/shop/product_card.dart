import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/shop/public_listing.dart';
import '../../../../../models/shop/seller_info.dart';
import '../../../../../services/preferences/currency_service.dart';

class ShopProductCard extends StatelessWidget {
  const ShopProductCard({
    super.key,
    required this.listing,
    required this.seller,
    required this.onTap,
    required this.onAdd,
  });

  final PublicListing listing;
  final SellerInfo seller;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final badgeColor =
        listing.isSecondhand
            ? ModernColors.success
            : listing.isCreation
            ? ModernColors.accent
            : ModernColors.primary;
    final sellerLine =
        listing.isSecondhand
            ? [
                  'Client',
                  listing.data['condition']?.toString(),
                  listing.data['city']?.toString(),
                ]
                .where((value) => value != null && value.trim().isNotEmpty)
                .join(' • ')
            : seller.name;
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      elevated: false,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ModernRadius.lg),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ListingImage(url: listing.imageUrl),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            listing.badgeLabel,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ModernColors.ink,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        CurrencyService.format(
                          listing.price,
                          code: listing.currency,
                        ),
                        style: const TextStyle(
                          color: ModernColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sellerLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ModernColors.inkSoft,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (seller.verified)
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: ModernColors.primary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                elevation: 7,
                child: IconButton(
                  tooltip:
                      listing.isSecondhand ? 'Réserver' : 'Ajouter au panier',
                  onPressed: onAdd,
                  icon: Icon(
                    listing.isSecondhand
                        ? Icons.bookmark_add_rounded
                        : Icons.add_shopping_cart_rounded,
                    size: 19,
                  ),
                  color: ModernColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url.trim();
    if (!_isNetworkImage(imageUrl)) return const _ImageFallback();
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: 520,
      fadeInDuration: const Duration(milliseconds: 140),
      errorWidget: (_, _, _) => const _ImageFallback(),
      placeholder:
          (_, _) => const ColoredBox(
            color: ModernColors.line,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: ModernColors.line,
      child: Center(
        child: Icon(Icons.image_outlined, color: ModernColors.inkSoft),
      ),
    );
  }
}

bool _isNetworkImage(String url) {
  return url.startsWith('http://') || url.startsWith('https://');
}
