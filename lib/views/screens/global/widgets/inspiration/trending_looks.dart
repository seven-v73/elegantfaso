import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class FashionLook {
  final String id;
  final String title;
  final String creator;
  final String imageUrl;
  final List<String> tags;
  final int likes;
  final double rating;
  bool isSaved;
  DateTime? savedDate;

  FashionLook({
    required this.id,
    required this.title,
    required this.creator,
    required this.imageUrl,
    required this.tags,
    required this.likes,
    required this.rating,
    this.isSaved = false,
    this.savedDate,
  });

  factory FashionLook.fromJson(Map<String, dynamic> json) {
    return FashionLook(
      id: json['id'] ?? '',
      title: json['alt_description']?.toString().isNotEmpty == true
          ? json['alt_description']
          : 'Look tendance',
      creator: '@${json['user']?['username'] ?? 'unknown'}',
      imageUrl: json['urls']?['regular'] ?? '',
      tags: ['#Mode', '#Style', '#Tendance'],
      likes: json['likes'] ?? 0,
      rating: 4.0 + ((json['likes'] ?? 0) % 10) / 10,
      isSaved: json['isSaved'] ?? false,
      savedDate: json['savedDate'] != null ? DateTime.parse(json['savedDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'creator': creator,
      'imageUrl': imageUrl,
      'tags': tags,
      'likes': likes,
      'rating': rating,
      'isSaved': isSaved,
      'savedDate': savedDate?.toIso8601String(),
    };
  }
}

class WardrobeService {
  static const String _wardrobeKey = 'saved_looks';

  static Future<List<FashionLook>> getSavedLooks() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getStringList(_wardrobeKey) ?? [];

    return savedData.map((data) {
      final json = jsonDecode(data);
      return FashionLook.fromJson(json);
    }).toList();
  }

  static Future<void> saveLook(FashionLook look) async {
    final prefs = await SharedPreferences.getInstance();
    final savedLooks = await getSavedLooks();

    // Vérifier si le look n'est pas déjà sauvegardé
    if (!savedLooks.any((saved) => saved.id == look.id)) {
      look.isSaved = true;
      look.savedDate = DateTime.now();
      savedLooks.add(look);

      final savedData = savedLooks.map((look) => jsonEncode(look.toJson())).toList();
      await prefs.setStringList(_wardrobeKey, savedData);
    }
  }

  static Future<void> removeLook(String lookId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedLooks = await getSavedLooks();

    savedLooks.removeWhere((look) => look.id == lookId);

    final savedData = savedLooks.map((look) => jsonEncode(look.toJson())).toList();
    await prefs.setStringList(_wardrobeKey, savedData);
  }

  static Future<bool> isLookSaved(String lookId) async {
    final savedLooks = await getSavedLooks();
    return savedLooks.any((look) => look.id == lookId);
  }
}

class FashionService {
  static const String baseUrl = 'https://api.unsplash.com';
  static const String accessKey = 'Hi5H3MBLFTkAjnP_WJTC-yaPQ9AB8ryekQh_W_8nR_8';

  // Termes de recherche pour la mode et fashion
  static const List<String> fashionQueries = [
    'fashion',
    'style',
    'clothing',
    'outfit',
    'dress',
    'african fashion',
    'traditional clothing',
    'modern fashion',
    'street style',
    'haute couture',
    'casual wear',
    'formal wear',
    'bohemian style',
    'minimalist fashion',
    'vintage fashion'
  ];

  static Future<List<FashionLook>> getTrendingLooks() async {
    try {
      // Sélectionner un terme de recherche aléatoire
      final randomQuery = fashionQueries[(DateTime.now().millisecondsSinceEpoch / 1000).round() % fashionQueries.length];

      final response = await http.get(
        Uri.parse('$baseUrl/search/photos?query=$randomQuery&per_page=15&orientation=portrait&client_id=$accessKey'),
        headers: {'Accept-Version': 'v1'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        if (results.isNotEmpty) {
          final looks = results.map((item) => FashionLook.fromJson(item)).toList();

          // Vérifier le statut de sauvegarde pour chaque look
          for (var look in looks) {
            look.isSaved = await WardrobeService.isLookSaved(look.id);
          }

          return looks;
        } else {
          return _getFallbackLooks();
        }
      } else {
        print('API Error: ${response.statusCode} - ${response.reasonPhrase}');
        return _getFallbackLooks();
      }
    } catch (e) {
      print('Network Error: $e');
      return _getFallbackLooks();
    }
  }

  static List<FashionLook> _getFallbackLooks() {
    return [
      FashionLook(
        id: '1',
        title: 'Look Élégant Africain',
        creator: '@afro_style',
        imageUrl: 'https://images.unsplash.com/photo-1594736797933-d0401ba2fe65',
        tags: ['#Africain', '#Élégant', '#Pagne'],
        likes: 245,
        rating: 4.8,
      ),
      FashionLook(
        id: '2',
        title: 'Tenue Traditionnelle Moderne',
        creator: '@modern_trad',
        imageUrl: 'https://images.unsplash.com/photo-1583394838336-acd977736f90',
        tags: ['#Traditionnel', '#Moderne', '#Chic'],
        likes: 189,
        rating: 4.6,
      ),
      FashionLook(
        id: '3',
        title: 'Style Bohème Chic',
        creator: '@boho_queen',
        imageUrl: 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446',
        tags: ['#Bohème', '#Chic', '#Naturel'],
        likes: 312,
        rating: 4.9,
      ),
      FashionLook(
        id: '4',
        title: 'Look Casual Urbain',
        creator: '@urban_style',
        imageUrl: 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03',
        tags: ['#Urbain', '#Casual', '#Tendance'],
        likes: 156,
        rating: 4.4,
      ),
      FashionLook(
        id: '5',
        title: 'Tenue de Soirée Glamour',
        creator: '@glam_fashion',
        imageUrl: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8',
        tags: ['#Glamour', '#Soirée', '#Élégant'],
        likes: 428,
        rating: 4.7,
      ),
      FashionLook(
        id: '6',
        title: 'Style Minimaliste',
        creator: '@minimal_mode',
        imageUrl: 'https://images.unsplash.com/photo-1581338834647-b0fb40704e21',
        tags: ['#Minimaliste', '#Clean', '#Simple'],
        likes: 201,
        rating: 4.5,
      ),
    ];
  }
}

class TrendingLooks extends StatefulWidget {
  const TrendingLooks({super.key});

  @override
  State<TrendingLooks> createState() => _TrendingLooksState();
}

class _TrendingLooksState extends State<TrendingLooks>
    with SingleTickerProviderStateMixin {

  List<FashionLook> fashionLooks = [];
  bool isLoading = true;
  String error = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _autoRefreshTimer;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadFashionLooks();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _refreshLooks();
      }
    });
  }

  Future<void> _loadFashionLooks() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      final looks = await FashionService.getTrendingLooks();

      setState(() {
        fashionLooks = looks;
        isLoading = false;
        _lastRefresh = DateTime.now();
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        error = 'Erreur lors du chargement: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _refreshLooks() async {
    _animationController.reset();
    await _loadFashionLooks();

    // Afficher un message de confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nouvelles images chargées !'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _toggleSaveLook(FashionLook look) async {
    if (look.isSaved) {
      await WardrobeService.removeLook(look.id);
      setState(() {
        look.isSaved = false;
        look.savedDate = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tenue retirée de la garde-robe'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      await WardrobeService.saveLook(look);
      setState(() {
        look.isSaved = true;
        look.savedDate = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tenue ajoutée à votre garde-robe !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Voir',
            textColor: Colors.white,
            onPressed: () => _showWardrobe(),
          ),
        ),
      );
    }
  }

  Future<void> _shareLook(FashionLook look) async {
    final shareText = '''
🌟 Découvrez ce superbe look ! 

"${look.title}"
Créé par ${look.creator}

⭐ Note: ${look.rating.toStringAsFixed(1)}/5
❤️ ${look.likes} J'aime

${look.tags.join(' ')}

#Fashion #Style #Mode
    ''';

    try {
      await Share.share(
        shareText,
        subject: 'Superbe look à découvrir !',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du partage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWardrobe() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WardrobePage(),
      ),
    );
  }

  String _getTimeAgo() {
    if (_lastRefresh == null) return '';

    final now = DateTime.now();
    final difference = now.difference(_lastRefresh!);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'Il y a ${difference.inHours}h';
    }
  }

  Color _getTagColor(String tag) {
    switch (tag.toLowerCase()) {
      case '#africain':
      case '#traditionnel':
        return Colors.orange;
      case '#pagne':
        return Colors.green;
      case '#élégant':
      case '#chic':
        return Colors.purple;
      case '#moderne':
        return Colors.blue;
      case '#bohème':
        return Colors.brown;
      case '#urbain':
        return Colors.grey;
      case '#glamour':
        return Colors.pink;
      case '#minimaliste':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Looks Tendance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (_lastRefresh != null)
                    Text(
                      'Mis à jour ${_getTimeAgo()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  // Bouton garde-robe
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: _showWardrobe,
                      icon: const Icon(Icons.checkroom, color: Colors.purple, size: 20),
                      tooltip: 'Ma garde-robe',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Indicateur d'actualisation automatique
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.update, size: 12, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          '5min',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton de rafraîchissement manuel
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: isLoading ? null : _refreshLooks,
                      icon: AnimatedRotation(
                        turns: isLoading ? 1 : 0,
                        duration: const Duration(seconds: 1),
                        child: const Icon(Icons.refresh, color: Colors.blue, size: 20),
                      ),
                      tooltip: 'Actualiser maintenant',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isLoading)
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) => _buildShimmerCard(),
              ),
            )
          else if (error.isNotEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 8),
                  Text(error, style: TextStyle(color: Colors.red[600])),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refreshLooks,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else
            FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: fashionLooks.length,
                  itemBuilder: (context, index) {
                    return _buildFashionCard(fashionLooks[index], index);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  color: Colors.grey[300],
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFashionCard(FashionLook look, int index) {
    return GestureDetector(
      onTap: () => _showLookDetails(look),
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: 6,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Hero(
                  tag: 'look_${look.id}',
                  child: CachedNetworkImage(
                    imageUrl: look.imageUrl,
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Bouton de sauvegarde
                            Positioned(
                              top: 8,
                              left: 8,
                              child: GestureDetector(
                                onTap: () => _toggleSaveLook(look),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    look.isSaved ? Icons.bookmark : Icons.bookmark_border,
                                    color: look.isSaved ? Colors.yellow : Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            // Compteur de likes
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.favorite, color: Colors.red, size: 12),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${look.likes}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Bouton de partage
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _shareLook(look),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.share,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      look.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            look.creator,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              Icons.star,
                              size: 10,
                              color: i < look.rating.floor()
                                  ? Colors.amber
                                  : Colors.grey[300],
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: look.tags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTagColor(tag).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: _getTagColor(tag),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
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

  void _showLookDetails(FashionLook look) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'look_${look.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CachedNetworkImage(
                            imageUrl: look.imageUrl,
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 300,
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 300,
                              color: Colors.grey[200],
                              child: const Icon(Icons.error, color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  look.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Créé par ${look.creator}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              // Bouton de sauvegarde
                              ElevatedButton.icon(
                                onPressed: () => _toggleSaveLook(look),
                                icon: Icon(
                                  look.isSaved ? Icons.bookmark : Icons.bookmark_border,
                                  size: 20,
                                ),
                                label: Text(look.isSaved ? 'Sauvé' : 'Sauver'),
                                style: ElevatedButton.styleFrom(
                                backgroundColor: look.isSaved ? Colors.green : Colors.purple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Bouton de partage
                              ElevatedButton.icon(
                                onPressed: () => _shareLook(look),
                                icon: const Icon(Icons.share, size: 20),
                                label: const Text('Partager'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section des statistiques
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(Icons.favorite, '${look.likes}', 'J\'aime', Colors.red),
                            _buildStatItem(Icons.star, '${look.rating}', 'Note', Colors.amber),
                            _buildStatItem(Icons.visibility, '${(look.likes * 1.5).toInt()}', 'Vues', Colors.blue),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tags avec plus de détails
                      const Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: look.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getTagColor(tag).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _getTagColor(tag).withOpacity(0.3)),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: _getTagColor(tag),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Section similaire (optionnel)
                      const Text(
                        'Looks similaires',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('Look\nsimilaire',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            );
                          },
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
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
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
    );
  }
}

// Nouvelle classe pour la page Garde-robe
class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage>
    with SingleTickerProviderStateMixin {

  List<FashionLook> savedLooks = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  String _sortBy = 'recent'; // recent, rating, title
  String _filterBy = 'all'; // all, saved, favoris

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _loadSavedLooks();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLooks() async {
    setState(() => isLoading = true);

    try {
      final looks = await WardrobeService.getSavedLooks();
      setState(() {
        savedLooks = looks;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  List<FashionLook> get filteredAndSortedLooks {
    List<FashionLook> filtered = List.from(savedLooks);

    // Tri
    switch (_sortBy) {
      case 'recent':
        filtered.sort((a, b) => (b.savedDate ?? DateTime.now())
            .compareTo(a.savedDate ?? DateTime.now()));
        break;
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'likes':
        filtered.sort((a, b) => b.likes.compareTo(a.likes));
        break;
    }

    return filtered;
  }

  Future<void> _removeLookFromWardrobe(FashionLook look) async {
    // Animation de suppression
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer de la garde-robe'),
        content: Text('Voulez-vous retirer "${look.title}" de votre garde-robe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await WardrobeService.removeLook(look.id);
              Navigator.pop(context);
              _loadSavedLooks();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Tenue retirée de la garde-robe'),
                  backgroundColor: Colors.orange,
                  action: SnackBarAction(
                    label: 'Annuler',
                    onPressed: () async {
                      await WardrobeService.saveLook(look);
                      _loadSavedLooks();
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ma Garde-robe',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          // Bouton de tri
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20),
                    SizedBox(width: 8),
                    Text('Plus récent'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rating',
                child: Row(
                  children: [
                    Icon(Icons.star, size: 20),
                    SizedBox(width: 8),
                    Text('Mieux noté'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'likes',
                child: Row(
                  children: [
                    Icon(Icons.favorite, size: 20),
                    SizedBox(width: 8),
                    Text('Plus aimé'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'title',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 20),
                    SizedBox(width: 8),
                    Text('Alphabétique'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : savedLooks.isEmpty
          ? _buildEmptyState()
          : SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: FadeTransition(
          opacity: _slideAnimation,
          child: _buildLooksGrid(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined,
              size: 80,
              color: Colors.grey[400]
          ),
          const SizedBox(height: 16),
          Text(
            'Votre garde-robe est vide',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez à sauvegarder vos looks favoris !',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore),
            label: const Text('Découvrir des looks'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLooksGrid() {
    final looks = filteredAndSortedLooks;

    return Column(
      children: [
        // En-tête avec statistiques
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWardrobeStats(Icons.checkroom, '${looks.length}', 'Tenues'),
              _buildWardrobeStats(Icons.star,
                  looks.isEmpty ? '0.0' : '${(looks.map((l) => l.rating).reduce((a, b) => a + b) / looks.length).toStringAsFixed(1)}',
                  'Moy. Note'
              ),
              _buildWardrobeStats(Icons.favorite,
                  looks.isEmpty ? '0' : '${looks.map((l) => l.likes).reduce((a, b) => a + b)}',
                  'Total J\'aime'
              ),
            ],
          ),
        ),

        // Grille des looks
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: looks.length,
            itemBuilder: (context, index) {
              return _buildWardrobeCard(looks[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWardrobeStats(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.purple, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
    );
  }

  Widget _buildWardrobeCard(FashionLook look, int index) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: look.imageUrl,
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: const Icon(Icons.error, color: Colors.red),
                  ),
                ),

                // Badge "Sauvegardé" et date
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bookmark, color: Colors.white, size: 12),
                        const SizedBox(width: 2),
                        if (look.savedDate != null)
                          Text(
                            '${look.savedDate!.day}/${look.savedDate!.month}',
                            style: const TextStyle(color: Colors.white, fontSize: 8),
                          ),
                      ],
                    ),
                  ),
                ),

                // Menu d'actions
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.more_vert, color: Colors.white, size: 16),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'remove',
                        child: const Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Supprimer'),
                          ],
                        ),
                        onTap: () => Future.delayed(
                          const Duration(milliseconds: 100),
                              () => _removeLookFromWardrobe(look),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: const Row(
                          children: [
                            Icon(Icons.share, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text('Partager'),
                          ],
                        ),
                        onTap: () => Future.delayed(
                          const Duration(milliseconds: 100),
                              () => _shareLook(look),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  look.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '${look.rating}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    Icon(Icons.favorite, color: Colors.red, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '${look.likes}',
                      style: const TextStyle(fontSize: 12),
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

  Future<void> _shareLook(FashionLook look) async {
    final shareText = '''
🌟 Mon look sauvegardé ! 

"${look.title}"
Créé par ${look.creator}

⭐ Note: ${look.rating.toStringAsFixed(1)}/5
❤️ ${look.likes} J'aime

${look.tags.join(' ')}

#MaGardeRobe #Fashion #Style
    ''';

    try {
      await Share.share(shareText, subject: 'Mon look de garde-robe');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du partage: $e')),
      );
    }
  }
}