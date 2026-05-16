import 'dart:math';

import '../../models/inspiration/external_look.dart';
import 'inspiration_api_service.dart';

class MoodboardService {
  MoodboardService({InspirationApiService? apiService})
    : _apiService = apiService ?? InspirationApiService();

  final InspirationApiService _apiService;

  static const queries = [
    'fashion outfit street style',
    'wedding guest fashion outfit',
    'braids hairstyle fashion beauty',
    'fashion shoes outfit inspiration',
    'african fashion editorial',
    'modest fashion outfit',
    'menswear tailoring outfit',
    'fashion accessories editorial',
  ];

  Future<List<ExternalLook>> load({
    required String query,
    required int page,
  }) async {
    final looks = await _apiService.loadLooks(query, page: page);
    return looks.isEmpty ? fallback(page) : looks;
  }

  List<ExternalLook> fallback(int page) {
    final looks = List<ExternalLook>.from(_fallbackLooks);
    looks.shuffle(Random(page + DateTime.now().minute));
    return looks.take(6).toList();
  }

  static const _fallbackLooks = [
    ExternalLook(
      id: 'fallback-streetwear',
      title: 'Streetwear affirmé',
      subtitle: 'Couleurs fortes, sneakers et silhouettes urbaines',
      imageUrl:
          'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=900&q=80',
      source: 'Inspiration',
    ),
    ExternalLook(
      id: 'fallback-ceremonie',
      title: 'Cérémonie moderne',
      subtitle: 'Tenues élégantes pour mariage et grands événements',
      imageUrl:
          'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=80',
      source: 'Inspiration',
    ),
    ExternalLook(
      id: 'fallback-beaute',
      title: 'Coiffures et beauté',
      subtitle: 'Tresses, textures, coupes et finitions beauté',
      imageUrl:
          'https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=900&q=80',
      source: 'Inspiration',
    ),
    ExternalLook(
      id: 'fallback-tailoring',
      title: 'Atelier couture',
      subtitle: 'Coupes, matières et création contemporaine',
      imageUrl:
          'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?auto=format&fit=crop&w=900&q=80',
      source: 'Inspiration',
    ),
    ExternalLook(
      id: 'fallback-shoes',
      title: 'Chaussures statement',
      subtitle: 'Silhouettes, matières et détails de style',
      imageUrl:
          'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=900&q=80',
      source: 'Inspiration',
    ),
    ExternalLook(
      id: 'fallback-editorial',
      title: 'Editorial mode',
      subtitle: 'Silhouettes soignées et détails de coupe',
      imageUrl:
          'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=900&q=80',
      source: 'Inspiration',
    ),
    ExternalLook(
      id: 'fallback-accessories',
      title: 'Accessoires',
      subtitle: 'Bijoux, sacs et finitions élégantes',
      imageUrl:
          'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?auto=format&fit=crop&w=900&q=80',
      source: 'Inspiration',
    ),
    ExternalLook(
      id: 'fallback-menswear',
      title: 'Menswear',
      subtitle: 'Élégance masculine et tailoring',
      imageUrl:
          'https://images.unsplash.com/photo-1516257984-b1b4d707412e?auto=format&fit=crop&w=900&q=80',
      source: 'Inspiration',
    ),
  ];
}
