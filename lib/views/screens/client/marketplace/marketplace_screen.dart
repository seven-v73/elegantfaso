import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'follow_service.dart';
import 'creator_profile.dart';
import '../../messages/chat_screen.dart';
import '../../messages/user_model.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FollowService _followService = FollowService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final PageController _carouselController = PageController();
  Timer? _debounceTimer;
  Timer? _carouselTimer;

  String _selectedCategory = 'Tous';
  String _searchQuery = '';
  bool _isLoading = true;
  UserModel? _currentUser;
  List<String> _looksImageUrls = [];
  bool _promoLoading = false;
  bool _promoError = false;
  int _currentCarouselIndex = 0;
  final Map<String, bool> _isFollowingMap = {};
  StreamSubscription<DocumentSnapshot>? _currentUserSubscription;
  List<QueryDocumentSnapshot> _allCreators = [];
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadLooksImages();
    _initCurrentUserStream();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {});
  }

  void _startAutoCarousel() {
    _carouselTimer?.cancel();
    if (_looksImageUrls.length > 1) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_looksImageUrls.isEmpty) return;

        final nextIndex = (_currentCarouselIndex + 1) % _looksImageUrls.length;
        _carouselController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _loadLooksImages() async {
    setState(() {
      _promoLoading = true;
      _promoError = false;
    });

    try {
      final looksRef = _storage.ref().child('looks');
      final result = await looksRef.listAll();

      // Trier par date de modification (le plus récent en premier)
      final sortedItems = await _sortItemsByDate(result.items);

      final urls = await Future.wait(
          sortedItems.map((ref) => ref.getDownloadURL()).toList()
      );

      setState(() => _looksImageUrls = urls);

      // Démarrer l'animation automatique
      _startAutoCarousel();
    } catch (e) {
      debugPrint('Erreur de chargement des looks: $e');
      setState(() => _promoError = true);
    } finally {
      setState(() => _promoLoading = false);
    }
  }

  Future<List<Reference>> _sortItemsByDate(List<Reference> items) async {
    final itemsWithMetadata = await Future.wait(
        items.map((ref) async {
          try {
            final metadata = await ref.getMetadata();
            return {
              'ref': ref,
              'updated': metadata.updated ?? DateTime.now()
            };
          } catch (e) {
            debugPrint('Erreur de récupération des métadonnées pour ${ref.fullPath}: $e');
            return {'ref': ref, 'updated': DateTime.now()};
          }
        })
    );

    itemsWithMetadata.sort((a, b) =>
        (b['updated'] as DateTime).compareTo(a['updated'] as DateTime));

    return itemsWithMetadata.map((item) => item['ref'] as Reference).toList();
  }

  void _initCurrentUserStream() {
    final user = _auth.currentUser;
    if (user != null) {
      _currentUserSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final userData = snapshot.data()!;
          final currentUser = UserModel.fromMap(userData, docId: snapshot.id);
          setState(() {
            _currentUser = currentUser;
            // Update following map
            _isFollowingMap.clear();
            for (final id in currentUser.following) {
              _isFollowingMap[id] = true;
            }
          });
        } else {
          _createUserDocument(user);
        }
        if (_isLoading) {
          setState(() => _isLoading = false);
        }
      }, onError: (e) {
        debugPrint('User stream error: $e');
        setState(() => _isLoading = false);
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      final newUser = {
        'id': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? 'Utilisateur',
        'role': 'client',
        'following': [],
        'followers': [],
        'followingCount': 0,
        'followersCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rating': 0.0,
        'isVerified': false,
      };

      await _firestore.collection('users').doc(user.uid).set(newUser);
    } catch (e) {
      debugPrint('Erreur création utilisateur: $e');
    }
  }

  Future<void> _toggleFollow(String creatorId) async {
    if (_currentUser == null || _currentUser!.id.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connectez-vous pour suivre')),
        );
      }
      return;
    }

    final isCurrentlyFollowing = _isFollowingMap[creatorId] ?? false;

    // Optimistic UI update
    setState(() => _isFollowingMap[creatorId] = !isCurrentlyFollowing);

    try {
      await _followService.toggleFollow(
        followerId: _currentUser!.id,
        followedId: creatorId,
      );
    } catch (e) {
      // Revert on error
      setState(() => _isFollowingMap[creatorId] = isCurrentlyFollowing);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().split('\n').first}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      debugPrint('Erreur follow: $e');
    }
  }

  void _navigateToChat(BuildContext context, String creatorId, String creatorName) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour discuter')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        ),
      ),
    );

    try {
      final creatorDoc = await _firestore.collection('users').doc(creatorId).get();

      UserModel creator;
      if (creatorDoc.exists) {
        creator = UserModel.fromMap(creatorDoc.data()! as Map<String, dynamic>, docId: creatorDoc.id);
      } else {
        creator = UserModel(
          id: creatorId,
          displayName: creatorName,
          email: '',
          role: 'creator',
          photoUrl: null,
          following: [],
          followers: [],
          followingCount: 0,
          followersCount: 0,
          phone: null,
          specialty: null,
          location: null,
          bio: null,
          boutiqueName: null,
          boutiqueAddress: null,
          boutiqueDescription: null,
          productsCount: 0,
          isOnline: false,
          lastSeen: DateTime.now(),
          fcmToken: '',
          preferences: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          roles: [],
        );
      }

      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              utilisateurCourant: _currentUser!,
              autreUtilisateur: creator,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  List<QueryDocumentSnapshot> get _filteredCreators {
    return _allCreators.where((creator) {
      final data = creator.data() as Map<String, dynamic>;
      final role = data['role']?.toString() ?? '';

      // Role filter
      final validRole = role == 'boutique' || role == 'createur';
      final categoryMatch = _selectedCategory == 'Tous' ||
          (_selectedCategory == 'Créateurs' && role == 'createur') ||
          (_selectedCategory == 'Boutiques' && role == 'boutique');

      // Search filter
      final name = data['displayName']?.toString().toLowerCase() ??
          data['name']?.toString().toLowerCase() ?? '';
      final specialty = data['specialty']?.toString().toLowerCase() ?? '';
      final boutiqueName = data['boutiqueName']?.toString().toLowerCase() ?? '';
      final searchMatch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          specialty.contains(_searchQuery.toLowerCase()) ||
          boutiqueName.contains(_searchQuery.toLowerCase());

      return validRole && categoryMatch && searchMatch;
    }).toList();
  }

  Future<void> _loadMoreCreators() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['createur', 'boutique'])
          .orderBy('followersCount', descending: true)
          .startAfterDocument(_allCreators.last)
          .limit(_pageSize)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
        return;
      }

      setState(() {
        _allCreators.addAll(snapshot.docs);
        _currentPage++;
        _hasMore = snapshot.docs.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Erreur de chargement: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  // Fonction pour afficher une image en plein écran
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Elegant',
                style: TextStyle(
                  color: Color(0xFFD2691E),
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Faso',
                style: TextStyle(
                  color: Color(0xFF212529),
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
            onPressed: () => _showSearchSheet(context),
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoader()
          : RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _allCreators.clear();
            _currentPage = 0;
            _hasMore = true;
            _looksImageUrls.clear();
          });
          await Future.wait([
            _loadMoreCreators(),
            _loadLooksImages(),
          ]);
        },
        child: Column(
          children: [
            _buildSearchBar(),
            if (_looksImageUrls.isNotEmpty || _promoLoading || _promoError)
              _buildPromoCarousel(context),
            _buildCategorySelector(),
            const SizedBox(height: 8),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 100,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            height: 12,
                            width: 30,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 12,
                            width: 30,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher créateurs, boutiques...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() => _searchQuery = '');
              _searchController.clear();
            },
          )
              : null,
        ),
        onChanged: (value) {
          if (_debounceTimer?.isActive ?? false) {
            _debounceTimer?.cancel();
          }
          _debounceTimer = Timer(const Duration(milliseconds: 300), () {
            setState(() => _searchQuery = value);
          });
        },
      ),
    );
  }

  Widget _buildPromoCarousel(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Augmentation de la hauteur pour mieux voir les images
    final height = screenWidth > 600 ? 280.0 : 220.0;

    if (_promoLoading) {
      return SizedBox(
        height: height,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      );
    }

    if (_promoError || _looksImageUrls.isEmpty) {
      return Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Aucun look disponible',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadLooksImages,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD2691E),
              ),
              child: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _carouselController,
                  itemCount: _looksImageUrls.length,
                  onPageChanged: (index) {
                    setState(() => _currentCarouselIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _showFullScreenImage(context, _looksImageUrls[index]),
                      child: Hero(
                        tag: 'look-image-$index',
                        child: CachedNetworkImage(
                          imageUrl: _looksImageUrls[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _looksImageUrls.length,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentCarouselIndex == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentCarouselIndex == index
                              ? const Color(0xFFD2691E)
                              : Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentCarouselIndex + 1}/${_looksImageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Découvrir la collection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD2691E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 3,
            ),
            onPressed: () {
              if (_looksImageUrls.isNotEmpty) {
                _showFullScreenImage(context, _looksImageUrls[_currentCarouselIndex]);
              }
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final categories = ['Tous', 'Créateurs', 'Boutiques'];
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          return ChoiceChip(
            label: Text(category),
            selected: _selectedCategory == category,
            onSelected: (selected) => setState(() {
              _selectedCategory = selected ? category : 'Tous';
            }),
            selectedColor: const Color(0xFFD2691E),
            labelStyle: TextStyle(
              color: _selectedCategory == category
                  ? Colors.white
                  : const Color(0xFF495057),
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: _selectedCategory == category
                    ? const Color(0xFFD2691E)
                    : const Color(0xFFE9ECEF),
                width: 1.5,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_allCreators.isEmpty) {
      return StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('role', whereIn: ['createur', 'boutique'])
            .orderBy('followersCount', descending: true)
            .limit(_pageSize)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          _allCreators = snapshot.data!.docs;
          _hasMore = snapshot.data!.docs.length == _pageSize;

          return _buildCreatorGrid();
        },
      );
    }

    return _buildCreatorGrid();
  }

  Widget _buildCreatorGrid() {
    final creators = _filteredCreators;

    if (creators.isEmpty) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollEndNotification &&
            _scrollController.position.extentAfter < 500 &&
            _hasMore &&
            !_isLoadingMore) {
          _loadMoreCreators();
        }
        return false;
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: creators.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= creators.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final creator = creators[index];
          final data = creator.data() as Map<String, dynamic>;
          return _buildCreatorCard(creator, data);
        },
      ),
    );
  }

  Widget _buildCreatorCard(QueryDocumentSnapshot creator, Map<String, dynamic> data) {
    final id = creator.id;
    final name = data['displayName'] ?? data['name'] ?? 'Utilisateur';
    final specialty = data['specialty'] ?? 'Mode Africaine';
    final rating = (data['rating'] ?? 4.5).toDouble();
    final role = data['role'] ?? 'createur';
    final isBoutique = role == 'boutique';
    final isFollowing = _isFollowingMap[id] ?? false;

    String? rawPhotoUrl = data['photoUrl'] ?? data['imageUrl'];
    String photoUrl = 'https://firebasestorage.googleapis.com/v0/b/fasostyle-1bb74.appspot.com/o/background%2Fboutique%2Fprofile_bkg.jpg?alt=media&token=e0199e40-14ce-44da-a31d-1fab0baae547';

    if (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(rawPhotoUrl);
        if (uri.isAbsolute) {
          photoUrl = rawPhotoUrl;
        }
      } catch (e) {
        debugPrint('Erreur parsing URL: $e');
      }
    }

    return GestureDetector(
      onTap: () => _navigateToCreatorProfile(context, creator),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.person, size: 40)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.person, size: 40)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isBoutique)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9F5FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Boutique',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty,
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people, color: Theme.of(context).primaryColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            NumberFormat.compact().format(data['followersCount'] ?? 0),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.star, color: Colors.amber[600], size: 14),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (data['isVerified'] == true)
                            Icon(Icons.verified, color: Theme.of(context).primaryColor, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _toggleFollow(id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isFollowing
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    color: isFollowing ? const Color(0xFFD2691E) : Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _navigateToChat(context, id, name),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              _getEmptyStateText(),
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF212529),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Aucun résultat ne correspond à vos critères de recherche',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6C757D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD2691E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
                shadowColor: const Color(0xFFD2691E).withOpacity(0.3),
              ),
              onPressed: () => setState(() {
                _selectedCategory = 'Tous';
                _searchQuery = '';
                _searchController.clear();
              }),
              child: const Text(
                'Réinitialiser les filtres',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyStateText() {
    if (_searchQuery.isNotEmpty) {
      return 'Aucun résultat pour "$_searchQuery"';
    }
    switch (_selectedCategory) {
      case 'Créateurs':
        return 'Aucun créateur disponible';
      case 'Boutiques':
        return 'Aucune boutique disponible';
      default:
        return 'Aucun contenu disponible';
    }
  }

  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher créateurs, boutiques...',
                prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 20),
            const Text(
              'Filtres avancés',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212529),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildFilterChip('Top créateurs'),
                _buildFilterChip('Nouveautés'),
                _buildFilterChip('Vérifiés'),
                _buildFilterChip('Proche de moi'),
                _buildFilterChip('Promotions'),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }


  Widget _buildFilterChip(String label) {
    return FilterChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 14),
      ),
      onSelected: (selected) {},
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFF5E9DB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE9ECEF)),
      ),
      labelStyle: const TextStyle(color: Color(0xFF495057)),
    );
  }

  void _navigateToCreatorProfile(
      BuildContext context, QueryDocumentSnapshot creator) {
    final userId = creator.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatorProfileScreen(
          userId: userId,
          isFollowing: _isFollowingMap[userId] ?? false,
          onFollowToggled: (creatorId) => _toggleFollow(creatorId),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentUserSubscription?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }
}