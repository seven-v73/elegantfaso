import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  runApp(WardrobeApp());
}

class WardrobeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ma Garde-Robe Intelligente',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: WardrobeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WardrobeScreen extends StatefulWidget {
  @override
  _WardrobeScreenState createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String selectedCategory = 'Tous';
  String currentUserName = 'Utilisateur';
  String? currentUserId;
  User? currentUser;
  String? userPhotoUrl;

  List<String> categories = [
    'Tous',
    'Haut',
    'Bas',
    'Robe',
    'Chaussures',
    'Accessoires',
    'Veste'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      currentUserId = currentUser!.uid;
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();

        if (userDoc.exists) {
          setState(() {
            currentUserName = userDoc.get('name') ??
                userDoc.get('displayName') ??
                'Utilisateur';
            userPhotoUrl = userDoc.get('photoUrl') ?? currentUser!.photoURL;
          });
        } else {
          setState(() {
            currentUserName = currentUser!.displayName ?? 'Utilisateur';
            userPhotoUrl = currentUser!.photoURL;
          });
        }
      } catch (e) {
        print("Erreur de chargement des données utilisateur: $e");
        setState(() {
          currentUserName = currentUser!.displayName ?? 'Utilisateur';
          userPhotoUrl = currentUser!.photoURL;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                _buildCategoryFilter(),
                Expanded(child: _buildWardrobeContent()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildAddButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.deepPurple.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl!) : null,
                  child: userPhotoUrl == null
                      ? Icon(Icons.person, color: Colors.purple, size: 30)
                      : null,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salut,',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      currentUserName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Ma Garde-Robe Intelligente',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Gérez vos tenues avec style',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = categories[index] == selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: isSelected,
              selectedColor: Colors.purple,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = categories[index];
                });
              },
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.purple : Colors.grey[300]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWardrobeContent() {
    if (currentUserId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Veuillez vous connecter',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _loadUserData(),
              child: Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildWardrobeGrid();
  }

  Widget _buildWardrobeGrid() {
    Query query = FirebaseFirestore.instance
        .collection('wardrobe')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true);

    if (selectedCategory != 'Tous') {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: Text('Réessayer', style: TextStyle(color: Colors.purple)),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checkroom, size: 80, color: Colors.purple.withOpacity(0.3)),
                  SizedBox(height: 20),
                  Text(
                    'Aucune tenue trouvée',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Commencez par ajouter votre première tenue !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => _showAddItemDialog(),
                    icon: Icon(Icons.add),
                    label: Text('Ajouter une tenue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(15),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return _buildWardrobeItem(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(15),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWardrobeItem(Map<String, dynamic> item, String docId) {
    return Hero(
      tag: 'item_$docId',
      child: Material(
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => _showItemDetails(item, docId),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getCategoryColor(item['category'] ?? 'Tous').withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: item['images'] != null && item['images'].isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      child: _buildItemImage(item['images'][0], item['category']),
                    )
                        : Center(
                      child: Icon(
                        _getCategoryIcon(item['category'] ?? 'Tous'),
                        size: 40,
                        color: _getCategoryColor(item['category'] ?? 'Tous'),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['name'] ?? 'Sans nom',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item['brand'] != null && item['brand'].isNotEmpty)
                          Text(
                            item['brand'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(item['category'] ?? 'Tous').withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item['category'] ?? 'Tous',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getCategoryColor(item['category'] ?? 'Tous'),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemImage(String imagePath, String? category) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.purple,
          ),
        ),
        errorWidget: (context, url, error) => Center(
          child: Icon(
            _getCategoryIcon(category ?? 'Tous'),
            size: 40,
            color: _getCategoryColor(category ?? 'Tous'),
          ),
        ),
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
  }

  Color _getCategoryColor(String? category) {
    final cat = category ?? 'Tous';
    switch (cat) {
      case 'Robe':
        return Colors.pink;
      case 'Haut':
        return Colors.blue;
      case 'Bas':
        return Colors.indigo;
      case 'Chaussures':
        return Colors.brown;
      case 'Veste':
        return Colors.green;
      case 'Accessoires':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon(String? category) {
    final cat = category ?? 'Tous';
    switch (cat) {
      case 'Robe':
        return Icons.checkroom;
      case 'Haut':
        return Icons.face_retouching_natural;
      case 'Bas':
        return Icons.dry_cleaning;
      case 'Chaussures':
        return Icons.directions_walk;
      case 'Veste':
        return Icons.card_travel;
      case 'Accessoires':
        return Icons.watch;
      default:
        return Icons.checkroom;
    }
  }

  Widget _buildAddButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddItemDialog(),
      backgroundColor: Colors.purple,
      icon: Icon(Icons.add),
      label: Text('Ajouter'),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item, String docId) {
    print("Showing item details for: ${item['name']}");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    margin: EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item['images'] != null && item['images'].isNotEmpty)
                            Container(
                              height: 250,
                              child: PageView.builder(
                                itemCount: item['images'].length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: _buildDetailImage(item['images'][index]),
                                    ),
                                  );
                                },
                              ),
                            ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(item['category'] ?? 'Tous').withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  _getCategoryIcon(item['category'] ?? 'Tous'),
                                  size: 30,
                                  color: _getCategoryColor(item['category'] ?? 'Tous'),
                                ),
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? 'Sans nom',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (item['brand'] != null && item['brand'].isNotEmpty)
                                      Text(
                                        item['brand'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _editItem(item, docId);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteItem(docId),
                              ),
                            ],
                          ),
                          SizedBox(height: 30),
                          _buildDetailRow('Catégorie', item['category'] ?? 'Non spécifiée'),
                          if (item['color'] != null && item['color'].isNotEmpty)
                            _buildDetailRow('Couleur', item['color']),
                          if (item['brand'] != null && item['brand'].isNotEmpty)
                            _buildDetailRow('Marque', item['brand']),
                          if (item['description'] != null && item['description'].isNotEmpty) ...[
                            SizedBox(height: 20),
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              item['description'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                          SizedBox(height: 20),
                          if (item['createdAt'] != null)
                            Text(
                              'Ajouté le ${_formatDate(item['createdAt'].toDate())}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          SizedBox(height: 20),

                          // Section de recommandations
                          Text(
                            'Suggestions de tenues',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          SizedBox(height: 15),
                          _buildRecommendationsSection(item, docId),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Fleche de retour positionnée en absolu
              Positioned(
                top: 15,
                left: 15,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.purple),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: Icon(Icons.error, size: 50),
        ),
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
      );
    }
  }

  void _editItem(Map<String, dynamic> item, String docId) {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        userId: currentUserId,
        isEditMode: true,
        existingItem: item,
        docId: docId,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteItem(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer la tenue', style: TextStyle(color: Colors.red)),
        content: Text('Êtes-vous sûr de vouloir supprimer cette tenue ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('wardrobe')
                    .doc(docId)
                    .delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tenue supprimée avec succès !'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la suppression: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(userId: currentUserId),
    );
  }

  // Widget pour les recommandations
  Widget _buildRecommendationsSection(Map<String, dynamic> currentItem, String docId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wardrobe')
          .where('userId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!.docs
            .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id,
          };
        })
            .toList();

        // Filtrer les items de la même catégorie
        final sameCategoryItems = items
            .where((item) =>
        item['category'] == currentItem['category'] &&
            item['id'] != docId)
            .toList();

        // Filtrer les items complémentaires
        final complementaryItems = _getComplementaryItems(currentItem, items);

        // Créer des tenues complètes
        final outfits = _generateOutfits(currentItem, items);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sameCategoryItems.isNotEmpty) ...[
              Text(
                'Autres ${currentItem['category']}s',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sameCategoryItems.length,
                  itemBuilder: (context, index) {
                    final item = sameCategoryItems[index];
                    return _buildRecommendationItem(item);
                  },
                ),
              ),
              SizedBox(height: 20),
            ],

            if (complementaryItems.isNotEmpty) ...[
              Text(
                'Compléments pour cette pièce',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: complementaryItems.length,
                  itemBuilder: (context, index) {
                    final item = complementaryItems[index];
                    return _buildRecommendationItem(item);
                  },
                ),
              ),
              SizedBox(height: 20),
            ],

            if (outfits.isNotEmpty) ...[
              Text(
                'Tenues complètes suggérées',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: outfits.length > 3 ? 3 : outfits.length,
                itemBuilder: (context, index) {
                  final outfit = outfits[index];
                  return _buildOutfitCard(outfit);
                },
              ),
            ],
          ],
        );
      },
    );
  }

  // Widget pour un item de recommandation
  Widget _buildRecommendationItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _showItemDetails(item, item['id']),
      child: Container(
        width: 100,
        margin: EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Expanded(
              child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item['images'] != null && item['images'].isNotEmpty
                        ? _buildRecommendationImage(item['images'][0])
                        : Center(
                      child: Icon(
                        _getCategoryIcon(item['category'] ?? 'Tous'),
                        size: 30,
                        color: Colors.grey[500],
                      ),
                    ),
                  )
              ),
            ),
            SizedBox(height: 5),
            Text(
              item['name'] ?? 'Sans nom',
              style: TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
      );
    }
  }

  // Widget pour une tenue complète
  Widget _buildOutfitCard(Map<String, dynamic> outfit) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 5),
                Text(
                  '${outfit['score']}% Compatible',
                  style: TextStyle(fontSize: 14, color: Colors.amber[700], fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Chip(
                  label: Text(outfit['occasion']),
                  backgroundColor: _getOccasionColor(outfit['occasion']).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getOccasionColor(outfit['occasion']),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              outfit['name'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Pièces:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 5),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: outfit['items'].map<Widget>((item) {
                return Chip(
                  label: Text(item['name']),
                  backgroundColor: _getCategoryColor(item['category']).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getCategoryColor(item['category']),
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 15),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: outfit['items'].length,
                itemBuilder: (context, index) {
                  final item = outfit['items'][index];
                  return _buildRecommendationItem(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getOccasionColor(String occasion) {
    switch (occasion) {
      case 'Travail': return Colors.blue;
      case 'Soirée': return Colors.purple;
      case 'Décontracté': return Colors.green;
      case 'Sport': return Colors.orange;
      default: return Colors.grey;
    }
  }

  // Algorithme de recommandation
  List<Map<String, dynamic>> _getComplementaryItems(
      Map<String, dynamic> currentItem, List<Map<String, dynamic>> allItems) {
    final complementaryCategories = {
      'Haut': ['Bas', 'Veste', 'Accessoires'],
      'Bas': ['Haut', 'Chaussures', 'Accessoires'],
      'Robe': ['Chaussures', 'Accessoires', 'Veste'],
      'Chaussures': ['Bas', 'Robe'],
      'Accessoires': ['Haut', 'Bas', 'Robe'],
      'Veste': ['Haut', 'Robe'],
    };

    return allItems.where((item) {
      return complementaryCategories[currentItem['category']]?.contains(item['category']) ?? false;
    }).toList();
  }

  // Algorithme de génération de tenues
  List<Map<String, dynamic>> _generateOutfits(
      Map<String, dynamic> currentItem, List<Map<String, dynamic>> allItems) {
    final outfits = <Map<String, dynamic>>[];
    final occasions = {
      'Travail': {
        'categories': ['Haut', 'Bas', 'Chaussures', 'Accessoires'],
        'colors': ['noir', 'blanc', 'gris', 'bleu', 'marron', 'beige']
      },
      'Soirée': {
        'categories': ['Robe', 'Accessoires', 'Chaussures'],
        'colors': ['rouge', 'noir', 'or', 'argent', 'violet', 'bleu nuit']
      },
      'Décontracté': {
        'categories': ['Haut', 'Bas', 'Chaussures'],
        'colors': ['bleu', 'jean', 'blanc', 'gris', 'vert', 'jaune']
      },
      'Sport': {
        'categories': ['Haut', 'Bas', 'Chaussures'],
        'colors': ['noir', 'gris', 'bleu', 'rouge', 'vert', 'orange']
      },
    };

    for (final occasion in occasions.entries) {
      final occasionName = occasion.key;
      final occasionRules = occasion.value;
      final requiredCategories = List<String>.from(occasionRules['categories'] as List<dynamic>);

      // Vérifier si l'item actuel correspond à l'occasion
      if (!_itemMatchesOccasion(currentItem, occasionName, occasionRules)) {
        continue;
      }

      // Trouver des pièces complémentaires
      final outfitItems = [currentItem];

      for (final category in requiredCategories) {
        if (category == currentItem['category']) continue;

        final matchingItems = allItems.where((item) {
          return item['category'] == category &&
              _itemMatchesOccasion(item, occasionName, occasionRules) &&
              !outfitItems.contains(item);
        }).toList();

        if (matchingItems.isNotEmpty) {
          // Prendre un item au hasard qui correspond
          final randomIndex = matchingItems.length > 1
              ? (matchingItems.length * 0.5).floor()
              : 0;
          outfitItems.add(matchingItems[randomIndex]);
        }
      }

      // Vérifier que toutes les catégories sont représentées
      if (outfitItems.length >= 3) {
        outfits.add({
          'name': 'Tenue ${occasionName}',
          'occasion': occasionName,
          'items': outfitItems,
          'score': _calculateOutfitScore(outfitItems, occasionRules),
        });
      }
    }

    // Trier par score
    outfits.sort((a, b) => b['score'].compareTo(a['score']));

    return outfits;
  }

  bool _itemMatchesOccasion(Map<String, dynamic> item, String occasion, Map<String, dynamic> rules) {
    final allowedColors = (rules['colors'] as List<dynamic>).cast<String>();
    final itemColor = (item['color'] as String? ?? '').toLowerCase();

    // Vérifier la couleur
    final colorMatch = allowedColors.any((color) => itemColor.contains(color));

    return colorMatch;
  }

  int _calculateOutfitScore(List<Map<String, dynamic>> items, Map<String, dynamic> rules) {
    int score = 0;
    final allowedColors = (rules['colors'] as List<dynamic>).cast<String>();

    for (final item in items) {
      final itemColor = (item['color'] as String? ?? '').toLowerCase();

      // Points pour correspondance de couleur
      if (allowedColors.any((color) => itemColor.contains(color))) {
        score += 20;
      }

      // Points supplémentaires pour les pièces principales
      if (item['category'] == 'Haut' || item['category'] == 'Robe') {
        score += 10;
      }
    }

    // Points pour complétude de la tenue
    if (items.length >= 3) score += 30;
    if (items.length >= 4) score += 20;

    // Maximum 100%
    return score > 100 ? 100 : score;
  }
}

class AddItemDialog extends StatefulWidget {
  final String? userId;
  final bool isEditMode;
  final Map<String, dynamic>? existingItem;
  final String? docId;

  const AddItemDialog({
    Key? key,
    this.userId,
    this.isEditMode = false,
    this.existingItem,
    this.docId,
  }) : super(key: key);

  @override
  _AddItemDialogState createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _colorController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Haut';
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  List<String> categories = [
    'Haut',
    'Bas',
    'Robe',
    'Chaussures',
    'Accessoires',
    'Veste'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.existingItem != null) {
      _nameController.text = widget.existingItem!['name'] ?? '';
      _brandController.text = widget.existingItem!['brand'] ?? '';
      _colorController.text = widget.existingItem!['color'] ?? '';
      _descriptionController.text = widget.existingItem!['description'] ?? '';
      _selectedCategory = widget.existingItem!['category'] ?? 'Haut';
      _existingImageUrls = List<String>.from(widget.existingItem!['images'] ?? []);
    }
  }

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)).toList());
        if (_selectedImages.length > 5) {
          _selectedImages = _selectedImages.sublist(0, 5);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum 5 images autorisées'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1000,
    );
    if (image != null) {
      setState(() {
        if (_selectedImages.length < 5) {
          _selectedImages.add(File(image.path));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum 5 images autorisées'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];

    for (File image in _selectedImages) {
      try {
        // Si c'est déjà une URL, on l'ajoute directement
        if (image.path.startsWith('http')) {
          imageUrls.add(image.path);
          continue;
        }

        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${widget.userId}';
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('wardrobe')
            .child(widget.userId!)
            .child(fileName);

        await ref.putFile(image);
        String imageUrl = await ref.getDownloadURL();
        imageUrls.add(imageUrl);
      } catch (e) {
        print("Erreur d'upload d'image: $e");
        // En cas d'erreur, utiliser le chemin local comme fallback
        imageUrls.add(image.path);
      }
    }

    return imageUrls;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isEditMode ? 'Modifier la tenue' : 'Ajouter une tenue',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom de la tenue *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.label),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ce champ est obligatoire';
                        }
                        if (value.length > 30) {
                          return 'Maximum 30 caractères';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Catégorie *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner une catégorie';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _brandController,
                      decoration: InputDecoration(
                        labelText: 'Marque (optionnel)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.business),
                      ),
                      maxLength: 20,
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _colorController,
                      decoration: InputDecoration(
                        labelText: 'Couleur (optionnel)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.palette),
                      ),
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (optionnel)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Photos (max 5)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 10),

                    // Images existantes (mode édition)
                    if (widget.isEditMode && _existingImageUrls.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Images existantes:',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 10),
                          Container(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _existingImageUrls.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: EdgeInsets.only(right: 10),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: _existingImageUrls[index].startsWith('http')
                                            ? CachedNetworkImage(
                                          imageUrl: _existingImageUrls[index],
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                                          errorWidget: (context, url, error) => Icon(Icons.error),
                                        )
                                            : Image.file(
                                          File(_existingImageUrls[index]),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _existingImageUrls.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 15),
                        ],
                      ),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: Icon(Icons.photo_library),
                            label: Text('Galerie'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.black87,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImageFromCamera,
                            icon: Icon(Icons.camera_alt),
                            label: Text('Appareil photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.black87,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    if (_selectedImages.isNotEmpty)
                      Container(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.only(right: 10),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedImages[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Annuler'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _addOrUpdateItem,
                            child: _isLoading
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : Text(widget.isEditMode ? 'Mettre à jour' : 'Ajouter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
        ),
      ),
    );
  }

  Future<void> _addOrUpdateItem() async {
    if (_formKey.currentState!.validate()) {
      if (widget.userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: Utilisateur non connecté'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        List<String> imageUrls = [..._existingImageUrls];
        final newImageUrls = await _uploadImages();
        imageUrls.addAll(newImageUrls);

        Map<String, dynamic> itemData = {
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'brand': _brandController.text.trim(),
          'color': _colorController.text.trim(),
          'description': _descriptionController.text.trim(),
          'images': imageUrls,
          'userId': widget.userId,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (widget.isEditMode && widget.docId != null) {
          // Mise à jour de l'item existant
          await FirebaseFirestore.instance
              .collection('wardrobe')
              .doc(widget.docId)
              .update(itemData);
        } else {
          // Création d'un nouvel item
          itemData['createdAt'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection('wardrobe')
              .add(itemData);
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.isEditMode
                    ? 'Tenue modifiée avec succès !'
                    : 'Tenue ajoutée avec succès !'
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}