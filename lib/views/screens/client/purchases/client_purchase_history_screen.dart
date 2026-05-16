import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/commerce/purchase_history_item.dart';
import '../../../../services/client/client_purchase_service.dart';
import '../../../../services/preferences/currency_service.dart';
import '../../global/salon_mode_burkinabe.dart';

class ClientPurchaseHistoryScreen extends StatefulWidget {
  const ClientPurchaseHistoryScreen({super.key});

  @override
  State<ClientPurchaseHistoryScreen> createState() =>
      _ClientPurchaseHistoryScreenState();
}

class _ClientPurchaseHistoryScreenState
    extends State<ClientPurchaseHistoryScreen> {
  final ClientPurchaseService _service = ClientPurchaseService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        title: const Text('Achats'),
        backgroundColor: ModernColors.canvas,
        foregroundColor: ModernColors.ink,
        elevation: 0,
      ),
      body:
          user == null
              ? _PurchaseEmpty(
                icon: Icons.lock_outline_rounded,
                title: 'Connexion requise',
                message: 'Connectez-vous pour voir vos achats.',
              )
              : StreamBuilder<List<PurchaseHistoryItem>>(
                stream: _service.watchHistory(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return _PurchaseEmpty(
                      icon: AppIcons.orders,
                      title: 'Aucun achat',
                      message: 'Vos commandes apparaîtront ici.',
                      actionLabel: 'Explorer le Salon',
                      onAction:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SalonModeBurkinabeScreen(),
                            ),
                          ),
                    );
                  }
                  return ListView.separated(
                    cacheExtent: 900,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder:
                        (context, index) => _PurchaseCard(
                          item: items[index],
                          service: _service,
                          onReview: () => _openReviewSheet(items[index]),
                        ),
                  );
                },
              ),
    );
  }

  void _openReviewSheet(PurchaseHistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(item: item, service: _service),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({
    required this.item,
    required this.service,
    required this.onReview,
  });

  final PurchaseHistoryItem item;
  final ClientPurchaseService service;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      elevated: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child:
                item.productImageUrl.isEmpty
                    ? const _ImageFallback()
                    : CachedNetworkImage(
                      imageUrl: item.productImageUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const _ImageFallback(),
                    ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.category} • ${item.sellerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MiniPill(
                      icon:
                          item.isForSelf
                              ? AppIcons.wardrobe
                              : Icons.card_giftcard_rounded,
                      text:
                          item.isForSelf
                              ? item.wardrobeItemId.isNotEmpty
                                  ? 'Garde-robe'
                                  : 'À recevoir'
                              : 'Pour ${item.recipientName}',
                    ),
                    _MiniPill(
                      icon:
                          item.isReceived
                              ? Icons.verified_rounded
                              : Icons.hourglass_top_rounded,
                      text: item.statusLabel,
                    ),
                    _MiniPill(
                      icon: Icons.sell_rounded,
                      text: CurrencyService.format(
                        item.price * item.quantity,
                        code: item.currency,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child:
                      item.hasReview
                          ? Text(
                            'Avis envoyé • ${item.reviewRating}/5',
                            style: const TextStyle(
                              color: ModernColors.success,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          )
                          : TextButton.icon(
                            onPressed: item.canReview ? onReview : null,
                            icon: const Icon(Icons.star_rounded, size: 18),
                            label: Text(item.canReview ? 'Avis' : 'Après reçu'),
                          ),
                ),
                if (item.canConfirmReceipt) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton(
                      label: 'Reçu',
                      onPressed: () => _confirmReceipt(context, service, item),
                      icon: Icons.inventory_2_rounded,
                      variant: AppButtonVariant.outline,
                      compact: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _confirmReceipt(
    BuildContext context,
    ClientPurchaseService service,
    PurchaseHistoryItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la réception ?'),
            content: Text('Confirmez après avoir reçu "${item.productName}".'),
            actions: [
              AppButton(
                label: 'Annuler',
                onPressed: () => Navigator.pop(context, false),
                variant: AppButtonVariant.tertiary,
                compact: true,
              ),
              AppButton(
                label: 'Confirmer',
                onPressed: () => Navigator.pop(context, true),
                compact: true,
              ),
            ],
          ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await service.confirmReceipt(item);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réception confirmée.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Erreur confirmation réception: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réception impossible pour le moment.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.item, required this.service});

  final PurchaseHistoryItem item;
  final ClientPurchaseService service;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.service.submitReview(
        item: widget.item,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avis envoyé.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Erreur envoi avis: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avis impossible pour le moment.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: ModernColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: ModernShadows.elevated,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Avis', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              widget.item.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.inkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(5, (index) {
                final value = index + 1;
                return IconButton(
                  onPressed:
                      _saving ? null : () => setState(() => _rating = value),
                  icon: Icon(
                    value <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: ModernColors.accent,
                  ),
                );
              }),
            ),
            TextField(
              controller: _commentController,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Votre retour',
                hintText: 'Confort, qualité, taille, usage réel...',
              ),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Publier',
              onPressed: _saving ? null : _save,
              icon: Icons.send_rounded,
              loading: _saving,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ModernColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      color: ModernColors.line,
      child: const Icon(Icons.image_outlined, color: ModernColors.muted),
    );
  }
}

class _PurchaseEmpty extends StatelessWidget {
  const _PurchaseEmpty({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: ModernColors.primary, size: 34),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ModernColors.inkSoft),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                AppButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  icon: Icons.arrow_forward_rounded,
                  variant: AppButtonVariant.secondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
