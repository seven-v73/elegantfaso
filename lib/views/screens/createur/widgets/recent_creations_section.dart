import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../model/creation.dart';
import '../widgets/detail_row.dart';

class RecentCreationsSection extends StatelessWidget {
  final String userId;

  const RecentCreationsSection({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Dynamique : le carrousel prend ~35% hauteur écran
    final carouselHeight = screenHeight * 0.35;
    final imageHeight = carouselHeight * 0.6;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('creations')
          .where('createurId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Aucune création récente',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }

        final creations = snapshot.data!.docs
            .map((doc) => Creation.fromFirestore(doc))
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Créations Récentes',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: carouselHeight,
                        width: screenWidth,
                        child: CarouselSlider.builder(
                          itemCount: creations.length,
                          options: CarouselOptions(
                            height: carouselHeight,
                            aspectRatio: 16 / 9,
                            viewportFraction: 0.85,
                            enableInfiniteScroll: creations.length > 1,
                            autoPlay: creations.length > 1,
                            autoPlayInterval: const Duration(seconds: 3),
                            autoPlayAnimationDuration: const Duration(milliseconds: 800),
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enlargeCenterPage: true,
                            scrollDirection: Axis.horizontal,
                          ),
                          itemBuilder: (context, index, realIndex) {
                            final creation = creations[index];
                            return _buildCarouselItem(context, creation, imageHeight);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

      },
    );
  }

  Widget _buildCarouselItem(BuildContext context, Creation creation, double imageHeight) {
    return GestureDetector(
      onTap: () => _showCreationDetails(context, creation),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // 🟢 Image flexible
              Expanded(
                flex: 6,
                child: creation.images.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: creation.images.first,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                )
                    : Container(
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.image, size: 50)),
                ),
              ),

              // 🟢 Détails flexibles
              Expanded(
                flex: 4,
                child: Padding(
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
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${creation.price} XOF',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              creation.category,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }




  void _showCreationDetails(BuildContext context, Creation creation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creation.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Image carousel
                      CarouselSlider.builder(
                        itemCount: creation.images.length,
                        options: CarouselOptions(
                          height: 250,
                          autoPlay: creation.images.length > 1,
                          enlargeCenterPage: true,
                          viewportFraction: 0.9,
                        ),
                        itemBuilder: (context, index, realIndex) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: creation.images[index],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.error, color: Colors.red),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      DetailRow(icon: Icons.category, label: 'Catégorie:', value: creation.category),
                      DetailRow(icon: Icons.attach_money, label: 'Prix:', value: '${creation.price} XOF'),
                      DetailRow(icon: Icons.description, label: 'Description:', value: creation.description),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Implement edit functionality
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Theme.of(context).primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.share),
                        label: const Text('Partager'),
                        onPressed: () {
                          // TODO: Implement share functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
        ],
        ),
        );
      },
    );
  }
}