import '../../models/inspiration/youtube_video.dart';
import 'inspiration_api_service.dart';

class TutorialTopic {
  const TutorialTopic({
    required this.title,
    required this.query,
    required this.iconName,
  });

  final String title;
  final String query;
  final String iconName;
}

class YoutubeTutorialService {
  YoutubeTutorialService({InspirationApiService? apiService})
    : _apiService = apiService ?? InspirationApiService();

  final InspirationApiService _apiService;

  static const topics = [
    TutorialTopic(
      title: 'Tenues',
      query: 'fashion outfit styling tutorial complete look',
      iconName: 'checkroom',
    ),
    TutorialTopic(
      title: 'Coiffures',
      query: 'hairstyle tutorial braids protective styles beauty',
      iconName: 'hair',
    ),
    TutorialTopic(
      title: 'Couture',
      query: 'sewing tailoring fashion design tutorial clothes',
      iconName: 'design',
    ),
    TutorialTopic(
      title: 'Chaussures',
      query: 'how to style shoes with outfits tutorial',
      iconName: 'shoes',
    ),
    TutorialTopic(
      title: 'Maquillage',
      query: 'makeup tutorial beauty fashion look',
      iconName: 'makeup',
    ),
    TutorialTopic(
      title: 'Accessoires',
      query: 'how to accessorize outfits jewelry bags scarf tutorial',
      iconName: 'accessories',
    ),
    TutorialTopic(
      title: 'Mode africaine',
      query: 'african fashion ankara wax styling tutorial',
      iconName: 'africa',
    ),
    TutorialTopic(
      title: 'Hommes',
      query: 'mens fashion outfit styling tutorial elegant',
      iconName: 'menswear',
    ),
  ];

  Future<List<YoutubeVideo>> load(String query) async {
    final videos = await _apiService.loadVideos(query);
    return videos.isEmpty ? fallbackVideos : videos;
  }

  static const fallbackVideos = [
    YoutubeVideo(
      id: 'M7lc1UVf-VE',
      title: 'Lecture YouTube intégrée',
      channelTitle: 'Inspiration vidéo',
      thumbnailUrl: 'https://img.youtube.com/vi/M7lc1UVf-VE/hqdefault.jpg',
    ),
    YoutubeVideo(
      id: 'aqz-KE-bpKQ',
      title: 'Tutoriel vidéo de démonstration',
      channelTitle: 'Inspiration vidéo',
      thumbnailUrl: 'https://img.youtube.com/vi/aqz-KE-bpKQ/hqdefault.jpg',
    ),
  ];
}
