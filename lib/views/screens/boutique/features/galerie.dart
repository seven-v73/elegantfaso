import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BoutiqueGalleryScreen extends StatefulWidget {
  const BoutiqueGalleryScreen({Key? key}) : super(key: key);

  @override
  _BoutiqueGalleryScreenState createState() => _BoutiqueGalleryScreenState();
}

class _BoutiqueGalleryScreenState extends State<BoutiqueGalleryScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String? boutiqueId;
  bool _isBoutiqueLoading = true;

  @override
  void initState() {
    super.initState();
    _getBoutiqueId();
  }

  // Récupérer l'ID de la boutique basé sur l'utilisateur connecté
  Future<void> _getBoutiqueId() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        setState(() {
          boutiqueId = userDoc.id; // L'ID de la boutique est l'ID de l'utilisateur
          _isBoutiqueLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la boutique: $e');
      setState(() => _isBoutiqueLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isBoutiqueLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (boutiqueId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Galerie'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Boutique non trouvée'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galerie des Produits'),
        backgroundColor: Colors.black12,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: _buildProductImagesGrid(),
      ),
    );
  }

  Widget _buildProductImagesGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('boutiqueId', isEqualTo: boutiqueId)
          .where('imageUrl', isNotEqualTo: null)
          .where('imageUrl', isNotEqualTo: '')
          .orderBy('imageUrl') // Nécessaire pour isNotEqualTo
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final products = snapshot.data!.docs
            .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final imageUrl = data['imageUrl'] as String?;
          return imageUrl != null && imageUrl.isNotEmpty;
        })
            .toList();

        if (products.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
              final productId = products[index].id;
              return _buildImageItem(product, productId);
            },
          ),
        );
      },
    );
  }

  Widget _buildImageItem(Map<String, dynamic> product, String productId) {
    final imageUrl = product['imageUrl'] as String? ?? '';

    return GestureDetector(
      onTap: () => _showImageFullscreen(imageUrl, productId),
      child: Hero(
        tag: 'image_$productId',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune image disponible',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos images de produits apparaîtront ici',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.image,
              color: Colors.grey,
              size: 30,
            ),
          ),
        );
      },
    );
  }

  void _showImageFullscreen(String imageUrl, String productId) {
    showDialog(
      context: context,
      barrierColor: Colors.black87, // rend le fond sombre par défaut
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // Fond sombre avec dismiss
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.transparent),
              ),
            ),

            // Image en plein écran
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: Hero(
                  tag: 'image_$productId',
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bouton de fermeture
            Positioned(
              top: 32,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}