import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productName;
  final double price;
  final String description;
  final double rating;
  final int reviewCount;
  final String imageUrl;

  const ProductDetailScreen({
    Key? key,
    required this.productName,
    required this.price,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,  // Retire la flèche retour
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom et prix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          productName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$price XOF',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Note
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: rating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20.0,
                        unratedColor: Colors.grey[300],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$rating ($reviewCount avis)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'AJOUTER AU PANIER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
