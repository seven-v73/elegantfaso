import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:convert';

class FashionTutorials extends StatefulWidget {
  const FashionTutorials({super.key});

  @override
  State<FashionTutorials> createState() => _FashionTutorialsState();
}

class _FashionTutorialsState extends State<FashionTutorials>
    with TickerProviderStateMixin {

  // REMPLACEZ PAR VOTRE VRAIE CLÉ API YOUTUBE
  static const String YOUTUBE_API_KEY = 'AIzaSyB8Cd9KFJNU5-RY3TvJohUUm6MvATz10z8';

  List<Map<String, dynamic>> tutorials = [];
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String selectedCategory = 'Mode africaine';
  String? error;

  // Catégories de recherche YouTube
  final Map<String, String> categories = {
    'Mode africaine': 'african fashion tutorial',
    'Pagne': 'pagne wax african fabric tutorial',
    'Boubou': 'boubou african dress tutorial',
    'Coiffure': 'african hairstyles braids tutorial',
    'Maquillage': 'makeup dark skin black women tutorial',
    'Accessoires': 'african jewelry accessories tutorial',
    'Couture': 'sewing african clothes tutorial',
    'Tendances': 'latest african fashion trends 2024',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadFashionVideos();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFashionVideos() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final searchQuery = categories[selectedCategory] ?? 'fashion tutorial';
      final url = Uri.parse(
          'https://www.googleapis.com/youtube/v3/search'
              '?key=$YOUTUBE_API_KEY'
              '&q=$searchQuery'
              '&part=snippet'
              '&type=video'
              '&maxResults=20'
              '&order=relevance'
              '&videoDuration=medium'
              '&videoDefinition=high'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Récupérer les statistiques des vidéos
        final videoIds = (data['items'] as List)
            .map((item) => item['id']['videoId'])
            .join(',');

        final statsUrl = Uri.parse(
            'https://www.googleapis.com/youtube/v3/videos'
                '?key=$YOUTUBE_API_KEY'
                '&id=$videoIds'
                '&part=statistics,contentDetails'
        );

        final statsResponse = await http.get(statsUrl);

        if (statsResponse.statusCode == 200) {
          final statsData = json.decode(statsResponse.body);
          final videosList = <Map<String, dynamic>>[];

          for (int i = 0; i < data['items'].length; i++) {
            final video = data['items'][i];
            final stats = statsData['items'][i];

            // Conversion de la durée ISO 8601 vers format lisible
            final duration = _parseDuration(stats['contentDetails']['duration']);
            final viewCount = _formatViewCount(stats['statistics']['viewCount']);

            videosList.add({
              'id': video['id']['videoId'],
              'title': video['snippet']['title'],
              'description': video['snippet']['description'],
              'thumbnail': video['snippet']['thumbnails']['high']['url'],
              'channelTitle': video['snippet']['channelTitle'],
              'publishedAt': video['snippet']['publishedAt'],
              'duration': duration,
              'viewCount': viewCount,
              'likeCount': stats['statistics']['likeCount'] ?? '0',
            });
          }

          setState(() {
            tutorials = videosList;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = 'Erreur de chargement: ${e.toString()}';
        isLoading = false;
      });

      // Fallback vers des données de démonstration si l'API échoue
      _loadDemoVideos();
    }
  }

  void _loadDemoVideos() {
    // Données de démonstration avec de vrais IDs YouTube
    setState(() {
      tutorials = [
        {
          'id': 'dQw4w9WgXcQ', // Exemple d'ID YouTube
          'title': 'Comment porter le pagne wax avec élégance',
          'description': 'Découvrez les techniques traditionnelles pour sublimer vos tenues en pagne...',
          'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
          'channelTitle': 'African Fashion TV',
          'publishedAt': '2024-01-15T10:00:00Z',
          'duration': '8:45',
          'viewCount': '125K',
          'likeCount': '3200',
        },
        {
          'id': 'ScMzIvxBSi4',
          'title': 'Tutoriel coiffure : Tresses africaines modernes',
          'description': 'Apprenez à réaliser de magnifiques tresses africaines adaptées au style moderne...',
          'thumbnail': 'https://img.youtube.com/vi/ScMzIvxBSi4/hqdefault.jpg',
          'channelTitle': 'Beauty Afro Channel',
          'publishedAt': '2024-01-10T14:30:00Z',
          'duration': '12:20',
          'viewCount': '89K',
          'likeCount': '2150',
        },
      ];
      isLoading = false;
    });
  }

  String _parseDuration(String isoDuration) {
    // Convertit PT4M13S vers 4:13
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(isoDuration);

    if (match != null) {
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

      if (hours > 0) {
        return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
      }
    }
    return '0:00';
  }

  String _formatViewCount(String count) {
    final num = int.tryParse(count) ?? 0;
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return 'il y a ${(difference.inDays / 365).floor()} an${(difference.inDays / 365).floor() > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      return 'il y a ${(difference.inDays / 30).floor()} mois';
    } else if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return 'Aujourd\'hui';
    }
  }

  void _playVideo(String videoId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoId: videoId,
          title: title,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.keys.length,
        itemBuilder: (context, index) {
          final category = categories.keys.elementAt(index);
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category;
                });
                _loadFashionVideos();
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor,
              elevation: isSelected ? 6 : 2,
              shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
        )),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail vidéo avec bouton play
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(video['thumbnail']),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.4),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Durée
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          video['duration'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Badge LIVE si récent
                    if (DateTime.parse(video['publishedAt'])
                        .isAfter(DateTime.now().subtract(const Duration(days: 7))))
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NOUVEAU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Informations vidéo
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        video['description'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withOpacity(0.7),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                video['channelTitle'][0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video['channelTitle'],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatDate(video['publishedAt']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${video['viewCount']} vues',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.thumb_up, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                _formatViewCount(video['likeCount']),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🎬 Tutoriels Mode',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _loadFashionVideos,
                icon: AnimatedRotation(
                  turns: isLoading ? 1 : 0,
                  duration: const Duration(seconds: 1),
                  child: Icon(
                    Icons.refresh,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filtres par catégorie
          _buildCategoryChips(),
          const SizedBox(height: 20),

          // Gestion des états
          if (error != null)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: TextStyle(color: Colors.red[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadFashionVideos,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else if (isLoading)
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Chargement des vidéos...'),
                ],
              ),
            )
          else if (tutorials.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune vidéo trouvée',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tutorials.length,
                itemBuilder: (context, index) {
                  final tutorial = tutorials[index];
                  return GestureDetector(
                    onTap: () => _playVideo(tutorial['id'], tutorial['title']),
                    child: _buildVideoCard(tutorial, index),
                  );
                },
              ),
        ],
      ),
    );
  }
}

// Écran de lecture vidéo
class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        captionLanguage: 'fr',
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
          progressColors: const ProgressBarColors(
            playedColor: Colors.red,
            handleColor: Colors.redAccent,
          ),
        ),
        builder: (context, player) {
          return Column(
            children: [
              player,
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'À propos de cette vidéo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Profitez de ce tutoriel de mode pour apprendre de nouvelles techniques et améliorer votre style !',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}