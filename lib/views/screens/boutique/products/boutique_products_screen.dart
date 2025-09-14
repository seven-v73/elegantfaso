import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elegantfaso/models/boutique/boutique_product.dart';
import 'package:elegantfaso/views/screens/boutique/products/add_product_screen.dart';
import 'package:elegantfaso/views/screens/boutique/products/edit_product_screen.dart';

class BoutiqueProductsScreen extends StatefulWidget {
  const BoutiqueProductsScreen({Key? key}) : super(key: key);
  @override
  _BoutiqueProductsScreenState createState() => _BoutiqueProductsScreenState();
}

class _BoutiqueProductsScreenState extends State<BoutiqueProductsScreen> {
  final String boutiqueId = FirebaseAuth.instance.currentUser!.uid;
  String _searchQuery = '';

  Future<void> _deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit supprimé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de suppression: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce produit ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(productId);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mes Produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>  AddProductScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('boutiqueId', isEqualTo: boutiqueId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag, size: 50, color: Colors.grey),
                        const SizedBox(height: 20),
                        const Text('Aucun produit disponible'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddProductScreen(),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Ajouter un produit'),
                        ),
                      ],
                    ),
                  );
                }

                final products = snapshot.data!.docs
                    .map((doc) => BoutiqueProduct.fromFirestore(doc))
                    .where((product) => product.name
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
                    .toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _ProductCard(
                      product: products[index],
                      onDelete: () => _confirmDelete(products[index].id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final BoutiqueProduct product;
  final VoidCallback onDelete;

  const _ProductCard({
    Key? key,
    required this.product,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                      : Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.photo, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price} FCFA',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock: ${product.stock}',
                      style: TextStyle(
                        color: product.stock > 0 ? Colors.blue : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: Colors.blue,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProductScreen(product: product),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    onPressed: onDelete,
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