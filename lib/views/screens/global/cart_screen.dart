import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/app_icons.dart';
import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';
import '../../../models/global/cart_item.dart';
import '../../../services/global/cart_service.dart';
import '../../../services/preferences/currency_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Stream<List<CartItem>>? _cartScreenItemsStream;
  final Set<String> _updatingItems = {};

  @override
  void initState() {
    super.initState();
    _cartScreenItemsStream = CartService.getCartStream();
  }

  Stream<List<CartItem>> get _effectiveCartScreenItemsStream =>
      _cartScreenItemsStream ??= CartService.getCartStream();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        title: const Text('Panier'),
        backgroundColor: ModernColors.canvas,
        foregroundColor: ModernColors.ink,
        elevation: 0,
        actions: [
          StreamBuilder<List<CartItem>>(
            stream: _effectiveCartScreenItemsStream,
            builder: (context, snapshot) {
              final hasItems = snapshot.hasData && snapshot.data!.isNotEmpty;
              return hasItems
                  ? IconButton(
                    tooltip: 'Vider le panier',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _showClearCartDialog(context),
                  )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body:
          !CartService.isSignedIn
              ? _buildSignedOutState()
              : StreamBuilder<List<CartItem>>(
                stream: _effectiveCartScreenItemsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _CartSkeleton();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorWidget(screenWidth);
                  }

                  final cartItems = snapshot.data ?? [];
                  if (cartItems.isEmpty) return _buildEmptyCart(screenWidth);

                  final grouped = CartService.groupItemsByVendor(cartItems);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
                    children: [
                      if (grouped.length > 1) const _MultiVendorNotice(),
                      for (final entry in grouped.entries)
                        _buildVendorGroup(entry.value),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildVendorGroup(List<CartItem> vendorItems) {
    final vendor = Vendor.fromCartItem(vendorItems.first);
    final totals = CartService.calculateTotals(vendorItems);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      elevated: false,
      child: Column(
        children: [
          Row(
            children: [
              _VendorAvatar(imageUrl: vendor.photoUrl, radius: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${vendorItems.length} article${vendorItems.length > 1 ? 's' : ''} chez ce vendeur',
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyService.format(
                  totals.grandTotal,
                  code: vendorItems.first.currency,
                ),
                style: const TextStyle(
                  color: ModernColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in vendorItems) _buildDismissibleCartItem(item),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackActions = constraints.maxWidth < 330;
              final checkoutButton = AppButton(
                label: 'Commander',
                icon: AppIcons.cart,
                onPressed: () => _proceedToCheckout(vendorItems),
                compact: true,
              );

              if (stackActions) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TotalsPreview(
                      totals: totals,
                      currency: vendorItems.first.currency,
                    ),
                    const SizedBox(height: 10),
                    checkoutButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _TotalsPreview(
                      totals: totals,
                      currency: vendorItems.first.currency,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(child: checkoutButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleCartItem(CartItem item) {
    return Dismissible(
      key: ValueKey('cart-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: ModernColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: ModernColors.danger),
      ),
      confirmDismiss: (_) async {
        await _removeItem(item);
        return false;
      },
      child: _buildCartItemCard(item),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    final size = item.metadata['size']?.toString() ?? '';
    final color = item.metadata['color']?.toString() ?? '';
    final isUpdating = _updatingItems.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ModernColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              placeholder: (_, _) => const _ImageFallback(),
              errorWidget: (_, _, _) => const _ImageFallback(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: ModernColors.ink,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyService.format(item.price, code: item.currency),
                      style: const TextStyle(
                        color: ModernColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (size.isNotEmpty) _MiniPill(label: 'Taille: $size'),
                    if (color.isNotEmpty) _MiniPill(label: color, accent: true),
                    if (item.stockLimit < 99)
                      _MiniPill(label: 'Stock: ${item.stockLimit}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuantityControls(item, isUpdating),
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: isUpdating ? null : () => _removeItem(item),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: ModernColors.danger,
                      ),
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

  Widget _buildQuantityControls(CartItem item, bool isUpdating) {
    return Container(
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 17),
            onPressed:
                isUpdating || item.quantity <= 1
                    ? null
                    : () => _updateQuantity(item, item.quantity - 1),
            padding: const EdgeInsets.all(4),
            color: ModernColors.primary,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child:
                isUpdating
                    ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(
                      '${item.quantity}',
                      key: ValueKey(item.quantity),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 17),
            onPressed:
                isUpdating || item.quantity >= item.stockLimit
                    ? null
                    : () => _updateQuantity(item, item.quantity + 1),
            padding: const EdgeInsets.all(4),
            color: ModernColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSignedOutState() {
    return _StateMessage(
      icon: Icons.lock_outline_rounded,
      title: 'Connectez-vous',
      message: 'Votre panier sera synchronisé après connexion.',
      actionLabel: 'Retour',
      onAction: () => Navigator.maybePop(context),
    );
  }

  Widget _buildEmptyCart(double screenWidth) {
    return _StateMessage(
      icon: Icons.shopping_cart_outlined,
      title: 'Panier vide',
      message: 'Ajoutez des produits pour commencer vos achats.',
      actionLabel: 'Continuer mes achats',
      onAction: () => Navigator.maybePop(context),
    );
  }

  Widget _buildErrorWidget(double screenWidth) {
    return _StateMessage(
      icon: Icons.error_outline_rounded,
      title: 'Chargement impossible',
      message: 'Veuillez réessayer dans un instant.',
      actionLabel: 'Réessayer',
      onAction:
          () => setState(
            () => _cartScreenItemsStream = CartService.getCartStream(),
          ),
      danger: true,
    );
  }

  Future<void> _updateQuantity(CartItem item, int quantity) async {
    setState(() => _updatingItems.add(item.id));
    try {
      await CartService.updateQuantity(item.id, quantity);
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Erreur mise à jour panier: $e');
      _showSnack('Panier indisponible pour le moment.', ModernColors.danger);
    } finally {
      if (mounted) setState(() => _updatingItems.remove(item.id));
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      await CartService.removeFromCart(item.id);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              Expanded(
                child: Text(
                  '${item.name} retiré du panier',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () async {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  await CartService.restoreItem(item);
                },
                child: const Text(
                  'Annuler',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: ModernColors.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Erreur suppression panier: $e');
      _showSnack('Impossible de retirer cet article.', ModernColors.danger);
    }
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Vider le panier'),
            content: const Text(
              'Êtes-vous sûr de vouloir vider votre panier ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  try {
                    await CartService.clearCart();
                    if (!mounted) return;
                    _showSnack('Panier vidé avec succès', ModernColors.success);
                    HapticFeedback.heavyImpact();
                  } catch (e) {
                    debugPrint('Erreur vidage panier: $e');
                    _showSnack(
                      'Impossible de vider le panier.',
                      ModernColors.danger,
                    );
                  }
                },
                child: const Text(
                  'Vider',
                  style: TextStyle(color: ModernColors.danger),
                ),
              ),
            ],
          ),
    );
  }

  void _proceedToCheckout(List<CartItem> items) {
    if (items.isEmpty) {
      _showSnack('Votre panier est vide', ModernColors.accent);
      return;
    }
    final vendorKeys = items.map((item) => item.vendorKey).toSet();
    if (vendorKeys.length > 1) {
      _showSnack(
        'Finalisez chaque fournisseur séparément.',
        ModernColors.accent,
      );
      return;
    }

    final vendor = Vendor.fromCartItem(items.first);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(cartItems: items, vendor: vendor),
      ),
    );
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _MultiVendorNotice extends StatelessWidget {
  const _MultiVendorNotice();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(13),
      elevated: false,
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: ModernColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Votre panier contient plusieurs vendeurs. Les commandes sont séparées par vendeur pour faciliter le paiement et la livraison.',
              style: TextStyle(
                color: ModernColors.inkSoft,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorAvatar extends StatelessWidget {
  const _VendorAvatar({required this.imageUrl, this.radius = 24});

  final String imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    Widget fallback() => Container(
      width: size,
      height: size,
      color: ModernColors.line,
      child: Icon(AppIcons.shop, color: ModernColors.inkSoft, size: radius),
    );
    return ClipOval(
      child:
          imageUrl.isEmpty
              ? fallback()
              : CachedNetworkImage(
                imageUrl: imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, _) => fallback(),
                errorWidget: (_, _, _) => fallback(),
                errorListener: (_) {},
              ),
    );
  }
}

class _TotalsPreview extends StatelessWidget {
  const _TotalsPreview({required this.totals, required this.currency});

  final CartTotals totals;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Sous-total ${_CartPrice.format(totals.subtotal, currency)}\n'
      'Livraison ${_CartPrice.format(totals.deliveryFee, currency)}',
      style: const TextStyle(
        color: ModernColors.inkSoft,
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ? ModernColors.accent : ModernColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.13)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 74,
              color: danger ? ModernColors.danger : ModernColors.inkSoft,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: ModernColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ModernColors.inkSoft),
            ),
            const SizedBox(height: 24),
            AppButton(label: actionLabel, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}

class _CartSkeleton extends StatelessWidget {
  const _CartSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: 4,
      itemBuilder: (context, index) {
        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          elevated: false,
          child: Row(
            children: [
              const _SkeletonBox(width: 64, height: 64, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SkeletonBox(width: double.infinity, height: 14),
                    SizedBox(height: 9),
                    _SkeletonBox(width: 150, height: 12),
                    SizedBox(height: 14),
                    _SkeletonBox(width: 112, height: 32, radius: 18),
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

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ModernColors.line.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ModernColors.surfaceRaised,
      child: const Icon(
        Icons.image_not_supported_rounded,
        color: ModernColors.muted,
      ),
    );
  }
}

class _CartPrice {
  static String format(double value, [String? currency]) =>
      CurrencyService.format(value, code: currency);
}
