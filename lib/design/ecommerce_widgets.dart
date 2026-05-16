import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'modern_design_system.dart';

enum AppButtonVariant { primary, secondary, outline, tertiary, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.compact = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool loading;
  final bool compact;
  final bool expand;

  static const double height = 52;
  static const double compactHeight = 44;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final child = _ButtonContent(
      label: label,
      icon: icon,
      loading: loading,
      compact: compact,
    );
    final minimumSize = Size(expand ? double.infinity : 0, _buttonHeight);

    final style = switch (variant) {
      AppButtonVariant.primary => FilledButton.styleFrom(
        minimumSize: minimumSize,
        backgroundColor: ModernColors.primary,
        foregroundColor: Colors.white,
        padding: _padding,
        shape: _shape,
      ),
      AppButtonVariant.secondary => FilledButton.styleFrom(
        minimumSize: minimumSize,
        backgroundColor: ModernColors.primary.withValues(alpha: 0.1),
        foregroundColor: ModernColors.primary,
        padding: _padding,
        shape: _shape,
      ),
      AppButtonVariant.outline => OutlinedButton.styleFrom(
        minimumSize: minimumSize,
        foregroundColor: ModernColors.ink,
        side: const BorderSide(color: ModernColors.line),
        padding: _padding,
        shape: _shape,
      ),
      AppButtonVariant.tertiary => TextButton.styleFrom(
        minimumSize: minimumSize,
        foregroundColor: ModernColors.inkSoft,
        padding: _padding,
        shape: _shape,
      ),
      AppButtonVariant.danger => FilledButton.styleFrom(
        minimumSize: minimumSize,
        backgroundColor: ModernColors.rose,
        foregroundColor: Colors.white,
        padding: _padding,
        shape: _shape,
      ),
    };

    return SizedBox(
      width: expand ? double.infinity : null,
      child: switch (variant) {
        AppButtonVariant.outline => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: child,
        ),
        AppButtonVariant.tertiary => TextButton(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: child,
        ),
        _ => FilledButton(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: child,
        ),
      },
    );
  }

  double get _buttonHeight => compact ? compactHeight : height;

  EdgeInsetsGeometry get _padding => EdgeInsets.symmetric(
    horizontal: compact ? 13 : 18,
    vertical: compact ? 10 : 14,
  );

  OutlinedBorder get _shape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(ModernRadius.button),
  );
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.loading,
    required this.compact,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final spinnerSize = compact ? 16.0 : 18.0;
    final text = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: spinnerSize,
            height: spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                IconTheme.of(context).color ?? ModernColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: compact ? 17 : 19),
          const SizedBox(width: 8),
        ],
        text,
      ],
    );
  }
}

class AppIconAction extends StatelessWidget {
  const AppIconAction({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.selected = false,
    this.color = ModernColors.primary,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      style: IconButton.styleFrom(
        backgroundColor: selected ? color : ModernColors.surfaceRaised,
        foregroundColor: selected ? Colors.white : color,
        disabledBackgroundColor: ModernColors.line.withValues(alpha: 0.45),
        disabledForegroundColor: ModernColors.muted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernRadius.button),
        ),
        side: BorderSide(
          color: selected ? color.withValues(alpha: 0.4) : ModernColors.line,
        ),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class AppOverflowAction {
  const AppOverflowAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool danger;
}

class AppOverflowMenu extends StatelessWidget {
  const AppOverflowMenu({
    super.key,
    required this.actions,
    this.tooltip = 'Plus',
  });

  final List<AppOverflowAction> actions;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final enabledActions =
        actions.where((action) => action.onPressed != null).toList();
    return PopupMenuButton<AppOverflowAction>(
      tooltip: tooltip,
      enabled: enabledActions.isNotEmpty,
      icon: const Icon(Icons.more_horiz_rounded, size: 20),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        backgroundColor: ModernColors.surfaceRaised,
        foregroundColor: ModernColors.inkSoft,
        disabledForegroundColor: ModernColors.muted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernRadius.button),
        ),
        side: const BorderSide(color: ModernColors.line),
      ),
      itemBuilder:
          (context) =>
              enabledActions
                  .map(
                    (action) => PopupMenuItem<AppOverflowAction>(
                      value: action,
                      child: Row(
                        children: [
                          Icon(
                            action.icon,
                            size: 18,
                            color:
                                action.danger
                                    ? ModernColors.danger
                                    : ModernColors.inkSoft,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              action.label,
                              style: TextStyle(
                                color:
                                    action.danger
                                        ? ModernColors.danger
                                        : ModernColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
      onSelected: (action) => action.onPressed?.call(),
    );
  }
}

class AppActionTile extends StatelessWidget {
  const AppActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(compact ? 12 : 14),
      elevated: false,
      child: Row(
        children: [
          Container(
            width: compact ? 40 : 44,
            height: compact ? 40 : 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ModernRadius.button),
              border: Border.all(color: color.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: color, size: compact ? 20 : 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: ModernColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: ModernColors.line),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: ModernColors.inkSoft,
                  size: 18,
                ),
              ),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color = ModernColors.surface,
    this.radius = ModernRadius.lg,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: ModernColors.line),
      boxShadow: elevated ? ModernShadows.elevated : ModernShadows.card,
    );

    return Container(
      margin: margin,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ],
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String price;
  final String sellerName;
  final String sellerImage;
  final String badge;
  final Color badgeColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProductTile({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.sellerName,
    required this.badge,
    required this.badgeColor,
    this.sellerImage = '',
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(ModernRadius.lg),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const _ImagePlaceholder(),
                    errorWidget:
                        (context, url, error) => const _ImagePlaceholder(
                          icon: Icons.image_not_supported,
                        ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: _Badge(
                    label: badge,
                    color: badgeColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (sellerImage.isNotEmpty) ...[
                        CircleAvatar(
                          radius: 8,
                          backgroundImage: CachedNetworkImageProvider(
                            sellerImage,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Expanded(
                        child: Text(
                          sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.inkSoft,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PromotionTile extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String shopName;
  final String location;
  final String originalPrice;
  final String discountedPrice;
  final String timeRemaining;
  final int discountPercentage;
  final Color accentColor;
  final IconData icon;
  final List<String> tags;
  final bool live;
  final VoidCallback? onTap;

  const PromotionTile({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.shopName,
    required this.location,
    required this.originalPrice,
    required this.discountedPrice,
    required this.timeRemaining,
    required this.discountPercentage,
    required this.accentColor,
    required this.icon,
    this.tags = const [],
    this.live = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      elevated: true,
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(ModernRadius.lg),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const _ImagePlaceholder(),
                    errorWidget:
                        (context, url, error) =>
                            const _ImagePlaceholder(icon: Icons.local_offer),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: _Badge(
                    label: '-$discountPercentage%',
                    color: ModernColors.surface,
                    foregroundColor: accentColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 17, color: accentColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ModernColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ModernColors.inkSoft,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (live)
                        const _Badge(
                          label: 'LIVE',
                          color: Color(0xFFEFFDF5),
                          foregroundColor: ModernColors.success,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontSize: 15,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              discountedPrice,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ModernColors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              originalPrice,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ModernColors.muted,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _Badge(
                        label: timeRemaining,
                        color: accentColor.withValues(alpha: 0.1),
                        foregroundColor: accentColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color foregroundColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final IconData icon;

  const _ImagePlaceholder({this.icon = Icons.image_outlined});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ModernColors.surfaceRaised,
      child: Center(child: Icon(icon, color: ModernColors.muted)),
    );
  }
}
