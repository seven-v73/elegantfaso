import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class BoutiqueReviewsScreen extends StatefulWidget {
  const BoutiqueReviewsScreen({Key? key}) : super(key: key);

  @override
  _BoutiqueReviewsScreenState createState() => _BoutiqueReviewsScreenState();
}

class _BoutiqueReviewsScreenState extends State<BoutiqueReviewsScreen> {
  final String boutiqueId = FirebaseAuth.instance.currentUser?.uid ?? '';
  double _averageRating = 0.0;
  final Map<int, int> _ratingDistribution = {
    5: 0,
    4: 0,
    3: 0,
    2: 0,
    1: 0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avis clients')),
      body: Column(
        children: [
          _buildSummaryHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('boutiqueId', isEqualTo: boutiqueId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reviews = snapshot.data!.docs;

                if (reviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.reviews, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun avis pour le moment',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index].data() as Map<String, dynamic>;
                    return _buildReviewCard(review);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A2D3E),
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        size: 20,
                        color: index < _averageRating.floor()
                            ? Colors.amber
                            : Colors.grey[300],
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_ratingDistribution.values.reduce((a, b) => a + b)} avis',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: 120,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(isVisible: false),
                  primaryYAxis: NumericAxis(isVisible: false),
                  series: <BarSeries<MapEntry<int, int>, int>>[
                    BarSeries<MapEntry<int, int>, int>(
                      dataSource: _ratingDistribution.entries.toList(),
                      xValueMapper: (entry, _) => entry.key,
                      yValueMapper: (entry, _) => entry.value,
                      color: const Color(0xFF6A11CB),
                      borderRadius: BorderRadius.circular(4),
                      width: 0.7,
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final rating = 5 - index;
              final count = _ratingDistribution[rating] ?? 0;
              return Column(
                children: [
                  Text(
                    '$rating',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('$count'),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                  review['userAvatar'] ?? 'https://via.placeholder.com/150',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['userName'] ?? 'Client',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          size: 16,
                          color: index < (review['rating'] as int)
                              ? Colors.amber
                              : Colors.grey[300],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(
                  (review['createdAt'] as Timestamp).toDate(),
                ),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            review['comment'] ?? '',
            style: TextStyle(color: Colors.grey[700]),
          ),
          if (review['images'] != null && (review['images'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: (review['images'] as List).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: review['images'][index],
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.thumb_up, size: 18),
                label: const Text('Utile'),
                onPressed: () {
                  // Action ici
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),

              const SizedBox(width: 16),
              TextButton.icon(
                icon: const Icon(Icons.comment, size: 18),
                label: const Text('Répondre'),
                onPressed: () {
                  // Action à exécuter lors du clic
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}