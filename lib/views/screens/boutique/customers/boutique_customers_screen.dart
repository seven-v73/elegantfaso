import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../messages/user_model.dart';
import '../../messages/chat_screen.dart';

class BoutiqueCustomersScreen extends StatefulWidget {
  const BoutiqueCustomersScreen({Key? key}) : super(key: key);

  @override
  State<BoutiqueCustomersScreen> createState() => _BoutiqueCustomersScreenState();
}

class _BoutiqueCustomersScreenState extends State<BoutiqueCustomersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, UserModel> _userCache = {};

  String _boutiqueId = '';
  bool _isLoading = true;
  bool _isAuthenticated = false;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _isAuthenticated = user != null;
          _boutiqueId = user?.uid ?? '';
        });

        if (_isAuthenticated) {
          _loadBoutiqueFollowers();
        } else {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _loadBoutiqueFollowers() async {
    if (_boutiqueId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final boutiqueDoc = await _firestore.collection('users').doc(_boutiqueId).get();
      if (boutiqueDoc.exists) {
        final followers = boutiqueDoc.get('followers') as List<dynamic>? ?? [];
        final followerIds = followers.map((e) => e.toString()).toList();

        if (followerIds.isNotEmpty) {
          final usersSnapshot = await _firestore.collection('users')
              .where(FieldPath.documentId, whereIn: followerIds)
              .get();

          _userCache.clear();
          for (var doc in usersSnapshot.docs) {
            _userCache[doc.id] = UserModel.fromDocument(doc);
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur de chargement: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Stream<List<UserModel>> _getBoutiqueFollowers() {
    if (_boutiqueId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore.collection('users').doc(_boutiqueId).snapshots().asyncMap(
          (boutiqueSnapshot) async {
        if (!boutiqueSnapshot.exists) return [];

        final boutiqueData = boutiqueSnapshot.data()!;
        final List<dynamic> followers = boutiqueData['followers'] ?? [];
        final List<String> followerIds = followers.map((id) => id.toString()).toList();

        if (followerIds.isEmpty) return [];

        // Filtrer les IDs non encore en cache
        final newIds = followerIds.where((id) => !_userCache.containsKey(id)).toList();

        if (newIds.isNotEmpty) {
          final usersSnapshot = await _firestore.collection('users')
              .where(FieldPath.documentId, whereIn: newIds)
              .get();

          for (var doc in usersSnapshot.docs) {
            _userCache[doc.id] = UserModel.fromDocument(doc);
          }
        }

        // Retourner uniquement les utilisateurs valides
        return followerIds
            .where((id) => _userCache.containsKey(id))
            .map((id) => _userCache[id]!)
            .toList();
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients Abonnés'),
        actions: [
          if (_isAuthenticated)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadBoutiqueFollowers,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isAuthenticated) {
      return _buildAuthErrorState();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<UserModel>>(
      stream: _getBoutiqueFollowers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final followers = snapshot.data ?? [];

        if (followers.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadBoutiqueFollowers,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: followers.length,
            itemBuilder: (context, index) => _buildCustomerCard(followers[index]),
          ),
        );
      },
    );
  }

  Widget _buildAuthErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 20),
          const Text(
            'Authentification requise',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Vous devez être connecté en tant que boutique pour accéder à cette fonctionnalité',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Se connecter', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadBoutiqueFollowers,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 150,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 24),
                const Text(
                  'Aucun client abonné',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Vos clients apparaîtront ici lorsqu\'ils s\'abonneront à votre boutique',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(user.photoUrl!)
                  : null,
              child: user.photoUrl == null || user.photoUrl!.isEmpty
                  ? const Icon(Icons.person, size: 30, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (user.phone != null && user.phone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.phone!,
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 12,
                          color: user.isOnline ? Colors.green : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        user.isOnline ? 'En ligne' : 'Hors ligne',
                        style: TextStyle(
                            color: user.isOnline ? Colors.green : Colors.grey,
                            fontSize: 14
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chat, color: Colors.blue, size: 28),
              onPressed: () => _startChatWithCustomer(context, user),
            ),
          ],
        ),
      ),
    );
  }

  void _startChatWithCustomer(BuildContext context, UserModel customer) async {
    if (_boutiqueId.isEmpty) return;

    try {
      final boutiqueDoc = await _firestore.collection('users').doc(_boutiqueId).get();

      if (!boutiqueDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Boutique introuvable")),
        );
        return;
      }

      final boutiqueUser = UserModel.fromDocument(boutiqueDoc);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            utilisateurCourant: boutiqueUser,
            autreUtilisateur: customer,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    }
  }
}