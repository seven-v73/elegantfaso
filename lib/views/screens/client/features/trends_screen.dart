import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

class TrendScreen extends StatefulWidget {
  @override
  _TrendScreenState createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen> with TickerProviderStateMixin {
  // Firebase services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State variables
  String _selectedCategory = 'Tous';
  final List<String> _categories = ['Tous', 'Vêtements', 'Robe', 'Accessoires', 'Chaussures', 'Bijoux'];
  String? _errorMessage;
  TrendingSortType _sortType = TrendingSortType.popular;
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';

  // Pagination
  bool _hasMore = true;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastProductDoc;
  DocumentSnapshot? _lastCreationDoc;
  List<DocumentSnapshot> _allDocs = [];

  // UI state
  final Map<String, int> _currentCarouselIndices = {};
  final Map<String, Map<String, dynamic>> _userCache = {};
  late Key _likeAnimationKey = UniqueKey();

  // Design constants
  static const Color _primaryColor = Color(0xFF6C5CE7);
  static const Color _secondaryColor = Color(0xFF74B9FF);
  static const Color _accentColor = Color(0xFFE17055);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeScrollListener();
    _checkAuthAndLoad();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutBack));
  }

  void _initializeScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMoreContent();
      }
    });
  }

  Future<void> _checkAuthAndLoad() async {
    if (_auth.currentUser == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Vous devez être connecté pour voir les tendances';
          _isLoading = false;
        });
      }
      return;
    }

    await _loadInitialContent();

    if (mounted) {
      _fadeAnimationController.forward();
      _slideAnimationController.forward();
    }
  }

  Future<void> _loadInitialContent() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _allDocs.clear();
          _lastProductDoc = null;
          _lastCreationDoc = null;
          _hasMore = true;
        });
      }

      final docs = await _fetchDocuments();

      if (mounted) {
        setState(() {
          _allDocs = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des tendances';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreContent() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final newDocs = await _fetchDocuments();

      if (mounted) {
        setState(() {
          _allDocs.addAll(newDocs);
          _hasMore = newDocs.isNotEmpty;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<List<DocumentSnapshot>> _fetchDocuments() async {
    try {
      Query productsQuery = _firestore.collectionGroup('products');
      Query creationsQuery = _firestore.collection('creations');

      if (_selectedCategory != 'Tous') {
        productsQuery = productsQuery.where('category', isEqualTo: _selectedCategory);
        creationsQuery = creationsQuery.where('category', isEqualTo: _selectedCategory);
      }

      if (_searchQuery.isNotEmpty) {
        productsQuery = productsQuery.where('keywords', arrayContains: _searchQuery.toLowerCase());
        creationsQuery = creationsQuery.where('keywords', arrayContains: _searchQuery.toLowerCase());
      }

      // Pagination
      if (_lastProductDoc != null) productsQuery = productsQuery.startAfterDocument(_lastProductDoc!);
      productsQuery = productsQuery.limit(5);

      if (_lastCreationDoc != null) creationsQuery = creationsQuery.startAfterDocument(_lastCreationDoc!);
      creationsQuery = creationsQuery.limit(5);

      final productsSnapshot = await productsQuery.get();
      final creationsSnapshot = await creationsQuery.get();

      // Update last documents
      if (productsSnapshot.docs.isNotEmpty) _lastProductDoc = productsSnapshot.docs.last;
      if (creationsSnapshot.docs.isNotEmpty) _lastCreationDoc = creationsSnapshot.docs.last;

      final allDocs = [
        ...productsSnapshot.docs,
        ...creationsSnapshot.docs,
      ];
      return _sortDocuments(allDocs);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Erreur réseau. Veuillez réessayer');
      return [];
    }
  }

  List<DocumentSnapshot> _sortDocuments(List<DocumentSnapshot> docs) {
    docs.sort((a, b) {
      try {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;

        switch (_sortType) {
          case TrendingSortType.popular:
            final likesA = (dataA['likes'] as List?)?.length ?? 0;
            final likesB = (dataB['likes'] as List?)?.length ?? 0;
            return likesB.compareTo(likesA);

          case TrendingSortType.recent:
            final dateA = (dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final dateB = (dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return dateB.compareTo(dateA);

          case TrendingSortType.mostCommented:
          // CORRECTION: Gestion des commentaires comme entier
            final commentsA = (dataA['comments'] as int?) ?? 0;
            final commentsB = (dataB['comments'] as int?) ?? 0;
            return commentsB.compareTo(commentsA);

          case TrendingSortType.priceAsc:
            final priceA = (dataA['price'] ?? 0).toDouble();
            final priceB = (dataB['price'] ?? 0).toDouble();
            return priceA.compareTo(priceB);

          case TrendingSortType.priceDesc:
            final priceA = (dataA['price'] ?? 0).toDouble();
            final priceB = (dataB['price'] ?? 0).toDouble();
            return priceB.compareTo(priceA);
        }
      } catch (e) {
        return 0;
      }
    });

    return docs;
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          if (_isLoading) _buildLoadingSliver(),
          if (_errorMessage != null && !_isLoading) _buildErrorSliver(),
          if (!_isLoading && _errorMessage == null) ...[
            _buildCategoryFilterSliver(),
            _buildSortFilterSliver(),
            _buildContentSliver(),
          ],
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: _cardColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primaryColor, _secondaryColor],
            ),
          ),
        ),
        title: AnimatedOpacity(
          opacity: _fadeAnimationController.value,
          duration: const Duration(milliseconds: 300),
          child: const Text(
            'Tendances',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
      ),
      actions: [
        AnimatedOpacity(
          opacity: _fadeAnimationController.value,
          duration: const Duration(milliseconds: 300),
          child: IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _loadInitialContent();
                }
              });
            },
          ),
        ),
      ],
      bottom: _isSearching ? _buildSearchBar() : null,
    );
  }

  PreferredSizeWidget _buildSearchBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Rechercher dans les tendances...',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onSubmitted: (value) {
            setState(() => _searchQuery = value.trim());
            _loadInitialContent();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Chargement des tendances...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: _accentColor),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 18,
                color: _accentColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkAuthAndLoad,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilterSliver() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: Container(
              height: 60,
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedCategory = category);
                          _loadInitialContent();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(colors: [_primaryColor, _secondaryColor])
                                : null,
                            color: isSelected ? null : _cardColor,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: (isSelected ? _primaryColor : Colors.grey).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortFilterSliver() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_allDocs.length} ${_allDocs.length > 1 ? 'éléments' : 'élément'}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButton<TrendingSortType>(
                      value: _sortType,
                      icon: const Icon(Icons.arrow_drop_down, color: _primaryColor),
                      iconSize: 24,
                      elevation: 8,
                      style: const TextStyle(color: _primaryColor, fontSize: 14),
                      underline: const SizedBox(),
                      onChanged: (TrendingSortType? newValue) {
                        if (newValue != null) {
                          HapticFeedback.lightImpact();
                          setState(() => _sortType = newValue);
                          _loadInitialContent();
                        }
                      },
                      items: TrendingSortType.values.map((sortType) {
                        return DropdownMenuItem<TrendingSortType>(
                          value: sortType,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(sortType.icon, size: 16, color: _primaryColor),
                              const SizedBox(width: 6),
                              Text(sortType.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentSliver() {
    if (_allDocs.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'Aucun contenu disponible',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Soyez le premier à publier dans cette catégorie !',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          if (index < _allDocs.length) {
            return AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildTrendingItem(_allDocs[index], index),
                );
              },
            );
          } else if (_isLoadingMore) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              ),
            );
          }
          return null;
        },
        childCount: _allDocs.length + (_isLoadingMore ? 1 : 0),
      ),
    );
  }

  Widget _buildTrendingItem(DocumentSnapshot doc, int index) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final isCreation = doc.reference.path.contains('creations');

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.lightImpact();
              _showItemDetails(doc, isCreation);
            },
            child: Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemHeader(data, isCreation),
                  _buildItemContent(data, isCreation, doc.id),
                  _buildItemActions(doc, isCreation),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return _buildErrorItem(e, index);
    }
  }

  Widget _buildErrorItem(dynamic error, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 32),
          const SizedBox(height: 12),
          const Text(
            'Erreur de chargement de l\'élément',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemHeader(Map<String, dynamic> data, bool isCreation) {
    String? creatorId;
    bool isBoutique = false;

    if (isCreation) {
      creatorId = data['createurId']?.toString();
    } else {
      if (data['boutiqueId'] != null && data['boutiqueId'].toString().isNotEmpty) {
        creatorId = data['boutiqueId']?.toString();
        isBoutique = true;
      } else {
        creatorId = data['creatorId']?.toString();
      }
    }

    if (creatorId == null || creatorId.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Créateur inconnu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserInfo(creatorId),
      builder: (context, snapshot) {
        String userName = isBoutique ? 'Boutique' : 'Créateur';
        String? userAvatar;

        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final userData = snapshot.data!;

          if (isBoutique) {
            userName = userData['name'] ?? userData['shopName'] ?? 'Boutique';
          } else {
            userName = userData['name'] ?? userData['username'] ?? 'Créateur';
          }

          userAvatar = userData['photoUrl'] ??
              userData['photolr1'] ??
              userData['avatar'] ??
              userData['profileImage'];
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'avatar_$creatorId',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: userAvatar != null && userAvatar.isNotEmpty
                      ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: userAvatar,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      memCacheWidth: 200,
                      memCacheHeight: 200,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        isBoutique ? Icons.store : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                  )
                      : Icon(
                    isBoutique ? Icons.store : Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isBoutique
                                ? _primaryColor.withOpacity(0.1)
                                : _secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isBoutique ? 'Boutique' : 'Créateur',
                            style: TextStyle(
                              color: isBoutique ? _primaryColor : _secondaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(data['createdAt']),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'report') _reportContent(data);
                },
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag, size: 16, color: _accentColor),
                        SizedBox(width: 8),
                        Text('Signaler'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserInfo(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId];

    try {
      final snapshot = await _firestore.collection('users').doc(userId).get();
      if (snapshot.exists) {
        final userData = snapshot.data()!;
        _userCache[userId] = userData;
        return userData;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Widget _buildItemContent(Map<String, dynamic> data, bool isCreation, String docId) {
    List<dynamic> images = [];

    if (isCreation) {
      images = data['images'] ?? [];
    } else {
      if (data['images'] != null && data['images'] is List) {
        images = data['images'];
      } else if (data['imageUrl'] != null) {
        images = [data['imageUrl']];
      }
    }

    _currentCarouselIndices.putIfAbsent(docId, () => 0);
    final currentIndex = _currentCarouselIndices[docId]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data['description'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              data['description'],
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        if (images.isNotEmpty)
          Container(
            height: 320,
            child: Stack(
              children: [
                CarouselSlider.builder(
                  itemCount: images.length,
                  options: CarouselOptions(
                    height: 320,
                    viewportFraction: 1.0,
                    autoPlay: images.length > 1,
                    autoPlayInterval: const Duration(seconds: 4),
                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                    autoPlayCurve: Curves.easeInOut,
                    onPageChanged: (index, reason) {
                      setState(() => _currentCarouselIndices[docId] = index);
                    },
                  ),
                  itemBuilder: (context, index, realIndex) {
                    return Hero(
                      tag: 'image_${images[index]}_$docId',
                      child: Container(
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: images[index],
                            fit: BoxFit.cover,
                            memCacheWidth: 800,
                            memCacheHeight: 800,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 60, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Image non disponible',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: images.asMap().entries.map((entry) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: currentIndex == entry.key ? 24.0 : 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: currentIndex == entry.key
                                ? _primaryColor
                                : Colors.white.withOpacity(0.6),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

        // Price and category info
        if (data['price'] != null || data['category'] != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (data['price'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${data['price']} FCFA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (data['category'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accentColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      data['category'],
                      style: TextStyle(
                        color: _accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildItemActions(DocumentSnapshot doc, bool isCreation) {
    final docRef = doc.reference;

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingActions();

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final currentUserId = _auth.currentUser?.uid;
        final likes = List<String>.from(data['likes'] ?? []);
        final isLiked = currentUserId != null && likes.contains(currentUserId);
        final likesCount = likes.length;

        // CORRECTION: Gestion des commentaires comme entier
        final commentsCount = (data['comments'] as int?) ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLikeButton(docRef, isLiked, likesCount),
              _buildActionButton(
                icon: Icons.comment_outlined,
                label: commentsCount.toString(),
                color: Colors.grey[600]!,
                onPressed: () => _showComments(doc, isCreation),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLikeButton(DocumentReference docRef, bool isLiked, int likesCount) {
    return GestureDetector(
      onTap: () => _toggleLike(docRef),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: _likeAnimationKey,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.grey[600],
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                likesCount.toString(),
                style: TextStyle(
                  color: isLiked ? Colors.red : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(width: 60, height: 24, color: Colors.white),
          ),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(width: 60, height: 24, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Date inconnue';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Date inconnue';
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return DateFormat('dd/MM/yyyy').format(date);
      } else if (difference.inDays > 0) {
        return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} min';
      } else {
        return 'À l\'instant';
      }
    } catch (e) {
      return 'Date inconnue';
    }
  }

  // Action methods
  Future<void> _toggleLike(DocumentReference docRef) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Animation feedback
      HapticFeedback.lightImpact();
      setState(() => _likeAnimationKey = ValueKey(DateTime.now()));

      final docSnapshot = await docRef.get();
      final data = docSnapshot.data() as Map<String, dynamic>;
      final likes = List<String>.from(data['likes'] ?? []);
      final isLiked = likes.contains(currentUserId);

      if (isLiked) {
        likes.remove(currentUserId);
      } else {
        likes.add(currentUserId);
      }

      await docRef.update({'likes': likes});
    } catch (e) {
      if (mounted) _showErrorSnackBar('Erreur lors de la mise à jour du like');
    }
  }

  void _showComments(DocumentSnapshot doc, bool isCreation) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(
        doc: doc,
        currentUserId: currentUserId,
        firestore: _firestore,
        primaryColor: _primaryColor,
        secondaryColor: _secondaryColor,
        onCommentAdded: _loadInitialContent,
      ),
    );
  }

  void _showItemDetails(DocumentSnapshot doc, bool isCreation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildItemDetailsSheet(doc, isCreation),
    );
  }

  Widget _buildItemDetailsSheet(DocumentSnapshot doc, bool isCreation) {
    final data = doc.data() as Map<String, dynamic>;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Détails',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['description'] != null) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (data['price'] != null) ...[
                    const Text(
                      'Prix',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${data['price']} FCFA',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (data['category'] != null) ...[
                    const Text(
                      'Catégorie',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accentColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        data['category'],
                        style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reportContent(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler le contenu'),
        content: const Text('Voulez-vous signaler ce contenu comme inapproprié ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) _showSuccessSnackBar('Contenu signalé');
            },
            child: const Text('Signaler', style: TextStyle(color: Color(0xFFE17055))),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _accentColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final DocumentSnapshot doc;
  final String currentUserId;
  final FirebaseFirestore firestore;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onCommentAdded;

  const CommentsSheet({
    required this.doc,
    required this.currentUserId,
    required this.firestore,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onCommentAdded,
  });

  @override
  _CommentsSheetState createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  late Stream<QuerySnapshot> _commentsStream;
  bool _isSendingComment = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Nouvelle structure de commentaires
    _commentsStream = widget.doc.reference
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildCommentsList()),
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<QuerySnapshot>(
      stream: _commentsStream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Commentaires ($count)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _commentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingComments();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoCommentsUI();
        }

        final comments = snapshot.data!.docs;

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            return _buildCommentItem(comments[index]);
          },
        );
      },
    );
  }

  Widget _buildLoadingComments() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: const CircleAvatar(radius: 20, backgroundColor: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 16,
                        width: 100,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 40,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoCommentsUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.comment_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucun commentaire',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Soyez le premier à commenter!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(DocumentSnapshot commentDoc) {
    final comment = commentDoc.data() as Map<String, dynamic>;

    return FutureBuilder<DocumentSnapshot>(
      future: widget.firestore.collection('users').doc(comment['userId']).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildCommentSkeleton();
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return _buildUnknownUserComment(comment);
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final userName = userData['name'] ?? userData['username'] ?? 'Utilisateur';
        final avatarUrl = userData['photoUrl'] ?? userData['avatar'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: avatarUrl != null
                    ? CachedNetworkImageProvider(avatarUrl) as ImageProvider
                    : null,
                backgroundColor: widget.primaryColor,
                child: avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment['text'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCommentDate(comment['timestamp']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: const CircleAvatar(radius: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 100,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 40,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownUserComment(Map<String, dynamic> comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Utilisateur inconnu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment['text'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCommentDate(comment['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              minLines: 1,
              maxLines: 3,
              style: const TextStyle(color: Colors.black), // Texte noir
              decoration: InputDecoration(
                hintText: 'Ajouter un commentaire...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                suffixIcon: _isSendingComment
                    ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                  ),
                )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.primaryColor, widget.secondaryColor],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _addComment(_commentController.text.trim()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment(String text) async {
    if (text.isEmpty || _isSendingComment) return;
    setState(() => _isSendingComment = true);

    try {
      if (widget.currentUserId.isEmpty) throw 'Session utilisateur expirée';

      final userDoc = await widget.firestore.collection('users').doc(widget.currentUserId).get();
      if (!userDoc.exists) throw 'Utilisateur non trouvé';

      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? userData['username'] ?? 'Utilisateur';

      // Ajouter le commentaire à la sous-collection
      await widget.doc.reference.collection('comments').add({
        'userId': widget.currentUserId,
        'userName': userName,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Mettre à jour le compteur de commentaires dans le document principal
      await widget.doc.reference.update({
        'comments': FieldValue.increment(1)
      });

      _commentController.clear();
      FocusScope.of(context).unfocus();
      widget.onCommentAdded();

      // Scroll vers le bas après l'ajout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commentaire ajouté'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.message ?? "Problème avec la base de données"}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => _isSendingComment = false);
    }
  }

  String _formatCommentDate(dynamic timestamp) {
    if (timestamp == null) return 'À l\'instant';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Date inconnue';
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return DateFormat('dd/MM/yyyy').format(date);
      } else if (difference.inDays > 0) {
        return '${difference.inDays} j';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} min';
      } else {
        return 'À l\'instant';
      }
    } catch (e) {
      return 'Date inconnue';
    }
  }
}

enum TrendingSortType {
  popular,
  recent,
  mostCommented,
  priceAsc,
  priceDesc,
}

extension TrendingSortTypeExtension on TrendingSortType {
  String get displayName {
    switch (this) {
      case TrendingSortType.popular: return 'Plus populaire';
      case TrendingSortType.recent: return 'Plus récent';
      case TrendingSortType.mostCommented: return 'Plus commenté';
      case TrendingSortType.priceAsc: return 'Prix croissant';
      case TrendingSortType.priceDesc: return 'Prix décroissant';
    }
  }

  IconData get icon {
    switch (this) {
      case TrendingSortType.popular: return Icons.trending_up;
      case TrendingSortType.recent: return Icons.access_time;
      case TrendingSortType.mostCommented: return Icons.comment;
      case TrendingSortType.priceAsc: return Icons.arrow_upward;
      case TrendingSortType.priceDesc: return Icons.arrow_downward;
    }
  }
}