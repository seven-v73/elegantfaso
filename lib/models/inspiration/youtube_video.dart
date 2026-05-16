class YoutubeVideo {
  const YoutubeVideo({
    required this.id,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    this.description = '',
  });

  final String id;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final String description;

  String get url => 'https://www.youtube.com/watch?v=$id';
}
