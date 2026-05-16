import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/talent/talent_portfolio_item.dart';

class TalentPortfolioStrip extends StatelessWidget {
  const TalentPortfolioStrip({
    super.key,
    required this.items,
    this.compact = false,
    this.onOpenItem,
  });

  final List<TalentPortfolioItem> items;
  final bool compact;
  final ValueChanged<TalentPortfolioItem>? onOpenItem;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(14),
        elevated: false,
        child: const Text(
          'Aucun contenu publié pour cette vitrine.',
          style: TextStyle(
            color: ModernColors.inkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return SizedBox(
      height: compact ? 72 : 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: ModernColors.line,
              child: InkWell(
                onTap: onOpenItem == null ? null : () => onOpenItem!(item),
                child: SizedBox(
                  width: compact ? 72 : 104,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _PortfolioImage(url: item.imageUrl),
                      Positioned(
                        left: 6,
                        top: 6,
                        child: _TypePill(type: item.type),
                      ),
                      if (!compact)
                        Positioned(
                          left: 6,
                          right: 6,
                          bottom: 6,
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PortfolioImage extends StatelessWidget {
  const _PortfolioImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url.trim();
    if (!_isNetworkImage(imageUrl)) return const _PortfolioImageFallback();
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: 360,
      fadeInDuration: const Duration(milliseconds: 140),
      errorWidget: (_, _, _) => const _PortfolioImageFallback(),
      placeholder: (_, _) => const ColoredBox(color: ModernColors.line),
    );
  }
}

class _PortfolioImageFallback extends StatelessWidget {
  const _PortfolioImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: ModernColors.line,
      child: Icon(Icons.image_outlined, color: ModernColors.inkSoft),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final isProduct = type == 'product';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          isProduct ? 'Produit' : 'Création',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

bool _isNetworkImage(String url) {
  return url.startsWith('http://') || url.startsWith('https://');
}
