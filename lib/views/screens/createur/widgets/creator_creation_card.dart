import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/createur/creator_creation.dart';
import '../../../../services/preferences/currency_service.dart';
import 'creator_status_chip.dart';

class CreatorCreationCard extends StatelessWidget {
  const CreatorCreationCard({
    super.key,
    required this.creation,
    required this.onTap,
    required this.onEdit,
    required this.onToggleVisibility,
    required this.onDuplicate,
    required this.onDelete,
    required this.onPreview,
  });

  final CreatorCreation creation;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final color = creatorStatusColor(creation.status);
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(ModernRadius.lg),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: ModernColors.canvas,
                    child:
                        creation.coverImage.isEmpty
                            ? const Icon(
                              Icons.image_rounded,
                              color: ModernColors.inkSoft,
                            )
                            : CachedNetworkImage(
                              imageUrl: creation.coverImage,
                              fit: BoxFit.cover,
                              memCacheWidth: 420,
                              errorWidget:
                                  (_, _, _) => const Icon(
                                    Icons.image_not_supported_rounded,
                                    color: ModernColors.inkSoft,
                                  ),
                            ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: CreatorStatusChip(
                    label: creation.statusLabel,
                    color: color,
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 2,
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.white,
                    ),
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
                        (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Modifier')),
                          PopupMenuItem(
                            value: 'visibility',
                            child: Text('Publier / masquer'),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Dupliquer'),
                          ),
                          PopupMenuItem(
                            value: 'preview',
                            child: Text('Voir dans le Salon'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Archiver'),
                          ),
                        ],
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
                  creation.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  creation.price > 0
                      ? CurrencyService.format(
                        creation.price,
                        code: creation.currency,
                      )
                      : creation.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.creator,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_rounded,
                      size: 14,
                      color: ModernColors.inkSoft,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${creation.viewsCount}',
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.favorite_rounded,
                      size: 14,
                      color: ModernColors.inkSoft,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${creation.savesCount}',
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 11,
                      ),
                    ),
                    if (creation.hasManagedStock) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 14,
                        color:
                            creation.isLowStock || creation.isOutOfStock
                                ? ModernColors.rose
                                : ModernColors.inkSoft,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stock ${creation.stock}',
                        style: TextStyle(
                          color:
                              creation.isLowStock || creation.isOutOfStock
                                  ? ModernColors.rose
                                  : ModernColors.inkSoft,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
