import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../messages/chat_screen.dart';
import '../../messages/user_model.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String userId;
  final bool isFollowing;
  final Future<void> Function(String) onFollowToggled;

  const CreatorProfileScreen({
    super.key,
    required this.userId,
    required this.isFollowing,
    required this.onFollowToggled,
  });

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _scrollController = ScrollController();
  int _selectedTabIndex = 0;
  bool _isUpdating = false;
  UserModel? _userModel;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.userId).get();

      if (doc.exists) {
        setState(() {
          _userModel = UserModel.fromDocument(doc);
        });
      }
    } catch (e) {
      debugPrint('Erreur de chargement: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      await widget.onFollowToggled(widget.userId);
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      debugPrint('Erreur de mise à jour: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _startChat(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour discuter')),
      );
      return;
    }

    if (_userModel == null) return;

    try {
      final clientDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      UserModel clientUser = UserModel.fromDocument(clientDoc);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            utilisateurCourant: clientUser,
            autreUtilisateur: _userModel!,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Erreur lors du démarrage du chat : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Une erreur est survenue.')),
      );
    }
  }

  void _navigateToAppointmentScreen(BuildContext context) {
    if (_userModel == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentScreen(
          creatorId: widget.userId,
          creatorName: _userModel!.mainName,
          creatorPhoto: _userModel!.safePhotoUrl,
          creatorRole: _userModel!.role,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _userModel == null
            ? _buildLoadingState()
            : _buildProfileContent(context),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    final role = _userModel!.role;
    final isBoutique = role == 'boutique';
    final creatorName = _userModel!.mainName;
    final specialty = _userModel!.specialty ??
        (isBoutique ? 'Articles divers' : 'Mode Africaine');
    final photoUrl = _userModel!.safePhotoUrl;
    final followersCount = _userModel!.followersCount;
    final productsCount = _userModel!.productsCount;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.share, color: Colors.white, size: 24),
              ),
              onPressed: () {},
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildProfileHeader(photoUrl),
            title: Text(
              creatorName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
            ),
            centerTitle: true,
            titlePadding: const EdgeInsets.only(bottom: 16),
          ),
        ),

        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 30,
                  spreadRadius: 10,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              creatorName,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              specialty,
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.grey[600],
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isBoutique && _userModel!.boutiqueAddress != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text(
                                      _userModel!.boutiqueAddress!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildFollowButton(),
                    ],
                  ),

                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[50]!,
                          Colors.grey[100]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          value: NumberFormat.compact().format(followersCount),
                          label: 'Abonnés',
                          icon: Icons.people_outline,
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          value: NumberFormat.compact().format(productsCount),
                          label: 'Produits',
                          icon: Icons.shopping_bag_outlined,
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          value: _userModel!.isOnline ? 'En ligne' : 'Hors ligne',
                          label: 'Statut',
                          icon: _userModel!.isOnline ? Icons.circle : Icons.circle_outlined,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  _buildActionButtons(context, isBoutique),

                  const SizedBox(height: 32),
                  _buildTabBar(),
                ],
              ),
            ),
          ),
        ),

        _buildTabContent(_userModel!),
      ],
    );
  }

  Widget _buildProfileHeader(String photoUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (photoUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[200]!,
                    Colors.grey[300]!,
                  ],
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.person, size: 80, color: Colors.grey)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[200]!,
                  Colors.grey[300]!,
                ],
              ),
            ),
            child: const Center(
              child: Icon(Icons.person, size: 100, color: Colors.white),
            ),
          ),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: const [0.0, 0.5, 0.8],
              colors: [
                Colors.black.withOpacity(0.85),
                Colors.black.withOpacity(0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: _isFollowing
            ? null
            : [
          BoxShadow(
            color: const Color(0xFFD2691E).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: _isUpdating ? null : _toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFollowing
              ? Colors.grey[50]
              : const Color(0xFFD2691E),
          foregroundColor: _isFollowing ? Colors.grey[700] : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: _isFollowing
                ? BorderSide(color: Colors.grey[300]!, width: 1.5)
                : BorderSide.none,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _isUpdating
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isFollowing ? Icons.check_circle : Icons.add_circle,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isFollowing ? 'Abonné' : 'S\'abonner',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    IconData? icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFFD2691E),
                ),
              ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 36,
      width: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.grey[400]!,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isBoutique) {
    final user = _userModel;
    if (user == null) return const SizedBox();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[200]!,
                      Colors.grey[100]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _startChat(context),
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    size: 22,
                    color: Colors.grey[800],
                  ),
                  label: Text(
                    'Discuter',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            if (isBoutique) ...[
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFD2691E),
                        Color(0xFFA0522D),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFD2691E).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 22,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Boutique',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),

        const SizedBox(height: 20),

        // Bouton "Prendre rendez-vous"
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4CAF50),
                Color(0xFF2E7D32),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _navigateToAppointmentScreen(context),
            icon: const Icon(
              Icons.calendar_today,
              size: 22,
              color: Colors.white,
            ),
            label: Text(
              isBoutique ? 'Visiter la boutique' : 'Prendre rendez-vous',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Produits', 'À propos', 'Avis'];
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: tabs.map((tab) {
          final index = tabs.indexOf(tab);
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  tab,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : Colors.grey[700],
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(UserModel userModel) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildProductsTab();
      case 1:
        return _buildAboutTab(userModel);
      case 2:
        return _buildReviewsTab();
      default:
        return _buildProductsTab();
    }
  }

  Widget _buildProductsTab() {
    final isBoutique = _userModel?.role == 'boutique';

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('products')
          .where('creatorId', isEqualTo: widget.userId)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Erreur de charement: ${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildProductShimmer(),
                childCount: 4,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                children: [
                  Icon(Icons.inventory_2, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 24),
                  Text(
                    isBoutique
                        ? 'Boutique vide'
                        : 'Aucun produit disponible',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      isBoutique
                          ? 'Cette boutique n\'a pas encore ajouté de produits'
                          : 'Ce créateur n\'a pas encore ajouté de produits',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final products = snapshot.data!.docs;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final product = products[index].data() as Map<String, dynamic>;
                return ClothingCard(
                  title: product['title']?.toString() ?? 'Sans titre',
                  price: _parseProductPrice(product['price']),
                  designer:
                  product['designer']?.toString() ?? 'Designer inconnu',
                  imageUrl: product['imageUrl']?.toString() ?? '',
                  rating: (product['rating']?.toDouble() ?? 0.0),
                );
              },
              childCount: products.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
            ),
          ),
        );
      },
    );
  }

  double _parseProductPrice(dynamic priceValue) {
    if (priceValue == null) return 0.0;
    if (priceValue is double) return priceValue;
    if (priceValue is int) return priceValue.toDouble();
    if (priceValue is String) return double.tryParse(priceValue) ?? 0.0;
    return 0.0;
  }

  Widget _buildProductShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 0,
              maxHeight: constraints.maxHeight,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 150,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 18,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                          Container(
                            height: 16,
                            width: constraints.maxWidth * 0.4,
                            color: Colors.white,
                          ),
                          Container(
                            height: 22,
                            width: constraints.maxWidth * 0.3,
                            color: Colors.white,
                          ),
                        ],
                      ),
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

  Widget _buildAboutTab(UserModel userModel) {
    final isBoutique = userModel.role == 'boutique';
    final description = userModel.bio ?? userModel.boutiqueDescription ??
        '${isBoutique ? 'Boutique' : 'Créateur'} spécialisé dans ${userModel.specialty ?? 'la mode africaine'}.';

    final location = isBoutique
        ? userModel.boutiqueAddress ?? userModel.location ?? ''
        : userModel.location ?? '';

    final phone = userModel.phone ?? '';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Description'),
            const SizedBox(height: 16),
            _buildSectionContent(description),

            if (location.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildSectionHeader(
                  isBoutique ? 'Adresse de la boutique' : 'Localisation'
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.location_on_outlined,
                content: location,
              ),
            ],

            if (phone.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildSectionHeader('Contact'),
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.phone_outlined,
                content: phone,
              ),
            ],

            if (userModel.email != null && userModel.email!.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildSectionHeader('Email'),
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.email_outlined,
                content: userModel.email!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSectionContent(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[700],
        height: 1.6,
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String content}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 18),
          Flexible(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.reviews,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Section Avis en développement',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Nous travaillons sur une expérience d\'avis exceptionnelle qui sera bientôt disponible',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClothingCard extends StatelessWidget {
  final String title;
  final double price;
  final String designer;
  final String imageUrl;
  final double rating;

  const ClothingCard({
    super.key,
    required this.title,
    required this.price,
    required this.designer,
    required this.imageUrl,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  height: 180,
                  color: Colors.grey[100],
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 180,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber[600], size: 18),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  designer,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${NumberFormat.currency(symbol: 'FCFA', decimalDigits: 0).format(price)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Color(0xFFD2691E),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Voir',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD2691E),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentScreen extends StatefulWidget {
  final String creatorId;
  final String creatorName;
  final String creatorPhoto;
  final String creatorRole;

  const AppointmentScreen({
    super.key,
    required this.creatorId,
    required this.creatorName,
    required this.creatorPhoto,
    required this.creatorRole,
  });

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedReason = 'Consultation';
  final List<String> _reasons = [
    'Consultation',
    'Essayage',
    'Commande spéciale',
    'Réparation',
    'Autre'
  ];
  bool _isSubmitting = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitAppointment() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une heure')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final appointmentTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await _firestore.collection('appointments').add({
        'creatorId': widget.creatorId,
        'creatorName': widget.creatorName,
        'creatorPhoto': widget.creatorPhoto,
        'creatorRole': widget.creatorRole,
        'clientId': user.uid,
        'clientEmail': user.email,
        'date': appointmentTime,
        'reason': _selectedReason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rendez-vous demandé avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBoutique = widget.creatorRole == 'boutique';

    return Scaffold(
      appBar: AppBar(
        title: Text(isBoutique ? 'Visiter la boutique' : 'Prendre rendez-vous'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec infos créateur
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: widget.creatorPhoto.isNotEmpty
                        ? CachedNetworkImageProvider(widget.creatorPhoto)
                        : null,
                    child: widget.creatorPhoto.isEmpty
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.creatorName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isBoutique ? 'Boutique' : 'Créateur',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Calendrier (pour les créateurs ET les boutiques)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sélectionnez une date',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime(DateTime.now().year + 1),
                    focusedDay: _selectedDate,
                    selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                        _selectedTime = null;
                      });
                    },
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      leftChevronIcon: const Icon(Icons.chevron_left, color: Color(0xFF4CAF50)),
                      rightChevronIcon: const Icon(Icons.chevron_right, color: Color(0xFF4CAF50)),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: Colors.black),
                      weekendStyle: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

// Sélecteur d'heure
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sélectionnez une heure',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildTimeSlot('09:00'),
                      _buildTimeSlot('10:00'),
                      _buildTimeSlot('11:00'),
                      _buildTimeSlot('13:00'),
                      _buildTimeSlot('14:00'),
                      _buildTimeSlot('15:00'),
                      _buildTimeSlot('16:00'),
                      _buildTimeSlot('17:00'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_selectedTime != null)
                    Center(
                      child: Text(
                        'Heure sélectionnée: ${_selectedTime!.format(context)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Raison du rendez-vous ou visite boutique
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBoutique ? 'Informations de visite' : 'Raison du rendez-vous',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isBoutique) ...[
                    Text(
                      'Précisez vos besoins pour préparer votre visite:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<String>(
                    value: _selectedReason,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    items: _reasons.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedReason = value);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Bouton de confirmation
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4CAF50),
                    Color(0xFF2E7D32),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  isBoutique ? 'Demander une visite' : 'Confirmer le rendez-vous',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String time) {
    final isSelected = _selectedTime != null &&
        '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}' == time;

    return GestureDetector(
      onTap: () {
        final parts = time.split(':');
        setState(() {
          _selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[800],
          ),
        ),
      ),
    );
  }
}