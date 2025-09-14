import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'story_creator_screen.dart';
import '../widgets/inspiration/community_screen.dart';

class AccueilTab extends StatefulWidget {
  const AccueilTab({super.key});

  @override
  _AccueilTabState createState() => _AccueilTabState();
}

class _AccueilTabState extends State<AccueilTab>
    with TickerProviderStateMixin {
  final FirebaseStoryService _storyService = FirebaseStoryService();
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late PageController _pageController;
  int _currentStoryIndex = 0;
  Timer? _autoScrollTimer;
  List<Story> _stories = [];
  StreamSubscription<List<Story>>? _storiesSubscription;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  String _userStatus = "Disponible";
  final currentUser = FirebaseAuth.instance.currentUser;
  Map<String, VideoPlayerController> _videoControllers = {};

  // Palette de couleurs améliorée
  static const Color primaryRed = Color(0xFFE53E3E);
  static const Color primaryGold = Color(0xFFD69E2E);
  static const Color primaryGreen = Color(0xFF38A169);
  static const Color primaryBlue = Color(0xFF3182CE);
  static const Color primaryPurple = Color(0xFF805AD5);
  static const Color backgroundLight = Color(0xFFF7FAFC);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2D3748);
  static const Color textMedium = Color(0xFF4A5568);
  static const Color textLight = Color(0xFF718096);
  static const Color accentOrange = Color(0xFFED8936);
  static const Color statusOnline = Color(0xFF48BB78);

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pageController = PageController();
    _storyService.startCleanupTimer();

    _storiesSubscription = _storyService.getStoriesStream().listen((stories) {
      if (mounted) {
        setState(() {
          _stories = stories;
          // Initialiser les contrôleurs vidéo
          _initializeVideoControllers();
        });
        if (_stories.isNotEmpty) {
          _startAutoScroll();
        }
      }
    });

    _loadUserStatus();
  }

  void _initializeVideoControllers() {
    for (var story in _stories) {
      if (story.isVideo && story.mediaUrl != null && !_videoControllers.containsKey(story.id)) {
        final controller = VideoPlayerController.network(story.mediaUrl!)
          ..initialize().then((_) {
            if (mounted) setState(() {});
          });
        _videoControllers[story.id] = controller;
      }
    }
  }

  void _loadUserStatus() async {
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('userStatus')
        .doc(currentUser!.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      setState(() {
        _userStatus = doc.data()!['status'] ?? "Disponible";
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_stories.isNotEmpty && _pageController.hasClients && mounted) {
        final nextIndex = (_currentStoryIndex + 1) % _stories.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    _storiesSubscription?.cancel();
    _commentController.dispose();
    _statusController.dispose();
    _storyService.dispose();

    // Dispose all video controllers
    _videoControllers.values.forEach((controller) {
      controller.dispose();
    });
    _videoControllers.clear();

    super.dispose();
  }

  Future<void> _navigateToStoryCreator() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StoryCreatorScreen()),
    );

    if (result == true) {
      _showSnackBar('Story publiée avec succès!', statusOnline);
    }
  }

  Future<void> _toggleLike(String storyId) async {
    await _storyService.toggleLike(storyId);
  }

  Future<void> _shareStory(Story story) async {
    final text = '${story.caption}\n\nPartagé depuis Mode Burkina - Style & Tradition';
    await Share.share(text);
  }

  Future<void> _deleteStory(String storyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Supprimer la story',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer cette story ?',
          style: TextStyle(color: textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _storyService.deleteStory(storyId);
      if (success) {
        _showSnackBar('Story supprimée', primaryRed);
      } else {
        _showSnackBar('Erreur lors de la suppression', primaryRed);
      }
    }
  }

  void _showStoryViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          stories: _stories,
          initialIndex: initialIndex,
          onDelete: _deleteStory,
        ),
      ),
    );
  }

  void _showCommentsModal(Story story) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: backgroundWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: textLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryRed.withOpacity(0.1), Colors.transparent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.chat_rounded, color: primaryRed, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Commentaires',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            Text(
                              '${story.comments.length} commentaire${story.comments.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: textMedium,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: backgroundLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: textMedium, size: 20),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: backgroundLight, thickness: 1),
              Expanded(
                child: story.comments.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryGold.withOpacity(0.2), primaryRed.withOpacity(0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: primaryGold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Aucun commentaire',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Soyez le premier à commenter cette story !',
                        style: TextStyle(
                          color: textMedium,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  itemCount: story.comments.length,
                  itemBuilder: (context, index) {
                    final comment = story.comments[index];
                    return _buildCommentItem(comment, index, story.id);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [backgroundLight.withOpacity(0.5), backgroundWhite],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(top: BorderSide(color: const Color(0xFFE2E8F0), width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryRed, primaryGold],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: primaryRed.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: currentUser?.photoURL != null
                            ? Image.network(
                          currentUser!.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildAvatarFallback(
                              currentUser?.displayName ?? 'U',
                            );
                          },
                        )
                            : _buildAvatarFallback(
                          currentUser?.displayName ?? 'U',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: backgroundWhite,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Écrivez votre commentaire...',
                            hintStyle: TextStyle(
                              color: textLight,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            fontSize: 15,
                            color: textDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _addComment(story.id),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryRed, accentOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: primaryRed.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(Comment comment, int index, String storyId) {
    final isMyComment = currentUser != null && comment.userId == currentUser!.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue.withOpacity(0.2), primaryGreen.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: primaryBlue.withOpacity(0.3), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: comment.userPhotoUrl.isNotEmpty
                      ? Image.network(
                    comment.userPhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: primaryBlue.withOpacity(0.1),
                        child: Center(
                          child: Text(
                            comment.userName.isNotEmpty
                                ? comment.userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                      : Container(
                    color: primaryBlue.withOpacity(0.1),
                    child: Center(
                      child: Text(
                        comment.userName.isNotEmpty
                            ? comment.userName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                comment.userName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [backgroundLight.withOpacity(0.8), backgroundWhite],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: textLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getTimeAgo(comment.createdAt),
                          style: TextStyle(
                            color: textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isMyComment)
                        GestureDetector(
                          onTap: () => _deleteComment(storyId, comment.id),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: primaryRed,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    comment.text,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}j';
    } else {
      return '${(difference.inDays / 7).floor()}sem';
    }
  }

  Future<void> _addComment(String storyId) async {
    if (_commentController.text.trim().isEmpty || currentUser == null) return;

    final success = await _storyService.addComment(
      storyId,
      _commentController.text.trim(),
    );

    if (success && mounted) {
      _commentController.clear();
      _showSnackBar('Commentaire ajouté!', statusOnline);
    } else if (mounted) {
      _showSnackBar('Erreur lors de l\'ajout du commentaire', primaryRed);
    }
  }

  Future<void> _deleteComment(String storyId, String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Supprimer le commentaire',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ce commentaire ?',
          style: TextStyle(color: textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _storyService.deleteComment(storyId, commentId);
      if (success) {
        _showSnackBar('Commentaire supprimé', primaryRed);
      } else {
        _showSnackBar('Erreur lors de la suppression', primaryRed);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildMainButtons(),
                    const SizedBox(height: 32),
                    _buildStoriesSection(),
                    const SizedBox(height: 32),
                    _buildStatsSection(),
                    const SizedBox(height: 20),
                    _buildCurrentStatus(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundWhite, backgroundLight.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryRed.withOpacity(0.15), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * 3.14159,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryRed, accentOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: primaryRed.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
                ),
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Burkina',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryGold.withOpacity(0.2), primaryRed.withOpacity(0.1)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Style & Tradition',
                    style: TextStyle(
                      color: primaryGold,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGold.withOpacity(0.2), primaryGold.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryGold.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.flash_on_rounded, color: primaryGold, size: 24),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusOnline,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: statusOnline.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _navigateToStoryCreator,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryRed, accentOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: primaryRed.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_pulseController.value * 0.1),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Créer Story',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Partage votre style',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CommunityScreen()),
            ),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, primaryPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -20,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    right: -40,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(70),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Communauté',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Rejoins la discussion',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoriesSection() {
    if (_stories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundWhite, backgroundLight.withOpacity(0.5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryGold.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGold.withOpacity(0.15), primaryRed.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: primaryGold.withOpacity(0.3), width: 3),
              ),
              child: Icon(
                Icons.photo_camera_rounded,
                size: 60,
                color: primaryGold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune Story Active',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre première story pour partager votre style avec la communauté !',
              style: TextStyle(
                color: textMedium,
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stories Actives',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusOnline.withOpacity(0.15), primaryGreen.withOpacity(0.1)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusOnline,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_stories.length} story${_stories.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: statusOnline,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryRed.withOpacity(0.1), primaryGold.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryRed.withOpacity(0.2), width: 1.5),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: primaryRed,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 420,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStoryIndex = index;
                });
              },
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                return _buildStoryCard(_stories[index], index);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_stories.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentStoryIndex == index ? 32 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: _currentStoryIndex == index
                    ? const LinearGradient(
                  colors: [primaryRed, primaryGold],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
                    : null,
                color: _currentStoryIndex == index ? null : textLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStoryCard(Story story, int index) {
    final isMyStory = currentUser != null && story.userId == currentUser!.uid;
    final isLiked = currentUser != null && story.likes.contains(currentUser!.uid);
    final videoController = _videoControllers[story.id];

    return GestureDetector(
      onTap: () => _showStoryViewer(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundWhite, backgroundLight.withOpacity(0.3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isMyStory ? primaryGold.withOpacity(0.4) : primaryRed.withOpacity(0.15),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isMyStory ? primaryGold.withOpacity(0.2) : Colors.black12,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Contenu de la story (image, vidéo ou texte)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: _buildStoryContent(story, videoController),
              ),
            ),

            // Overlay sombre pour améliorer la lisibilité
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Badge "Ma Story" si c'est la story de l'utilisateur
            if (isMyStory)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryGold, accentOrange],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGold.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Ma Story',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bouton de suppression pour les stories de l'utilisateur
            if (isMyStory)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => _deleteStory(story.id),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

            // En-tête avec avatar et informations utilisateur
            Positioned(
              top: 20,
              left: isMyStory ? 120 : 20,
              right: isMyStory ? 70 : 20,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryRed, primaryGold],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: story.userPhotoUrl.isNotEmpty
                          ? Image.network(
                        story.userPhotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildAvatarFallback(story.userName);
                        },
                      )
                          : _buildAvatarFallback(story.userName),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: Text(
                            story.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getTimeAgo(story.createdAt),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Pied de page avec légende et boutons d'action
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (story.caption.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Text(
                        story.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildActionButton(
                        icon: isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
                        color: isLiked
                            ? primaryRed
                            : Colors.white,
                        count: story.likes.length,
                        onTap: () => _toggleLike(story.id),
                        gradient: isLiked
                            ? const LinearGradient(colors: [primaryRed, accentOrange])
                            : null,
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        count: story.comments.length,
                        onTap: () => _showCommentsModal(story),
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        icon: Icons.share_rounded,
                        color: Colors.white,
                        onTap: () => _shareStory(story),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(Story story, VideoPlayerController? videoController) {
    if (story.mediaUrl != null && !story.isVideo) {
      // Story image
      return Image.network(
        story.mediaUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue.withOpacity(0.3), primaryPurple.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.broken_image_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          );
        },
      );
    } else if (story.mediaUrl != null && story.isVideo) {
      // Story vidéo
      return Stack(
        fit: StackFit.expand,
        children: [
          if (videoController != null && videoController.value.isInitialized)
            VideoPlayer(videoController)
          else
            const Center(child: CircularProgressIndicator()),
          if (videoController == null || !videoController.value.isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
        ],
      );
    } else {
      // Story texte
      final textStyle = story.textStyle ?? {};
      return Container(
        color: story.backgroundColor != null
            ? Color(story.backgroundColor!)
            : Colors.grey,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              story.caption,
              style: TextStyle(
                color: textStyle['textColor'] != null
                    ? Color(textStyle['textColor'] as int)
                    : Colors.white,
                fontSize: textStyle['fontSize']?.toDouble() ?? 28.0,
                fontWeight: textStyle['fontWeight'] != null
                    ? FontWeight.values[textStyle['fontWeight'] as int]
                    : FontWeight.bold,
                fontFamily: textStyle['fontFamily'] as String?,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    int? count,
    required VoidCallback onTap,
    Gradient? gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? Colors.black.withOpacity(0.5) : null,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            if (count != null && count > 0) ...[
              const SizedBox(width: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final totalLikes = _stories.fold<int>(0, (sum, story) => sum + story.likes.length);
    final totalComments = _stories.fold<int>(0, (sum, story) => sum + story.comments.length);
    final uniqueUsers = _stories.map((s) => s.userId).toSet().length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundWhite, backgroundLight.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryBlue.withOpacity(0.15), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue.withOpacity(0.15), primaryPurple.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryBlue.withOpacity(0.3), width: 1.5),
                ),
                child: Icon(Icons.analytics_rounded, color: primaryBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistiques',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    Text(
                      'Aperçu de l\'activité communautaire',
                      style: TextStyle(
                        color: textMedium,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Stories Actives',
                  _stories.length.toString(),
                  Icons.auto_stories_rounded,
                  primaryRed,
                  accentOrange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Likes',
                  totalLikes.toString(),
                  Icons.favorite_rounded,
                  primaryGold,
                  primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Commentaires',
                  totalComments.toString(),
                  Icons.chat_bubble_rounded,
                  primaryBlue,
                  primaryPurple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Communauté',
                  '$uniqueUsers',
                  Icons.groups_rounded,
                  primaryGreen,
                  primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color1, Color color2) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1.withOpacity(0.1), color2.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color1.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color1.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color1, color2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color1.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: textMedium,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus() {
    final userName = currentUser?.displayName ?? "Utilisateur";

    return GestureDetector(
      onTap: _showStatusOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryGreen.withOpacity(0.2), primaryBlue.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryGreen.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusOnline,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: statusOnline.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Statut de $userName",
                    style: TextStyle(
                      color: textMedium,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userStatus,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.more_vert_rounded, color: primaryGreen),
          ],
        ),
      ),
    );
  }

  void _showStatusOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: textLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: primaryBlue),
              title: const Text('Modifier mon statut'),
              onTap: () => _editStatus(),
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: primaryRed),
              title: const Text('Supprimer mon statut'),
              onTap: () => _deleteStatus(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _editStatus() {
    _statusController.text = _userStatus;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Modifier votre statut',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: _statusController,
          decoration: InputDecoration(
            hintText: 'Entrez votre nouveau statut...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryGreen),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLines: 2,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: textMedium)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_statusController.text.isNotEmpty) {
                setState(() {
                  _userStatus = _statusController.text;
                });
                _saveUserStatus();
                Navigator.pop(context);
                _showSnackBar('Statut mis à jour', primaryGreen);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUserStatus() async {
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('userStatus')
        .doc(currentUser!.uid)
        .set({'status': _userStatus});
  }

  void _deleteStatus() {
    Navigator.pop(context);
    setState(() {
      _userStatus = "Disponible";
    });
    _saveUserStatus();
    _showSnackBar('Statut supprimé', primaryRed);
  }
}

class Story {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String? mediaUrl;
  final bool isVideo;
  final String caption;
  final List<String> likes;
  final List<Comment> comments;
  final DateTime createdAt;
  final Map<String, dynamic>? textStyle;
  final int? backgroundColor;

  Story({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    this.mediaUrl,
    this.isVideo = false,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.createdAt,
    this.textStyle,
    this.backgroundColor,
  });
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.text,
    required this.createdAt,
  });
}

class FirebaseStoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _cleanupTimer;

  Stream<List<Story>> getStoriesStream() {
    return _firestore
        .collection('stories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Story(
          id: doc.id,
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? '',
          userPhotoUrl: data['userPhotoUrl'] ?? '',
          mediaUrl: data['mediaUrl'],
          isVideo: data['isVideo'] ?? false,
          caption: data['caption'] ?? '',
          likes: List<String>.from(data['likes'] ?? []),
          comments: (data['comments'] as List<dynamic>? ?? [])
              .map((comment) => Comment(
            id: comment['id'] ?? '',
            userId: comment['userId'] ?? '',
            userName: comment['userName'] ?? '',
            userPhotoUrl: comment['userPhotoUrl'] ?? '',
            text: comment['text'] ?? '',
            createdAt: (comment['createdAt'] as Timestamp).toDate(),
          ))
              .toList(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          textStyle: data['textStyle'],
          backgroundColor: data['backgroundColor'],
        );
      }).toList();
    });
  }

  Future<bool> toggleLike(String storyId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.runTransaction((transaction) async {
        final storyRef = _firestore.collection('stories').doc(storyId);
        final storySnapshot = await transaction.get(storyRef);

        if (!storySnapshot.exists) return;

        final likes = List<String>.from(storySnapshot.data()?['likes'] ?? []);
        if (likes.contains(user.uid)) {
          likes.remove(user.uid);
        } else {
          likes.add(user.uid);
        }

        transaction.update(storyRef, {'likes': likes});
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteStory(String storyId) async {
    try {
      await _firestore.collection('stories').doc(storyId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addComment(String storyId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final comment = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': user.uid,
        'userName': user.displayName ?? 'Utilisateur',
        'userPhotoUrl': user.photoURL ?? '',
        'text': text,
        'createdAt': Timestamp.now(),
      };

      await _firestore.collection('stories').doc(storyId).update({
        'comments': FieldValue.arrayUnion([comment])
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteComment(String storyId, String commentId) async {
    try {
      final storyRef = _firestore.collection('stories').doc(storyId);
      final storySnapshot = await storyRef.get();

      if (!storySnapshot.exists) return false;

      final comments = List<Map<String, dynamic>>.from(storySnapshot.data()?['comments'] ?? []);
      comments.removeWhere((comment) => comment['id'] == commentId);

      await storyRef.update({'comments': comments});
      return true;
    } catch (e) {
      return false;
    }
  }

  void startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _cleanupExpiredStories();
    });
  }

  Future<void> _cleanupExpiredStories() async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final expiredStories = await _firestore
        .collection('stories')
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
        .get();

    for (final doc in expiredStories.docs) {
      await doc.reference.delete();
    }
  }

  void dispose() {
    _cleanupTimer?.cancel();
  }
}

class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final Function(String) onDelete;

  const StoryViewerScreen({
    Key? key,
    required this.stories,
    required this.initialIndex,
    required this.onDelete,
  }) : super(key: key);

  @override
  _StoryViewerScreenState createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initVideoController(widget.stories[_currentIndex]);
  }

  void _initVideoController(Story story) {
    if (story.isVideo && story.mediaUrl != null) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.network(story.mediaUrl!)
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
        });
    } else {
      _videoController?.dispose();
      _videoController = null;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController != null) {
      setState(() {
        _isPlaying = !_isPlaying;
        if (_isPlaying) {
          _videoController?.play();
        } else {
          _videoController?.pause();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.stories.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _initVideoController(widget.stories[index]);
            _isPlaying = true;
          });
        },
        itemBuilder: (context, index) {
          final story = widget.stories[index];
          final currentUser = FirebaseAuth.instance.currentUser;
          final isMyStory = currentUser != null && story.userId == currentUser.uid;

          return GestureDetector(
            onTap: _togglePlayPause,
            child: Stack(
              children: [
                // Contenu de la story
                _buildStoryContent(story),

                // Contrôles de la vidéo
                if (story.isVideo)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bouton de suppression
                if (isMyStory)
                  Positioned(
                    top: 40,
                    right: 20,
                    child: GestureDetector(
                      onTap: () {
                        widget.onDelete(story.id);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoryContent(Story story) {
    if (story.mediaUrl != null && !story.isVideo) {
      return Center(
        child: Image.network(
          story.mediaUrl!,
          fit: BoxFit.contain,
        ),
      );
    } else if (story.mediaUrl != null && story.isVideo) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController?.value.aspectRatio ?? 16/9,
          child: _videoController != null && _videoController!.value.isInitialized
              ? VideoPlayer(_videoController!)
              : Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      return Container(
        color: story.backgroundColor != null
            ? Color(story.backgroundColor!)
            : Colors.grey,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              story.caption,
              style: story.textStyle != null
                  ? TextStyle(
                color: story.textStyle!['textColor'] != null
                    ? Color(story.textStyle!['textColor'] as int)
                    : Colors.white,
                fontSize: story.textStyle!['fontSize']?.toDouble() ?? 28.0,
                fontWeight: story.textStyle!['fontWeight'] != null
                    ? FontWeight.values[story.textStyle!['fontWeight'] as int]
                    : FontWeight.bold,
                fontFamily: story.textStyle!['fontFamily'] as String?,
              )
                  : TextStyle(color: Colors.white, fontSize: 28),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }
}