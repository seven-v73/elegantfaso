import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/commerce/managed_payment.dart';
import '../../../../../models/client/gamification/client_visibility_tier.dart';
import '../../../../../models/messages/conversation_context.dart';
import '../../../../../models/secondhand/secondhand_listing.dart';
import '../../../../../services/preferences/currency_service.dart';
import '../../../../../services/secondhand/secondhand_listing_service.dart';
import '../../../../widgets/forms/app_form_section.dart';
import '../../../../widgets/forms/app_image_picker_field.dart';
import '../../../../widgets/forms/app_money_field.dart';
import '../../../../widgets/forms/app_responsive_field_row.dart';
import '../../../../widgets/forms/app_select_field.dart';
import '../../../../widgets/forms/app_sticky_form_bar.dart';
import '../../../../widgets/forms/app_text_field.dart';
import '../../../base/client_profile_screen.dart';
import '../../../messages/chat_screen.dart';
import '../../../messages/user_model.dart';

class SecondhandMarketplace extends StatefulWidget {
  const SecondhandMarketplace({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SecondhandMarketplace> createState() => _SecondhandMarketplaceState();
}

class _SecondhandMarketplaceState extends State<SecondhandMarketplace> {
  static const _pageSize = 24;
  static const _categories = [
    'Tout',
    'Sacs',
    'Bijoux',
    'Chaussures',
    'Foulards',
    'Lunettes',
    'Ceintures',
  ];

  final SecondhandListingService _service = SecondhandListingService();
  final TextEditingController _searchController = TextEditingController();
  late Future<SecondhandSnapshot> _snapshotFuture;
  Timer? _searchDebounce;
  String _category = 'Tout';
  String _query = '';
  int _listingLimit = _pageSize;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _searchController.text = _query;
    _snapshotFuture = _service.loadSnapshot();
  }

  @override
  void didUpdateWidget(covariant SecondhandMarketplace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextQuery = widget.initialQuery.trim();
    if (nextQuery != oldWidget.initialQuery.trim() && nextQuery != _query) {
      _searchController.text = nextQuery;
      setState(() {
        _query = nextQuery;
        _listingLimit = _pageSize;
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _setCategory(String category) {
    setState(() {
      _category = category;
      _listingLimit = _pageSize;
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      setState(() {
        _query = value.trim();
        _listingLimit = _pageSize;
      });
    });
  }

  void _openPublishSheet() {
    if (FirebaseAuth.instance.currentUser == null) {
      _showLoginSnack('Connectez-vous pour publier une pièce.');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _SecondhandPublishSheet(
            service: _service,
            onPublished: _refreshSnapshot,
          ),
    );
  }

  void _refreshSnapshot() {
    setState(() => _snapshotFuture = _service.loadSnapshot());
  }

  void _showLoginSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SecondhandHero(onPublish: _openPublishSheet),
        const SizedBox(height: 12),
        _SecondhandSearch(
          controller: _searchController,
          query: _query,
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return ChoiceChip(
                label: Text(category),
                selected: _category == category,
                onSelected: (_) => _setCategory(category),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<SecondhandSnapshot>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            final data = snapshot.data;
            return _TrustStrip(
              available: data?.available ?? 0,
              reserved: data?.reserved ?? 0,
              sold: data?.sold ?? 0,
            );
          },
        ),
        const SizedBox(height: 16),
        SectionHeader(
          title: 'Pièces de clients',
          subtitle:
              _query.isEmpty
                  ? 'Accessoires vérifiés par la communauté'
                  : 'Résultats pour "$_query"',
          action: AppIconAction(
            icon: AppIcons.add,
            tooltip: 'Publier',
            onPressed: _openPublishSheet,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StreamBuilder<List<SecondhandListing>>(
            stream: _service.watchListings(
              category: _category,
              query: _query,
              limit: _listingLimit,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _SecondhandSkeleton();
              }
              if (snapshot.hasError) {
                return const _SecondhandEmpty(
                  icon: Icons.cloud_off_rounded,
                  title: 'Impossible de charger',
                  message: 'Réessayez dans un instant.',
                );
              }
              final listings = snapshot.data ?? [];
              if (listings.isEmpty) {
                return _SecondhandEmpty(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aucune pièce pour le moment',
                  message:
                      'Soyez le premier à publier une tenue ou un accessoire.',
                  actionLabel: 'Publier une pièce',
                  onAction: _openPublishSheet,
                );
              }

              return Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 620 ? 3 : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listings.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.66,
                        ),
                        itemBuilder:
                            (context, index) => _SecondhandCard(
                              listing: listings[index],
                              service: _service,
                            ),
                      );
                    },
                  ),
                  if (listings.length >= _listingLimit) ...[
                    const SizedBox(height: 14),
                    AppButton(
                      label: 'Voir plus',
                      onPressed:
                          () => setState(() => _listingLimit += _pageSize),
                      icon: Icons.expand_more_rounded,
                      variant: AppButtonVariant.outline,
                      expand: true,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SecondhandHero extends StatelessWidget {
  const _SecondhandHero({required this.onPublish});

  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ModernColors.ink,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ModernColors.ink),
          boxShadow: ModernShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.recycling_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Vide-dressing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Revendez les accessoires que vous ne portez plus. Les points gagnés au quiz augmentent la visibilité des annonces, sans abonnement.',
              style: TextStyle(
                color: Color(0xFFE5E7EB),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _HeroChip(
                    icon: Icons.verified_user_rounded,
                    label: 'Clients identifiés',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeroChip(
                    icon: Icons.trending_up_rounded,
                    label: 'Visibilité méritée',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Publier',
              onPressed: onPublish,
              icon: AppIcons.add,
              variant: AppButtonVariant.secondary,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondhandSearch extends StatelessWidget {
  const _SecondhandSearch({
    required this.controller,
    required this.query,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Sac, bijoux, foulard, ville...',
          prefixIcon: const Icon(AppIcons.search),
          suffixIcon:
              query.isEmpty
                  ? null
                  : IconButton(
                    tooltip: 'Effacer',
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: const Icon(AppIcons.close),
                  ),
        ),
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip({
    required this.available,
    required this.reserved,
    required this.sold,
  });

  final int available;
  final int reserved;
  final int sold;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _TrustCard(
            icon: Icons.shopping_bag_outlined,
            label: '$available disponibles',
            detail: 'à acheter ou réserver',
            color: ModernColors.primary,
          ),
          const SizedBox(width: 10),
          _TrustCard(
            icon: Icons.lock_clock_rounded,
            label: '$reserved réservées',
            detail: 'en discussion',
            color: ModernColors.accent,
          ),
          const SizedBox(width: 10),
          _TrustCard(
            icon: Icons.eco_rounded,
            label: '$sold revendues',
            detail: 'pièces prolongées',
            color: ModernColors.success,
          ),
        ],
      ),
    );
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 172,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        elevated: false,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    detail,
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
          ],
        ),
      ),
    );
  }
}

class _SecondhandCard extends StatelessWidget {
  const _SecondhandCard({required this.listing, required this.service});

  final SecondhandListing listing;
  final SecondhandListingService service;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final liked = userId != null && listing.likedBy.contains(userId);

    return AppCard(
      padding: EdgeInsets.zero,
      onTap:
          () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder:
                (_) =>
                    _SecondhandDetailSheet(listing: listing, service: service),
          ),
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
                  child:
                      listing.coverUrl.isEmpty
                          ? const _ImageFallback()
                          : CachedNetworkImage(
                            imageUrl: listing.coverUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const _ImageFallback(),
                            errorWidget: (_, _, _) => const _ImageFallback(),
                          ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: _StatusPill(label: listing.statusLabel),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: _VisibilityPill(listing: listing),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: AppIconAction(
                    icon:
                        liked ? Icons.favorite_rounded : Icons.favorite_border,
                    tooltip: 'Aimer',
                    onPressed: () => _toggleLike(context),
                    selected: liked,
                    color: ModernColors.rose,
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
                  CurrencyService.format(listing.price, code: listing.currency),
                  style: const TextStyle(
                    color: ModernColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${listing.condition} • ${listing.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  listing.visibilityCategory,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(BuildContext context) async {
    try {
      await service.toggleLike(listing);
    } catch (error) {
      if (!context.mounted) return;
      final message = error.toString().replaceFirst('Bad state: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: ModernColors.ink.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VisibilityPill extends StatelessWidget {
  const _VisibilityPill({required this.listing});

  final SecondhandListing listing;

  @override
  Widget build(BuildContext context) {
    final tier = ClientVisibilityTiers.fromId(listing.visibilityTierId);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: tier.color.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                listing.visibilityLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondhandDetailSheet extends StatefulWidget {
  const _SecondhandDetailSheet({required this.listing, required this.service});

  final SecondhandListing listing;
  final SecondhandListingService service;

  @override
  State<_SecondhandDetailSheet> createState() => _SecondhandDetailSheetState();
}

class _SecondhandDetailSheetState extends State<_SecondhandDetailSheet> {
  bool _busy = false;
  late Future<Map<String, String>> _paymentMethodsFuture;

  bool get _isOwner =>
      FirebaseAuth.instance.currentUser?.uid == widget.listing.sellerId;

  @override
  void initState() {
    super.initState();
    _paymentMethodsFuture =
        widget.service.loadCurrentUserWithdrawalPaymentMethods();
  }

  Future<void> _reserve() async {
    setState(() => _busy = true);
    try {
      await widget.service.reserve(widget.listing);
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Pièce réservée. Contactez le vendeur pour finaliser.');
    } catch (e) {
      debugPrint('Erreur réservation vide-dressing: $e');
      _showSnack('Réservation impossible pour le moment.', danger: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markSold() async {
    setState(() => _busy = true);
    try {
      await widget.service.markSold(widget.listing);
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Annonce marquée comme vendue.');
    } catch (e) {
      debugPrint('Erreur vente vide-dressing: $e');
      _showSnack('Mise à jour impossible pour le moment.', danger: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestWithdrawal() async {
    setState(() => _busy = true);
    try {
      await widget.service.requestWithdrawal(widget.listing);
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Demande de retrait envoyée à l’admin.');
    } catch (e) {
      _showSnack('Retrait impossible: ${_friendlyError(e)}', danger: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    return text.startsWith('Bad state: ')
        ? text.replaceFirst('Bad state: ', '')
        : text;
  }

  Future<void> _openWithdrawalSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientProfileScreen(showBackButton: true),
      ),
    );
    if (!mounted) return;
    setState(() {
      _paymentMethodsFuture =
          widget.service.loadCurrentUserWithdrawalPaymentMethods();
    });
  }

  Future<void> _convertToStylePoints() async {
    final points = SecondhandSettlementPolicy.stylePointsFor(
      amount:
          widget.listing.secondhandAvailableBalance > 0
              ? widget.listing.secondhandAvailableBalance
              : widget.listing.price,
      currency: widget.listing.currency,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Transformer en points Style ?'),
            content: Text(
              'Vous recevrez environ $points points Style. Ces points augmentent votre niveau, la visibilité de vos annonces et votre présence dans le Salon. Cette action remplace le retrait normal.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Garder le retrait'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Recevoir les points'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      final awarded = await widget.service.convertSaleToStylePoints(
        widget.listing,
      );
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('+$awarded points Style ajoutés à votre parcours.');
    } catch (e) {
      _showSnack('Conversion impossible: $e', danger: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnack('Connectez-vous pour contacter le vendeur.', danger: true);
      return;
    }
    if (_isOwner) {
      _showSnack('Ceci est votre annonce.');
      return;
    }

    setState(() => _busy = true);
    try {
      final currentDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
      final currentModel =
          currentDoc.exists
              ? UserModel.fromDocument(currentDoc)
              : UserModel.fromMap({
                'id': currentUser.uid,
                'email': currentUser.email ?? '',
                'displayName': currentUser.displayName ?? 'Client',
                'role': 'client',
                'photoUrl': currentUser.photoURL,
              });
      final sellerModel = UserModel.fromMap({
        'id': widget.listing.sellerId,
        'displayName': widget.listing.sellerName,
        'role': 'client',
        'roles': const ['client'],
        'photoUrl': widget.listing.sellerPhotoUrl,
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ChatScreen(
                utilisateurCourant: currentModel,
                autreUtilisateur: sellerModel,
                currentRole: 'client',
                otherRole: 'client',
                primaryColor: ModernColors.primary,
                conversationContext: ConversationContext(
                  type: ConversationContextTypes.secondhand,
                  id: widget.listing.id,
                  title: widget.listing.title,
                  subtitle: CurrencyService.format(
                    widget.listing.price,
                    code: widget.listing.currency,
                  ),
                  imageUrl: widget.listing.coverUrl,
                  metadata: {'listingId': widget.listing.id},
                ),
              ),
        ),
      );
    } catch (e) {
      debugPrint('Erreur ouverture discussion vide-dressing: $e');
      _showSnack('Discussion indisponible pour le moment.', danger: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _report() async {
    try {
      await widget.service.report(
        widget.listing,
        'Annonce signalée par client',
      );
      _showSnack('Merci, l’annonce sera vérifiée.');
    } catch (e) {
      _showSnack('Signalement impossible: $e', danger: true);
    }
  }

  Future<void> _shareListing() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Vide-dressing ElegantStyle',
          text:
              '${widget.listing.title}\n'
              '${CurrencyService.format(widget.listing.price, code: widget.listing.currency)}'
              '${widget.listing.city.isEmpty ? '' : '\n${widget.listing.city}'}'
              '${widget.listing.coverUrl.isEmpty ? '' : '\n${widget.listing.coverUrl}'}',
        ),
      );
    } catch (_) {
      _showSnack('Partage indisponible sur cet appareil.', danger: true);
    }
  }

  void _showSnack(String message, {bool danger = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: danger ? ModernColors.danger : ModernColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ModernColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child:
                    listing.coverUrl.isEmpty
                        ? const SizedBox(height: 300, child: _ImageFallback())
                        : CachedNetworkImage(
                          imageUrl: listing.coverUrl,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      listing.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    CurrencyService.format(
                      listing.price,
                      code: listing.currency,
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
                  _InfoPill(
                    icon: Icons.person_rounded,
                    text: 'Vendu par un client',
                  ),
                  _InfoPill(
                    icon: Icons.visibility_rounded,
                    text: listing.visibilityLabel,
                  ),
                  _InfoPill(
                    icon: Icons.check_circle_rounded,
                    text: listing.condition,
                  ),
                  _InfoPill(icon: Icons.place_rounded, text: listing.city),
                  if (listing.size.isNotEmpty)
                    _InfoPill(
                      icon: Icons.straighten_rounded,
                      text: listing.size,
                    ),
                  if (listing.color.isNotEmpty)
                    _InfoPill(icon: Icons.palette_rounded, text: listing.color),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                listing.description,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<SecondhandSellerTrust>(
                future: widget.service.loadSellerTrust(listing.sellerId),
                builder: (context, snapshot) {
                  final trust = snapshot.data;
                  return _SecondhandSellerCard(
                    listing: listing,
                    trust: trust,
                    onReport: _report,
                  );
                },
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Partager',
                onPressed: _shareListing,
                icon: Icons.ios_share_rounded,
                variant: AppButtonVariant.outline,
                expand: true,
              ),
              const SizedBox(height: 10),
              if (_isOwner) ...[
                if (listing.hasSettlementAvailable)
                  FutureBuilder<Map<String, String>>(
                    future: _paymentMethodsFuture,
                    builder: (context, snapshot) {
                      return _SecondhandSettlementPanel(
                        listing: listing,
                        busy:
                            _busy ||
                            snapshot.connectionState == ConnectionState.waiting,
                        paymentMethods: snapshot.data ?? const {},
                        onWithdraw: _requestWithdrawal,
                        onConvert: _convertToStylePoints,
                        onConfigurePayment: _openWithdrawalSettings,
                      );
                    },
                  )
                else if (listing.hasWithdrawalRequest)
                  Column(
                    children: [
                      const _OwnerSettlementInfo(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Retrait demandé',
                        message:
                            'Votre demande est en vérification admin. Le transfert sera traité manuellement.',
                      ),
                      const SizedBox(height: 10),
                      _SecondhandSettlementTimeline(listing: listing),
                    ],
                  )
                else if (listing.isConvertedToStylePoints)
                  Column(
                    children: [
                      _OwnerSettlementInfo(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Converti en points Style',
                        message:
                            '${listing.stylePointsAwarded} points ont été ajoutés à votre visibilité.',
                      ),
                      const SizedBox(height: 10),
                      _SecondhandSettlementTimeline(listing: listing),
                    ],
                  )
                else if (listing.isWithdrawn)
                  Column(
                    children: [
                      _OwnerSettlementInfo(
                        icon: Icons.verified_rounded,
                        title: 'Retrait payé',
                        message:
                            '${CurrencyService.format(listing.secondhandWithdrawnBalance, code: listing.currency)} a été marqué comme transféré par l’admin.',
                      ),
                      const SizedBox(height: 10),
                      _SecondhandSettlementTimeline(listing: listing),
                    ],
                  )
                else if (listing.isDisputed)
                  Column(
                    children: [
                      const _OwnerSettlementInfo(
                        icon: Icons.block_rounded,
                        title: 'Solde bloqué',
                        message:
                            'Le retrait est temporairement bloqué pour vérification admin. Le suivi reste conservé.',
                      ),
                      const SizedBox(height: 10),
                      _SecondhandSettlementTimeline(listing: listing),
                    ],
                  )
                else if (listing.hasSettlementHistory)
                  _SecondhandSettlementTimeline(listing: listing)
                else
                  AppButton(
                    label: 'Vendu',
                    onPressed: _busy || listing.isSold ? null : _markSold,
                    icon: Icons.done_all_rounded,
                    loading: _busy,
                    expand: true,
                  ),
              ] else ...[
                AppButton(
                  label: listing.isAvailable ? 'Réserver' : listing.statusLabel,
                  onPressed: _busy || !listing.isAvailable ? null : _reserve,
                  icon: Icons.lock_clock_rounded,
                  loading: _busy,
                  expand: true,
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Message',
                  onPressed: _busy ? null : _openChat,
                  icon: AppIcons.messages,
                  variant: AppButtonVariant.outline,
                  expand: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: ModernColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: ModernColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondhandSettlementPanel extends StatelessWidget {
  const _SecondhandSettlementPanel({
    required this.listing,
    required this.busy,
    required this.paymentMethods,
    required this.onWithdraw,
    required this.onConvert,
    required this.onConfigurePayment,
  });

  final SecondhandListing listing;
  final bool busy;
  final Map<String, String> paymentMethods;
  final VoidCallback onWithdraw;
  final VoidCallback onConvert;
  final VoidCallback onConfigurePayment;

  @override
  Widget build(BuildContext context) {
    final amount =
        listing.secondhandAvailableBalance > 0
            ? listing.secondhandAvailableBalance
            : listing.price;
    final points = SecondhandSettlementPolicy.stylePointsFor(
      amount: amount,
      currency: listing.currency,
    );
    final hasPaymentMethods = paymentMethods.isNotEmpty;
    final firstMethod = hasPaymentMethods ? paymentMethods.entries.first : null;
    return AppCard(
      elevated: false,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde vide-dressing disponible',
            style: TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${CurrencyService.format(amount, code: listing.currency)} peut être retiré ou transformé en $points points Style.',
            style: const TextStyle(
              color: ModernColors.inkSoft,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color:
                  hasPaymentMethods
                      ? ModernColors.success.withValues(alpha: 0.08)
                      : ModernColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    hasPaymentMethods
                        ? ModernColors.success.withValues(alpha: 0.16)
                        : ModernColors.warning.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasPaymentMethods
                      ? Icons.verified_rounded
                      : Icons.info_outline_rounded,
                  color:
                      hasPaymentMethods
                          ? ModernColors.success
                          : ModernColors.warning,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasPaymentMethods
                        ? 'Retrait prêt via ${firstMethod!.key} • ${firstMethod.value}.'
                        : 'Ajoutez un moyen de retrait dans votre profil avant de demander un transfert.',
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Points Style',
                  onPressed: busy ? null : onConvert,
                  icon: Icons.auto_awesome_rounded,
                  variant: AppButtonVariant.outline,
                  expand: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child:
                    hasPaymentMethods
                        ? AppButton(
                          label: 'Retirer',
                          onPressed: busy ? null : onWithdraw,
                          icon: Icons.account_balance_wallet_rounded,
                          loading: busy,
                          expand: true,
                        )
                        : AppButton(
                          label: 'Configurer',
                          onPressed: busy ? null : onConfigurePayment,
                          icon: Icons.tune_rounded,
                          loading: busy,
                          expand: true,
                        ),
              ),
            ],
          ),
          if (listing.timeline.isNotEmpty) ...[
            const SizedBox(height: 10),
            _SecondhandSettlementTimeline(listing: listing),
          ],
        ],
      ),
    );
  }
}

class _SecondhandSettlementTimeline extends StatelessWidget {
  const _SecondhandSettlementTimeline({required this.listing});

  final SecondhandListing listing;

  @override
  Widget build(BuildContext context) {
    final entries = listing.timeline.reversed.take(4).toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return AppCard(
      elevated: false,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suivi du solde',
            style: TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < entries.length; i++) ...[
            _SettlementTimelineRow(
              entry: entries[i],
              isLast: i == entries.length - 1,
            ),
            if (i != entries.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SettlementTimelineRow extends StatelessWidget {
  const _SettlementTimelineRow({required this.entry, required this.isLast});

  final ManagedPaymentTimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _timelineColor(entry.status);
    final date = entry.at;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withValues(alpha: 0.22)),
              ),
              child: Icon(_timelineIcon(entry.status), color: color, size: 15),
            ),
            if (!isLast)
              Container(width: 2, height: 24, color: ModernColors.line),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date == null
                      ? 'Date en synchronisation'
                      : DateFormat('dd MMM yyyy • HH:mm', 'fr').format(date),
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static IconData _timelineIcon(String status) {
    return switch (status) {
      'withdrawn' => Icons.verified_rounded,
      'withdrawal_blocked' || 'disputed' => Icons.block_rounded,
      'converted_to_style_points' => Icons.auto_awesome_rounded,
      'withdrawal_requested' => Icons.account_balance_wallet_rounded,
      'sold' => Icons.done_all_rounded,
      _ => Icons.radio_button_checked_rounded,
    };
  }

  static Color _timelineColor(String status) {
    return switch (status) {
      'withdrawn' => ModernColors.success,
      'withdrawal_blocked' || 'disputed' => ModernColors.danger,
      'converted_to_style_points' => ModernColors.primary,
      'withdrawal_requested' => ModernColors.warning,
      _ => ModernColors.client,
    };
  }
}

class _OwnerSettlementInfo extends StatelessWidget {
  const _OwnerSettlementInfo({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: false,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ModernColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondhandSellerCard extends StatelessWidget {
  const _SecondhandSellerCard({
    required this.listing,
    required this.trust,
    required this.onReport,
  });

  final SecondhandListing listing;
  final SecondhandSellerTrust? trust;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final sellerName = trust?.sellerName ?? listing.sellerName;
    final trustPhoto = trust?.photoUrl ?? '';
    final photoUrl =
        trustPhoto.isNotEmpty ? trustPhoto : listing.sellerPhotoUrl;
    final sold = trust?.soldListings ?? 0;
    final active = trust?.activeListings ?? 0;
    final city = trust?.city ?? listing.city;
    final verified = trust?.isVerified == true;

    return AppCard(
      elevated: false,
      child: Column(
        children: [
          Row(
            children: [
              _SellerAvatar(url: photoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sellerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ModernColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 5),
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
                      trust?.roleLabel ?? 'Client de la communauté',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onReport, child: const Text('Signaler')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TrustMetric(
                  label: 'En vente',
                  value: '$active',
                  icon: Icons.inventory_2_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrustMetric(
                  label: 'Vendues',
                  value: '$sold',
                  icon: Icons.handshake_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrustMetric(
                  label: 'Ville',
                  value: city.isEmpty ? 'Locale' : city,
                  icon: Icons.place_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Échangez dans la discussion avant de réserver. Privilégiez les photos réelles et un rendez-vous clair.',
              style: TextStyle(
                color: ModernColors.inkSoft,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustMetric extends StatelessWidget {
  const _TrustMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ModernColors.primary, size: 17),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.inkSoft,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondhandPublishSheet extends StatefulWidget {
  const _SecondhandPublishSheet({required this.service, this.onPublished});

  final SecondhandListingService service;
  final VoidCallback? onPublished;

  @override
  State<_SecondhandPublishSheet> createState() =>
      _SecondhandPublishSheetState();
}

class _SecondhandPublishSheetState extends State<_SecondhandPublishSheet> {
  static const _categories = [
    'Sacs',
    'Bijoux',
    'Chaussures',
    'Foulards',
    'Lunettes',
    'Ceintures',
  ];
  static const _conditions = [
    'Neuf avec étiquette',
    'Comme neuf',
    'Très bon état',
    'Bon état',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _images = [];
  String _category = 'Sacs';
  String _condition = 'Très bon état';
  String _currency = CurrencyService.defaultCode;
  String _stage = '';
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await CurrencyService().currentUserCurrency();
    if (mounted) setState(() => _currency = currency);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 86);
    if (picked == null) return;
    setState(() => _images.add(File(picked.path)));
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      _showSnack('Ajoutez au moins une photo.', danger: true);
      return;
    }
    setState(() => _publishing = true);
    try {
      final draft = SecondhandDraft(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        condition: _condition,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        currency: _currency,
        city: _cityController.text.trim(),
        size: _sizeController.text.trim(),
        color: _colorController.text.trim(),
      );
      await widget.service.publishListing(
        draft: draft,
        images: _images,
        onStage: (stage) {
          if (mounted) setState(() => _stage = stage);
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onPublished?.call();
      _showSnack('Annonce publiée dans le Vide-dressing.');
    } catch (e) {
      _showSnack('Publication impossible: $e', danger: true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _showSnack(String message, {bool danger = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: danger ? ModernColors.danger : ModernColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.65,
      maxChildSize: 0.96,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ModernColors.line,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Nouvelle pièce',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Quelques infos nettes suffisent.',
                        style: TextStyle(
                          color: ModernColors.inkSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      AppFormSection(
                        title: 'Photos',
                        icon: Icons.photo_camera_rounded,
                        children: [
                          AppImagePickerField(
                            title: 'Photos réelles',
                            subtitle: 'Face, détail, défaut éventuel.',
                            files: _images,
                            maxImages: 4,
                            onAdd: _pickImage,
                            onRemove:
                                (index) =>
                                    setState(() => _images.removeAt(index)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppFormSection(
                        title: 'Essentiel',
                        icon: Icons.shopping_bag_rounded,
                        children: [
                          AppTextField(
                            controller: _titleController,
                            label: 'Nom de la pièce',
                            hint: 'Sac perlé, porté une fois',
                            icon: Icons.shopping_bag_rounded,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.sentences,
                            validator:
                                (value) =>
                                    value == null || value.trim().length < 3
                                        ? 'Ajoute un nom plus précis'
                                        : null,
                          ),
                          AppTextField(
                            controller: _descriptionController,
                            label: 'Description honnête',
                            hint: 'Matière, défaut, raison de vente',
                            icon: Icons.notes_rounded,
                            minLines: 3,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            textCapitalization: TextCapitalization.sentences,
                            validator:
                                (value) =>
                                    value == null || value.trim().length < 10
                                        ? 'Ajoute quelques détails'
                                        : null,
                          ),
                          AppResponsiveFieldRow(
                            children: [
                              AppSelectField<String>(
                                value: _category,
                                items: _categories,
                                label: 'Catégorie',
                                icon: Icons.category_rounded,
                                onChanged:
                                    (value) => setState(
                                      () => _category = value ?? _category,
                                    ),
                              ),
                              AppSelectField<String>(
                                value: _condition,
                                items: _conditions,
                                label: 'État',
                                icon: Icons.verified_rounded,
                                onChanged:
                                    (value) => setState(
                                      () => _condition = value ?? _condition,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppFormSection(
                        title: 'Vente',
                        icon: Icons.sell_rounded,
                        children: [
                          AppResponsiveFieldRow(
                            children: [
                              AppMoneyField(
                                controller: _priceController,
                                label: 'Prix',
                                hint: 'Montant',
                                currencySymbol:
                                    CurrencyService.optionFor(_currency).symbol,
                                validator: (value) {
                                  final price = double.tryParse(
                                    value?.trim() ?? '',
                                  );
                                  if (price == null || price <= 0) {
                                    return 'Entre un prix valide';
                                  }
                                  return null;
                                },
                              ),
                              AppTextField(
                                controller: _cityController,
                                label: 'Ville',
                                hint: 'Ouagadougou',
                                icon: Icons.place_rounded,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                validator:
                                    (value) =>
                                        value == null || value.trim().isEmpty
                                            ? 'Choisis une ville'
                                            : null,
                              ),
                            ],
                          ),
                          AppResponsiveFieldRow(
                            children: [
                              AppTextField(
                                controller: _sizeController,
                                label: 'Taille',
                                hint: 'Optionnel',
                                icon: Icons.straighten_rounded,
                                textInputAction: TextInputAction.next,
                              ),
                              AppTextField(
                                controller: _colorController,
                                label: 'Couleur',
                                hint: 'Optionnel',
                                icon: Icons.palette_rounded,
                                textInputAction: TextInputAction.done,
                                textCapitalization: TextCapitalization.words,
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_publishing) ...[
                        const SizedBox(height: 14),
                        LinearProgressIndicator(
                          color: ModernColors.primary,
                          backgroundColor: ModernColors.primary.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _stage,
                          style: const TextStyle(
                            color: ModernColors.inkSoft,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AppStickyFormBar(
                  primaryLabel: 'Publier',
                  onPrimary: _publishing ? null : _publish,
                  secondaryLabel: 'Fermer',
                  onSecondary: () => Navigator.pop(context),
                  isLoading: _publishing,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SellerAvatar extends StatelessWidget {
  const _SellerAvatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child:
          url.isEmpty
              ? Container(
                width: 42,
                height: 42,
                color: ModernColors.canvas,
                child: const Icon(
                  AppIcons.profile,
                  color: ModernColors.inkSoft,
                ),
              )
              : CachedNetworkImage(
                imageUrl: url,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ModernColors.canvas,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_rounded,
        color: ModernColors.muted,
      ),
    );
  }
}

class _SecondhandEmpty extends StatelessWidget {
  const _SecondhandEmpty({
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
    return AppCard(
      elevated: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icon, color: ModernColors.primary, size: 34),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: ModernColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ModernColors.inkSoft),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                icon: AppIcons.add,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SecondhandSkeleton extends StatelessWidget {
  const _SecondhandSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemBuilder:
          (_, _) => Container(
            decoration: BoxDecoration(
              color: ModernColors.line,
              borderRadius: BorderRadius.circular(ModernRadius.lg),
            ),
          ),
    );
  }
}
