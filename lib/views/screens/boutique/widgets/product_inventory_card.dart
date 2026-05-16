import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/boutique/shop_product.dart';
import '../../../../services/preferences/currency_service.dart';
import 'boutique_status_chip.dart';

class ProductInventoryCard extends StatelessWidget {
  const ProductInventoryCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onToggleVisibility,
    required this.onDuplicate,
    required this.onDelete,
    required this.onPreview,
  });

  final ShopProduct product;
  final VoidCallback onEdit;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        product.isOutOfStock
            ? ModernColors.rose
            : product.isHidden
            ? ModernColors.inkSoft
            : product.isDraft
            ? ModernColors.accent
            : ModernColors.primary;

    return AppCard(
      padding: const EdgeInsets.all(12),
      elevated: false,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 86,
              height: 104,
              color: ModernColors.canvas,
              child:
                  product.coverImage.isEmpty
                      ? const Icon(
                        Icons.image_rounded,
                        color: ModernColors.inkSoft,
                      )
                      : CachedNetworkImage(
                        imageUrl: product.coverImage,
                        fit: BoxFit.cover,
                        memCacheWidth: 260,
                        errorWidget:
                            (_, _, _) => const Icon(
                              Icons.image_not_supported_rounded,
                              color: ModernColors.inkSoft,
                            ),
                      ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ModernColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit();
                          case 'visibility':
                            onToggleVisibility();
                          case 'duplicate':
                            onDuplicate();
                          case 'preview':
                            onPreview();
                          case 'delete':
                            onDelete();
                        }
                      },
                      itemBuilder:
                          (_) => [
                            const PopupMenuItem(
                              value: 'preview',
                              child: Text('Voir Salon'),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: const Text('Modifier'),
                            ),
                            PopupMenuItem(
                              value: 'visibility',
                              child: Text(
                                product.isHidden ? 'Publier' : 'Masquer',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'duplicate',
                              child: Text('Dupliquer'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Archiver'),
                            ),
                          ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  CurrencyService.format(product.price, code: product.currency),
                  style: const TextStyle(
                    color: ModernColors.shop,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    BoutiqueStatusChip(
                      label: product.statusLabel,
                      color: statusColor,
                    ),
                    BoutiqueStatusChip(
                      label: 'Stock ${product.stock}',
                      color:
                          product.isLowStock || product.isOutOfStock
                              ? ModernColors.rose
                              : ModernColors.creator,
                    ),
                    if (product.hasPromotion)
                      const BoutiqueStatusChip(
                        label: 'Promo',
                        color: ModernColors.accent,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: onToggleVisibility,
                      icon: Icon(
                        product.isHidden
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 17,
                      ),
                      label: Text(product.isHidden ? 'Publier' : 'Masquer'),
                    ),
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 17),
                      label: const Text('Modifier'),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 16,
                          color: ModernColors.inkSoft,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.viewsCount} vues',
                          style: const TextStyle(
                            color: ModernColors.inkSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
