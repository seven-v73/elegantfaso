import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/createur/creator_creation.dart';
import '../../../../services/createur/creator_creation_service.dart';
import '../../../widgets/common/app_action_empty_state.dart';
import '../../commerce/catalogue_express_screen.dart';
import '../creations/add_creation_screen.dart';
import '../creations/edit_creation_screen.dart';
import '../model/creation.dart' as legacy;
import '../widgets/creator_creation_card.dart';
import '../widgets/creator_status_chip.dart';

class CreationsTab extends StatefulWidget {
  const CreationsTab({
    super.key,
    required this.user,
    required this.onOpenSalon,
    this.showFloatingActionButton = true,
  });

  final User user;
  final VoidCallback onOpenSalon;
  final bool showFloatingActionButton;

  @override
  State<CreationsTab> createState() => _CreationsTabState();
}

class _CreationsTabState extends State<CreationsTab> {
  final CreatorCreationService _service = CreatorCreationService();
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String _filter = 'Toutes';

  static const _filters = [
    'Toutes',
    'Salon',
    'Brouillons',
    'Masquées',
    'Demandées',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CreatorCreation> _applyFilters(List<CreatorCreation> creations) {
    final query = _query.trim().toLowerCase();
    return creations.where((creation) {
      final matchesQuery =
          query.isEmpty ||
          '${creation.title} ${creation.category} ${creation.description}'
              .toLowerCase()
              .contains(query);
      final matchesFilter = switch (_filter) {
        'Salon' => creation.isVisibleInSalon,
        'Brouillons' => creation.isDraft,
        'Masquées' => creation.isHidden,
        'Demandées' => creation.requestsCount > 0,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _delete(CreatorCreation creation) async {
    await _service.deleteCreation(creation.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${creation.title} archivée.'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () => _service.restoreCreation(creation),
        ),
      ),
    );
  }

  void _showDetails(CreatorCreation creation) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _CreationDetailSheet(
            creation: creation,
            onEdit: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => EditCreationScreen(
                        creation: _legacyCreation(creation),
                      ),
                ),
              );
            },
            onToggleVisibility:
                () => _service.updateStatus(
                  creation.id,
                  creation.isHidden ? 'published' : 'hidden',
                ),
            onPreview: widget.onOpenSalon,
          ),
    );
  }

  void _openAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCreationScreen()),
    );
  }

  void _openExpress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CatalogueExpressScreen(role: 'createur'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      floatingActionButton:
          widget.showFloatingActionButton
              ? FloatingActionButton.extended(
                heroTag: null,
                onPressed: _openExpress,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Publier'),
              )
              : null,
      body: StreamBuilder<List<CreatorCreation>>(
        stream: _service.watchCreations(widget.user.uid),
        builder: (context, snapshot) {
          final allCreations = snapshot.data ?? const [];
          final creations = _applyFilters(allCreations);
          final visibleCount =
              allCreations
                  .where((creation) => creation.isVisibleInSalon)
                  .length;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
              children: [
                _InventoryHeader(
                  controller: _searchController,
                  query: _query,
                  visibleCount: visibleCount,
                  totalCount: allCreations.length,
                  onQueryChanged: (value) => setState(() => _query = value),
                  onAddManual: _openAdd,
                  onOpenSalon: widget.onOpenSalon,
                ),
                const SizedBox(height: 12),
                _FilterRail(
                  filters: _filters,
                  selected: _filter,
                  onSelected: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const _LoadingGrid()
                else if (snapshot.hasError)
                  const _CreationState(
                    icon: Icons.error_outline_rounded,
                    title: 'Créations indisponibles',
                    message: 'Impossible de charger votre portfolio.',
                  )
                else if (creations.isEmpty)
                  _CreationState(
                    icon: Icons.checkroom_outlined,
                    title: 'Aucune création',
                    message: 'Ajoutez une création ou préparez un brouillon.',
                    actionLabel: 'Ajout rapide',
                    onAction: _openExpress,
                    secondaryActionLabel: 'Fiche détaillée',
                    onSecondaryAction: _openAdd,
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                    itemCount: creations.length,
                    itemBuilder: (context, index) {
                      final creation = creations[index];
                      return CreatorCreationCard(
                        creation: creation,
                        onTap: () => _showDetails(creation),
                        onEdit:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => EditCreationScreen(
                                      creation: _legacyCreation(creation),
                                    ),
                              ),
                            ),
                        onToggleVisibility:
                            () => _service.updateStatus(
                              creation.id,
                              creation.isHidden ? 'published' : 'hidden',
                            ),
                        onDuplicate: () => _service.duplicateCreation(creation),
                        onDelete: () => _delete(creation),
                        onPreview: widget.onOpenSalon,
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  legacy.Creation _legacyCreation(CreatorCreation creation) {
    return legacy.Creation(
      id: creation.id,
      createurId: creation.creatorId,
      title: creation.title,
      description: creation.description,
      category: creation.category,
      images: creation.images,
      price: creation.price,
      createdAt: creation.createdAt ?? DateTime.now(),
      updatedAt: creation.updatedAt,
    );
  }
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader({
    required this.controller,
    required this.query,
    required this.visibleCount,
    required this.totalCount,
    required this.onQueryChanged,
    required this.onAddManual,
    required this.onOpenSalon,
  });

  final TextEditingController controller;
  final String query;
  final int visibleCount;
  final int totalCount;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onAddManual;
  final VoidCallback onOpenSalon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Portfolio',
                      style: TextStyle(
                        color: ModernColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$visibleCount/$totalCount visibles dans le Salon',
                      style: const TextStyle(color: ModernColors.inkSoft),
                    ),
                  ],
                ),
              ),
              AppIconAction(
                icon: AppIcons.salon,
                tooltip: 'Salon',
                onPressed: onOpenSalon,
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Ajouter une création détaillée',
                onPressed: onAddManual,
                icon: const Icon(Icons.edit_note_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher une création...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon:
                  query.isEmpty
                      ? null
                      : IconButton(
                        onPressed: () {
                          controller.clear();
                          onQueryChanged('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              filled: true,
              fillColor: ModernColors.canvas,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRail extends StatelessWidget {
  const _FilterRail({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return ChoiceChip(
            label: Text(filter),
            selected: filter == selected,
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _CreationDetailSheet extends StatelessWidget {
  const _CreationDetailSheet({
    required this.creation,
    required this.onEdit,
    required this.onToggleVisibility,
    required this.onPreview,
  });

  final CreatorCreation creation;
  final VoidCallback onEdit;
  final VoidCallback onToggleVisibility;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ModernColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                creation.title,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  CreatorStatusChip(
                    label: creation.statusLabel,
                    color: creatorStatusColor(creation.status),
                  ),
                  CreatorStatusChip(
                    label: creation.category,
                    color: ModernColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 4 / 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    color: ModernColors.canvas,
                    child:
                        creation.coverImage.isEmpty
                            ? const Icon(Icons.image_rounded, size: 42)
                            : Image.network(
                              creation.coverImage,
                              fit: BoxFit.cover,
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                creation.description.isEmpty
                    ? 'Aucune description.'
                    : creation.description,
                style: const TextStyle(color: ModernColors.inkSoft),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Vues',
                      value: '${creation.viewsCount}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Metric(
                      label: 'Souhaits',
                      value: '${creation.savesCount}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Metric(
                      label: 'Demandes',
                      value: '${creation.requestsCount}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Modifier',
                onPressed: onEdit,
                icon: Icons.edit_rounded,
                expand: true,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: creation.isHidden ? 'Publier' : 'Masquer',
                onPressed: onToggleVisibility,
                icon: Icons.visibility_rounded,
                variant: AppButtonVariant.outline,
                expand: true,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Salon',
                onPressed: onPreview,
                icon: AppIcons.salon,
                variant: AppButtonVariant.outline,
                expand: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      color: ModernColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: ModernColors.creator,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: ModernColors.inkSoft, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.68,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _CreationState extends StatelessWidget {
  const _CreationState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return AppActionEmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      secondaryActionLabel: secondaryActionLabel,
      onSecondaryAction: onSecondaryAction,
      accent: ModernColors.creator,
    );
  }
}
