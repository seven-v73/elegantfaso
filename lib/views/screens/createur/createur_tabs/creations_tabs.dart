import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../model/creation.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_effects.dart';
import '../widgets/detail_row.dart';
import '../creations/add_creation_screen.dart';
import '../creations/edit_creation_screen.dart';

class CreationsTab extends StatelessWidget {
  final User user;

  const CreationsTab({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 360;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Mes Créations',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, _, __) => AddCreationScreen(),
                        transitionsBuilder: (context, animation, _, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          );
                        },
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    label: isSmallScreen ? const SizedBox.shrink() : const Text('Ajouter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A6FA5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  )],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('creations')
                  .where('createurId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerGrid();
                }

                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.error,
                    message: 'Erreur: ${snapshot.error}',
                  );
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory,
                    message: 'Aucune création pour le moment',
                    actionText: 'Ajouter une création',
                    onAction: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddCreationScreen())),
                  );
                }

                final creations = snapshot.data!.docs
                    .map((doc) => Creation.fromFirestore(doc))
                    .toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  color: const Color(0xFF4A6FA5),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                      final aspectRatio = constraints.maxWidth > 600 ? 0.82 : 0.75;

                      return GridView.builder(
                        padding: const EdgeInsets.only(top: 12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: creations.length,
                        itemBuilder: (context, index) => _CreationCard(
                          creation: creations[index],
                          onTap: () => _showCreationDetails(context, creations[index]),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
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
                      if (creation.images.isNotEmpty)
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
                        )
                      else
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: Icon(Icons.image, size: 50)),
                        ),

                      const SizedBox(height: 24),
                      DetailRow(icon: Icons.category, label: 'Catégorie:', value: creation.category),
                      DetailRow(icon: Icons.attach_money, label: 'Prix:', value: '${creation.price} XOF'),

                      // Description with line limit
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.description, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Description:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    creation.description,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditCreationScreen(creation: creation),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Theme.of(context).primaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

class _CreationCard extends StatelessWidget {
  final Creation creation;
  final VoidCallback onTap;

  const _CreationCard({
    Key? key,
    required this.creation,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: creation.images.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: creation.images.first,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 140,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 140,
                  color: Colors.grey[200],
                  child: const Icon(Icons.error),
                ),
              )
                  : Container(
                height: 140,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image, size: 50),
                ),
              ),
            ),

            // Title, Category, Price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SizedBox(
                height: 64,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creation.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      creation.category,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${creation.price} XOF',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}