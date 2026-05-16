import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/try_on/try_on_source.dart';
import '../../../../../models/wardrobe/wardrobe_item.dart';
import '../../../../../services/wardrobe/wardrobe_service.dart';
import '../../../../widgets/forms/app_form_section.dart';
import '../../../../widgets/forms/app_image_picker_field.dart';
import '../../../../widgets/forms/app_select_field.dart';
import '../../../../widgets/forms/app_sticky_form_bar.dart';
import '../../../../widgets/forms/app_text_field.dart';
import '../../../global/salon_search_screen.dart';
import '../../../global/widgets/inspiration/community_screen.dart';
import '../../secondhand/client_secondhand_screen.dart';
import '../virtual_try_on_screen.dart';
part 'wardrobe_add_item_sheet.dart';
part 'wardrobe_filter_widgets.dart';
part 'wardrobe_support_models.dart';

enum WardrobeViewMode { visual, compact, list }

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key, this.embeddedInClientShell = false});

  final bool embeddedInClientShell;

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen>
    with TickerProviderStateMixin {
  static const _pageSize = 30;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  final WardrobeService _wardrobeService = WardrobeService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  User? _currentUser;
  String? _currentUserId;
  String? _userPhotoUrl;
  String _searchQuery = '';
  String _selectedCategory = 'Tous';
  String _selectedColor = 'Toutes';
  String _selectedBrand = 'Toutes';
  String _selectedOccasion = 'Toutes';
  String _selectedSeason = 'Toutes';
  WardrobeViewMode _viewMode = WardrobeViewMode.visual;
  final Set<String> _selectedIds = {};
  List<WardrobeItem> _itemsCache = const [];
  bool _selectionMode = false;
  int _visibleCount = _pageSize;

  static const Color _primaryColor = ModernColors.primary;
  static const Color _primaryDark = ModernColors.primaryDark;
  static const Color _amberAccent = ModernColors.accent;
  static const Color _roseAccent = ModernColors.rose;
  static const Color _blueInfo = ModernColors.client;
  static const Color _successGreen = ModernColors.success;
  static const Color _errorRed = Color(0xFFDC2626);
  static const Color _bgColor = ModernColors.canvas;
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = ModernColors.ink;
  static const Color _textSecondary = ModernColors.inkSoft;
  static const Color _borderColor = ModernColors.line;

  static const List<String> _categories = [
    'Tous',
    'Haut',
    'Bas',
    'Robe',
    'Chaussures',
    'Accessoires',
    'Veste',
    'Souhaits',
  ];

  static const List<String> _occasions = [
    'Toutes',
    'Travail',
    'Soirée',
    'Décontracté',
    'Sport',
    'Cérémonie',
  ];

  static const List<String> _seasons = [
    'Toutes',
    'Toute saison',
    'Saison chaude',
    'Saison fraîche',
    'Pluie',
  ];

  @override
  void initState() {
    super.initState();
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animationController = animationController;
    _fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic),
    );
    _searchController.addListener(_onSearchChanged);
    animationController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _animationController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim();
        _visibleCount = _pageSize;
      });
    });
  }

  Future<void> _loadUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    final user = _currentUser;
    if (user == null) return;

    _currentUserId = user.uid;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();
      if (!mounted) return;
      setState(() {
        _userPhotoUrl = data?['photoUrl']?.toString() ?? user.photoURL;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userPhotoUrl = user.photoURL;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: widget.embeddedInClientShell ? null : _buildAppBar(),
      body:
          userId == null
              ? _buildSignedOutState()
              : StreamBuilder<List<WardrobeItem>>(
                stream: _wardrobeService.watchItems(userId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }
                  if (!snapshot.hasData) {
                    return _buildLoading();
                  }

                  final allItems = snapshot.data!;
                  _itemsCache = allItems;
                  final filteredItems = _filterItems(allItems);
                  final visibleItems =
                      filteredItems.take(_visibleCount).toList();
                  final summary = _WardrobeSummary.fromItems(allItems);

                  return RefreshIndicator(
                    color: _primaryColor,
                    onRefresh: () async {
                      await _loadUserData();
                      setState(() {});
                    },
                    child: FadeTransition(
                      opacity:
                          _fadeAnimation ??
                          const AlwaysStoppedAnimation<double>(1),
                      child: SlideTransition(
                        position:
                            _slideAnimation ??
                            const AlwaysStoppedAnimation<Offset>(Offset.zero),
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: _buildHeader(summary, allItems),
                            ),
                            SliverToBoxAdapter(child: _buildSearchAndModes()),
                            SliverToBoxAdapter(child: _buildQuickFilters()),
                            if (filteredItems.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _buildEmptyState(allItems.isEmpty),
                              )
                            else ...[
                              _buildItemsSliver(visibleItems, allItems),
                              if (_visibleCount < filteredItems.length)
                                SliverToBoxAdapter(
                                  child: _buildLoadMoreButton(
                                    remaining:
                                        filteredItems.length -
                                        visibleItems.length,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton:
          _selectionMode || userId == null ? null : _buildAddButton(),
      bottomNavigationBar:
          _selectionMode ? _buildSelectionBar(userId ?? '') : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: Icon(
          _selectionMode ? Icons.close_rounded : Icons.arrow_back_rounded,
          color: _textPrimary,
        ),
        onPressed:
            _selectionMode
                ? _clearSelection
                : () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        _selectionMode ? '${_selectedIds.length} sélectionné(s)' : 'Garde-robe',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: _textPrimary,
        ),
      ),
      centerTitle: true,
      backgroundColor: _cardColor,
      elevation: 0,
      actions: _wardrobeActions(),
    );
  }

  List<Widget> _wardrobeActions() {
    if (_selectionMode) {
      return [
        IconButton(
          tooltip: 'Supprimer',
          onPressed: _selectedIds.isEmpty ? null : _deleteSelectedItems,
          icon: const Icon(Icons.delete_rounded, color: _errorRed),
        ),
      ];
    }
    return [
      IconButton(
        tooltip: 'Filtres',
        onPressed: _showFiltersSheet,
        icon: const Icon(Icons.tune_rounded, color: _primaryColor),
      ),
    ];
  }

  Widget _buildHeader(_WardrobeSummary summary, List<WardrobeItem> items) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, ModernColors.surfaceRaised, Color(0xFFEFF7F6)],
          stops: [0, .56, 1],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            offset: Offset(0, 18),
            blurRadius: 32,
            spreadRadius: -18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .78),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child:
                      _userPhotoUrl == null || _userPhotoUrl!.isEmpty
                          ? Container(
                            color: _primaryColor.withValues(alpha: .1),
                            child: const Icon(
                              Icons.checkroom_rounded,
                              color: _primaryColor,
                            ),
                          )
                          : Image.network(_userPhotoUrl!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.totalItems == 0
                          ? 'Dressing prêt'
                          : 'Mon dressing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary.lastAdded == null
                          ? '${summary.totalItems} pièce(s) à composer'
                          : 'Dernière pièce : ${summary.lastAdded!.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .72),
                  foregroundColor: _primaryColor,
                ),
                onPressed: items.isEmpty ? null : () => _showOutfitIdeas(items),
                icon: const Icon(Icons.auto_stories_rounded),
                tooltip: 'Carnet de looks',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  Icons.checkroom_rounded,
                  '${summary.totalItems}',
                  'Pièces',
                  _primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatTile(
                  Icons.label_outline_rounded,
                  summary.dominantCategory,
                  'Dominante',
                  _blueInfo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatTile(
                  Icons.auto_stories_rounded,
                  '${summary.outfitIdeas}',
                  'Looks',
                  _amberAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndModes() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Retrouver une pièce',
                prefixIcon: const Icon(Icons.manage_search_rounded),
                suffixIcon:
                    _searchQuery.isEmpty
                        ? null
                        : IconButton(
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                filled: true,
                fillColor: _cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          PopupMenuButton<WardrobeViewMode>(
            tooltip: 'Mode d’affichage',
            initialValue: _viewMode,
            onSelected: (mode) => setState(() => _viewMode = mode),
            itemBuilder:
                (context) => const [
                  PopupMenuItem(
                    value: WardrobeViewMode.visual,
                    child: Text('Visuel'),
                  ),
                  PopupMenuItem(
                    value: WardrobeViewMode.compact,
                    child: Text('Compact'),
                  ),
                  PopupMenuItem(
                    value: WardrobeViewMode.list,
                    child: Text('Liste'),
                  ),
                ],
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor),
              ),
              child: Icon(_viewModeIcon(_viewMode), color: _primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == _categories.length) {
            return _FilterChipButton(
              label: 'Plus',
              icon: Icons.tune_rounded,
              selected: _hasAdvancedFilters,
              onTap: _showFiltersSheet,
            );
          }
          final category = _categories[index];
          return _FilterChipButton(
            label: category,
            icon: _getCategoryIcon(category),
            selected: _selectedCategory == category,
            onTap:
                () => setState(() {
                  _selectedCategory = category;
                  _visibleCount = _pageSize;
                }),
          );
        },
      ),
    );
  }

  SliverPadding _buildItemsSliver(
    List<WardrobeItem> items,
    List<WardrobeItem> allItems,
  ) {
    if (_viewMode == WardrobeViewMode.list) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildListItem(items[index], allItems);
          },
        ),
      );
    }

    final isCompact = _viewMode == WardrobeViewMode.compact;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isCompact ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isCompact ? 0.7 : 0.72,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildWardrobeCard(items[index], allItems, compact: isCompact);
        },
      ),
    );
  }

  Widget _buildLoadMoreButton({required int remaining}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 108),
      child: AppButton(
        label: 'Voir $remaining',
        onPressed: () => setState(() => _visibleCount += _pageSize),
        icon: Icons.expand_more_rounded,
        variant: AppButtonVariant.outline,
        expand: true,
      ),
    );
  }

  Widget _buildWardrobeCard(
    WardrobeItem item,
    List<WardrobeItem> allItems, {
    bool compact = false,
  }) {
    final selected = _selectedIds.contains(item.id);
    final looksCount = _generateOutfits(item, allItems).length;

    return Dismissible(
      key: ValueKey(item.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _wardrobeService.toggleFavorite(item);
          _showSnack(item.favorite ? 'Favori retiré' : 'Ajouté aux favoris');
          return false;
        }
        return await _confirmDelete(item);
      },
      onDismissed: (_) => _wardrobeService.deleteItem(item.userId, item.id),
      background: _buildSwipeBackground(
        Icons.favorite_rounded,
        'Favori',
        _roseAccent,
        Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        Icons.delete_rounded,
        'Supprimer',
        _errorRed,
        Alignment.centerRight,
      ),
      child: GestureDetector(
        onLongPress:
            _selectionMode
                ? () => _toggleSelection(item.id)
                : () => _showQuickItemMenu(item, allItems),
        onTap:
            _selectionMode
                ? () => _toggleSelection(item.id)
                : () => _showItemDetails(item, allItems),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color:
                  selected
                      ? _primaryColor
                      : _borderColor.withValues(alpha: 0.9),
              width: selected ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                offset: Offset(0, 14),
                blurRadius: 24,
                spreadRadius: -16,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: compact ? 5 : 6,
                      child: _buildItemImage(item.coverImage, item.category),
                    ),
                    Expanded(
                      flex: compact ? 4 : 5,
                      child: Padding(
                        padding: EdgeInsets.all(compact ? 8 : 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: compact ? 12 : 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (!compact) ...[
                              const SizedBox(height: 4),
                              Text(
                                [
                                  if (item.brand.isNotEmpty) item.brand,
                                  if (item.color.isNotEmpty) item.color,
                                ].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: [
                                if (item.tryOnDisplayLabel.isNotEmpty)
                                  _miniBadge(
                                    item.tryOnDisplayLabel,
                                    _tryOnExperienceColor(item),
                                  ),
                                _miniBadge(
                                  item.category,
                                  _getCategoryColor(item.category),
                                ),
                                if (!compact && looksCount > 0)
                                  _miniBadge(
                                    '$looksCount look(s)',
                                    _amberAccent,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      if (item.wearCount >= 3)
                        _iconBadge(Icons.repeat_rounded, _amberAccent),
                      if (item.favorite)
                        _iconBadge(Icons.favorite_rounded, _roseAccent),
                      if (_selectionMode)
                        _iconBadge(
                          selected ? Icons.check_circle : Icons.circle_outlined,
                          _primaryColor,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(WardrobeItem item, List<WardrobeItem> allItems) {
    final selected = _selectedIds.contains(item.id);
    final looksCount = _generateOutfits(item, allItems).length;

    return Dismissible(
      key: ValueKey('list_${item.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _wardrobeService.toggleFavorite(item);
          return false;
        }
        return await _confirmDelete(item);
      },
      onDismissed: (_) => _wardrobeService.deleteItem(item.userId, item.id),
      background: _buildSwipeBackground(
        Icons.favorite_rounded,
        'Favori',
        _roseAccent,
        Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        Icons.delete_rounded,
        'Supprimer',
        _errorRed,
        Alignment.centerRight,
      ),
      child: ListTile(
        onTap:
            _selectionMode
                ? () => _toggleSelection(item.id)
                : () => _showItemDetails(item, allItems),
        onLongPress:
            _selectionMode
                ? () => _toggleSelection(item.id)
                : () => _showQuickItemMenu(item, allItems),
        tileColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: selected ? _primaryColor : _borderColor),
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 56,
            height: 56,
            child: _buildItemImage(item.coverImage, item.category),
          ),
        ),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            if (item.tryOnDisplayLabel.isNotEmpty) item.tryOnDisplayLabel,
            item.category,
            if (item.brand.isNotEmpty) item.brand,
            if (item.color.isNotEmpty) item.color,
            if (looksCount > 0) '$looksCount look(s)',
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing:
            _selectionMode
                ? Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: _primaryColor,
                )
                : PopupMenuButton<String>(
                  onSelected:
                      (value) => _handleItemAction(value, item, allItems),
                  itemBuilder:
                      (context) => const [
                        PopupMenuItem(value: 'favorite', child: Text('Favori')),
                        PopupMenuItem(
                          value: 'worn',
                          child: Text('Porté aujourd’hui'),
                        ),
                        PopupMenuItem(value: 'edit', child: Text('Modifier')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer'),
                        ),
                      ],
                ),
      ),
    );
  }

  Widget _buildSwipeBackground(
    IconData icon,
    String label,
    Color color,
    Alignment alignment,
  ) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      padding: EdgeInsets.only(left: isLeft ? 20 : 0, right: isLeft ? 0 : 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Color _tryOnExperienceColor(WardrobeItem item) {
    return switch (item.tryOnExperience) {
      'faceAccessory' => _blueInfo,
      'aiGarment' => _primaryColor,
      'freePreview' => _amberAccent,
      _ => _primaryDark,
    };
  }

  Widget _buildItemImage(String imagePath, String? category) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder:
            (context, url) => Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _primaryColor,
              ),
            ),
        errorWidget: (_, _, _) => _buildImageFallback(category),
      );
    }
    if (imagePath.isNotEmpty) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildImageFallback(category),
      );
    }
    return _buildImageFallback(category);
  }

  Widget _buildImageFallback(String? category) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(category).withValues(alpha: .08),
            _primaryColor.withValues(alpha: .04),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .78),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getCategoryIcon(category ?? 'Tous'),
            size: 31,
            color: _getCategoryColor(category),
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .12)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 5),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8)],
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton.extended(
      heroTag: null,
      onPressed: _showAddItemSheet,
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_photo_alternate_rounded),
      label: const Text('Ajouter une pièce'),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildSelectionBar(String userId) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: _cardColor,
          boxShadow: [BoxShadow(color: Color(0x140F172A), blurRadius: 18)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${_selectedIds.length} pièce(s) sélectionnée(s)',
                style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Organiser',
              onPressed: _selectedIds.isEmpty ? null : _showBulkOrganizeSheet,
              icon: const Icon(Icons.folder_special_rounded),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Annuler',
              onPressed: _clearSelection,
              icon: const Icon(Icons.close_rounded),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Supprimer',
              style: IconButton.styleFrom(backgroundColor: _errorRed),
              onPressed: _selectedIds.isEmpty ? null : _deleteSelectedItems,
              icon: const Icon(Icons.delete_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignedOutState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off_rounded,
              size: 78,
              color: _textSecondary,
            ),
            const SizedBox(height: 18),
            const Text(
              'Connectez-vous pour gérer votre garde-robe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _loadUserData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder:
          (context, index) => Shimmer.fromColors(
            baseColor: const Color(0xFFE2E8F0),
            highlightColor: const Color(0xFFF8FAFC),
            child: Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
    );
  }

  Widget _buildErrorState(String message) {
    final needsIndex = message.contains('index');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 72, color: _errorRed),
            const SizedBox(height: 18),
            Text(
              needsIndex
                  ? 'Index Firestore requis'
                  : 'Impossible de charger la garde-robe',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              needsIndex
                  ? 'Créez l’index demandé par Firebase pour userId/isArchived/createdAt, ou retirez temporairement le tri.'
                  : message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noItemsAtAll) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.checkroom_rounded,
              color: _primaryColor,
              size: 52,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            noItemsAtAll ? 'Votre dressing est prêt' : 'Aucune pièce trouvée',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noItemsAtAll
                ? 'Ajoutez vos premières pièces pour composer des tenues adaptées à vos occasions.'
                : 'Essayez de retirer quelques filtres ou cherchez un autre mot-clé.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textSecondary,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              AppButton(
                label: 'Importer',
                onPressed:
                    () => _showAddItemSheet(initialSource: ImageSource.gallery),
                icon: Icons.add_photo_alternate_rounded,
                compact: true,
              ),
              AppButton(
                label: 'Prendre photo',
                onPressed:
                    () => _showAddItemSheet(initialSource: ImageSource.camera),
                icon: Icons.photo_camera_rounded,
                variant: AppButtonVariant.secondary,
                compact: true,
              ),
              AppButton(
                label: 'Exemple',
                onPressed: _createSampleItem,
                icon: Icons.checkroom_rounded,
                variant: AppButtonVariant.outline,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<WardrobeItem> _filterItems(List<WardrobeItem> items) {
    final query = _searchQuery.toLowerCase();
    return items.where((item) {
      if (item.isArchived) return false;
      final matchesSearch =
          query.isEmpty ||
          [
            item.name,
            item.brand,
            item.color,
            item.category,
            item.occasion,
            item.season,
          ].any((value) => value.toLowerCase().contains(query));
      final matchesCategory =
          _selectedCategory == 'Tous' || item.category == _selectedCategory;
      final matchesColor =
          _selectedColor == 'Toutes' || item.color == _selectedColor;
      final matchesBrand =
          _selectedBrand == 'Toutes' || item.brand == _selectedBrand;
      final matchesOccasion =
          _selectedOccasion == 'Toutes' || item.occasion == _selectedOccasion;
      final matchesSeason =
          _selectedSeason == 'Toutes' || item.season == _selectedSeason;
      return matchesSearch &&
          matchesCategory &&
          matchesColor &&
          matchesBrand &&
          matchesOccasion &&
          matchesSeason;
    }).toList();
  }

  bool get _hasAdvancedFilters {
    return _selectedColor != 'Toutes' ||
        _selectedBrand != 'Toutes' ||
        _selectedOccasion != 'Toutes' ||
        _selectedSeason != 'Toutes';
  }

  void _showFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _FiltersSheet(
            colors: _availableColors,
            brands: _availableBrands,
            selectedCategory: _selectedCategory,
            selectedColor: _selectedColor,
            selectedBrand: _selectedBrand,
            selectedOccasion: _selectedOccasion,
            selectedSeason: _selectedSeason,
            onApply: (category, color, brand, occasion, season) {
              setState(() {
                _selectedCategory = category;
                _selectedColor = color;
                _selectedBrand = brand;
                _selectedOccasion = occasion;
                _selectedSeason = season;
                _visibleCount = _pageSize;
              });
            },
          ),
    );
  }

  List<String> get _availableColors {
    final values =
        _itemsCache
            .map((item) => item.color.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['Toutes', ...values];
  }

  List<String> get _availableBrands {
    final values =
        _itemsCache
            .map((item) => item.brand.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['Toutes', ...values];
  }

  void _showItemDetails(WardrobeItem item, List<WardrobeItem> allItems) {
    final outfits = _generateOutfits(item, allItems);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.78,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, controller) => Container(
                  decoration: const BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _borderColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (item.images.isNotEmpty)
                        SizedBox(
                          height: 280,
                          child: PageView(
                            children:
                                item.images
                                    .map(
                                      (image) => ClipRRect(
                                        borderRadius: BorderRadius.circular(22),
                                        child: _buildItemImage(
                                          image,
                                          item.category,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(
                                item.category,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              _getCategoryIcon(item.category),
                              color: _getCategoryColor(item.category),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  [
                                    if (item.brand.isNotEmpty) item.brand,
                                    if (item.color.isNotEmpty) item.color,
                                  ].join(' • '),
                                  style: const TextStyle(
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await _wardrobeService.toggleFavorite(item);
                              if (context.mounted) Navigator.pop(context);
                            },
                            icon: Icon(
                              item.favorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: _roseAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _miniBadge(
                            item.category,
                            _getCategoryColor(item.category),
                          ),
                          if (item.tryOnDisplayLabel.isNotEmpty)
                            _miniBadge(
                              item.tryOnDisplayLabel,
                              _tryOnExperienceColor(item),
                            ),
                          if (item.occasion.isNotEmpty)
                            _miniBadge(item.occasion, _blueInfo),
                          if (item.season.isNotEmpty)
                            _miniBadge(item.season, _successGreen),
                          if (item.wearCount > 0)
                            _miniBadge(
                              '${item.wearCount} porté(s)',
                              _amberAccent,
                            ),
                        ],
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const Text(
                          'Notes',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: _textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _buildQuickActions(item, allItems),
                      const SizedBox(height: 22),
                      if (outfits.isNotEmpty) ...[
                        const Text(
                          'Looks',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...outfits.take(3).map(_buildOutfitCard),
                      ],
                    ],
                  ),
                ),
          ),
    );
  }

  void _showQuickItemMenu(WardrobeItem item, List<WardrobeItem> allItems) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x180F172A), blurRadius: 24),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 58,
                          height: 58,
                          child: _buildItemImage(
                            item.coverImage,
                            item.category,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              [
                                item.category,
                                if (item.brand.isNotEmpty) item.brand,
                                if (item.color.isNotEmpty) item.color,
                              ].join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _QuickMenuAction(
                        icon: Icons.check_circle_rounded,
                        label: 'Sélectionner',
                        onTap: () {
                          Navigator.pop(context);
                          _toggleSelection(item.id);
                        },
                      ),
                      _QuickMenuAction(
                        icon:
                            item.favorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                        label: item.favorite ? 'Retirer favori' : 'Favori',
                        onTap: () async {
                          Navigator.pop(context);
                          await _wardrobeService.toggleFavorite(item);
                        },
                      ),
                      _QuickMenuAction(
                        icon: Icons.edit_rounded,
                        label: 'Modifier',
                        onTap: () {
                          Navigator.pop(context);
                          _showAddItemSheet(item: item);
                        },
                      ),
                      _QuickMenuAction(
                        icon: Icons.auto_stories_rounded,
                        label: 'Composer',
                        onTap: () {
                          Navigator.pop(context);
                          _showOutfitIdeas(allItems, anchor: item);
                        },
                      ),
                      _QuickMenuAction(
                        icon: AppIcons.shop,
                        label: 'Similaire',
                        onTap: () {
                          Navigator.pop(context);
                          _openSalonForItem(item);
                        },
                      ),
                      _QuickMenuAction(
                        icon: Icons.sell_rounded,
                        label: 'Revendre',
                        onTap: () {
                          Navigator.pop(context);
                          _openSecondhandForItem();
                        },
                      ),
                      _QuickMenuAction(
                        icon: Icons.forum_rounded,
                        label: 'Avis',
                        onTap: () {
                          Navigator.pop(context);
                          _openCommunityForItem();
                        },
                      ),
                      _QuickMenuAction(
                        icon: Icons.checkroom_rounded,
                        label: 'Détail',
                        onTap: () {
                          Navigator.pop(context);
                          _showItemDetails(item, allItems);
                        },
                      ),
                      if (item.canRetryTryOn)
                        _QuickMenuAction(
                          icon: Icons.checkroom_rounded,
                          label: 'Essayer',
                          onTap: () {
                            Navigator.pop(context);
                            _openTryOnFromWardrobe(item);
                          },
                        ),
                      _QuickMenuAction(
                        icon: Icons.delete_rounded,
                        label: 'Supprimer',
                        danger: true,
                        onTap: () async {
                          Navigator.pop(context);
                          final confirmed = await _confirmDelete(item);
                          if (confirmed == true) {
                            await _wardrobeService.deleteItem(
                              item.userId,
                              item.id,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildQuickActions(WardrobeItem item, List<WardrobeItem> allItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (item.canRetryTryOn) ...[
          _ActionButton(
            icon: Icons.checkroom_rounded,
            label: 'Essayer',
            onTap: () {
              Navigator.pop(context);
              _openTryOnFromWardrobe(item);
            },
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _ActionButton(
                icon: Icons.auto_stories_rounded,
                label: 'Composer',
                onTap: () => _showOutfitIdeas(allItems, anchor: item),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.repeat_rounded,
                label: 'Porté',
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await _wardrobeService.markWorn(item);
                  if (!mounted) return;
                  navigator.pop();
                  _showSnack('Pièce marquée comme portée');
                },
              ),
            ),
            const SizedBox(width: 8),
            AppOverflowMenu(
              actions: [
                AppOverflowAction(
                  icon: AppIcons.shop,
                  label: 'Trouver similaire',
                  onPressed: () {
                    Navigator.pop(context);
                    _openSalonForItem(item);
                  },
                ),
                AppOverflowAction(
                  icon: Icons.sell_rounded,
                  label: 'Revendre',
                  onPressed: () {
                    Navigator.pop(context);
                    _openSecondhandForItem();
                  },
                ),
                AppOverflowAction(
                  icon: Icons.forum_rounded,
                  label: 'Demander avis',
                  onPressed: () {
                    Navigator.pop(context);
                    _openCommunityForItem();
                  },
                ),
                AppOverflowAction(
                  icon: Icons.edit_rounded,
                  label: 'Modifier',
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddItemSheet(item: item);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _salonQueryForItem(WardrobeItem item) {
    return [
      item.name,
      if (item.category.isNotEmpty) item.category,
      if (item.color.isNotEmpty) item.color,
      if (item.occasion.isNotEmpty) item.occasion,
    ].join(' ').trim();
  }

  void _openSalonForItem(WardrobeItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SalonSearchScreen(initialQuery: _salonQueryForItem(item)),
      ),
    );
  }

  void _openCommunityForItem() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityScreen()),
    );
  }

  void _openSecondhandForItem() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClientSecondhandScreen()),
    );
  }

  void _openTryOnFromWardrobe(WardrobeItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => VirtualTryOnScreen(
              initialSource: TryOnSource(
                id: item.sourceId.isEmpty ? item.id : item.sourceId,
                type: _tryOnSourceType(item.sourceType),
                title: item.name.replaceFirst(RegExp(r'^Essayage\s*-\s*'), ''),
                subtitle:
                    item.tryOnDisplayLabel.isNotEmpty
                        ? item.tryOnDisplayLabel
                        : item.category,
                imageUrl: item.sourceImageUrl,
                ownerId:
                    item.sourceOwnerId.isEmpty
                        ? item.userId
                        : item.sourceOwnerId,
                raw: _retryTryOnRaw(item),
              ),
            ),
      ),
    );
  }

  TryOnSourceType _tryOnSourceType(String value) {
    return TryOnSourceType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => TryOnSourceType.gallery,
    );
  }

  Map<String, dynamic> _retryTryOnRaw(WardrobeItem item) {
    return {
      ...item.sourceRaw,
      if (item.tryOnKind.isNotEmpty) 'tryOnKind': item.tryOnKind,
      if (item.tryOnExperience.isNotEmpty)
        'tryOnExperience': item.tryOnExperience,
      'tryOnModes': [
        ...((item.sourceRaw['tryOnModes'] as List?) ?? const []),
        if (item.tryOnExperience == 'faceAccessory') 'face',
        if (item.tryOnExperience == 'aiGarment') 'ai',
        'preview',
      ],
    };
  }

  void _showAddItemSheet({WardrobeItem? item, ImageSource? initialSource}) {
    final userId = _currentUserId;
    if (userId == null) return;
    showModalBottomSheet<WardrobeItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AddWardrobeItemSheet(
            userId: userId,
            item: item,
            initialSource: initialSource,
            service: _wardrobeService,
          ),
    ).then((savedItem) {
      if (savedItem != null && mounted) {
        _showAddedConfirmation(savedItem);
      }
    });
  }

  Future<void> _createSampleItem() async {
    final userId = _currentUserId;
    if (userId == null) return;
    final item = WardrobeItem(
      id: '',
      userId: userId,
      name: 'Chemise signature',
      category: 'Haut',
      brand: 'ElegantStyle',
      color: 'blanc',
      occasion: 'Travail',
      season: 'Toute saison',
      description: 'Pièce d’inspiration pour explorer les recommandations.',
      favorite: true,
    );
    final id = await _wardrobeService.addItem(item);
    _showAddedConfirmation(item.copyWith(id: id));
  }

  void _showAddedConfirmation(WardrobeItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: _buildItemImage(item.coverImage, item.category),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pièce enregistrée',
                        style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showItemDetails(item, [item, ..._itemsCache]);
                      },
                      child: const Text('Voir'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddItemSheet();
                      },
                      child: const Text('Autre'),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Future<bool?> _confirmDelete(WardrobeItem item) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer cette pièce ?'),
            content: Text('"${item.name}" sera retirée de votre garde-robe.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _errorRed),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteSelectedItems() async {
    final userId = _currentUserId;
    if (userId == null || _selectedIds.isEmpty) return;
    await _wardrobeService.deleteItems(userId, _selectedIds);
    _showSnack('${_selectedIds.length} pièce(s) supprimée(s)');
    _clearSelection();
  }

  void _showBulkOrganizeSheet() {
    var category = 'Conserver';
    var occasion = 'Conserver';
    var season = 'Conserver';
    final categories = ['Conserver', ..._categories.where((e) => e != 'Tous')];
    final occasions = ['Conserver', ..._occasions.where((e) => e != 'Toutes')];
    final seasons = ['Conserver', ..._seasons.where((e) => e != 'Toutes')];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setSheetState) => Container(
                  margin: const EdgeInsets.all(16),
                  padding: EdgeInsets.only(
                    left: 18,
                    right: 18,
                    top: 18,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                  ),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Organiser la sélection',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _bulkDropdown(
                        label: 'Catégorie',
                        value: category,
                        values: categories,
                        onChanged:
                            (value) => setSheetState(() => category = value),
                      ),
                      _bulkDropdown(
                        label: 'Occasion',
                        value: occasion,
                        values: occasions,
                        onChanged:
                            (value) => setSheetState(() => occasion = value),
                      ),
                      _bulkDropdown(
                        label: 'Saison',
                        value: season,
                        values: seasons,
                        onChanged:
                            (value) => setSheetState(() => season = value),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Annuler',
                              onPressed: () => Navigator.pop(context),
                              variant: AppButtonVariant.tertiary,
                              expand: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              label: 'Appliquer',
                              onPressed: () async {
                                final updates = <String, dynamic>{};
                                if (category != 'Conserver') {
                                  updates['category'] = category;
                                }
                                if (occasion != 'Conserver') {
                                  updates['occasion'] = occasion;
                                }
                                if (season != 'Conserver') {
                                  updates['season'] = season;
                                }
                                if (updates.isEmpty) {
                                  Navigator.pop(context);
                                  return;
                                }
                                final userId = _currentUserId;
                                if (userId == null) return;
                                await _wardrobeService.updateItemsFields(
                                  userId,
                                  _selectedIds,
                                  updates,
                                );
                                if (!context.mounted || !mounted) return;
                                Navigator.pop(context);
                                _showSnack('Sélection organisée');
                                _clearSelection();
                              },
                              expand: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _bulkDropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: _bgColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        items:
            values
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      _selectionMode = true;
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _handleItemAction(
    String action,
    WardrobeItem item,
    List<WardrobeItem> allItems,
  ) async {
    switch (action) {
      case 'favorite':
        await _wardrobeService.toggleFavorite(item);
        break;
      case 'worn':
        await _wardrobeService.markWorn(item);
        break;
      case 'edit':
        _showAddItemSheet(item: item);
        break;
      case 'delete':
        final confirmed = await _confirmDelete(item);
        if (confirmed == true) {
          await _wardrobeService.deleteItem(item.userId, item.id);
        }
        break;
    }
  }

  void _showOutfitIdeas(List<WardrobeItem> items, {WardrobeItem? anchor}) {
    final ideas =
        anchor == null
            ? items.expand((item) => _generateOutfits(item, items)).toList()
            : _generateOutfits(anchor, items);
    ideas.sort((a, b) => b.score.compareTo(a.score));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.65,
            maxChildSize: 0.9,
            minChildSize: 0.35,
            builder:
                (context, controller) => Container(
                  decoration: const BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child:
                      ideas.isEmpty
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(28),
                              child: Text(
                                'Ajoutez plus de pièces avec couleurs, saisons et occasions pour composer des tenues.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                          : ListView(
                            controller: controller,
                            padding: const EdgeInsets.all(18),
                            children: [
                              const Text(
                                'Idées de tenues',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ...ideas.take(8).map(_buildOutfitCard),
                            ],
                          ),
                ),
          ),
    );
  }

  Widget _buildOutfitCard(_OutfitIdea idea) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, color: _amberAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  idea.name,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              _miniBadge('${idea.score}%', _amberAccent),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                idea.items
                    .map(
                      (item) => _miniBadge(
                        item.name,
                        _getCategoryColor(item.category),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  List<_OutfitIdea> _generateOutfits(
    WardrobeItem currentItem,
    List<WardrobeItem> allItems,
  ) {
    final rules = <String, List<String>>{
      'Travail': ['Haut', 'Bas', 'Chaussures', 'Accessoires'],
      'Soirée': ['Robe', 'Chaussures', 'Accessoires', 'Veste'],
      'Décontracté': ['Haut', 'Bas', 'Chaussures'],
      'Sport': ['Haut', 'Bas', 'Chaussures'],
      'Cérémonie': ['Robe', 'Chaussures', 'Accessoires'],
    };
    final ideas = <_OutfitIdea>[];
    for (final entry in rules.entries) {
      final occasion = entry.key;
      final required = entry.value;
      if (currentItem.occasion.isNotEmpty && currentItem.occasion != occasion) {
        continue;
      }
      final selected = <WardrobeItem>[currentItem];
      for (final category in required) {
        if (category == currentItem.category) continue;
        final matches =
            allItems
                .where(
                  (item) =>
                      item.category == category &&
                      item.id != currentItem.id &&
                      (currentItem.season.isEmpty ||
                          item.season.isEmpty ||
                          item.season == currentItem.season ||
                          item.season == 'Toute saison'),
                )
                .toList();
        if (matches.isNotEmpty) selected.add(matches.first);
      }
      if (selected.length >= 3) {
        ideas.add(
          _OutfitIdea(
            name: 'Tenue $occasion',
            occasion: occasion,
            items: selected,
            score: _scoreOutfit(selected, currentItem),
          ),
        );
      }
    }
    return ideas;
  }

  int _scoreOutfit(List<WardrobeItem> items, WardrobeItem anchor) {
    var score = 45 + items.length * 10;
    if (items.any(
      (item) => item.color == anchor.color && item.id != anchor.id,
    )) {
      score += 10;
    }
    if (items.any((item) => item.favorite)) score += 8;
    if (items.any((item) => item.season == anchor.season)) score += 8;
    return score.clamp(0, 98);
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Robe':
        return _roseAccent;
      case 'Haut':
        return _blueInfo;
      case 'Bas':
        return _primaryDark;
      case 'Chaussures':
        return _amberAccent;
      case 'Veste':
        return _successGreen;
      case 'Accessoires':
        return _primaryColor;
      case 'Souhaits':
        return _roseAccent;
      default:
        return _primaryColor;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Robe':
        return Icons.checkroom_rounded;
      case 'Haut':
        return Icons.style_rounded;
      case 'Bas':
        return Icons.dry_cleaning_rounded;
      case 'Chaussures':
        return Icons.directions_walk_rounded;
      case 'Veste':
        return Icons.layers_rounded;
      case 'Accessoires':
        return Icons.watch_rounded;
      case 'Souhaits':
        return Icons.favorite_rounded;
      default:
        return Icons.checkroom_rounded;
    }
  }

  IconData _viewModeIcon(WardrobeViewMode mode) {
    switch (mode) {
      case WardrobeViewMode.visual:
        return Icons.grid_view_rounded;
      case WardrobeViewMode.compact:
        return Icons.apps_rounded;
      case WardrobeViewMode.list:
        return Icons.view_agenda_rounded;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
