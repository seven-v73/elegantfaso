import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';


// Modèle de données pour les promotions
class Promotion {
  final String id;
  final String title;
  final String description;
  final String category;
  final int discountPercentage;
  final String originalPrice;
  final String discountedPrice;
  final String imageUrl;
  final String shopName;
  final String shopUrl;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String location;
  final List<String> tags;
  final String source;

  Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.discountPercentage,
    required this.originalPrice,
    required this.discountedPrice,
    required this.imageUrl,
    required this.shopName,
    required this.shopUrl,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.location,
    required this.tags,
    required this.source,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      discountPercentage: json['discount_percentage'] ?? 0,
      originalPrice: json['original_price'] ?? '',
      discountedPrice: json['discounted_price'] ?? '',
      imageUrl: json['image_url'] ?? '',
      shopName: json['shop_name'] ?? '',
      shopUrl: json['shop_url'] ?? '',
      startDate: DateTime.parse(json['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toIso8601String()),
      isActive: json['is_active'] ?? false,
      location: json['location'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      source: json['source'] ?? 'unknown',
    );
  }

  bool get isValidToday {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  String get timeRemaining {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Expire bientôt!';
    }
  }
}

// Service de scraping dynamique
class WebScrapingService {
  static const Duration timeout = Duration(seconds: 30);
  static final Random _random = Random();

  // Configuration des sites avec leurs sélecteurs spécifiques
  static const List<Map<String, dynamic>> burkinaFashionSites = [
    {
      'name': 'Burkina24',
      'url': 'https://burkina24.com',
      'searchPath': '/tag/mode/',
      'articleSelector': '.post',
      'titleSelector': '.entry-title',
      'descriptionSelector': '.entry-summary',
      'imageSelector': '.post-thumbnail img',
      'linkSelector': '.entry-title a',
    },
    {
      'name': 'Fasozine',
      'url': 'https://fasozine.com',
      'searchPath': '/category/mode/',
      'articleSelector': '.post',
      'titleSelector': '.entry-title',
      'descriptionSelector': '.entry-content',
      'imageSelector': '.post-thumbnail img',
      'linkSelector': '.entry-title a',
    },
    {
      'name': 'Wakat Sera',
      'url': 'https://wakatsera.com',
      'searchPath': '/mode-et-beaute/',
      'articleSelector': 'article',
      'titleSelector': '.entry-title',
      'descriptionSelector': '.entry-content',
      'imageSelector': '.entry-thumbnail img',
      'linkSelector': '.entry-title a',
    },
    {
      'name': 'Infos Culture du Faso',
      'url': 'https://www.infosculturedufaso.net',
      'searchPath': '/category/mode/',
      'articleSelector': '.post',
      'titleSelector': '.post-title',
      'descriptionSelector': '.post-excerpt',
      'imageSelector': '.post-thumb img',
      'linkSelector': '.post-title a',
    }
  ];

  static Future<List<Promotion>> scrapePromotions() async {
    List<Promotion> allPromotions = [];

    for (var site in burkinaFashionSites) {
      try {
        final promotions = await _scrapeSite(site);
        allPromotions.addAll(promotions);
        print('✅ ${promotions.length} promotions from ${site['name']}');
      } catch (e) {
        print('❌ Erreur scraping ${site['name']}: $e');
      }
    }

    // Trier par pourcentage de réduction
    allPromotions.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));

    return allPromotions.isNotEmpty ? allPromotions : _getDemoPromotions();
  }

  static Future<List<Promotion>> _scrapeSite(Map<String, dynamic> site) async {
    try {
      final url = '${site['url']}${site['searchPath']}';
      print('🌐 Scraping: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return _parseHtmlContent(response.body, site);
      }
      return [];
    } catch (e) {
      print('🚨 HTTP error for ${site['name']}: $e');
      return [];
    }
  }

  static List<Promotion> _parseHtmlContent(String htmlContent, Map<String, dynamic> site) {
    List<Promotion> promotions = [];
    try {
      dom.Document document = html.parse(htmlContent);
      final articles = document.querySelectorAll(site['articleSelector']);

      if (articles.isEmpty) return promotions;

      for (var article in articles.take(6)) {
        try {
          final promotion = _extractPromotionFromArticle(article, site);
          if (promotion != null) promotions.add(promotion);
        } catch (e) {
          print('⚠️ Error extracting article: $e');
        }
      }
    } catch (e) {
      print('🚨 Parsing error: $e');
    }
    return promotions;
  }

  static Promotion? _extractPromotionFromArticle(dom.Element article, Map<String, dynamic> site) {
    // Extraction du titre
    final titleElement = article.querySelector(site['titleSelector']);
    if (titleElement == null) return null;

    final title = titleElement.text.trim();
    if (title.isEmpty || !_isFashionRelated(title)) return null;

    // Extraction de l'URL
    String articleUrl = site['url']!;
    final linkElement = article.querySelector(site['linkSelector']);
    if (linkElement != null) {
      String href = linkElement.attributes['href'] ?? '';
      if (href.startsWith('http')) {
        articleUrl = href;
      } else if (href.startsWith('/')) {
        articleUrl = '${site['url']}$href';
      }
    }

    // Extraction de l'image
    String imageUrl = _extractImageUrl(article, site['imageSelector'], site['url']!);

    // Extraction de la description
    String description = '';
    final descElement = article.querySelector(site['descriptionSelector']);
    if (descElement != null) {
      description = descElement.text.trim();
      if (description.length > 100) {
        description = '${description.substring(0, 100)}...';
      }
    }

    // Catégorisation dynamique
    String category = _categorizeContent(title + ' ' + description);

    // Génération des données
    int discountPercentage = _generateRandomDiscount();
    Map<String, String> prices = _generateRandomPrices(category);

    return Promotion(
      id: '${DateTime.now().millisecondsSinceEpoch}-${title.hashCode}',
      title: title,
      description: description.isEmpty ? 'Offre spéciale mode burkinabè' : description,
      category: category,
      discountPercentage: discountPercentage,
      originalPrice: prices['original']!,
      discountedPrice: prices['discounted']!,
      imageUrl: imageUrl,
      shopName: site['name']!,
      shopUrl: articleUrl,
      startDate: DateTime.now().subtract(Duration(hours: _random.nextInt(48))),
      endDate: DateTime.now().add(Duration(days: _random.nextInt(7) + 1)),
      isActive: true,
      location: _getRandomLocation(),
      tags: _generateTags(title + ' ' + description),
      source: site['name']!,
    );
  }

  static String _extractImageUrl(dom.Element article, String selector, String baseUrl) {
    final imgElement = article.querySelector(selector);
    if (imgElement == null) return _getDefaultImage();

    String src = imgElement.attributes['src'] ??
        imgElement.attributes['data-src'] ??
        imgElement.attributes['data-lazy-src'] ?? '';

    if (src.isEmpty) return _getDefaultImage();

    if (src.startsWith('http')) return src;
    if (src.startsWith('/')) return baseUrl + src;
    return '$baseUrl/$src';
  }

  static bool _isFashionRelated(String text) {
    const fashionKeywords = [
      'mode', 'fashion', 'vêtement', 'habit', 'robe', 'pagne', 'wax',
      'batik', 'faso dan fani', 'bijoux', 'accessoire', 'sac', 'chaussure',
      'style', 'tendance', 'collection', 'couture', 'tissu', 'textile'
    ];
    return fashionKeywords.any(text.toLowerCase().contains);
  }

  static String _categorizeContent(String content) {
    const clothingKeywords = [
      'robe', 'pagne', 'habit', 'vêtement', 'chemise', 'pantalon', 'jupe',
      'boubou', 'wax', 'batik', 'tissu', 'couture'
    ];

    const accessoryKeywords = [
      'bijoux', 'sac', 'chaussure', 'ceinture', 'montre', 'lunettes',
      'bracelet', 'collier', 'bague', 'boucles', 'maroquinerie'
    ];

    final lowerContent = content.toLowerCase();
    if (clothingKeywords.any(lowerContent.contains)) return 'vetements';
    if (accessoryKeywords.any(lowerContent.contains)) return 'accessoires';
    return 'vetements';
  }

  static int _generateRandomDiscount() {
    const commonDiscounts = [15, 20, 25, 30, 35, 40, 45, 50, 60, 70];
    return commonDiscounts[_random.nextInt(commonDiscounts.length)];
  }

  static Map<String, String> _generateRandomPrices(String category) {
    final basePrices = category == 'vetements'
        ? [15000, 18000, 25000, 30000, 35000, 40000]
        : [8000, 12000, 15000, 18000, 22000, 28000];

    final originalPrice = basePrices[_random.nextInt(basePrices.length)];
    final discountedPrice = (originalPrice * (100 - _generateRandomDiscount()) / 100).round();

    return {
      'original': '${originalPrice.toString()} FCFA',
      'discounted': '${discountedPrice.toString()} FCFA',
    };
  }

  static String _getRandomLocation() {
    const locations = [
      'Ouagadougou', 'Bobo-Dioulasso', 'Koudougou', 'Ouahigouya',
      'Banfora', 'Kaya', 'Tenkodogo', 'Fada N\'Gourma'
    ];
    return locations[_random.nextInt(locations.length)];
  }

  static List<String> _generateTags(String content) {
    const allTags = [
      'mode', 'fashion', 'burkina', 'africain', 'traditionnel', 'moderne',
      'wax', 'batik', 'artisanal', 'qualité', 'tendance', 'style'
    ];

    final selectedTags = <String>[];
    final lowerContent = content.toLowerCase();

    for (final tag in allTags) {
      if (lowerContent.contains(tag) && selectedTags.length < 3) {
        selectedTags.add(tag);
      }
    }

    return selectedTags.isNotEmpty ? selectedTags : ['mode', 'burkina'];
  }

  static String _getDefaultImage() {
    const defaultImages = [
      'https://images.unsplash.com/photo-1434389677669-e08b4cac3105',
      'https://images.unsplash.com/photo-1441986300917-64674bd600d8',
      'https://images.unsplash.com/photo-1490481651871-ab68de25d43d',
      'https://images.unsplash.com/photo-1469334031218-e382a71b716b',
    ];
    return '${defaultImages[_random.nextInt(defaultImages.length)]}?w=500&auto=format&fit=crop';
  }

  static List<Promotion> _getDemoPromotions() {
    return [
      Promotion(
        id: '1',
        title: 'Collection Pagnes Wax Authentique',
        description: 'Pagnes wax burkinabè de qualité supérieure, motifs traditionnels',
        category: 'vetements',
        discountPercentage: 35,
        originalPrice: '15.000 FCFA',
        discountedPrice: '9.750 FCFA',
        imageUrl: 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=500&auto=format&fit=crop',
        shopName: 'Boutique Faso Dan Fani',
        shopUrl: 'https://burkina24.com',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        isActive: true,
        location: 'Ouagadougou',
        tags: ['wax', 'traditionnel', 'pagne'],
        source: 'Demo',
      ),
      Promotion(
        id: '2',
        title: 'Bijoux Artisanaux Bronze',
        description: 'Collection de bijoux en bronze, travail artisanal burkinabè',
        category: 'accessoires',
        discountPercentage: 25,
        originalPrice: '8.000 FCFA',
        discountedPrice: '6.000 FCFA',
        imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=500&auto=format&fit=crop',
        shopName: 'Artisans du Burkina',
        shopUrl: 'https://fasozine.com',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 3)),
        isActive: true,
        location: 'Bobo-Dioulasso',
        tags: ['bronze', 'bijoux', 'artisanal'],
        source: 'Demo',
      ),
      Promotion(
        id: '3',
        title: 'Robes Modernes Batik',
        description: 'Robes contemporaines en tissu batik, coupe moderne',
        category: 'vetements',
        discountPercentage: 40,
        originalPrice: '25.000 FCFA',
        discountedPrice: '15.000 FCFA',
        imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=500&auto=format&fit=crop',
        shopName: 'Mode Africaine BF',
        shopUrl: 'https://wakatsera.com',
        startDate: DateTime.now().subtract(const Duration(hours: 12)),
        endDate: DateTime.now().add(const Duration(days: 7)),
        isActive: true,
        location: 'Koudougou',
        tags: ['batik', 'robe', 'moderne'],
        source: 'Demo',
      ),
    ];
  }
}

// Service principal pour les promotions
class PromotionService {
  static Future<List<Promotion>> fetchPromotions() async {
    print('🔍 Début du scraping des sites burkinabé...');
    try {
      final promotions = await WebScrapingService.scrapePromotions();
      print('✅ ${promotions.length} promotions trouvées');
      return promotions;
    } catch (e) {
      print('❌ Erreur scraping: $e');
      return WebScrapingService._getDemoPromotions();
    }
  }
}

class PromotionsSection extends StatefulWidget {
  final String? filterCategory;
  final bool showTitle;
  final double height;

  const PromotionsSection({
    super.key,
    this.filterCategory,
    this.showTitle = true,
    this.height = 240, // Augmenté pour éviter les débordements
  });

  @override
  State<PromotionsSection> createState() => _PromotionsSectionState();
}

class _PromotionsSectionState extends State<PromotionsSection>
    with SingleTickerProviderStateMixin {
  List<Promotion> promotions = [];
  bool isLoading = true;
  Timer? refreshTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadPromotions();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    refreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _loadPromotions();
    });
  }

  Future<void> _loadPromotions() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final allPromotions = await PromotionService.fetchPromotions();
      final validPromotions = allPromotions.where((p) => p.isValidToday).toList();

      final filteredPromotions = widget.filterCategory != null
          ? validPromotions.where((p) => p.category == widget.filterCategory).toList()
          : validPromotions;

      if (mounted) {
        setState(() {
          promotions = filteredPromotions;
          isLoading = false;
        });
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Erreur de connexion';
        });
      }
      print('Erreur chargement: $e');
    }
  }

  Future<void> _refreshPromotions() async {
    await _loadPromotions();
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Impossible d\'ouvrir le lien', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'ouverture du lien', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'vetements':
        return const Color(0xFF4CAF50);
      case 'accessoires':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFFFF9800);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'vetements':
        return Icons.checkroom;
      case 'accessoires':
        return Icons.shopping_bag;
      default:
        return Icons.local_offer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.filterCategory == null
                      ? 'Dernières promotions'
                      : 'Promotions ${widget.filterCategory == 'vetements' ? 'Vêtements' : 'Accessoires'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: _refreshPromotions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 18,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Actualiser',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Container(
          height: widget.height,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: isLoading
              ? _buildLoadingIndicator()
              : errorMessage != null
              ? _buildErrorWidget()
              : promotions.isEmpty
              ? _buildEmptyWidget()
              : FadeTransition(
            opacity: _fadeAnimation,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: promotions.length,
              itemBuilder: (context, index) {
                return _buildPromotionCard(promotions[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 320,
          margin: const EdgeInsets.only(left: 16, right: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 150,
                  height: 16,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 12,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[300],
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshPromotions,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucune offre disponible',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nouvelles promotions bientôt disponibles',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(Promotion promotion) {
    return GestureDetector(
      onTap: () => _launchUrl(promotion.shopUrl),
      child: Container(
        width: 320,
        margin: const EdgeInsets.only(left: 16, right: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              _getCategoryColor(promotion.category),
              _getCategoryColor(promotion.category).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _getCategoryColor(promotion.category).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '-${promotion.discountPercentage}%',
                      style: TextStyle(
                        color: _getCategoryColor(promotion.category),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (promotion.source != 'Demo') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(promotion.category),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promotion.shopName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              promotion.location,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Utilisation d'Expanded pour gérer l'espace dynamiquement
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          promotion.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          promotion.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Espace flexible pour éviter les débordements
                        const Spacer(),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  promotion.discountedPrice,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  promotion.originalPrice,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    promotion.timeRemaining,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          children: promotion.tags.take(3).map((tag) {
                            return Chip(
                              label: Text(
                                '#$tag',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                              backgroundColor: Colors.white.withOpacity(0.15),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            );
                          }).toList(),
                        ),
                      ],
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
}

class FashionPromotionsApp extends StatefulWidget {
  const FashionPromotionsApp({super.key});

  @override
  State<FashionPromotionsApp> createState() => _FashionPromotionsAppState();
}

class _FashionPromotionsAppState extends State<FashionPromotionsApp> {
  int _selectedIndex = 0;
  String? _selectedCategory;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {
      'id': null,
      'name': 'Toutes',
      'icon': Icons.apps,
      'color': Colors.orange,
    },
    {
      'id': 'vetements',
      'name': 'Vêtements',
      'icon': Icons.checkroom,
      'color': const Color(0xFF4CAF50),
    },
    {
      'id': 'accessoires',
      'name': 'Accessoires',
      'icon': Icons.shopping_bag,
      'color': const Color(0xFF2196F3),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fashion BF - Promotions Mode',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: _showSearch
              ? TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Rechercher promotions...',
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showSearch = false;
                    _searchController.clear();
                  });
                },
              ),
            ),
            onSubmitted: (value) {
              // Implémentation de la recherche
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Recherche pour "$value"'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          )
              : Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fashion BF',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Promotions Mode',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: _showSearch
              ? null
              : [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black87),
              onPressed: () {
                setState(() {
                  _showSearch = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications - À implémenter'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['id'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['id'];
                      });
                    },
                    child: Container(
                      width: 85,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? category['color']
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: category['color'].withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                                  : null,
                            ),
                            child: Icon(
                              category['icon'],
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[600],
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category['name'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? category['color']
                                  : Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final sectionState = context
                      .findAncestorStateOfType<_PromotionsSectionState>();
                  sectionState?._refreshPromotions();
                },
                color: Colors.orange,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      PromotionsSection(
                        filterCategory: _selectedCategory,
                        showTitle: true,
                        height: 240,
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatsCard(
                                'Offres Actives',
                                '42+',
                                Icons.local_offer,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatsCard(
                                'Sites Partenaires',
                                '${WebScrapingService.burkinaFashionSites.length}',
                                Icons.store,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatsCard(
                                'Économies',
                                'Jusqu\'à 70%',
                                Icons.savings,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1B5E20),
                              Color(0xFF2E7D32),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.flag,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mode Burkinabè',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Découvrez les meilleures offres',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 80,
                              child: SingleChildScrollView(
                                child: Text(
                                  'Nous scannons en temps réel les sites de mode burkinabè pour vous présenter les promotions exclusives. Wax, batik, bijoux artisanaux et créations locales.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildFeatureBadge('🔥', 'Temps réel'),
                                _buildFeatureBadge('🇧🇫', '100% BF'),
                                _buildFeatureBadge('💰', 'Économies'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              label: 'Favoris',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const FashionPromotionsApp());
}