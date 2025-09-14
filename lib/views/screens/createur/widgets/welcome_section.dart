import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../createur_model.dart';
import '../widgets/status_indicator.dart';

class WelcomeSection extends StatelessWidget {
  final CreateurModel createur;
  final bool isOnline;
  final ValueChanged<bool> onStatusChanged;

  const WelcomeSection({
    super.key,
    required this.createur,
    required this.isOnline,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A6FA5), Color(0xFF6B4E71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 2)),
                  ),
                  child: ClipOval(
                    child: createur.profileImage.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: createur.profileImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.person,
                        size: 36,
                        color: Colors.grey[400],
                      ),
                    )
                        : Icon(
                      Icons.person,
                      size: 36,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        createur.name,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        createur.specialty.isNotEmpty
                            ? createur.specialty
                            : 'Artisan Créateur',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9)
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${createur.rating.toStringAsFixed(1)} (${createur.reviewsCount} avis)',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7)
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StatusIndicator(isOnline: isOnline, onChanged: onStatusChanged),
          ],
        ),
      ),
    );
  }
}