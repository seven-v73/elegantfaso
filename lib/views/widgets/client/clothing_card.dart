import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ClothingCard extends StatelessWidget {
  final String title;
  final String price;
  final String designer;
  final bool isFavorite;
  final bool isNew;
  final bool isPromo;
  final String? oldPrice;
  final bool is3D;
  final String? imageUrl;
  final String? modelPath;

  const ClothingCard({
    super.key,
    required this.title,
    required this.price,
    required this.designer,
    this.isFavorite = false,
    this.isNew = false,
    this.isPromo = false,
    this.oldPrice,
    this.imageUrl,
    this.is3D = false,
    this.modelPath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: is3D && modelPath != null
                      ? ModelViewer(
                    src: modelPath!,
                    alt: "Modèle 3D de tenue",
                    ar: true,
                    autoRotate: true,
                    cameraControls: true,
                    disableZoom: false,
                    backgroundColor: Colors.white,
                  )
                      : (imageUrl != null
                      ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image)),
                  )),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      designer,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD2691E),
                          ),
                        ),
                        if (isPromo && oldPrice != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(
                              oldPrice!,
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.white,
                size: 20,
              ),
              onPressed: () {},
            ),
          ),
          if (isNew)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
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
          if (isPromo)
            Positioned(
              bottom: 60,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'PROMO',
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
    );
  }
}