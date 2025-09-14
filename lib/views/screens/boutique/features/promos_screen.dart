import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elegantfaso/utils/date_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badges/badges.dart' as bdg;

class BoutiquePromotionsScreen extends StatefulWidget {
  const BoutiquePromotionsScreen({Key? key}) : super(key: key);

  @override
  _BoutiquePromotionsScreenState createState() => _BoutiquePromotionsScreenState();
}

class _BoutiquePromotionsScreenState extends State<BoutiquePromotionsScreen> {
  final String boutiqueId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = true;
  List<DocumentSnapshot> _promotions = [];

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('promotions')
          .where('boutiqueId', isEqualTo: boutiqueId)
          .orderBy('endDate', descending: false)
          .get();

      setState(() {
        _promotions = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading promotions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions en cours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewPromotion,
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerList()
          : _promotions.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _promotions.length,
        itemBuilder: (context, index) {
          final promo = _promotions[index].data() as Map<String, dynamic>;
          return _buildPromotionCard(promo);
        },
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promo) {
    final now = DateTime.now();
    final startDate = (promo['startDate'] as Timestamp).toDate();
    final endDate = (promo['endDate'] as Timestamp).toDate();
    final isActive = now.isAfter(startDate) && now.isBefore(endDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                  bdg.Badge(
                    badgeStyle: bdg.BadgeStyle(
                    badgeColor: isActive ? Colors.green : Colors.orange,

                  ),
                  badgeContent: Text(
                    isActive ? 'ACTIF' : 'TERMINÉ',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const Spacer(),
                Text(
                  '${promo['discountPercentage']}% OFF',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              promo['title'] ?? 'Sans titre',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${formatDate(startDate)} - ${formatDate(endDate)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: now.difference(startDate).inDays / endDate.difference(startDate).inDays,
              backgroundColor: Colors.grey[200],
              color: Colors.deepPurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/boutique/promotion.png', height: 150),
          const SizedBox(height: 20),
          const Text(
            'Aucune promotion active',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Créer une promotion'),
            onPressed: _createNewPromotion,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  void _createNewPromotion() {
    // Implementation for creating new promotion
  }
}