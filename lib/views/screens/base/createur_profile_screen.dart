import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateurProfileScreen extends StatefulWidget {
  final String? userId;

  const CreateurProfileScreen({super.key, this.userId});

  @override
  State<CreateurProfileScreen> createState() => _CreateurProfileScreenState();
}

class _CreateurProfileScreenState extends State<CreateurProfileScreen>
    with TickerProviderStateMixin {
  late User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isCurrentUserProfile = true;
  int _selectedTab = 0;
  Map<String, dynamic>? _userData;
  int _clientsCount = 0;
  int _creationsCount = 0;
  int _likesCount = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _userCreations = [];

  List<String> _competences = [];
  List<Map<String, String>> _certifications = [];
  String _paymentMethod = '';
  String _paymentNumber = '';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _specialityController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  final TextEditingController _competenceController = TextEditingController();
  final TextEditingController _certifTitleController = TextEditingController();
  final TextEditingController _certifInstitutionController = TextEditingController();
  final TextEditingController _certifYearController = TextEditingController();
  final TextEditingController _paymentNumberController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isCurrentUserProfile = widget.userId == null || widget.userId == _currentUser?.uid;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _loadUserData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _specialityController.dispose();
    _websiteController.dispose();
    _competenceController.dispose();
    _certifTitleController.dispose();
    _certifInstitutionController.dispose();
    _certifYearController.dispose();
    _paymentNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userId = widget.userId ?? _currentUser?.uid;
    if (userId == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _nameController.text = _userData!['name'] ?? '';
          _bioController.text = _userData!['bio'] ?? '';
          _emailController.text = _userData!['email'] ?? '';
          _specialityController.text = _userData!['speciality'] ?? '';
          _websiteController.text = _userData!['website'] ?? '';

          _competences = List<String>.from(_userData?['competences'] ?? []);
          _certifications = List<Map<String, String>>.from(
              _userData?['certifications']?.map((e) => Map<String, String>.from(e)) ?? []);
          _paymentMethod = _userData?['paymentMethod'] ?? '';
          _paymentNumber = _userData?['paymentNumber'] ?? '';
          _paymentNumberController.text = _paymentNumber;
        });
      }

      final clientsQuery = await _firestore
          .collection('relationships')
          .where('followingId', isEqualTo: userId)
          .get();

      final creationsSnapshot = await _firestore
          .collection('creations')
          .where('creatorId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      List<Map<String, dynamic>> creations = [];
      int totalLikes = 0;

      for (var doc in creationsSnapshot.docs) {
        final likes = doc['likeCount'] as int? ?? 0;
        totalLikes += likes;

        creations.add({
          'id': doc.id,
          'title': doc['title'],
          'imageUrl': doc['imageUrl'],
          'date': doc['date'],
          'likes': likes,
        });
      }

      setState(() {
        _clientsCount = clientsQuery.size;
        _creationsCount = creationsSnapshot.size;
        _likesCount = totalLikes;
        _userCreations = creations;
        _isLoading = false;
      });

      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Erreur de chargement: $e');
    }
  }

  Future<void> _changeProfilePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    _showLoadingDialog('Mise à jour de la photo...');

    try {
      final userId = _currentUser?.uid;
      if (userId == null) return;

      final ref = _storage.ref().child('user_profiles/$userId/profile.jpg');
      await ref.putFile(File(pickedFile.path));
      final photoUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(userId).update({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _userData?['photoUrl'] = photoUrl);
      await _currentUser?.updatePhotoURL(photoUrl);

      Navigator.pop(context);
      _showSuccessSnackBar('Photo de profil mise à jour');
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('Erreur lors de la mise à jour de la photo: $e');
    }
  }

  Future<void> _selectCoverPhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    _showLoadingDialog('Mise à jour de la couverture...');

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

      setState(() => _userData?['coverPhoto'] = coverUrl);

      Navigator.pop(context);
      _showSuccessSnackBar('Photo de couverture mise à jour');
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('Erreur lors de la mise à jour de la couverture: $e');
    }
  }

  Future<void> _saveProfileChanges() async {
    if (_nameController.text.isEmpty) {
      _showErrorSnackBar('Le nom ne peut pas être vide');
      return;
    }

    _showLoadingDialog('Sauvegarde...');

    try {
      final userId = _currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'email': _emailController.text.trim(),
        'speciality': _specialityController.text.trim(),
        'website': _websiteController.text.trim(),
        'competences': _competences,
        'certifications': _certifications,
        'paymentMethod': _paymentMethod,
        'paymentNumber': _paymentNumberController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (_emailController.text.trim() != _currentUser?.email) {
        await _currentUser?.updateEmail(_emailController.text.trim());
      }

      Navigator.pop(context);
      Navigator.pop(context);
      _showSuccessSnackBar('Profil mis à jour avec succès');
      _loadUserData();
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('Erreur: ${e.toString()}');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Chargement du profil...',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 320,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: innerBoxIsScrolled
                          ? (isDarkMode ? Colors.white : Colors.black)
                          : Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    if (_isCurrentUserProfile)
                      IconButton(
                        icon: Icon(
                          Icons.settings,
                          color: innerBoxIsScrolled
                              ? (isDarkMode ? Colors.white : Colors.black)
                              : Colors.white,
                        ),
                        onPressed: () => setState(() => _selectedTab = 3),
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: _buildCoverSection(),
                  ),
                ),
              ];
            },
            body: _buildBody(),
          ),
        ),
      ),
      floatingActionButton: _isCurrentUserProfile
          ? FloatingActionButton.extended(
        heroTag: UniqueKey(),
        backgroundColor: primaryColor,
        onPressed: _navigateToEditProfile,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Modifier', style: TextStyle(color: Colors.white)),
      )
          : FloatingActionButton(
        heroTag: UniqueKey(),
        backgroundColor: primaryColor,
        onPressed: () {},
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildCoverSection() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'cover_${widget.userId ?? _currentUser?.uid}',
          child: CachedNetworkImage(
            imageUrl: _userData?['coverPhoto']?.isNotEmpty == true
                ? _userData!['coverPhoto']
                : 'https://i.pinimg.com/564x/83/7a/4e/837a4ed6ecbd41f63eb123e973f9b202.jpg',
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.3),
                    primaryColor.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.3),
                    primaryColor.withOpacity(0.6),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(Icons.broken_image, size: 50, color: Colors.white),
              ),
            ),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),

        if (_isCurrentUserProfile)
          Positioned(
            top: 60,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: _selectCoverPhoto,
              ),
            ),
          ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Hero(
                      tag: 'avatar_${widget.userId ?? _currentUser?.uid}',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _userData?['photoUrl'] != null
                              ? CachedNetworkImageProvider(_userData!['photoUrl'])
                              : null,
                          child: _userData?['photoUrl'] == null
                              ? const Icon(Icons.person, size: 40, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                    if (_isCurrentUserProfile)
                      Positioned(
                        bottom: -5,
                        right: -5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: _changeProfilePhoto,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _userData?['name'] ?? _currentUser?.displayName ?? 'Créateur',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                      if (_userData?['speciality'] != null && _userData!['speciality'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _userData!['speciality'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
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
      ],
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEnhancedStatItem(_clientsCount.toString(), 'Clients', Icons.people_alt, Colors.blue),
                _buildVerticalDivider(),
                _buildEnhancedStatItem(_creationsCount.toString(), 'Créations', Icons.brush, Colors.purple),
                _buildVerticalDivider(),
                _buildEnhancedStatItem(_likesCount.toString(), 'Likes', Icons.favorite, Colors.red),
              ],
            ),
          ),
        ),

        if (_userData?['bio'] != null && _userData!['bio'].isNotEmpty)
          SliverToBoxAdapter(
            child: _buildAboutSection(),
          ),

        SliverToBoxAdapter(
          child: _buildTabBar(),
        ),

        SliverToBoxAdapter(
          child: _buildCurrentTabContent(),
        ),
      ],
    );
  }

  Widget _buildEnhancedStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).dividerColor.withOpacity(0.3),
    );
  }

  Widget _buildAboutSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'À propos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userData!['bio'],
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          if (_userData?['website'] != null && _userData!['website'].isNotEmpty) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _launchURL(_userData!['website']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _userData!['website'],
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                _currentUser?.metadata.creationTime != null
                    ? 'Membre depuis ${DateFormat('MMMM yyyy', 'fr').format(_currentUser!.metadata.creationTime!)}'
                    : 'Créateur de mode',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Portfolio', 0)),
          if (_isCurrentUserProfile) Expanded(child: _buildTabButton('Paramètres', 1)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTab == index;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_selectedTab) {
      // case 0: return _buildActivityTab();
      // case 1: return _buildCreationsTab();
      case 0: return _buildPortfolioTab();
      case 1: return _buildSettingsTab();
      default: return _buildPortfolioTab();
    }
  }

  Widget _buildActivityTab() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        final activities = [
          {'icon': Icons.person_add, 'title': 'Nouveau client', 'color': Colors.blue},
          {'icon': Icons.comment, 'title': 'Commentaire sur votre création', 'color': Colors.green},
          {'icon': Icons.share, 'title': 'Votre création a été partagée', 'color': Colors.orange},
          {'icon': Icons.favorite, 'title': 'Votre création a été aimée', 'color': Colors.red},
          {'icon': Icons.star, 'title': 'Nouvelle évaluation 5 étoiles', 'color': Colors.amber},
        ];

        final activity = activities[index % activities.length];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (activity['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  activity['icon'] as IconData,
                  color: activity['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Il y a ${index + 1} ${index == 0 ? 'heure' : 'heures'}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget _buildCreationsTab() {
  //   if (_userCreations.isEmpty) {
  //     return _buildEmptyState(
  //       icon: Icons.brush,
  //       title: 'Aucune création',
  //       subtitle: _isCurrentUserProfile
  //           ? 'Commencez à créer pour voir vos œuvres ici'
  //           : 'Ce créateur n\'a pas encore publié de créations',
  //     );
  //   }
  //
  //   return GridView.builder(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     padding: const EdgeInsets.all(24),
  //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //       crossAxisCount: 2,
  //       crossAxisSpacing: 16,
  //       mainAxisSpacing: 16,
  //       childAspectRatio: 0.8,
  //     ),
  //     itemCount: _userCreations.length,
  //     itemBuilder: (context, index) {
  //       final creation = _userCreations[index];
  //       return _buildCreationCard(creation);
  //     },
  //   );
  // }

  Widget _buildCreationCard(Map<String, dynamic> creation) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: creation['imageUrl'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    creation['title'] ?? 'Sans titre',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.red.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${creation['likes'] ?? 0}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatDate(creation['date']),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
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
    );
  }

  Widget _buildPortfolioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_competences.isNotEmpty)
            _buildPortfolioSection(
              title: 'Compétences',
              icon: Icons.star,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _competences.map((skill) => Chip(
                  label: Text(skill),
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                )).toList(),
              ),
            ),

          if (_competences.isNotEmpty) const SizedBox(height: 24),

          if (_certifications.isNotEmpty)
            _buildPortfolioSection(
              title: 'Certifications',
              icon: Icons.verified,
              child: Column(
                children: _certifications.map((certif) =>
                    _buildCertificationItem(
                      certif['title'] ?? '',
                      certif['institution'] ?? '',
                      certif['year'] ?? '',
                    ),
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCertificationItem(String title, String institution, String year) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$institution • $year',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    if (!_isCurrentUserProfile) return Container();

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSettingsSection(
            title: 'Compte',
            children: [
              _buildSettingsItem(
                icon: Icons.payment,
                title: 'Moyen de paiement',
                subtitle: _paymentMethod.isNotEmpty
                    ? (_paymentMethod == 'orange_money' ? 'Orange Money' : 'Moov Money')
                    : 'Non configuré',
                onTap: _navigateToEditProfile,
              ),
            ],
          ),

          const SizedBox(height: 24),


          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
              ),
            ),
            child: InkWell(
              onTap: _showLogoutDialog,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Se déconnecter',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEditProfileBottomSheet(),
    );
  }

  Widget _buildEditProfileBottomSheet() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Modifier le profil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: _saveProfileChanges,
                      child: Text(
                        'Sauvegarder',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildEditField('Nom', _nameController, Icons.person),
                      const SizedBox(height: 16),
                      _buildEditField('Email', _emailController, Icons.email),
                      const SizedBox(height: 16),
                      _buildEditField('Spécialité', _specialityController, Icons.work),
                      const SizedBox(height: 16),
                      _buildEditField('Site web', _websiteController, Icons.link),
                      const SizedBox(height: 16),
                      _buildEditField('Bio', _bioController, Icons.info, maxLines: 4),
                      const SizedBox(height: 32),

                      _buildSectionTitle('Compétences'),
                      _buildCompetenceInput(setState),
                      const SizedBox(height: 20),

                      _buildSectionTitle('Certifications'),
                      _buildCertificationInput(setState),
                      const SizedBox(height: 20),

                      _buildSectionTitle('Moyen de paiement'),
                      _buildPaymentInput(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: theme.colorScheme.primary),
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompetenceInput(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _competenceController,
                decoration: const InputDecoration(
                  hintText: 'Ajouter une compétence',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                if (_competenceController.text.isNotEmpty) {
                  setState(() {
                    _competences.add(_competenceController.text);
                    _competenceController.clear();
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _competences.map((competence) => Chip(
            label: Text(competence),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () {
              setState(() {
                _competences.remove(competence);
              });
            },
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCertificationInput(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _certifTitleController,
          decoration: const InputDecoration(
            labelText: 'Titre de la certification',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _certifInstitutionController,
          decoration: const InputDecoration(
            labelText: 'Établissement',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _certifYearController,
          decoration: const InputDecoration(
            labelText: 'Année d\'obtention',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_certifTitleController.text.isNotEmpty &&
                _certifInstitutionController.text.isNotEmpty) {
              setState(() {
                _certifications.add({
                  'title': _certifTitleController.text,
                  'institution': _certifInstitutionController.text,
                  'year': _certifYearController.text,
                });
                _certifTitleController.clear();
                _certifInstitutionController.clear();
                _certifYearController.clear();
              });
            }
          },
          child: const Text('Ajouter la certification'),
        ),
        const SizedBox(height: 16),
        ..._certifications.map((certif) => ListTile(
          title: Text(certif['title'] ?? ''),
          subtitle: Text('${certif['institution']} • ${certif['year']}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                _certifications.remove(certif);
              });
            },
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildPaymentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _paymentMethod.isNotEmpty ? _paymentMethod : null,
          items: const [
            DropdownMenuItem(value: 'orange_money', child: Text('Orange Money')),
            DropdownMenuItem(value: 'moov_money', child: Text('Moov Money')),
          ],
          onChanged: (value) {
            setState(() {
              _paymentMethod = value!;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Sélectionnez votre moyen de paiement',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _paymentNumberController,
          decoration: const InputDecoration(
            labelText: 'Numéro de paiement',
            hintText: 'Ex: 05 XX XX XX',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(date);
  }
}