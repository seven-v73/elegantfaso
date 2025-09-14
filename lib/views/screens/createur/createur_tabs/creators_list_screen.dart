import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../messages/user_model.dart';

class CreatorsListScreen extends StatefulWidget {
  const CreatorsListScreen({super.key});

  @override
  State<CreatorsListScreen> createState() => _CreatorsListScreenState();
}

class _CreatorsListScreenState extends State<CreatorsListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<UserModel> _creators = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCreators();
  }

  Future<void> _loadCreators() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .where('role',  isEqualTo: 'createur')
          .get();

      setState(() {
        _creators = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), docId: doc.id))
            .where((creator) => creator.id != user.uid)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement créateurs: $e');
      setState(() => _isLoading = false);
    }
  }

  List<UserModel> get _filteredCreators {
    if (_searchQuery.isEmpty) return _creators;
    return _creators.where((creator) {
      final name = creator.displayName.toLowerCase();
      final boutique = creator.boutiqueName?.toLowerCase() ?? '';
      final location = creator.location?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          boutique.contains(query) ||
          location.contains(query);
    }).toList();
  }

  Widget _buildCreatorCard(UserModel creator) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigation vers le profil du créateur
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: creator.photoUrl != null
                    ? CachedNetworkImageProvider(creator.photoUrl!)
                    : null,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: creator.photoUrl == null
                    ? Text(
                  creator.shortName,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator.isBoutique
                          ? creator.boutiqueName ?? creator.displayName
                          : creator.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (creator.specialty != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          creator.specialty!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    if (creator.location != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              creator.location!,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                            Icons.people,
                            '${creator.followersCount} abonnés'
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                            Icons.shopping_bag,
                            '${creator.productsCount} produits'
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      avatar: Icon(icon, size: 14),
      backgroundColor: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créateurs & Boutiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCreators,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un créateur ou boutique...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCreators.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun créateur trouvé',
                    style: TextStyle(fontSize: 18),
                  ),
                  const Text(
                    'Vérifiez votre recherche ou réessayez plus tard',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _filteredCreators.length,
              itemBuilder: (context, index) {
                return _buildCreatorCard(_filteredCreators[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}