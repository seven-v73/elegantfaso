import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../model/creation_model.dart';

class CreationCard extends StatelessWidget {
  final CreationModel creation;
  final VoidCallback? onTap;
  final bool showDetails;

  const CreationCard({
    Key? key,
    required this.creation,
    this.onTap,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: creation.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    creation.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showDetails) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text(creation.category),
                          backgroundColor: Colors.grey[100],
                        ),
                        const Spacer(),
                        Text(
                          '${creation.price} XOF',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF4A6FA5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          creation.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${creation.reviewsCount} avis)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}