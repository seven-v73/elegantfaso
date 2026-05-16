import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/inspiration/external_look.dart';
import '../../../../../services/inspiration/inspiration_wishlist_service.dart';
import '../../../../../services/inspiration/moodboard_service.dart';
import '../../../client/features/virtual_try_on_screen.dart';

class MoodboardSection extends StatefulWidget {
  const MoodboardSection({
    super.key,
    required this.searchQuery,
    required this.onFindTutorials,
  });

  final String searchQuery;
  final ValueChanged<String> onFindTutorials;

  @override
  State<MoodboardSection> createState() => _MoodboardSectionState();
}

class _MoodboardSectionState extends State<MoodboardSection> {
  final MoodboardService _moodboardService = MoodboardService();
  final InspirationWishlistService _wishlistService =
      InspirationWishlistService();
  final PageController _controller = PageController(viewportFraction: 0.84);

  Timer? _slideTimer;
  Timer? _refreshTimer;
  List<ExternalLook> _looks = const [];
  Set<String> _savedLookIds = const {};
  bool _isLoading = true;
  int _queryIndex = 0;
  int _lookPage = Random().nextInt(4);

  String get _effectiveQuery =>
      widget.searchQuery.trim().isNotEmpty
          ? '${widget.searchQuery.trim()} fashion style inspiration'
          : MoodboardService.queries[_queryIndex];

  @override
  void initState() {
    super.initState();
    _loadWishlistState();
    _loadLooks();
    _slideTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_controller.hasClients || _looks.length < 2) return;
      final next = ((_controller.page ?? 0).round() + 1) % _looks.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 3),
      (_) => _loadLooks(rotate: true),
    );
  }

  @override
  void didUpdateWidget(covariant MoodboardSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _loadLooks(rotate: true);
    }
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _refreshTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLooks({bool rotate = false}) async {
    if (mounted) setState(() => _isLoading = true);
    if (rotate) {
      final random = Random(DateTime.now().millisecondsSinceEpoch);
      _queryIndex =
          (_queryIndex + 1 + random.nextInt(MoodboardService.queries.length)) %
          MoodboardService.queries.length;
      _lookPage = random.nextInt(6);
    }
    try {
      final looks = await _moodboardService.load(
        query: _effectiveQuery,
        page: _lookPage,
      );
      if (!mounted) return;
      setState(() {
        _looks = looks;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _looks = _moodboardService.fallback(_lookPage);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWishlistState() async {
    final ids = await _wishlistService.loadSavedIds();
    if (!mounted) return;
    setState(() => _savedLookIds = ids);
  }

  Future<void> _toggleWishlist(ExternalLook look) async {
    final isSaved = _savedLookIds.contains(look.id);
    ExternalLook? removed;
    if (isSaved) {
      removed = await _wishlistService.remove(look);
    } else {
      await _wishlistService.save(look);
    }
    await _loadWishlistState();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved
              ? 'Retiré des souhaits.'
              : 'Ajouté aux souhaits de votre garde-robe.',
        ),
        behavior: SnackBarBehavior.floating,
        action:
            removed == null
                ? null
                : SnackBarAction(
                  label: 'Annuler',
                  onPressed: () async {
                    await _wishlistService.save(removed!);
                    await _loadWishlistState();
                  },
                ),
      ),
    );
  }

  void _openWishlist() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _WishlistSheet(
            wishlistService: _wishlistService,
            onChanged: _loadWishlistState,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          padding: EdgeInsets.zero,
          title: 'Moodboard du Salon',
          subtitle:
              _isLoading
                  ? 'Actualisation des sélections...'
                  : 'Images renouvelées pour nourrir vos idées',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                tooltip: 'Souhaits',
                onPressed: _openWishlist,
                icon: Badge(
                  isLabelVisible: _savedLookIds.isNotEmpty,
                  label: Text(_savedLookIds.length.toString()),
                  child: const Icon(Icons.favorite_rounded),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Actualiser',
                onPressed: () => _loadLooks(rotate: true),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child:
              _isLoading && _looks.isEmpty
                  ? const AppCard(
                    child: Center(child: CircularProgressIndicator()),
                  )
                  : PageView.builder(
                    controller: _controller,
                    itemCount: _looks.length,
                    itemBuilder: (context, index) {
                      final look = _looks[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _LookCard(
                          look: look,
                          isSaved: _savedLookIds.contains(look.id),
                          onToggle: () => _toggleWishlist(look),
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => LookPreviewScreen(
                                        look: look,
                                        isSaved: _savedLookIds.contains(
                                          look.id,
                                        ),
                                        onToggle: () => _toggleWishlist(look),
                                        onFindTutorials: widget.onFindTutorials,
                                      ),
                                ),
                              ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

class _LookCard extends StatelessWidget {
  const _LookCard({
    required this.look,
    required this.isSaved,
    required this.onToggle,
    required this.onTap,
  });

  final ExternalLook look;
  final bool isSaved;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ModernRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: look.imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder:
                  (_, _) => const ColoredBox(
                    color: ModernColors.line,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              errorWidget:
                  (_, _, _) => const ColoredBox(
                    color: ModernColors.line,
                    child: Center(child: Icon(Icons.image_outlined)),
                  ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _RoundAction(
                tooltip:
                    isSaved ? 'Retirer des souhaits' : 'Ajouter aux souhaits',
                icon:
                    isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                color: isSaved ? const Color(0xFFE11D48) : ModernColors.ink,
                onPressed: onToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 8,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: color),
      ),
    );
  }
}

class LookPreviewScreen extends StatelessWidget {
  const LookPreviewScreen({
    super.key,
    required this.look,
    required this.isSaved,
    required this.onToggle,
    required this.onFindTutorials,
  });

  final ExternalLook look;
  final bool isSaved;
  final VoidCallback onToggle;
  final ValueChanged<String> onFindTutorials;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: isSaved ? 'Retirer des souhaits' : 'Ajouter aux souhaits',
            onPressed: onToggle,
            icon: Icon(
              isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isSaved ? const Color(0xFFE11D48) : Colors.white,
            ),
          ),
          IconButton(
            tooltip: 'Partager',
            onPressed:
                () => SharePlus.instance.share(
                  ShareParams(
                    text: '${look.title}\n${look.imageUrl}',
                    subject: 'Inspiration ElegantStyle',
                  ),
                ),
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: look.imageUrl,
                fit: BoxFit.contain,
                errorWidget:
                    (_, _, _) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white,
                      size: 42,
                    ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  AppButton(
                    label: 'Essayer',
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => VirtualTryOnScreen(
                                  initialImagePath: look.imageUrl,
                                ),
                          ),
                        ),
                    icon: Icons.checkroom_rounded,
                    variant: AppButtonVariant.secondary,
                    compact: true,
                  ),
                  AppButton(
                    label: 'Explorer',
                    onPressed: () {
                      onFindTutorials(look.title);
                      Navigator.pop(context);
                    },
                    icon: Icons.explore_rounded,
                    compact: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistSheet extends StatefulWidget {
  const _WishlistSheet({
    required this.wishlistService,
    required this.onChanged,
  });

  final InspirationWishlistService wishlistService;
  final Future<void> Function() onChanged;

  @override
  State<_WishlistSheet> createState() => _WishlistSheetState();
}

class _WishlistSheetState extends State<_WishlistSheet> {
  late Future<List<ExternalLook>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.wishlistService.loadLooks();
  }

  void _reload() {
    setState(() {
      _future = widget.wishlistService.loadLooks();
    });
  }

  Future<void> _remove(ExternalLook look) async {
    final removed = await widget.wishlistService.remove(look);
    await widget.onChanged();
    _reload();
    if (!mounted || removed == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Souhait retiré.'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () async {
            await widget.wishlistService.save(removed);
            await widget.onChanged();
            _reload();
          },
        ),
      ),
    );
  }

  Future<void> _addNote(ExternalLook look) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Note du souhait'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'à montrer au tailleur, pour mariage...',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              AppButton(
                label: 'Enregistrer',
                onPressed: () => Navigator.pop(context, controller.text),
                compact: true,
              ),
            ],
          ),
    );
    controller.dispose();
    if (note == null || note.trim().isEmpty) return;
    await widget.wishlistService.addNote(look, note);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: FutureBuilder<List<ExternalLook>>(
            future: _future,
            builder: (context, snapshot) {
              final looks = snapshot.data ?? const <ExternalLook>[];
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ModernColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Souhaits de garde-robe',
                    style: TextStyle(
                      color: ModernColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Transformez une inspiration en projet, ajoutez une note ou lancez un essayage.',
                    style: TextStyle(
                      color: ModernColors.inkSoft,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (looks.isEmpty)
                    const AppCard(
                      child: Text(
                        'Touchez le cœur sur une inspiration pour la garder ici.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    for (final look in looks) ...[
                      _WishlistTile(
                        look: look,
                        onRemove: () => _remove(look),
                        onNote: () => _addNote(look),
                        onProject:
                            () => widget.wishlistService.markAsProject(look),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _WishlistTile extends StatelessWidget {
  const _WishlistTile({
    required this.look,
    required this.onRemove,
    required this.onNote,
    required this.onProject,
  });

  final ExternalLook look;
  final VoidCallback onRemove;
  final VoidCallback onNote;
  final VoidCallback onProject;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: look.imageUrl,
              width: 76,
              height: 92,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  look.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TinyAction(
                      label: 'Note',
                      icon: Icons.edit_note_rounded,
                      onTap: onNote,
                    ),
                    _TinyAction(
                      label: 'Projet',
                      icon: Icons.task_alt_rounded,
                      onTap: onProject,
                    ),
                    _TinyAction(
                      label: 'Retirer',
                      icon: Icons.delete_outline_rounded,
                      onTap: onRemove,
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

class _TinyAction extends StatelessWidget {
  const _TinyAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onTap,
      icon: icon,
      variant: AppButtonVariant.secondary,
      compact: true,
    );
  }
}
