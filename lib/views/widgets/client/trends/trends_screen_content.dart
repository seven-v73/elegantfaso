import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:elegantfaso/design/app_styles.dart';
import 'package:elegantfaso/providers/fashion_provider.dart';
import 'package:elegantfaso/views/widgets/client/trend_card.dart';
import 'package:elegantfaso/views/widgets/client/look_of_the_day_card.dart';

class TrendsScreenContent extends StatelessWidget {
  const TrendsScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FashionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.loadInitialData,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => provider.loadTrends(refresh: true),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (provider.featured != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: LookOfTheDayCard(
                    imageUrl: provider.featured!.imageUrl,
                    title: provider.featured!.title,
                    description: provider.featured!.description,
                    onTap: () {},
                  ),
                ),
              _buildCategoryList(context, provider),
              _buildViewToggle(context, provider),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child:
                    provider.trends.isEmpty
                        ? const Center(child: Text('Aucune tendance trouvée.'))
                        : provider.isGridView
                        ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.7,
                              ),
                          itemCount: provider.trends.length,
                          itemBuilder: (context, index) {
                            final item = provider.trends[index];
                            return TrendCard(
                              title: item.title,
                              imageUrl: item.imageUrl,
                              likes: item.likes,
                              designer: item.designer,
                            );
                          },
                        )
                        : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: provider.trends.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = provider.trends[index];
                            return TrendCard(
                              title: item.title,
                              imageUrl: item.imageUrl,
                              likes: item.likes,
                              designer: item.designer,
                            );
                          },
                        ),
              ),
              if (provider.isFetchingMore)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryList(BuildContext context, FashionProvider provider) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: provider.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = provider.categories[index];
          final isSelected = provider.selectedCategory == index;
          return ChoiceChip(
            label: Text(category['name']),
            selected: isSelected,
            avatar: Icon(
              category['icon'],
              size: 20,
              color: isSelected ? Colors.white : AppStyles.primary,
            ),
            selectedColor: AppStyles.primary,
            onSelected: (_) => provider.setCategory(index),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppStyles.primary,
            ),
            backgroundColor: AppStyles.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewToggle(BuildContext context, FashionProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(
            provider.isGridView ? Icons.view_list : Icons.grid_view_rounded,
          ),
          tooltip:
              provider.isGridView ? 'Afficher en liste' : 'Afficher en grille',
          onPressed: provider.toggleViewMode,
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
