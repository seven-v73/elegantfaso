import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../models/createur/creation_model.dart';

class CreationCard extends StatelessWidget {
  final CreationModel creation;
  final VoidCallback? onTap;
  final bool showDetails;
  final bool showFavorite;
  final bool isFavorite;
  final Function(bool)? onFavoriteChanged;

  const CreationCard({
    Key? key,
    required this.creation,
    this.onTap,
    this.showDetails = true,
    this.showFavorite = true,
    this.isFavorite = false,
    this.onFavoriteChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceFormatter = NumberFormat.currency(
      symbol: 'XOF',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section with Hero Animation
                Hero(
                  tag: 'creation-${creation.id}-image',
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: creation.imageUrl,
                        height: showDetails ? 180 : 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.surfaceVariant,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.errorContainer,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: theme.colorScheme.onErrorContainer,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      if (creation.isNew)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NOUVEAU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (showDetails) ...[
                  // Details Section
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Category
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                creation.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (creation.category.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  creation.category.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Rating and Price Row
                        Row(
                          children: [
                            if (creation.rating > 0) ...[
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                creation.rating.toStringAsFixed(1),
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                priceFormatter.format(creation.price),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Description
                        if (creation.description.isNotEmpty)
                          Text(
                            creation.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Favorite Button
            if (showFavorite)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                    size: 24,
                  ),
                  onPressed: () => onFavoriteChanged?.call(!isFavorite),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.4),
                    padding: const EdgeInsets.all(4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}