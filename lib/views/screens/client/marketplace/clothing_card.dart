import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class ClothingCard extends StatelessWidget {
  final String title;
  final double price;
  final String designer;
  final String imageUrl;
  final double rating;
  final bool showFavorite;

  const ClothingCard({
    super.key,
    required this.title,
    required this.price,
    required this.designer,
    required this.imageUrl,
    this.rating = 0.0,
    this.showFavorite = true,
  });

  @override
  Widget build(BuildContext context) {
    final formattedPrice = NumberFormat.currency(
      symbol: 'XOF',
      decimalDigits: 0,
    ).format(price);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  height: 150,
                  color: Colors.grey[100],
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey[300]!,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[300],
                      size: 40,
                    ),
                  )
                      : Icon(
                    Icons.image,
                    color: Colors.grey[300],
                    size: 40,
                  ),
                ),
              ),
              if (showFavorite)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: Color(0xFFD2691E),
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formattedPrice,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFFD2691E),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  designer,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                if (rating > 0)
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
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
}