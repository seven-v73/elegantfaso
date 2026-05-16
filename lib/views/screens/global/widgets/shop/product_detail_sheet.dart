import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/inspiration/external_look.dart';
import '../../../../../models/commerce/product_review.dart';
import '../../../../../models/shop/public_listing.dart';
import '../../../../../models/shop/seller_info.dart';
import '../../../../../models/try_on/try_on_source.dart';
import '../../../../../services/commerce/product_review_service.dart';
import '../../../../../services/inspiration/inspiration_wishlist_service.dart';
import '../../../../../services/preferences/currency_service.dart';
import '../../../../../services/salon/salon_analytics_service.dart';
import '../../salon_search_screen.dart';
import '../../../client/features/virtual_try_on_screen.dart';

class ProductDetailSheet extends StatefulWidget {
  const ProductDetailSheet({
    super.key,
    required this.listing,
    required this.seller,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final PublicListing listing;
  final SellerInfo seller;
  final Future<void> Function() onAddToCart;
  final Future<void> Function() onBuyNow;

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  final InspirationWishlistService _wishlistService =
      InspirationWishlistService();
  final ProductReviewService _reviewService = ProductReviewService();
  final SalonAnalyticsService _analyticsService = SalonAnalyticsService();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _analyticsService.trackListingView(
      itemId: widget.listing.id,
      itemType:
          widget.listing.isSecondhand
              ? 'secondhand'
              : widget.listing.isCreation
              ? 'creation'
              : 'product',
      ownerId:
          widget.seller.id.isNotEmpty
              ? widget.seller.id
              : widget.listing.sellerId,
      title: widget.listing.title,
      city: widget.seller.city,
    );
  }

  ExternalLook get _look => ExternalLook(
    id: ExternalLook.idFromImage(widget.listing.imageUrl),
    title: widget.listing.title,
    subtitle: widget.listing.category,
    imageUrl: widget.listing.imageUrl,
    source: widget.listing.isSecondhand ? 'Vide-dressing' : 'Shopping',
    tags: [widget.listing.category, widget.listing.badgeLabel],
  );

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      _showSnack(
        'Action impossible pour le moment. Réessayez dans un instant.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _contactSeller() async {
    final phone = widget.seller.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) {
      _showSnack('Contact direct indisponible pour ce vendeur.');
      return;
    }
    final launched = await launchUrl(
      Uri.parse(_whatsAppUrl(phone)),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) _showSnack('Impossible d’ouvrir la discussion.');
  }

  Future<void> _saveWish() async {
    try {
      await _wishlistService.save(_look);
    } catch (_) {
      _showSnack('Impossible de sauvegarder ce souhait maintenant.');
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ajouté aux souhaits de votre garde-robe.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareListing() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text:
              '${widget.listing.title}\n'
              '${CurrencyService.format(widget.listing.price, code: widget.listing.currency)}'
              '${widget.seller.name.isEmpty ? '' : '\nPar ${widget.seller.name}'}'
              '${widget.listing.imageUrl.isEmpty ? '' : '\n${widget.listing.imageUrl}'}',
          subject: 'Produit ElegantStyle',
        ),
      );
    } catch (_) {
      _showSnack('Partage indisponible sur cet appareil.');
    }
  }

  void _openTryOn() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => VirtualTryOnScreen(
              initialSource: TryOnSource(
                id: widget.listing.id,
                type:
                    widget.listing.isCreation
                        ? TryOnSourceType.creation
                        : TryOnSourceType.product,
                title: widget.listing.title,
                subtitle:
                    widget.listing.category.isEmpty
                        ? widget.listing.badgeLabel
                        : widget.listing.category,
                imageUrl: widget.listing.imageUrl,
                ownerId: widget.listing.sellerId,
                raw: widget.listing.data,
              ),
            ),
      ),
    );
  }

  String _whatsAppUrl(String phone) {
    return 'https://wa.me/$phone?text=${Uri.encodeComponent('Bonjour, je suis intéressé par ${widget.listing.title}.')}';
  }

  void _openSearch(String query) {
    final clean = query.trim();
    if (clean.isEmpty) {
      _showSnack('Aucun contexte disponible pour cette recherche.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SalonSearchScreen(initialQuery: clean)),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, controller) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: ModernColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.zero,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: AspectRatio(
                  aspectRatio: 0.85,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ProductHeroImage(url: widget.listing.imageUrl),
                      Positioned(
                        top: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 24,
                        child: _RoundIcon(
                          icon: Icons.close_rounded,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.listing.title,
                            style: const TextStyle(
                              color: ModernColors.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          CurrencyService.format(
                            widget.listing.price,
                            code: widget.listing.currency,
                          ),
                          style: const TextStyle(
                            color: ModernColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          icon: Icons.category_rounded,
                          label:
                              widget.listing.category.isEmpty
                                  ? widget.listing.badgeLabel
                                  : widget.listing.category,
                        ),
                        _MetaChip(
                          icon:
                              widget.listing.hasStock
                                  ? Icons.inventory_2_rounded
                                  : Icons.block_rounded,
                          label:
                              widget.listing.isSecondhand
                                  ? 'Disponible'
                                  : widget.listing.stock == null
                                  ? 'Disponible'
                                  : 'Stock ${widget.listing.stock}',
                        ),
                        if (widget.seller.city.isNotEmpty)
                          _MetaChip(
                            icon: Icons.place_rounded,
                            label: widget.seller.city,
                          ),
                        if (widget.listing.isSecondhand) ...[
                          if ((widget.listing.data['condition']?.toString() ??
                                  '')
                              .trim()
                              .isNotEmpty)
                            _MetaChip(
                              icon: Icons.check_circle_rounded,
                              label:
                                  widget.listing.data['condition'].toString(),
                            ),
                          if ((widget.listing.data['size']?.toString() ?? '')
                              .trim()
                              .isNotEmpty)
                            _MetaChip(
                              icon: Icons.straighten_rounded,
                              label: widget.listing.data['size'].toString(),
                            ),
                          if ((widget.listing.data['color']?.toString() ?? '')
                              .trim()
                              .isNotEmpty)
                            _MetaChip(
                              icon: Icons.palette_rounded,
                              label: widget.listing.data['color'].toString(),
                            ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SellerBlock(
                      seller: widget.seller,
                      listing: widget.listing,
                      onOpen: () => _openSearch(widget.seller.name),
                    ),
                    const SizedBox(height: 16),
                    if (!widget.listing.isSecondhand)
                      _ProductReviewPreview(
                        stream: _reviewService.watchSummary(widget.listing.id),
                      ),
                    if (widget.listing.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.listing.description,
                        style: const TextStyle(
                          color: ModernColors.inkSoft,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label:
                                widget.listing.isSecondhand
                                    ? 'Réserver'
                                    : 'Acheter',
                            onPressed:
                                _busy
                                    ? null
                                    : () => _run(
                                      widget.listing.isSecondhand
                                          ? widget.onAddToCart
                                          : widget.onBuyNow,
                                    ),
                            icon:
                                widget.listing.isSecondhand
                                    ? Icons.bookmark_add_rounded
                                    : AppIcons.cart,
                            loading: _busy,
                            expand: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppIconAction(
                          icon: Icons.favorite_border_rounded,
                          tooltip: 'Souhait',
                          onPressed: _saveWish,
                          color: ModernColors.rose,
                        ),
                        const SizedBox(width: 8),
                        AppOverflowMenu(
                          actions: [
                            if (!widget.listing.isSecondhand)
                              AppOverflowAction(
                                label: 'Ajouter au panier',
                                icon: Icons.add_shopping_cart_rounded,
                                onPressed:
                                    _busy
                                        ? null
                                        : () => _run(widget.onAddToCart),
                              ),
                            AppOverflowAction(
                              label: 'Contacter',
                              icon: Icons.chat_rounded,
                              onPressed: _contactSeller,
                            ),
                            if (widget.listing.canTryOn)
                              AppOverflowAction(
                                label: 'Essayer',
                                icon: Icons.checkroom_rounded,
                                onPressed: _openTryOn,
                              ),
                            AppOverflowAction(
                              label: 'Partager',
                              icon: Icons.ios_share_rounded,
                              onPressed: _shareListing,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SuggestionsBlock(
                      listing: widget.listing,
                      onSimilar:
                          () => _openSearch(
                            '${widget.listing.category} ${widget.listing.title}',
                          ),
                      onSameSeller: () => _openSearch(widget.seller.name),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SellerBlock extends StatelessWidget {
  const _SellerBlock({
    required this.seller,
    required this.listing,
    required this.onOpen,
  });

  final SellerInfo seller;
  final PublicListing listing;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      elevated: false,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                seller.imageUrl.isEmpty ? null : NetworkImage(seller.imageUrl),
            child:
                seller.imageUrl.isEmpty
                    ? Icon(
                      seller.isClient
                          ? Icons.person_rounded
                          : seller.isBoutique
                          ? AppIcons.boutique
                          : AppIcons.talents,
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        seller.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ModernColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (seller.verified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        color: ModernColors.primary,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (listing.isSecondhand)
                      'Vide-dressing'
                    else if (seller.isBoutique)
                      'Boutique'
                    else
                      'Créateur',
                    if (seller.city.isNotEmpty) seller.city,
                    if (seller.responseTime.isNotEmpty) seller.responseTime,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            label: 'Voir',
            onPressed: onOpen,
            variant: AppButtonVariant.tertiary,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _SuggestionsBlock extends StatelessWidget {
  const _SuggestionsBlock({
    required this.listing,
    required this.onSimilar,
    required this.onSameSeller,
  });

  final PublicListing listing;
  final VoidCallback onSimilar;
  final VoidCallback onSameSeller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À explorer ensuite',
            style: TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.style_rounded, size: 16),
                label: Text('Similaires ${listing.category}'),
                onPressed: onSimilar,
              ),
              ActionChip(
                avatar: const Icon(AppIcons.shop, size: 16),
                label: const Text('Même vendeur'),
                onPressed: onSameSeller,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductReviewPreview extends StatelessWidget {
  const _ProductReviewPreview({required this.stream});

  final Stream<ProductReviewSummary> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProductReviewSummary>(
      stream: stream,
      builder: (context, snapshot) {
        final summary = snapshot.data ?? ProductReviewSummary.empty;
        return AppCard(
          padding: const EdgeInsets.all(14),
          elevated: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: ModernColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary.count == 0
                          ? 'Avis après usage'
                          : '${summary.average.toStringAsFixed(1)}/5 • ${summary.count} avis',
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (summary.count == 0)
                const Text(
                  'Les avis apparaîtront ici après achat et usage réel.',
                  style: TextStyle(
                    color: ModernColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                ...summary.recent.map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${'★' * review.rating} ${review.comment.isEmpty ? review.userName : review.comment}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      side: const BorderSide(color: ModernColors.line),
      backgroundColor: Colors.white,
    );
  }
}

class _ProductHeroImage extends StatelessWidget {
  const _ProductHeroImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url.trim();
    if (!_isNetworkImage(imageUrl)) return const _ProductImageFallback();
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: 900,
      fadeInDuration: const Duration(milliseconds: 160),
      errorWidget: (_, _, _) => const _ProductImageFallback(),
      placeholder: (_, _) => const ColoredBox(color: ModernColors.line),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: ModernColors.line,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: ModernColors.inkSoft,
          size: 42,
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: IconButton(onPressed: onPressed, icon: Icon(icon)),
    );
  }
}

bool _isNetworkImage(String url) {
  return url.startsWith('http://') || url.startsWith('https://');
}
