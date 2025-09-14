import 'package:flutter/material.dart';

class LookOfTheDayCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const LookOfTheDayCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image principale
            Image.network(
              imageUrl,
              height: 220,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Bouton "Voir plus"
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onTap,
                      child: const Text('Voir plus'),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
