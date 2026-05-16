import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../models/inspiration/external_look.dart';
import '../../models/inspiration/youtube_video.dart';

class InspirationApiService {
  static String? get _youtubeKey => _clean(dotenv.env['YOUTUBE_API_KEY']);
  static String? get _unsplashKey => _clean(dotenv.env['UNSPLASH_ACCESS_KEY']);
  static String? get _serpApiKey => _clean(dotenv.env['SERPAPI_KEY']);

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<List<ExternalLook>> loadLooks(String query, {int page = 0}) async {
    if (_unsplashKey != null) {
      return _loadUnsplashLooks(query, page: page);
    }
    if (_serpApiKey != null) {
      return _loadSerpImageLooks(query, page: page);
    }
    return const [];
  }

  Future<List<YoutubeVideo>> loadVideos(String query) async {
    if (_youtubeKey != null) {
      return _loadYoutubeDataApi(query);
    }
    if (_serpApiKey != null) {
      return _loadSerpYoutube(query);
    }
    return const [];
  }

  Future<List<ExternalLook>> _loadUnsplashLooks(
    String query, {
    int page = 0,
  }) async {
    final uri = Uri.https('api.unsplash.com', '/search/photos', {
      'query': query,
      'per_page': '10',
      'page': (page + 1).toString(),
      'orientation': 'portrait',
      'order_by': 'latest',
      'content_filter': 'high',
      'client_id': _unsplashKey!,
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return const [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'];
    if (results is! List) return const [];

    return results
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final urls = item['urls'];
          final imageUrl =
              urls is Map
                  ? (urls['regular']?.toString() ??
                      urls['small']?.toString() ??
                      '')
                  : '';
          return ExternalLook(
            id:
                item['id']?.toString().isNotEmpty == true
                    ? item['id'].toString()
                    : ExternalLook.idFromImage(imageUrl),
            title:
                item['alt_description']?.toString() ??
                item['description']?.toString() ??
                'Inspiration mode',
            subtitle: 'Sélection visuelle',
            imageUrl: imageUrl,
            source: 'Unsplash',
            tags: const ['look', 'mode'],
          );
        })
        .where((look) => look.imageUrl.isNotEmpty)
        .toList();
  }

  Future<List<ExternalLook>> _loadSerpImageLooks(
    String query, {
    int page = 0,
  }) async {
    final uri = Uri.https('serpapi.com', '/search.json', {
      'engine': 'google_images',
      'q': query,
      'ijn': page.toString(),
      'api_key': _serpApiKey!,
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return const [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['images_results'];
    if (results is! List) return const [];

    return results
        .whereType<Map<String, dynamic>>()
        .take(12)
        .map((item) {
          final imageUrl =
              item['original']?.toString() ??
              item['thumbnail']?.toString() ??
              '';
          return ExternalLook(
            id: ExternalLook.idFromImage(imageUrl),
            title: item['title']?.toString() ?? 'Inspiration mode',
            subtitle: item['source']?.toString() ?? 'Sélection visuelle',
            imageUrl: imageUrl,
            source: 'Inspiration',
            tags: const ['look', 'mode'],
          );
        })
        .where((look) => look.imageUrl.isNotEmpty)
        .toList();
  }

  Future<List<YoutubeVideo>> _loadYoutubeDataApi(String query) async {
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'key': _youtubeKey!,
      'q': query,
      'part': 'snippet',
      'type': 'video',
      'maxResults': '10',
      'order': 'relevance',
      'videoEmbeddable': 'true',
      'videoSyndicated': 'true',
      'safeSearch': 'moderate',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return const [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'];
    if (items is! List) return const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final id = item['id'];
          final snippet = item['snippet'];
          final thumbnails = snippet is Map ? snippet['thumbnails'] : null;
          final high =
              thumbnails is Map
                  ? thumbnails['high'] ?? thumbnails['medium']
                  : null;
          return YoutubeVideo(
            id: id is Map ? id['videoId']?.toString() ?? '' : '',
            title:
                snippet is Map
                    ? snippet['title']?.toString() ?? 'Tutoriel mode'
                    : 'Tutoriel mode',
            channelTitle:
                snippet is Map
                    ? snippet['channelTitle']?.toString() ?? 'YouTube'
                    : 'YouTube',
            thumbnailUrl: high is Map ? high['url']?.toString() ?? '' : '',
            description:
                snippet is Map ? snippet['description']?.toString() ?? '' : '',
          );
        })
        .where((video) => video.id.isNotEmpty)
        .toList();
  }

  Future<List<YoutubeVideo>> _loadSerpYoutube(String query) async {
    final uri = Uri.https('serpapi.com', '/search.json', {
      'engine': 'youtube',
      'search_query': query,
      'api_key': _serpApiKey!,
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return const [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['video_results'];
    if (results is! List) return const [];

    return results
        .whereType<Map<String, dynamic>>()
        .take(10)
        .map((item) {
          final link = item['link']?.toString() ?? '';
          return YoutubeVideo(
            id: _youtubeIdFromUrl(link) ?? '',
            title: item['title']?.toString() ?? 'Tutoriel mode',
            channelTitle:
                item['channel'] is Map
                    ? (item['channel']['name']?.toString() ?? 'YouTube')
                    : 'YouTube',
            thumbnailUrl: item['thumbnail']?.toString() ?? '',
          );
        })
        .where((video) => video.id.isNotEmpty)
        .toList();
  }

  String? _youtubeIdFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    if (uri.host.contains('youtube.com')) {
      final watchId = uri.queryParameters['v'];
      if (watchId != null && watchId.isNotEmpty) return watchId;
      final shortsIndex = uri.pathSegments.indexOf('shorts');
      if (shortsIndex != -1 && uri.pathSegments.length > shortsIndex + 1) {
        return uri.pathSegments[shortsIndex + 1];
      }
      final embedIndex = uri.pathSegments.indexOf('embed');
      if (embedIndex != -1 && uri.pathSegments.length > embedIndex + 1) {
        return uri.pathSegments[embedIndex + 1];
      }
    }
    return null;
  }
}
