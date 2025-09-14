import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isCurrentUserProfile = true;
  int _selectedTab = 0;
  final List<String> _wardrobeItems = [];
  Map<String, dynamic>? _userData;
  int _followersCount = 0;
  int _followingCount = 0;
  int _creationsCount = 0;
  bool _isLoading = true;

  // Contrôleurs pour les champs de formulaire
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specialityController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();

  // Variables d'état
  bool _isPublicProfile = true;
  bool _isActivityVisible = true;
  bool _isPublic = true;
  bool _twoFactorAuthEnabled = false;
  bool _securityAlertsEnabled = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isCurrentUserProfile = widget.userId == null || widget.userId == _currentUser?.uid;
    _loadUserData();
    if (_isCurrentUserProfile) {
      _loadWardrobeItems();
    }
  }

  Future<void> _loadUserData() async {
    final userId = widget.userId ?? _currentUser?.uid;
    if (userId == null) return;

    try {
      // Charger les données de base de l'utilisateur
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          // Initialiser les contrôleurs
          _nameController.text = _userData!['name'] ?? '';
          _bioController.text = _userData!['bio'] ?? '';
          _emailController.text = _userData!['email'] ?? '';
          _phoneController.text = _userData!['phone'] ?? '';

          // Rôle spécifique
          if (_userData!['role'] == 'createur') {
            _specialityController.text = _userData!['speciality'] ?? '';
            _websiteController.text = _userData!['website'] ?? '';
          } else if (_userData!['role'] == 'boutique') {
            _addressController.text = _userData!['address'] ?? '';
            _openingHoursController.text = _userData!['openingHours'] ?? '';
          }
        });
      }

      // Charger les statistiques
      final followersQuery = await _firestore
          .collection('relationships')
          .where('followingId', isEqualTo: userId)
          .get();

      final followingQuery = await _firestore
          .collection('relationships')
          .where('followerId', isEqualTo: userId)
          .get();

      final creationsQuery = await _firestore
          .collection('creations')
          .where('creatorId', isEqualTo: userId)
          .get();

      setState(() {
        _followersCount = followersQuery.size;
        _followingCount = followingQuery.size;
        _creationsCount = creationsQuery.size;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Erreur de chargement: $e');
    }
  }

  Future<void> _loadWardrobeItems() async {
    if (_currentUser == null) return;

    final query = await _firestore
        .collection('wardrobe')
        .where('userId', isEqualTo: _currentUser!.uid)
        .get();

    setState(() {
      _wardrobeItems.addAll(query.docs.map((doc) => doc['imageUrl'] as String));
    });
  }

  Future<void> _addToWardrobe() async {
    if (_currentUser == null) return;

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      // Upload de l'image vers Firebase Storage
      final ref = _storage.ref().child('wardrobe/${_currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(pickedFile.path));
      final imageUrl = await ref.getDownloadURL();

      // Ajout à Firestore
      final newItem = {
        'userId': _currentUser!.uid,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'tags': ['top', 'casual'], // Exemple de tags pour l'IA
      };

      await _firestore.collection('wardrobe').add(newItem);
      _loadWardrobeItems(); // Recharger les éléments
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout: $e')),
      );
    }
  }

  Future<void> _removeWardrobeItem(int index) async {
    try {
      final query = await _firestore
          .collection('wardrobe')
          .where('imageUrl', isEqualTo: _wardrobeItems[index])
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }

      // Supprimer l'image du storage
      final ref = _storage.refFromURL(_wardrobeItems[index]);
      await ref.delete();

      setState(() {
        _wardrobeItems.removeAt(index);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  Future<void> _changeProfilePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      final userId = _currentUser?.uid;
      if (userId == null) return;

      // Upload vers Firebase Storage
      final ref = _storage.ref().child('user_profiles/$userId/profile.jpg');
      await ref.putFile(File(pickedFile.path));
      final photoUrl = await ref.getDownloadURL();

      // Mettre à jour Firestore
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour l'état local
      setState(() {
        _userData?['photoUrl'] = photoUrl;
      });

      // Mettre à jour le profil Firebase Auth
      await _currentUser?.updatePhotoURL(photoUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur upload photo: $e')),
      );
    }
  }

  Future<void> _selectCoverPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      final userId = _currentUser?.uid;
      if (userId == null) return;

      final ref = _storage.ref().child('user_profiles/$userId/cover.jpg');
      await ref.putFile(File(pickedFile.path));
      final coverUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(userId).update({
        'coverPhoto': coverUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _userData?['coverPhoto'] = coverUrl;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur upload photo couverture: $e')),
      );
    }
  }

  Future<void> _saveProfileChanges() async {
    try {
      final userId = _currentUser?.uid;
      if (userId == null) return;

      final userData = {
        'name': _nameController.text,
        'bio': _bioController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Ajouter les champs spécifiques
      if (_userData?['role'] == 'createur') {
        userData['speciality'] = _specialityController.text;
        userData['website'] = _websiteController.text;
      } else if (_userData?['role'] == 'boutique') {
        userData['address'] = _addressController.text;
        userData['openingHours'] = _openingHoursController.text;
      }

      await _firestore.collection('users').doc(userId).update(userData);

      // Mettre à jour l'email dans Firebase Auth si nécessaire
      if (_emailController.text != _currentUser?.email) {
        await _currentUser?.updateEmail(_emailController.text);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _userData?['coverPhoto'] ?? 'https://i.pinimg.com/564x/83/7a/4e/837a4ed6ecbd41f63eb123e973f9b202.jpg',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userData?['name'] ?? _currentUser?.displayName ?? 'Utilisateur',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _userData?['email'] ?? _currentUser?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        if (_userData?['role'] != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _userData?['role'] == 'createur'
                                  ? Colors.orange[700]
                                  : _userData?['role'] == 'boutique'
                                  ? Colors.blue[700]
                                  : Colors.green[700],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _userData?['role']?.toUpperCase() ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  _buildStatItem(_followersCount.toString(), 'Abonnés'),
                  _buildStatItem(_followingCount.toString(), 'Abonnements'),
                  _buildStatItem(_creationsCount.toString(), 'Créations'),
                  if (_isCurrentUserProfile)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 2,
                            shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                          onPressed: _navigateToEditProfile,
                          child: const Text(
                            'Modifier profil',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_userData?['bio'] != null) ...[
                    Text(
                      'À propos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userData!['bio'],
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Afficher les informations spécifiques au rôle
                  if (_userData?['role'] == 'createur' && _userData?['speciality'] != null)
                    _buildProfileInfoRow(Icons.star, 'Spécialité: ${_userData!['speciality']}'),

                  if (_userData?['role'] == 'createur' && _userData?['website'] != null)
                    _buildProfileInfoRow(Icons.link, 'Site web: ${_userData!['website']}'),

                  if (_userData?['role'] == 'boutique' && _userData?['address'] != null)
                    _buildProfileInfoRow(Icons.location_on, 'Adresse: ${_userData!['address']}'),

                  if (_userData?['role'] == 'boutique' && _userData?['openingHours'] != null)
                    _buildProfileInfoRow(Icons.schedule, 'Horaires: ${_userData!['openingHours']}'),

                  Text(
                    _currentUser?.metadata.creationTime != null
                        ? 'Membre depuis ${DateFormat('MMMM yyyy').format(_currentUser!.metadata.creationTime!)}'
                        : 'Date d\'inscription inconnue',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(child: _buildTabButton('Activité', 0)),
                  if (_userData?['role'] == 'client') ...[
                    Expanded(child: _buildTabButton('Garde-robe', 1)),
                    Expanded(child: _buildTabButton('Suggestions', 2)),
                  ] else if (_userData?['role'] == 'createur') ...[
                    Expanded(child: _buildTabButton('Créations', 1)),
                    Expanded(child: _buildTabButton('Portfolio', 2)),
                  ] else if (_userData?['role'] == 'boutique') ...[
                    Expanded(child: _buildTabButton('Catalogue', 1)),
                    Expanded(child: _buildTabButton('Promotions', 2)),
                  ],
                  if (_isCurrentUserProfile)
                    Expanded(child: _buildTabButton('Paramètres', 3)),
                ],
              ),
            ),
          ),
          if (_selectedTab == 0) _buildActivityTab(),
          if (_selectedTab == 1 && _userData?['role'] == 'client') _buildWardrobeTab(),
          if (_selectedTab == 1 && _userData?['role'] == 'createur') _buildCreationsTab(),
          if (_selectedTab == 1 && _userData?['role'] == 'boutique') _buildCatalogTab(),
          if (_selectedTab == 2 && _userData?['role'] == 'client') _buildSuggestionsTab(),
          if (_selectedTab == 2 && _userData?['role'] == 'createur') _buildPortfolioTab(),
          if (_selectedTab == 2 && _userData?['role'] == 'boutique') _buildPromotionsTab(),
          if (_selectedTab == 3 && _isCurrentUserProfile) _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    final roleColor = _userData?['role'] == 'createur'
        ? Colors.orange
        : _userData?['role'] == 'boutique'
        ? Colors.blue
        : Colors.green;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: roleColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTab == index;
    final roleColor = _userData?['role'] == 'createur'
        ? Colors.orange
        : _userData?['role'] == 'boutique'
        ? Colors.blue
        : Colors.green;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? roleColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? roleColor : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(
                index % 3 == 0
                    ? Icons.favorite
                    : index % 3 == 1
                    ? Icons.comment
                    : Icons.share,
                color: Colors.white,
              ),
            ),
            title: Text(
              index % 3 == 0
                  ? 'Vous avez aimé une création'
                  : index % 3 == 1
                  ? 'Vous avez commenté une création'
                  : 'Vous avez partagé une boutique',
            ),
            subtitle: Text('Il y a ${index + 1} heures'),
            trailing: const Icon(Icons.chevron_right),
          );
        },
        childCount: 5,
      ),
    );
  }

  Widget _buildWardrobeTab() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            if (index < _wardrobeItems.length) {
              return _buildWardrobeItem(index);
            } else {
              return _buildAddWardrobeItem();
            }
          },
          childCount: _wardrobeItems.length + 1,
        ),
      ),
    );
  }

  Widget _buildWardrobeItem(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: _wardrobeItems[index],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => Container(color: Colors.grey[200]),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeWardrobeItem(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddWardrobeItem() {
    return GestureDetector(
      onTap: _addToWardrobe,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Ajouter un vêtement',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreationsTab() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return ListTile(
              leading: const Icon(Icons.brush),
              title: Text('Création ${index + 1}'),
              subtitle: const Text('Description de la création...'),
            );
          },
          childCount: 5,
        ),
      ),
    );
  }

  Widget _buildCatalogTab() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: Text('Produit ${index + 1}'),
              subtitle: const Text('Description du produit...'),
            );
          },
          childCount: 5,
        ),
      ),
    );
  }

  Widget _buildSuggestionsTab() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            if (_wardrobeItems.isEmpty)
              const Text('Ajoutez des vêtements à votre garde-robe pour obtenir des suggestions')
            else
              ElevatedButton(
                onPressed: _generateAISuggestions,
                child: const Text('Générer des suggestions IA'),
              ),
            const SizedBox(height: 20),
            Text(
              'Suggestions basées sur votre garde-robe (${_wardrobeItems.length} vêtements)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Vos suggestions apparaîtront ici'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioTab() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            const Text(
              'Votre portfolio de créations',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Ajouter une création au portfolio'),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: const Center(child: Icon(Icons.add_a_photo)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsTab() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            const Text(
              'Vos promotions en cours',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Créer une nouvelle promotion'),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.local_offer),
                    title: Text('Promotion ${index + 1}'),
                    subtitle: const Text('Réduction de 20% sur une sélection'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildSettingsSectionHeader('Mon Compte'),
          _buildSettingsItem(
            icon: Icons.person_outline,
            title: 'Modifier le profil',
            subtitle: 'Mettez à jour vos informations personnelles',
            onTap: _navigateToEditProfile,
          ),

          _buildSettingsSectionHeader('Confidentialité'),
          _buildSettingsItem(
            icon: Icons.lock_outline,
            title: 'Paramètres de confidentialité',
            subtitle: 'Contrôlez qui voit vos informations',
            onTap: _navigateToPrivacySettings,
          ),
          _buildSettingsItem(
            icon: Icons.visibility_outlined,
            title: 'Visibilité du compte',
            subtitle: 'Définissez votre profil comme public ou privé',
            onTap: _navigateToAccountVisibility,
          ),

          _buildSettingsSectionHeader('Sécurité'),
          _buildSettingsItem(
            icon: Icons.security_outlined,
            title: 'Sécurité du compte',
            subtitle: 'Authentification à deux facteurs et connexions',
            onTap: _navigateToSecuritySettings,
          ),
          _buildSettingsItem(
            icon: Icons.password_outlined,
            title: 'Changer le mot de passe',
            subtitle: 'Mettez à jour votre mot de passe régulièrement',
            onTap: _navigateToChangePassword,
          ),

          _buildSettingsSectionHeader('Aide & Support'),
          _buildSettingsItem(
            icon: Icons.help_outline_outlined,
            title: 'Centre d\'aide',
            subtitle: 'Trouvez des réponses à vos questions',
            onTap: _navigateToHelpCenter,
          ),
          _buildSettingsItem(
            icon: Icons.email_outlined,
            title: 'Nous contacter',
            subtitle: 'Envoyez-nous vos questions ou commentaires',
            onTap: _navigateToContactUs,
          ),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'À propos',
            subtitle: 'En savoir plus sur notre application',
            onTap: _navigateToAbout,
          ),

          const SizedBox(height: 24),
          _buildLogoutButton(),
        ]),
      ),
    );
  }

  Widget _buildEditProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        child: Column(
          children: [
            _buildAvatarEditor(),
            const SizedBox(height: 30),
            _buildFormField('Nom complet', Icons.person, _nameController),
            _buildFormField('Bio', Icons.info, _bioController, maxLines: 3),

            // Champs spécifiques aux créateurs
            if (_userData?['role'] == 'createur') ...[
              _buildFormField('Spécialité', Icons.star, _specialityController),
              _buildFormField('Site web', Icons.link, _websiteController),
            ],

            // Champs spécifiques aux boutiques
            if (_userData?['role'] == 'boutique') ...[
              _buildFormField('Adresse', Icons.location_on, _addressController),
              _buildFormField('Heures d\'ouverture', Icons.schedule, _openingHoursController),
            ],

            _buildFormField('Email', Icons.email, _emailController),
            _buildFormField('Téléphone', Icons.phone, _phoneController),
            _buildCoverPhotoSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarEditor() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: CachedNetworkImageProvider(
            _userData?['photoUrl'] ?? _currentUser?.photoURL ?? '',
          ),
          child: _userData?['photoUrl'] == null && _currentUser?.photoURL == null
              ? const Icon(Icons.person, size: 50)
              : null,
        ),
        if (_isCurrentUserProfile)
          FloatingActionButton.small(
            onPressed: _changeProfilePhoto,
            child: const Icon(Icons.edit),
          ),
      ],
    );
  }

  Widget _buildFormField(String label, IconData icon, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildCoverPhotoSelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Photo de couverture',
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _isCurrentUserProfile ? _selectCoverPhoto : null,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
                image: _userData?['coverPhoto'] != null
                    ? DecorationImage(
                  image: CachedNetworkImageProvider(_userData!['coverPhoto']),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: _userData?['coverPhoto'] == null
                  ? Center(
                child: _isCurrentUserProfile
                    ? const Icon(Icons.add_a_photo, size: 40)
                    : const Icon(Icons.photo_library, size: 40),
              )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).hintColor,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).hintColor,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: _signOut,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Modifier le profil'),
            actions: [
              TextButton(
                onPressed: _saveProfileChanges,
                child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          body: _buildEditProfileForm(),
        ),
      ),
    );
  }

  void _navigateToPrivacySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Confidentialité')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPrivacySwitch(
                'Profil public',
                'Visible par tous les utilisateurs',
                _isPublicProfile,
                    (value) => setState(() => _isPublicProfile = value),
              ),
              _buildPrivacySwitch(
                'Activité visible',
                'Afficher mes activités récentes',
                _isActivityVisible,
                    (value) => setState(() => _isActivityVisible = value),
              ),
              const SizedBox(height: 20),
              _buildPrivacyOption(
                Icons.block,
                'Utilisateurs bloqués',
                'Gérer la liste des utilisateurs bloqués',
                _navigateToBlockedUsers,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  void _navigateToAccountVisibility() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Visibilité du compte',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            _buildVisibilityOption(
              Icons.public,
              'Public',
              'Tout le monde peut voir votre profil',
              _isPublic,
            ),
            _buildVisibilityOption(
              Icons.lock_outline,
              'Privé',
              'Seuls vos abonnés peuvent voir vos publications',
              !_isPublic,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSecuritySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Sécurité')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSecurityCard(
                Icons.two_wheeler,
                'Authentification à deux facteurs',
                'Ajoutez une couche de sécurité supplémentaire',
                _twoFactorAuthEnabled,
                _toggleTwoFactorAuth,
              ),
              _buildSecurityCard(
                Icons.devices,
                'Appareils connectés',
                'Gérez les appareils ayant accès à votre compte',
                false,
                _navigateToConnectedDevices,
              ),
              _buildSecurityCard(
                Icons.notifications_active,
                'Alertes de sécurité',
                'Recevez des notifications pour activités suspectes',
                _securityAlertsEnabled,
                _toggleSecurityAlerts,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToChangePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: _updatePassword,
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  void _navigateToHelpCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Centre d\'aide')),
          body: ListView(
            children: [
              _buildHelpTopic('Problèmes de connexion', Icons.login),
              _buildHelpTopic('Gestion du compte', Icons.account_circle),
              _buildHelpTopic('Problèmes de paiement', Icons.payment),
              _buildHelpTopic('Signaler un bug', Icons.bug_report),
              _buildHelpTopic('FAQ', Icons.help_center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpTopic(String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showHelpDetails(title),
      ),
    );
  }

  void _navigateToContactUs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Nous contacter')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Nous sommes là pour vous aider',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 30),
                _buildContactOption(
                  Icons.email,
                  'support@elegantfaso.com',
                  'Envoyez-nous un email',
                  _launchEmail,
                ),
                _buildContactOption(
                  Icons.chat,
                  'Chat en direct',
                  'Disponible 9h-18h',
                  _startLiveChat,
                ),
                _buildContactOption(
                  Icons.phone,
                  '+226 05670981',
                  'Appelez notre support',
                  _callSupport,
                ),
                const Spacer(),
                const Text('Réponse sous 24h maximum'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAbout() {
    showDialog(
      context: context,
      builder: (context) => _buildAboutDialog(),
    );
  }

  Widget _buildAboutDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'À propos',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            'ElegantFaso v1.0.0',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'L\'application ultime pour les passionnés de mode',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            '© 2025 ElegantFaso Inc.\nTous droits réservés.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildPrivacyOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildVisibilityOption(IconData icon, String title, String subtitle, bool isSelected) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected ? const Icon(Icons.check) : null,
      tileColor: isSelected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () => setState(() => _isPublic = title == 'Public'),
    );
  }

  Widget _buildSecurityCard(IconData icon, String title, String subtitle, bool value, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: (val) => onTap(),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildContactOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _toggleTwoFactorAuth() {
    setState(() {
      _twoFactorAuthEnabled = !_twoFactorAuthEnabled;
    });
  }

  void _navigateToConnectedDevices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Appareils connectés')),
          body: const Center(child: Text('Gestion des appareils')),
        ),
      ),
    );
  }

  void _toggleSecurityAlerts() {
    setState(() {
      _securityAlertsEnabled = !_securityAlertsEnabled;
    });
  }

  Future<void> _updatePassword() async {
    // Implémentez la logique de mise à jour du mot de passe
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe mis à jour')),
    );
  }

  void _showHelpDetails(String topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(topic),
        content: Text('Détails d\'aide pour $topic...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@elegantfaso.com',
      queryParameters: {'subject': 'Support FashionApp'},
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir l\'email')),
      );
    }
  }

  void _startLiveChat() {
    // Implémentez le chat en direct
  }

  void _callSupport() async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: '+226 05670981',
    );
    if (await canLaunchUrl(phoneLaunchUri)) {
      await launchUrl(phoneLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir l\'appel')),
      );
    }
  }

  void _navigateToBlockedUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Utilisateurs bloqués')),
          body: const Center(child: Text('Liste des utilisateurs bloqués')),
        ),
      ),
    );
  }

  Future<void> _generateAISuggestions() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggestions IA'),
        content: const Text('Voici des tenues suggérées basées sur votre garde-robe...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    // Naviguer vers l'écran de connexion
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}