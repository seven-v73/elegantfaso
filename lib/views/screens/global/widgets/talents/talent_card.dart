import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/talent/talent_portfolio_item.dart';
import '../../../../../models/talent/talent_profile.dart';
import '../../../../../services/talent/follow_service.dart';
import '../../salon_search_screen.dart';
import 'talent_detail_sheet.dart';
import 'talent_portfolio_strip.dart';

class TalentCard extends StatelessWidget {
  const TalentCard({super.key, required this.talent, required this.portfolio});

  final TalentProfile talent;
  final List<TalentPortfolioItem> portfolio;

  Color get _color {
    return switch (talent.primaryRole) {
      'Boutique' => ModernColors.shop,
      'Coiffure' => ModernColors.client,
      'Chaussures' => ModernColors.rose,
      'Maquillage' => const Color(0xFFE11D48),
      _ => ModernColors.creator,
    };
  }

  IconData get _icon {
    return switch (talent.primaryRole) {
      'Boutique' => AppIcons.boutique,
      'Coiffure' => Icons.content_cut_rounded,
      'Chaussures' => Icons.directions_walk_rounded,
      'Maquillage' => Icons.face_retouching_natural_rounded,
      _ => AppIcons.talents,
    };
  }

  bool get _isShop => talent.primaryRole == 'Boutique';

  String get _showcaseLabel => _isShop ? 'Boutique' : 'Atelier';

  String get _contentLabel => _isShop ? 'Produits' : 'Créations';

  int get _contentCount =>
      _isShop ? talent.productsCount : talent.creationsCount;

  void _openDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TalentDetailSheet(talent: talent, portfolio: portfolio),
    );
  }

  void _openPortfolioItem(BuildContext context, TalentPortfolioItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SalonSearchScreen(
              initialQuery: '${item.title} ${talent.displayName}',
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _openDetail(context),
      padding: const EdgeInsets.all(12),
      elevated: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 88,
                  height: 104,
                  child:
                      talent.photoUrl.isEmpty
                          ? ColoredBox(
                            color: _color.withValues(alpha: 0.12),
                            child: Icon(_icon, color: _color, size: 34),
                          )
                          : CachedNetworkImage(
                            imageUrl: talent.photoUrl,
                            fit: BoxFit.cover,
                            errorWidget:
                                (_, _, _) => ColoredBox(
                                  color: _color.withValues(alpha: 0.12),
                                  child: Icon(_icon, color: _color),
                                ),
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            talent.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ModernColors.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (talent.verified)
                          const Icon(
                            Icons.verified_rounded,
                            color: ModernColors.client,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniTag(
                          icon: _icon,
                          label: _showcaseLabel,
                          color: _color,
                        ),
                        _MiniTag(
                          icon: Icons.place_rounded,
                          label: talent.place,
                        ),
                        if (talent.isAvailable)
                          const _MiniTag(
                            icon: Icons.check_circle_rounded,
                            label: 'Disponible',
                            color: ModernColors.accent,
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      talent.speciality,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _color,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      talent.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        height: 1.25,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (portfolio.isNotEmpty) ...[
            const SizedBox(height: 12),
            TalentPortfolioStrip(
              items: portfolio.take(3).toList(),
              compact: true,
              onOpenItem: (item) => _openPortfolioItem(context, item),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$_contentCount $_contentLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _FollowButton(talent: talent),
              const SizedBox(width: 8),
              SizedBox(
                width: 112,
                height: 44,
                child: FilledButton.tonalIcon(
                  onPressed: () => _openDetail(context),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                  label: Text(_isShop ? 'Produits' : 'Créations'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  _FollowButton({required this.talent});

  final TalentProfile talent;
  final FollowService _followService = FollowService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _followService.watchFollowing(talent.id),
      builder: (context, snapshot) {
        final following = snapshot.data == true;
        return _TalentIconButton(
          icon: following ? Icons.check_rounded : Icons.person_add_alt_rounded,
          tooltip: following ? 'Ne plus suivre' : 'Suivre',
          selected: following,
          onPressed: () async {
            if (!_followService.isSignedIn) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Connectez-vous pour suivre ou contacter.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            await _followService.toggleFollow(
              talentId: talent.id,
              talentName: talent.displayName,
              professionalId: talent.accountId,
              professionalRole: talent.professionalRole,
            );
          },
        );
      },
    );
  }
}

class _TalentIconButton extends StatelessWidget {
  const _TalentIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  static const Color _color = ModernColors.primary;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      style: IconButton.styleFrom(
        backgroundColor: selected ? _color : ModernColors.surfaceRaised,
        foregroundColor: selected ? Colors.white : _color,
        disabledBackgroundColor: ModernColors.line.withValues(alpha: 0.45),
        disabledForegroundColor: ModernColors.muted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: selected ? _color.withValues(alpha: 0.4) : ModernColors.line,
        ),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({
    required this.icon,
    required this.label,
    this.color = ModernColors.inkSoft,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.46,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
