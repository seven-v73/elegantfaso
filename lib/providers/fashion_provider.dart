import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/fashion_item.dart';
import '../services/fashion_service.dart';

class FashionProvider extends ChangeNotifier {
  final FashionService _service = FashionService();
  List<FashionItem> _trends = [];
  List<FashionItem> _recommendations = [];
  FashionItem? _featured;
  int _selectedCategory = 0;
  String _sortOrder = 'popular';
  bool _isGridView = false;
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String? _error;
  double _minPrice = 1000;
  double _maxPrice = 100000;
  List<String> _selectedOccasions = [];
  bool _onlyLocalMade = false;
  bool _onlyInStock = false;
  bool _onlyNew = false;
  bool _showToTopButton = false;
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Toutes', 'icon': Icons.grid_view_rounded},
    {'name': 'Robes', 'icon': Icons.checkroom},
    {'name': 'Boubous', 'icon': Icons.person},
    {'name': 'Accessoires', 'icon': Icons.watch},
    {'name': 'Hommes', 'icon': Icons.male},
    {'name': 'Femmes', 'icon': Icons.female},
  ];

  List<FashionItem> get trends => _trends;
  List<FashionItem> get recommendations => _recommendations;
  FashionItem? get featured => _featured;
  int get selectedCategory => _selectedCategory;
  List<Map<String, dynamic>> get categories => _categories;
  String get sortOrder => _sortOrder;
  bool get isGridView => _isGridView;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get showToTopButton => _showToTopButton;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  List<String> get selectedOccasions => _selectedOccasions;
  bool get onlyLocalMade => _onlyLocalMade;
  bool get onlyInStock => _onlyInStock;
  bool get onlyNew => _onlyNew;

  FashionProvider() {
    loadInitialData();
  }

  void loadInitialData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await loadTrends(refresh: true);
      _service.getFeatured().listen((item) {
        _featured = item;
        if (_isLoading) {
          _isLoading = false;
          notifyListeners();
        }
      });
      loadRecommendations();
    } catch (e) {
      _error = "Une erreur est survenue lors du chargement des données";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTrends({bool refresh = false}) async {
    if (refresh) {
      _isLoading = true;
      _lastDocument = null;
      _trends = [];
      _hasMore = true;
      notifyListeners();
    } else if (_isFetchingMore || !_hasMore) {
      return;
    } else {
      _isFetchingMore = true;
      notifyListeners();
    }
    try {
      final items = await _service.getTrendsPaginated(
        sortBy: _sortOrder,
        filterCategory:
            selectedCategory == 0 ? null : categories[selectedCategory]['name'],
        filterOccasions: _selectedOccasions.isEmpty ? null : _selectedOccasions,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        onlyLocalMade: _onlyLocalMade,
        lastDocument: _lastDocument,
      );
      if (items.isEmpty) {
        _hasMore = false;
      } else {
        _trends.addAll(items);
      }
      if (_onlyInStock) {
        _trends = _trends.where((item) => item.inStock).toList();
      }
      if (_onlyNew) {
        _trends = _trends.where((item) => item.isNew).toList();
      }
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    } catch (e) {
      _error = "Impossible de charger les tendances";
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadRecommendations() async {
    try {
      _recommendations = await _service.getRecommendations('current_user_id');
      notifyListeners();
    } catch (e) {}
  }

  Future<bool> toggleFavorite(String itemId) async {
    try {
      bool success = await _service.toggleFavorite('current_user_id', itemId);
      if (success) {
        _trends =
            _trends.map((item) {
              if (item.id == itemId) {
                return FashionItem(
                  id: item.id,
                  title: item.title,
                  imageUrl: item.imageUrl,
                  likes: item.likes,
                  designer: item.designer,
                  designerImageUrl: item.designerImageUrl,
                  category: item.category,
                  isHot: item.isHot,
                  isNew: item.isNew,
                  styles: item.styles,
                  occasions: item.occasions,
                  description: item.description,
                  price: item.price,
                  availableSizes: item.availableSizes,
                  availableColors: item.availableColors,
                  matchingScore: item.matchingScore,
                  materialComposition: item.materialComposition,
                  origin: item.origin,
                  createdAt: item.createdAt,
                  viewCount: item.viewCount,
                  isFavorite: !item.isFavorite,
                  rating: item.rating,
                  reviewCount: item.reviewCount,
                  inStock: item.inStock,
                );
              }
              return item;
            }).toList();
        if (_featured != null && _featured!.id == itemId) {
          _featured = FashionItem(
            id: _featured!.id,
            title: _featured!.title,
            imageUrl: _featured!.imageUrl,
            likes: _featured!.likes,
            designer: _featured!.designer,
            designerImageUrl: _featured!.designerImageUrl,
            category: _featured!.category,
            isHot: _featured!.isHot,
            isNew: _featured!.isNew,
            styles: _featured!.styles,
            occasions: _featured!.occasions,
            description: _featured!.description,
            price: _featured!.price,
            availableSizes: _featured!.availableSizes,
            availableColors: _featured!.availableColors,
            matchingScore: _featured!.matchingScore,
            materialComposition: _featured!.materialComposition,
            origin: _featured!.origin,
            createdAt: _featured!.createdAt,
            viewCount: _featured!.viewCount,
            isFavorite: !_featured!.isFavorite,
            rating: _featured!.rating,
            reviewCount: _featured!.reviewCount,
            inStock: _featured!.inStock,
          );
        }
        _recommendations =
            _recommendations.map((item) {
              if (item.id == itemId) {
                return FashionItem(
                  id: item.id,
                  title: item.title,
                  imageUrl: item.imageUrl,
                  likes: item.likes,
                  designer: item.designer,
                  designerImageUrl: item.designerImageUrl,
                  category: item.category,
                  isHot: item.isHot,
                  isNew: item.isNew,
                  styles: item.styles,
                  occasions: item.occasions,
                  description: item.description,
                  price: item.price,
                  availableSizes: item.availableSizes,
                  availableColors: item.availableColors,
                  matchingScore: item.matchingScore,
                  materialComposition: item.materialComposition,
                  origin: item.origin,
                  createdAt: item.createdAt,
                  viewCount: item.viewCount,
                  isFavorite: !item.isFavorite,
                  rating: item.rating,
                  reviewCount: item.reviewCount,
                  inStock: item.inStock,
                );
              }
              return item;
            }).toList();
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  void setCategory(int index) {
    if (_selectedCategory == index) return;
    _selectedCategory = index;
    loadTrends(refresh: true);
  }

  void setSortOrder(String order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
    loadTrends(refresh: true);
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  void setShowToTopButton(bool show) {
    if (_showToTopButton != show) {
      _showToTopButton = show;
      notifyListeners();
    }
  }

  void setFilterPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    loadTrends(refresh: true);
  }

  void toggleFilterOccasion(String occasion) {
    if (_selectedOccasions.contains(occasion)) {
      _selectedOccasions.remove(occasion);
    } else {
      _selectedOccasions.add(occasion);
    }
    loadTrends(refresh: true);
  }

  void setSelectedOccasions(List<String> occasions) {
    _selectedOccasions = occasions;
    loadTrends(refresh: true);
  }

  void setOnlyLocalMade(bool value) {
    _onlyLocalMade = value;
    loadTrends(refresh: true);
  }

  void setOnlyInStock(bool value) {
    _onlyInStock = value;
    loadTrends(refresh: true);
  }

  void setOnlyNew(bool value) {
    _onlyNew = value;
    loadTrends(refresh: true);
  }

  void resetFilters() {
    _minPrice = 1000;
    _maxPrice = 100000;
    _selectedOccasions = [];
    _onlyLocalMade = false;
    _onlyInStock = false;
    _onlyNew = false;
    loadTrends(refresh: true);
  }

  List<FashionItem> get filteredItems => _trends;
}
