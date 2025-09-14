import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';


class ClientProfileScreen extends StatefulWidget {
  final String? userId;

  const ClientProfileScreen({super.key, this.userId});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  late User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isCurrentUserProfile = true;
  int _selectedTab = 0;
  final List<String> _wardrobeItems = [];
  Map<String, dynamic>? _userData;
  int _followersCount = 0;
  int _followingCount = 0;
  int _wardrobeCount = 0;
  int _suggestionsCount = 0;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isGeneratingSuggestions = false;
  bool _isFollowing = false;
  List<Map<String, dynamic>> _aiSuggestions = [];

  // Contrôleurs pour les champs de formulaire
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isCurrentUserProfile = widget.userId == null || widget.userId == _currentUser?.uid;
    _loadUserData();
    if (_isCurrentUserProfile) {

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

          // Charger les compteurs
          _followersCount = (_userData!['followers'] as List?)?.length ?? 0;
          _followingCount = (_userData!['following'] as List?)?.length ?? 0;
        });
      }

      // Vérifier si l'utilisateur actuel suit ce profil
      if (!_isCurrentUserProfile && _currentUser != null) {
        final followers = List<String>.from(_userData?['followers'] ?? []);
        setState(() {
          _isFollowing = followers.contains(_currentUser!.uid);
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Erreur de chargement: $e');
    }
  }

  Future<void> _followUser() async {
    final currentUserId = _currentUser?.uid;
    final profileUserId = widget.userId ?? _currentUser?.uid;

    if (currentUserId == null || profileUserId == null) return;
    if (currentUserId == profileUserId) return;

    try {
      setState(() => _isLoading = true);

      // Mettre à jour le profil de l'utilisateur suivi
      await _firestore.collection('users').doc(profileUserId).update({
        'followers': FieldValue.arrayUnion([currentUserId])
      });

      // Mettre à jour le profil de l'utilisateur actuel
      await _firestore.collection('users').doc(currentUserId).update({
        'following': FieldValue.arrayUnion([profileUserId])
      });

      // Recharger les données
      await _loadUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isFollowing
            ? 'Vous ne suivez plus ce profil'
            : 'Vous suivez maintenant ce profil')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Future<void> _loadWardrobeItems() async {
  //   if (_currentUser == null) return;
  //
  //   try {
  //     final query = await _firestore
  //         .collection('wardrobe')
  //         .where('userId', isEqualTo: _currentUser!.uid)
  //         .get();
  //
  //     setState(() {
  //       _wardrobeItems.clear();
  //       _wardrobeItems.addAll(query.docs.map((doc) => doc['imageUrl'] as String));
  //       _wardrobeCount = _wardrobeItems.length;
  //     });
  //   } catch (e) {
  //     debugPrint('Erreur de chargement de la garde-robe: $e');
  //   }
  // }

  // Future<void> _loadAISuggestions() async {
  //   if (_currentUser == null) return;
  //
  //   try {
  //     final query = await _firestore
  //         .collection('ai_suggestions')
  //         .where('userId', isEqualTo: _currentUser!.uid)
  //         .orderBy('createdAt', descending: true)
  //         .get();
  //
  //     setState(() {
  //       _aiSuggestions = query.docs.map((doc) {
  //         final data = doc.data() as Map<String, dynamic>;
  //         return {
  //           'id': doc.id,
  //           'outfit': data['outfit'] ?? 'Tenue stylée',
  //           'items': List<String>.from(data['items'] ?? []),
  //           'createdAt': (data['createdAt'] as Timestamp).toDate(),
  //         };
  //       }).toList();
  //       _suggestionsCount = _aiSuggestions.length;
  //     });
  //   } catch (e) {
  //     debugPrint('Erreur de chargement des suggestions IA: $e');
  //   }
  // }

  // Future<void> _addToWardrobe() async {
  //   if (_currentUser == null) return;
  //
  //   final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  //   if (pickedFile == null) return;
  //
  //   try {
  //     setState(() => _isLoading = true);
  //
  //     // Upload de l'image vers Firebase Storage
  //     final ref = _storage.ref().child('wardrobe/${_currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
  //     await ref.putFile(File(pickedFile.path));
  //     final imageUrl = await ref.getDownloadURL();
  //
  //     // Ajout à Firestore
  //     final newItem = {
  //       'userId': _currentUser!.uid,
  //       'imageUrl': imageUrl,
  //       'createdAt': FieldValue.serverTimestamp(),
  //       'tags': ['top', 'casual'],
  //     };
  //
  //     await _firestore.collection('wardrobe').add(newItem);
  //     await _loadWardrobeItems();
  //
  //     // Générer des suggestions si suffisamment d'articles
  //     if (_wardrobeCount >= 3) {
  //       await _generateAISuggestions();
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Erreur lors de l\'ajout: $e')),
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  // Future<void> _removeWardrobeItem(int index) async {
  //   try {
  //     setState(() => _isLoading = true);
  //
  //     final query = await _firestore
  //         .collection('wardrobe')
  //         .where('imageUrl', isEqualTo: _wardrobeItems[index])
  //         .get();
  //
  //     for (var doc in query.docs) {
  //       await doc.reference.delete();
  //     }
  //
  //     // Supprimer l'image du storage
  //     final ref = _storage.refFromURL(_wardrobeItems[index]);
  //     await ref.delete();
  //
  //     await _loadWardrobeItems();
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Erreur lors de la suppression: $e')),
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _changeProfilePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      setState(() => _isLoading = true);

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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectCoverPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      setState(() => _isLoading = true);

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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfileChanges() async {
    try {
      setState(() => _isLoading = true);

      final userId = _currentUser?.uid;
      if (userId == null) return;

      final userData = {
        'name': _nameController.text,
        'bio': _bioController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).update(userData);

      // Mettre à jour l'email dans Firebase Auth si nécessaire
      if (_emailController.text != _currentUser?.email) {
        await _currentUser?.updateEmail(_emailController.text);
      }

      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Future<void> _generateAISuggestions() async {
  //   if (_wardrobeCount < 3) return;
  //
  //   try {
  //     setState(() {
  //       _isGeneratingSuggestions = true;
  //       _isLoading = true;
  //     });
  //
  //     // Générer 2-4 nouvelles suggestions
  //     final random = Random();
  //     final count = random.nextInt(3) + 2; // 2-4 suggestions
  //
  //     for (int i = 0; i < count; i++) {
  //       // Sélectionner 3-5 articles aléatoires
  //       final itemCount = min(5, max(3, random.nextInt(3) + 3));
  //       final selectedItems = _wardrobeItems.toList()..shuffle();
  //       final outfitItems = selectedItems.sublist(0, min(itemCount, selectedItems.length));
  //
  //       final outfitNames = [
  //         'Tenue décontractée',
  //         'Style élégant',
  //         'Look urbain',
  //         'Ensemble printanier',
  //         'Tenue soirée'
  //       ];
  //
  //       final newSuggestion = {
  //         'userId': _currentUser!.uid,
  //         'outfit': outfitNames[random.nextInt(outfitNames.length)],
  //         'items': outfitItems,
  //         'createdAt': FieldValue.serverTimestamp(),
  //       };
  //
  //       await _firestore.collection('ai_suggestions').add(newSuggestion);
  //     }
  //
  //     await _loadAISuggestions();
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('$count nouvelles suggestions générées !')),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Erreur IA: ${e.toString()}')),
  //     );
  //   } finally {
  //     setState(() {
  //       _isGeneratingSuggestions = false;
  //       _isLoading = false;
  //     });
  //   }
  // }

  Future<void> _deleteSuggestion(String suggestionId) async {
    try {
      setState(() => _isLoading = true);

      await _firestore.collection('ai_suggestions').doc(suggestionId).delete();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de suppression: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFFD2691E);
    final secondaryColor = const Color(0xFFA0522D);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // AppBar extensible avec photo de couverture
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildCoverPhoto(primaryColor),
              title: Text(
                _userData?['name'] ?? _currentUser?.displayName ?? 'Utilisateur',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
            actions: [
              if (_isCurrentUserProfile)
                IconButton(
                  icon: Icon(
                    _isEditing ? Icons.save : Icons.edit,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (_isEditing) {
                      _saveProfileChanges();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
                ),
            ],
          ),

          // Section de statistiques
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(_followersCount.toString(), 'Abonnés', primaryColor),
                  ),
                  Expanded(
                    child: _buildStatItem(_followingCount.toString(), 'Abonnements', primaryColor),
                  ),
                  Expanded(
                    child: _buildStatItem(_wardrobeCount.toString(), 'Garde-robe', primaryColor),
                  ),
                  if (_isCurrentUserProfile)
                    Expanded(
                      child: _buildStatItem(_suggestionsCount.toString(), 'Suggestions', primaryColor),
                    ),
                ],
              ),

            ),
          ),

          // Section d'informations
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_userData?['bio'] != null && !_isEditing) ...[
                    Text(
                      'À propos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
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

                  // Champs d'édition
                  if (_isEditing) ...[
                    _buildEditableField('Nom complet', Icons.person, _nameController),
                    _buildEditableField('Bio', Icons.info, _bioController, maxLines: 3),
                    _buildEditableField('Email', Icons.email, _emailController),
                    _buildEditableField('Téléphone', Icons.phone, _phoneController),
                  ],

                  Text(
                    _currentUser?.metadata.creationTime != null
                        ? 'Membre depuis ${DateFormat('MMMM yyyy').format(_currentUser!.metadata.creationTime!)}'
                        : 'Date d\'inscription inconnue',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Barre d'onglets
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTabButton('Activité', 0, primaryColor)),
                    if (_isCurrentUserProfile)
                      Expanded(child: _buildTabButton('Paramètres', 1, primaryColor)),
                  ],
                ),
              ),
            ),
          ),

          // Contenu des onglets
          if (_selectedTab == 0) _buildActivityTab(primaryColor, isDarkMode),
          if (_selectedTab == 1 && _isCurrentUserProfile) _buildSettingsTab(primaryColor, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildCoverPhoto(Color primaryColor) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: _userData?['coverPhoto'] ?? 'https://i.pinimg.com/564x/83/7a/4e/837a4ed6ecbd41f63eb123e973f9b202.jpg',
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image, size: 50),
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
          top: 70,
          right: 20,
          child: GestureDetector(
            onTap: _isCurrentUserProfile ? _changeProfilePhoto : null,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 38,
                backgroundImage: _userData?['photoUrl'] != null
                    ? CachedNetworkImageProvider(_userData!['photoUrl'])
                    : null,
                child: _userData?['photoUrl'] == null
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
          ),
        ),
        if (!_isCurrentUserProfile)
          Positioned(
            bottom: 20,
            left: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.grey : primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: _followUser,
              child: Text(_isFollowing ? 'Abonné' : 'Suivre'),
            ),
          ),
        if (_isCurrentUserProfile)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.small(
              backgroundColor: primaryColor,
              onPressed: _selectCoverPhoto,
              child: const Icon(Icons.camera_alt, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, IconData icon, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFD2691E)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildTabButton(String text, int index, Color primaryColor) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primaryColor : Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTab(Color primaryColor, bool isDarkMode) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final activities = [
            {'type': 'like', 'text': 'Vous avez aimé une création', 'icon': Icons.favorite},
            {'type': 'comment', 'text': 'Vous avez commenté une création', 'icon': Icons.comment},
            {'type': 'share', 'text': 'Vous avez partagé une boutique', 'icon': Icons.share},
            {'type': 'follow', 'text': 'Vous avez suivi un créateur', 'icon': Icons.person_add},
            {'type': 'purchase', 'text': 'Vous avez effectué un achat', 'icon': Icons.shopping_bag},
          ];

          final activity = activities[index % activities.length];
          final hoursAgo = (index % 5) + 1;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    activity['icon'] as IconData,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['text'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Il y a ${hoursAgo}h',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          );
        },
        childCount: 10,
      ),
    );
  }

  Widget _buildSettingsTab(Color primaryColor, bool isDarkMode) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildSettingsSectionHeader('Sécurité', primaryColor),
          _buildSettingsItem(
            icon: Icons.password_outlined,
            title: 'Changer le mot de passe',
            subtitle: 'Mettez à jour votre mot de passe régulièrement',
            onTap: () {},
            primaryColor: primaryColor,
            isDarkMode: isDarkMode,
          ),

          _buildSettingsSectionHeader('Aide & Support', primaryColor),
          _buildSettingsItem(
            icon: Icons.help_outline_outlined,
            title: 'Centre d\'aide',
            subtitle: 'Trouvez des réponses à vos questions',
            onTap: () {},
            primaryColor: primaryColor,
            isDarkMode: isDarkMode,
          ),
          _buildSettingsItem(
            icon: Icons.email_outlined,
            title: 'Nous contacter',
            subtitle: 'Envoyez-nous vos questions ou commentaires',
            onTap: () {},
            primaryColor: primaryColor,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 24),
          _buildLogoutButton(primaryColor, isDarkMode),
        ]),
      ),
    );
  }

  Widget _buildSettingsSectionHeader(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color primaryColor,
    required bool isDarkMode,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(Color primaryColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
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

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}