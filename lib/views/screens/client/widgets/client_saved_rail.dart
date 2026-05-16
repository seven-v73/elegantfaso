import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/client/client_saved_item.dart';

class ClientSavedRail extends StatelessWidget {
  final List<ClientSavedItem> items;
  final VoidCallback? onSeeAll;
  final void Function(ClientSavedItem item)? onTapItem;
  final void Function(ClientSavedItem item)? onTryOn;
  final void Function(ClientSavedItem item)? onFindVendor;
  final void Function(ClientSavedItem item)? onAskAdvice;
  final void Function(ClientSavedItem item)? onCreateLook;

  const ClientSavedRail({
    super.key,
    required this.items,
    this.onSeeAll,
    this.onTapItem,
    this.onTryOn,
    this.onFindVendor,
    this.onAskAdvice,
    this.onCreateLook,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppCard(
        onTap: onSeeAll,
        child: const Row(
          children: [
            Icon(Icons.favorite_border_rounded, color: ModernColors.rose),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucun favori pour le moment.',
                style: TextStyle(
                  color: ModernColors.inkSoft,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 186,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 132,
            child: AppCard(
              padding: EdgeInsets.zero,
              onTap: () => onTapItem?.call(item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(ModernRadius.lg),
                      ),
                      child:
                          item.imageUrl.isEmpty
                              ? const _SavedPlaceholder()
                              : CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder:
                                    (_, _) => const _SavedPlaceholder(),
                                errorWidget:
                                    (_, _, _) => const _SavedPlaceholder(),
                              ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.inkSoft,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _SavedQuickAction(
                              icon: Icons.checkroom_rounded,
                              tooltip: 'Essayer',
                              onTap: () => onTryOn?.call(item),
                            ),
                            _SavedQuickAction(
                              icon: AppIcons.boutique,
                              tooltip: 'Vendeur',
                              onTap: () => onFindVendor?.call(item),
                            ),
                            _SavedQuickAction(
                              icon: Icons.forum_rounded,
                              tooltip: 'Avis',
                              onTap: () => onAskAdvice?.call(item),
                            ),
                            _SavedQuickAction(
                              icon: Icons.palette_rounded,
                              tooltip: 'Look',
                              onTap: () => onCreateLook?.call(item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SavedQuickAction extends StatelessWidget {
  const _SavedQuickAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: SizedBox(
            height: 30,
            child: Icon(
              icon,
              size: 16,
              color: onTap == null ? ModernColors.muted : ModernColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedPlaceholder extends StatelessWidget {
  const _SavedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: ModernColors.canvas,
      child: const Icon(Icons.image_rounded, color: ModernColors.muted),
    );
  }
}
