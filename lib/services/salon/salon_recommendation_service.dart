import '../../models/salon/salon_context.dart';
import '../../models/salon/salon_item.dart';
import 'salon_unified_search_service.dart';

class SalonRecommendationService {
  SalonRecommendationService({SalonUnifiedSearchService? searchService})
    : _searchService = searchService ?? SalonUnifiedSearchService();

  final SalonUnifiedSearchService _searchService;

  Future<List<SalonItem>> relatedTo(SalonItem item) {
    return _searchService.loadRecommendations(
      SalonContext.fromQuery(
        '${item.title} ${item.subtitle} ${item.tags.join(' ')}',
      ),
    );
  }
}
