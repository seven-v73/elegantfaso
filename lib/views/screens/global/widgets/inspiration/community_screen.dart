import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class AppColors {
  static const Color primary = Color(0xFF8B4513);
  static const Color secondary = Color(0xFFD2691E);
  static const Color accent = Color(0xFFFF8C00);
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFFAFAFA);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = Colors.black;
  static const Color onSurface = Colors.black87;
  static const Color onError = Colors.white;

  static Color primaryLight = primary.withOpacity(0.1);
  static Color secondaryLight = secondary.withOpacity(0.1);
  static Color accentLight = accent.withOpacity(0.1);
}

enum MediaType { image, video, audio, text }

class MediaAttachment {
  final String url;
  final MediaType type;
  final String? filename;
  final int? duration;

  MediaAttachment({
    required this.url,
    required this.type,
    this.filename,
    this.duration,
  });
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedCategory = 'Tout';
  List<MediaAttachment> _selectedMedia = [];
  bool _isUploading = false;

  final List<String> _categories = [
    'Tout',
    'Général',
    'Faso Dan Fani',
    'Pagnes',
    'Bijoux',
    'Coiffures',
    'Mariage',
    'Tendances',
    'Conseils'
  ];

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedMedia.add(MediaAttachment(
          url: image.path,
          type: MediaType.image,
          filename: image.name,
        ));
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );

    if (video != null) {
      setState(() {
        _selectedMedia.add(MediaAttachment(
          url: video.path,
          type: MediaType.video,
          filename: video.name,
        ));
      });
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _selectedMedia.add(MediaAttachment(
          url: file.path!,
          type: MediaType.audio,
          filename: file.name,
        ));
      });
    }
  }

  Future<String> _uploadMedia(MediaAttachment media) async {
    final file = File(media.url);
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${media.filename ?? 'file'}';
    final String path = 'community_media/${media.type.name}/$fileName';

    final UploadTask uploadTask = _storage.ref(path).putFile(file);
    final TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _postQuestion() async {
    if (_questionController.text.trim().isEmpty && _selectedMedia.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) {
      _showLoginDialog();
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      List<Map<String, dynamic>> mediaUrls = [];

      for (MediaAttachment media in _selectedMedia) {
        final uploadedUrl = await _uploadMedia(media);
        mediaUrls.add({
          'url': uploadedUrl,
          'type': media.type.name,
          'filename': media.filename,
          'duration': media.duration,
        });
      }

      final now = DateTime.now();
      await _firestore.collection('community_questions').add({
        'userId': user.uid,
        'userName': userData['displayName'] ?? user.displayName ?? 'Utilisateur',
        'userPhoto': userData['photoURL'] ?? user.photoURL,
        'question': _questionController.text.trim(),
        'category': _selectedCategory == 'Tout' ? 'Général' : _selectedCategory,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'likesCount': 0,
        'answersCount': 0,
        'isVerified': userData['isVerified'] ?? false,
        'tags': _extractTags(_questionController.text),
        'media': mediaUrls,
        'isEditable': true,
        'editableUntil': Timestamp.fromDate(now.add(const Duration(minutes: 2))),
      });

      _questionController.clear();
      _selectedMedia.clear();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Question publiée avec succès!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _updateQuestion(String questionId, String newQuestion, String newCategory, List<MediaAttachment> newMedia) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final questionDoc = await _firestore.collection('community_questions').doc(questionId).get();
      if (!questionDoc.exists) return;

      final questionData = questionDoc.data()!;
      final editableUntil = (questionData['editableUntil'] as Timestamp).toDate();

      if (DateTime.now().isAfter(editableUntil)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le délai de modification est expiré'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      List<Map<String, dynamic>> mediaUrls = [];

      for (MediaAttachment media in newMedia) {
        final uploadedUrl = await _uploadMedia(media);
        mediaUrls.add({
          'url': uploadedUrl,
          'type': media.type.name,
          'filename': media.filename,
          'duration': media.duration,
        });
      }

      await _firestore.collection('community_questions').doc(questionId).update({
        'question': newQuestion,
        'category': newCategory,
        'media': mediaUrls,
        'tags': _extractTags(newQuestion),
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question mise à jour avec succès!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la question?'),
        content: const Text('Voulez-vous vraiment supprimer cette question? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final questionDoc = await _firestore.collection('community_questions').doc(questionId).get();
      if (!questionDoc.exists) return;

      final questionData = questionDoc.data()!;
      final editableUntil = (questionData['editableUntil'] as Timestamp).toDate();

      if (DateTime.now().isAfter(editableUntil)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le délai de suppression est expiré'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final mediaList = List<Map<String, dynamic>>.from(questionData['media'] ?? []);
      for (final media in mediaList) {
        try {
          final ref = _storage.refFromURL(media['url']);
          await ref.delete();
        } catch (e) {
          debugPrint('Erreur suppression média: $e');
        }
      }

      await _firestore.collection('community_questions').doc(questionId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question supprimée avec succès!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<String> _extractTags(String text) {
    final words = text.toLowerCase().split(' ');
    final tags = <String>[];
    final keywords = [
      'faso',
      'pagne',
      'bijoux',
      'mariage',
      'traditionnel',
      'moderne'
    ];

    for (final word in words) {
      for (final keyword in keywords) {
        if (word.contains(keyword)) {
          tags.add(keyword);
        }
      }
    }
    return tags.toSet().toList();
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Connexion requise'),
        content: const Text('Veuillez vous connecter pour poser une question.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildCategoryFilter(),
          _buildQuestionsList(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: () => _showQuestionModal(),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle question'),
              elevation: 8,
              heroTag: "fab_question",
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Communauté Style BF',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
                AppColors.accent,
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.people_alt_rounded,
              size: 80,
              color: Colors.white54,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
        ),
      ],
      bottom: _isSearching
          ? PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher des questions...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildCategoryFilter() {
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = category == _selectedCategory;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                backgroundColor: Colors.grey[100],
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                elevation: isSelected ? 4 : 1,
                shadowColor: AppColors.primary.withOpacity(0.3),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getQuestionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildShimmerCard(),
              childCount: 5,
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            ),
          );
        }

        final questions = snapshot.data?.docs ?? [];

        if (questions.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Icon(Icons.forum_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune question trouvée',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Soyez le premier à poser une question!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final questionDoc = questions[index];
              final questionData = questionDoc.data() as Map<String, dynamic>;
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutBack,
                child: EnhancedQuestionCard(
                  questionId: questionDoc.id,
                  questionData: questionData,
                  currentUserId: _auth.currentUser?.uid,
                  onReply: (questionId) => _showReplyModal(questionId, questionData),
                  onReplyToReply: (questionId, replyId, userName) =>
                      _showReplyToReplyModal(questionId, replyId, userName),
                  onEdit: (questionId) => _showEditModal(questionId, questionData),
                  onDelete: (questionId) => _deleteQuestion(questionId),
                ),
              );
            },
            childCount: questions.length,
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getQuestionsStream() {
    Query query = _firestore.collection('community_questions');

    if (_selectedCategory != 'Tout') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    query = query.orderBy('timestamp', descending: true);

    return query.snapshots();
  }

  Widget _buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 16,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Container(
                width: 200,
                height: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuestionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedQuestionModal(
        controller: _questionController,
        onPost: _postQuestion,
        categories: _categories.where((c) => c != 'Tout').toList(),
        selectedMedia: _selectedMedia,
        onPickImage: _pickImage,
        onPickVideo: _pickVideo,
        onPickAudio: _pickAudio,
        onRemoveMedia: (index) {
          setState(() {
            _selectedMedia.removeAt(index);
          });
        },
        isUploading: _isUploading,
      ),
    );
  }

  void _showEditModal(String questionId, Map<String, dynamic> questionData) {
    final controller = TextEditingController(text: questionData['question']);
    final category = questionData['category'] ?? 'Général';
    _selectedMedia.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedQuestionModal(
        controller: controller,
        onPost: () => _updateQuestion(
          questionId,
          controller.text.trim(),
          category,
          _selectedMedia,
        ),
        categories: _categories.where((c) => c != 'Tout').toList(),
        selectedMedia: _selectedMedia,
        onPickImage: _pickImage,
        onPickVideo: _pickVideo,
        onPickAudio: _pickAudio,
        onRemoveMedia: (index) {
          setState(() {
            _selectedMedia.removeAt(index);
          });
        },
        isUploading: _isUploading,
        initialCategory: category,
        isEditing: true,
      ),
    );
  }

  void _showReplyModal(String questionId, Map<String, dynamic> questionData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReplyModal(
        questionId: questionId,
        questionData: questionData,
        onReply: _postReply,
      ),
    );
  }

  void _showReplyToReplyModal(String questionId, String replyId, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReplyToReplyModal(
        questionId: questionId,
        replyId: replyId,
        userName: userName,
        onReply: _postReplyToReply,
      ),
    );
  }

  Future<void> _postReply(String questionId, String reply, List<MediaAttachment> media) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      List<Map<String, dynamic>> mediaUrls = [];

      for (MediaAttachment mediaItem in media) {
        final uploadedUrl = await _uploadMedia(mediaItem);
        mediaUrls.add({
          'url': uploadedUrl,
          'type': mediaItem.type.name,
          'filename': mediaItem.filename,
          'duration': mediaItem.duration,
        });
      }

      await _firestore.collection('community_questions').doc(questionId).collection('replies').add({
        'userId': user.uid,
        'userName': userData['name'] ?? user.displayName ?? 'Utilisateur',
        'userPhoto': userData['photoUrl'] ?? user.photoURL,
        'reply': reply,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'likesCount': 0,
        'isVerified': userData['isVerified'] ?? false,
        'media': mediaUrls,
        'parentReplyId': null,
      });

      await _firestore.collection('community_questions').doc(questionId).update({
        'answersCount': FieldValue.increment(1),
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Réponse publiée avec succès!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _postReplyToReply(
      String questionId,
      String parentReplyId,
      String reply,
      List<MediaAttachment> media
      ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      List<Map<String, dynamic>> mediaUrls = [];

      for (MediaAttachment mediaItem in media) {
        final uploadedUrl = await _uploadMedia(mediaItem);
        mediaUrls.add({
          'url': uploadedUrl,
          'type': mediaItem.type.name,
          'filename': mediaItem.filename,
          'duration': mediaItem.duration,
        });
      }

      await _firestore.collection('community_questions')
          .doc(questionId)
          .collection('replies')
          .add({
        'userId': user.uid,
        'userName': userData['name'] ?? user.displayName ?? 'Utilisateur',
        'userPhoto': userData['photoUrl'] ?? user.photoURL,
        'reply': reply,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'likesCount': 0,
        'isVerified': userData['isVerified'] ?? false,
        'media': mediaUrls,
        'parentReplyId': parentReplyId,
      });

      await _firestore.collection('community_questions').doc(questionId).update({
        'answersCount': FieldValue.increment(1),
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Réponse publiée avec succès!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class ReplyModal extends StatefulWidget {
  final String questionId;
  final Map<String, dynamic> questionData;
  final Function(String, String, List<MediaAttachment>) onReply;

  const ReplyModal({
    super.key,
    required this.questionId,
    required this.questionData,
    required this.onReply,
  });

  @override
  State<ReplyModal> createState() => _ReplyModalState();
}

class _ReplyModalState extends State<ReplyModal> {
  final TextEditingController _replyController = TextEditingController();
  final List<MediaAttachment> _selectedMedia = [];
  bool _isUploading = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await Permission.microphone.request().isGranted) {
      try {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/reply_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = Duration.zero;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration += const Duration(seconds: 1);
          });
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'enregistrement: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission microphone refusée')),
      );
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordedFilePath = path;
    });
  }

  Future<void> _playRecordedAudio() async {
    if (_recordedFilePath == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
    }
  }

  void _deleteRecording() {
    if (_recordedFilePath != null) {
      File(_recordedFilePath!).delete();
    }
    setState(() {
      _recordedFilePath = null;
      _recordDuration = Duration.zero;
    });
    _audioPlayer.stop();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.reply,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Répondre à la question',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.questionData['question'] ?? '',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _replyController,
                maxLines: 5,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: 'Écrivez votre réponse...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              if (_recordedFilePath != null) ...[
                const SizedBox(height: 16),
                _buildRecordPreview(),
              ],
              const SizedBox(height: 16),
              _buildRecordingButtons(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submitReply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                      ),
                      child: _isUploading
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text('Répondre'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: AppColors.primary,
            ),
            onPressed: _playRecordedAudio,
          ),
          const SizedBox(width: 10),
          Text(
            _formatDuration(_recordDuration),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingButtons() {
    return Row(
      children: [
        if (!_isRecording)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.mic),
              label: const Text('Enregistrer une réponse vocale'),
            ),
          )
        else
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _stopRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[900],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.stop),
              label: Text('Arrêter (${_formatDuration(_recordDuration)})'),
            ),
          ),
      ],
    );
  }

  void _submitReply() {
    if (_replyController.text.trim().isEmpty && _recordedFilePath == null) return;

    setState(() {
      _isUploading = true;
    });

    if (_recordedFilePath != null) {
      _selectedMedia.add(MediaAttachment(
        url: _recordedFilePath!,
        type: MediaType.audio,
        filename: 'reponse_vocale.m4a',
      ));
    }

    widget.onReply(
      widget.questionId,
      _replyController.text.trim(),
      _selectedMedia,
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String audioId;
  final AudioPlayer? player;
  final VoidCallback onPlay;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.audioId,
    this.player,
    required this.onPlay,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = widget.player ?? AudioPlayer();
    _initPlayer();
  }

  void _initPlayer() async {
    _player.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });

    _player.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    _player.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });
  }

  @override
  void dispose() {
    if (widget.player == null) {
      _player.dispose();
    }
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 100) {
          return Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_playerState == PlayerState.playing) {
                      _player.pause();
                    } else {
                      widget.onPlay();
                    }
                  },
                  child: Icon(
                    _playerState == PlayerState.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: AppColors.primary,
                    size: 12,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 14,
                    child: Slider(
                      min: 0,
                      max: _duration.inSeconds.toDouble(),
                      value: _position.inSeconds.toDouble(),
                      onChanged: (value) async {
                        await _player.seek(Duration(seconds: value.toInt()));
                        setState(() {
                          _position = Duration(seconds: value.toInt());
                        });
                      },
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (width < 150) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_playerState == PlayerState.playing) {
                      _player.pause();
                    } else {
                      widget.onPlay();
                    }
                  },
                  child: Icon(
                    _playerState == PlayerState.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 18,
                    child: Slider(
                      min: 0,
                      max: _duration.inSeconds.toDouble(),
                      value: _position.inSeconds.toDouble(),
                      onChanged: (value) async {
                        await _player.seek(Duration(seconds: value.toInt()));
                        setState(() {
                          _position = Duration(seconds: value.toInt());
                        });
                      },
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.grey[300],
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  child: Text(
                    _formatDuration(_position),
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        } else if (width < 250) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_playerState == PlayerState.playing) {
                      _player.pause();
                    } else {
                      widget.onPlay();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      _playerState == PlayerState.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: _duration.inSeconds.toDouble(),
                    value: _position.inSeconds.toDouble(),
                    onChanged: (value) async {
                      await _player.seek(Duration(seconds: value.toInt()));
                      setState(() {
                        _position = Duration(seconds: value.toInt());
                      });
                    },
                    activeColor: AppColors.primary,
                    inactiveColor: Colors.grey[300],
                  ),
                ),
                Container(
                  width: 32,
                  child: Text(
                    _formatDuration(_position),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(4),
                      icon: Icon(
                        _playerState == PlayerState.playing
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      onPressed: () {
                        if (_playerState == PlayerState.playing) {
                          _player.pause();
                        } else {
                          widget.onPlay();
                        }
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Slider(
                            min: 0,
                            max: _duration.inSeconds.toDouble(),
                            value: _position.inSeconds.toDouble(),
                            onChanged: (value) async {
                              await _player.seek(Duration(seconds: value.toInt()));
                              setState(() {
                                _position = Duration(seconds: value.toInt());
                              });
                            },
                            activeColor: AppColors.primary,
                            inactiveColor: Colors.grey[300],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_position),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  _formatDuration(_duration),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.audiotrack,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Enregistrement vocal',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

class EnhancedQuestionCard extends StatefulWidget {
  final String questionId;
  final Map<String, dynamic> questionData;
  final String? currentUserId;
  final Function(String) onReply;
  final Function(String, String, String) onReplyToReply;
  final Function(String) onEdit;
  final Function(String) onDelete;

  const EnhancedQuestionCard({
    super.key,
    required this.questionId,
    required this.questionData,
    this.currentUserId,
    required this.onReply,
    required this.onReplyToReply,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<EnhancedQuestionCard> createState() => _EnhancedQuestionCardState();
}

class _EnhancedQuestionCardState extends State<EnhancedQuestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLiked = false;
  int _likesCount = 0;
  bool _showReplies = false;
  final Map<String, AudioPlayer> _audioPlayers = {};
  bool _isEditable = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _likesCount = widget.questionData['likesCount'] ?? 0;
    final likes = List<String>.from(widget.questionData['likes'] ?? []);
    _isLiked = widget.currentUserId != null && likes.contains(widget.currentUserId);

    final editableUntil = (widget.questionData['editableUntil'] as Timestamp?)?.toDate();
    if (editableUntil != null) {
      _isEditable = DateTime.now().isBefore(editableUntil);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (widget.currentUserId == null) return;

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    final firestore = FirebaseFirestore.instance;
    final questionRef = firestore.collection('community_questions').doc(widget.questionId);

    try {
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(questionRef);
        if (!snapshot.exists) return;

        final currentLikes = List<String>.from(snapshot.data()!['likes'] ?? []);

        if (_isLiked) {
          currentLikes.remove(widget.currentUserId);
          setState(() {
            _isLiked = false;
            _likesCount--;
          });
        } else {
          currentLikes.add(widget.currentUserId!);
          setState(() {
            _isLiked = true;
            _likesCount++;
          });
        }

        transaction.update(questionRef, {
          'likes': currentLikes,
          'likesCount': currentLikes.length,
        });
      });
    } catch (e) {
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });
    }
  }

  void _playAudio(String audioUrl, String audioId) {
    if (_audioPlayers.containsKey(audioId)) {
      final player = _audioPlayers[audioId]!;
      if (player.state == PlayerState.playing) {
        player.pause();
      } else {
        player.play(UrlSource(audioUrl));
      }
    } else {
      final player = AudioPlayer();
      _audioPlayers[audioId] = player;
      player.play(UrlSource(audioUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = widget.questionData['timestamp'] as Timestamp?;
    final timeAgo = timestamp != null
        ? timeago.format(timestamp.toDate(), locale: 'fr')
        : 'Maintenant';

    final tags = List<String>.from(widget.questionData['tags'] ?? []);
    final mediaList = List<Map<String, dynamic>>.from(widget.questionData['media'] ?? []);
    final bool isAuthor = widget.currentUserId == widget.questionData['userId'];

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.background,
                    AppColors.primaryLight,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserHeader(timeAgo),
                    const SizedBox(height: 16),
                    _buildQuestionContent(),
                    if (mediaList.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildMediaContent(mediaList),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildTags(tags),
                    ],
                    const SizedBox(height: 16),
                    _buildActionBar(isAuthor),
                    if (_showReplies) ...[
                      const SizedBox(height: 16),
                      _buildRepliesSection(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserHeader(String timeAgo) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: widget.questionData['userPhoto'] != null
                ? CachedNetworkImageProvider(widget.questionData['userPhoto'])
                : null,
            child: widget.questionData['userPhoto'] == null
                ? Text(
              widget.questionData['userName']?[0]?.toUpperCase() ?? 'U',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.questionData['userName'] ?? 'Utilisateur',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.questionData['isVerified'] == true) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
              Text(
                timeAgo,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
          child: Text(
            widget.questionData['category'] ?? 'Général',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionContent() {
    return Text(
      widget.questionData['question'] ?? '',
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
        color: AppColors.onSurface,
      ),
    );
  }

  Widget _buildMediaContent(List<Map<String, dynamic>> mediaList) {
    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mediaList.length,
        itemBuilder: (context, index) {
          final media = mediaList[index];
          final type = media['type'] as String;
          final url = media['url'] as String;
          final uniqueId = '${widget.questionId}_$index';

          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildMediaItem(type, url, media, uniqueId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaItem(String type, String url, Map<String, dynamic> media, String uniqueId) {
    switch (type) {
      case 'image':
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.error),
          ),
        );
      case 'video':
        return GestureDetector(
          onTap: () => _showVideoPlayer(context, url),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                color: Colors.black,
                child: const Icon(
                  Icons.video_library,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 50,
              ),
            ],
          ),
        );
      case 'audio':
        return AudioPlayerWidget(
          audioUrl: url,
          audioId: uniqueId,
          player: _audioPlayers[uniqueId],
          onPlay: () => _playAudio(url, uniqueId),
        );
      default:
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.attachment),
        );
    }
  }

  void _showVideoPlayer(BuildContext context, String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoUrl: videoUrl),
      ),
    );
  }

  Widget _buildTags(List<String> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
          ),
        ),
        child: Text(
          '#$tag',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildActionBar(bool isAuthor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleLike,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(_isLiked),
                    color: _isLiked ? Colors.red : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$_likesCount',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16), // Reduced spacing
          GestureDetector(
            onTap: () => widget.onReply(widget.questionId),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  'Répondre',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16), // Reduced spacing
          GestureDetector(
            onTap: () {
              setState(() {
                _showReplies = !_showReplies;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showReplies ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${widget.questionData['answersCount'] ?? 0} réponses',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (isAuthor && _isEditable) ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => widget.onEdit(widget.questionId),
              color: Colors.grey[600],
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(4),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => widget.onDelete(widget.questionId),
              color: Colors.grey[600],
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(4),
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareQuestion();
                  break;
                case 'report':
                  _reportQuestion();
                  break;
                case 'save':
                  _saveQuestion();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 18),
                    SizedBox(width: 8),
                    Text('Partager'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.bookmark_border, size: 18),
                    SizedBox(width: 8),
                    Text('Sauvegarder'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Signaler', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Icon(
              Icons.more_vert,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_questions')
          .doc(widget.questionId)
          .collection('replies')
          .where('parentReplyId', isEqualTo: null)
          .orderBy('timestamp', descending: false)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final replies = snapshot.data!.docs;

        if (replies.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Aucune réponse pour le moment. Soyez le premier à répondre!',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Réponses récentes:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ...replies.map((reply) => _buildReplyItem(reply)).toList(),
            if (replies.length == 3) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    _showAllReplies();
                  },
                  child: const Text('Voir toutes les réponses'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildReplyItem(QueryDocumentSnapshot reply) {
    final replyData = reply.data() as Map<String, dynamic>? ?? {};
    final Timestamp? timestamp = replyData['timestamp'] as Timestamp?;
    final String timeAgo = timestamp != null
        ? timeago.format(timestamp.toDate(), locale: 'fr')
        : 'Maintenant';

    final String userName = (replyData['userName'] as String?)?.trim() ?? 'Utilisateur';
    final String initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final String? userPhoto = replyData['userPhoto'] as String?;
    final bool isVerified = replyData['isVerified'] == true;
    final bool isLiked = replyData['isLiked'] == true;
    final int likesCount = replyData['likesCount'] ?? 0;
    final List<dynamic>? mediaList = replyData['media'] as List<dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// Row entête: Avatar + nom + vérifié + temps
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: userPhoto != null
                    ? CachedNetworkImageProvider(userPhoto)
                    : null,
                child: userPhoto == null
                    ? Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// Texte de la réponse
          if ((replyData['reply'] as String?)?.trim().isNotEmpty ?? false)
            Text(
              replyData['reply'],
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),

          /// Media attaché
          if (mediaList != null && mediaList.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildReplyMedia(
              List<Map<String, dynamic>>.from(mediaList),
              reply.id,
            ),
          ],

          const SizedBox(height: 8),

          /// Actions: Like et Répondre
          Row(
            children: [

              /// Like
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _toggleReplyLike(reply.id, replyData),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$likesCount',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              /// Bouton répondre
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => widget.onReplyToReply(
                  widget.questionId,
                  reply.id,
                  userName,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Répondre',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
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


  Widget _buildReplyMedia(List<Map<String, dynamic>> mediaList, String parentId) {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mediaList.length,
        itemBuilder: (context, index) {
          final media = mediaList[index];
          final uniqueId = '${parentId}_$index';
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildMediaItem(media['type'], media['url'], media, uniqueId),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleReplyLike(String replyId, Map<String, dynamic> replyData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final isCurrentlyLiked = replyData['isLiked'] == true;
      final currentLikesCount = replyData['likesCount'] ?? 0;

      await FirebaseFirestore.instance
          .collection('community_questions')
          .doc(widget.questionId)
          .collection('replies')
          .doc(replyId)
          .update({
        'isLiked': !isCurrentlyLiked,
        'likesCount': isCurrentlyLiked
            ? currentLikesCount - 1
            : currentLikesCount + 1,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _shareQuestion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de partage à venir')),
    );
  }

  void _reportQuestion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler cette question'),
        content: const Text('Voulez-vous vraiment signaler cette question comme inappropriée?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Question signalée')),
              );
            },
            child: const Text('Signaler', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _saveQuestion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question sauvegardée')),
    );
  }

  void _showAllReplies() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllRepliesScreen(
          questionId: widget.questionId,
          questionData: widget.questionData,
          onReplyToReply: widget.onReplyToReply,
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                        _isPlaying = false;
                      } else {
                        _controller.play();
                        _isPlaying = true;
                      }
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _isPlaying ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(
                          Icons.play_circle_filled,
                          color: Colors.white54,
                          size: 80,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppColors.primary,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                        _isPlaying = false;
                      } else {
                        _controller.play();
                        _isPlaying = true;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class EnhancedQuestionModal extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onPost;
  final List<String> categories;
  final List<MediaAttachment> selectedMedia;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onPickAudio;
  final Function(int) onRemoveMedia;
  final bool isUploading;
  final String? initialCategory;
  final bool isEditing;

  const EnhancedQuestionModal({
    super.key,
    required this.controller,
    this.onPost,
    required this.categories,
    required this.selectedMedia,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onPickAudio,
    required this.onRemoveMedia,
    required this.isUploading,
    this.initialCategory,
    this.isEditing = false,
  });

  @override
  State<EnhancedQuestionModal> createState() => _EnhancedQuestionModalState();
}

class _EnhancedQuestionModalState extends State<EnhancedQuestionModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  String _selectedCategory = 'Général';
  final FocusNode _focusNode = FocusNode();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _selectedCategory = widget.initialCategory ?? 'Général';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await Permission.microphone.request().isGranted) {
      try {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = Duration.zero;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration += const Duration(seconds: 1);
          });
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'enregistrement: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission microphone refusée')),
      );
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordedFilePath = path;
    });
  }

  Future<void> _playRecordedAudio() async {
    if (_recordedFilePath == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
    }
  }

  void _deleteRecording() {
    if (_recordedFilePath != null) {
      File(_recordedFilePath!).delete();
    }
    setState(() {
      _recordedFilePath = null;
      _recordDuration = Duration.zero;
    });
    _audioPlayer.stop();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * MediaQuery.of(context).size.height),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildCategorySelector(),
                    const SizedBox(height: 16),
                    _buildTextInput(),
                    if (_recordedFilePath != null) ...[
                      const SizedBox(height: 16),
                      _buildRecordPreview(),
                    ],
                    if (widget.selectedMedia.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildMediaPreview(),
                    ],
                    const SizedBox(height: 16),
                    _buildMediaButtons(),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.edit,
          color: AppColors.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          widget.isEditing ? 'Modifier la question' : 'Nouvelle question',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
            foregroundColor: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catégorie',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.categories.length,
            itemBuilder: (context, index) {
              final category = widget.categories[index];
              final isSelected = category == _selectedCategory;

              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      maxLines: 6,
      maxLength: 500,
      decoration: InputDecoration(
        hintText: 'Posez votre question sur la mode et la culture burkinabé...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildRecordPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: AppColors.primary,
            ),
            onPressed: _playRecordedAudio,
          ),
          const SizedBox(width: 10),
          Text(
            _formatDuration(_recordDuration),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Médias attachés',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.selectedMedia.length,
            itemBuilder: (context, index) {
              final media = widget.selectedMedia[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildMediaPreviewItem(media),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => widget.onRemoveMedia(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPreviewItem(MediaAttachment media) {
    switch (media.type) {
      case MediaType.image:
        return Image.file(
          File(media.url),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.error),
          ),
        );
      case MediaType.video:
        return Container(
          color: Colors.black,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, color: Colors.white, size: 20),
              SizedBox(height: 4),
              Text('Vidéo', style: TextStyle(color: Colors.white, fontSize: 10)),
            ],
          ),
        );
      case MediaType.audio:
        return Container(
          color: AppColors.primaryLight,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.audiotrack, color: AppColors.primary, size: 20),
              SizedBox(height: 4),
              Text('Audio', style: TextStyle(color: AppColors.primary, fontSize: 10)),
            ],
          ),
        );
      default:
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.attachment),
        );
    }
  }

  Widget _buildMediaButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildMediaButton(
            icon: Icons.photo_library,
            label: 'Photo',
            onTap: widget.onPickImage,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMediaButton(
            icon: Icons.videocam,
            label: 'Vidéo',
            onTap: widget.onPickVideo,
          ),
        ),
        const SizedBox(width: 8),
        if (!_isRecording)
          Expanded(
            child: _buildMediaButton(
              icon: Icons.mic,
              label: 'Enregistrer',
              onTap: _startRecording,
            ),
          )
        else
          Expanded(
            child: _buildMediaButton(
              icon: Icons.stop,
              label: 'Arrêter',
              onTap: _stopRecording,
              color: Colors.red,
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMediaButton(
            icon: Icons.audiotrack,
            label: 'Fichier',
            onTap: widget.onPickAudio,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: widget.isUploading ? null : () {
              if (_recordedFilePath != null) {
                widget.selectedMedia.add(MediaAttachment(
                  url: _recordedFilePath!,
                  type: MediaType.audio,
                  filename: 'enregistrement_vocal.m4a',
                ));
              }
              widget.onPost?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: widget.isUploading
                ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                Text('Publication...'),
              ],
            )
                : Text(widget.isEditing ? 'Mettre à jour' : 'Publier'),
          ),
        ),
      ],
    );
  }
}

class ReplyToReplyModal extends StatefulWidget {
  final String questionId;
  final String replyId;
  final String userName;
  final Function(String, String, String, List<MediaAttachment>) onReply;

  const ReplyToReplyModal({
    super.key,
    required this.questionId,
    required this.replyId,
    required this.userName,
    required this.onReply,
  });

  @override
  State<ReplyToReplyModal> createState() => _ReplyToReplyModalState();
}

class _ReplyToReplyModalState extends State<ReplyToReplyModal> {
  final TextEditingController _replyController = TextEditingController();
  final List<MediaAttachment> _selectedMedia = [];
  bool _isUploading = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _replyController.text = '@${widget.userName} ';
  }

  @override
  void dispose() {
    _replyController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await Permission.microphone.request().isGranted) {
      try {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/reply_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = Duration.zero;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration += const Duration(seconds: 1);
          });
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'enregistrement: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission microphone refusée')),
      );
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordedFilePath = path;
    });
  }

  Future<void> _playRecordedAudio() async {
    if (_recordedFilePath == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
    }
  }

  void _deleteRecording() {
    if (_recordedFilePath != null) {
      File(_recordedFilePath!).delete();
    }
    setState(() {
      _recordedFilePath = null;
      _recordDuration = Duration.zero;
    });
    _audioPlayer.stop();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _submitReply() {
    if (_replyController.text.trim().isEmpty && _recordedFilePath == null) return;

    setState(() {
      _isUploading = true;
    });

    if (_recordedFilePath != null) {
      _selectedMedia.add(MediaAttachment(
        url: _recordedFilePath!,
        type: MediaType.audio,
        filename: 'reponse_vocale.m4a',
      ));
    }

    widget.onReply(
      widget.questionId,
      widget.replyId,
      _replyController.text.trim(),
      _selectedMedia,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.reply,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Répondre à ${widget.userName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _replyController,
                maxLines: 5,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: 'Écrivez votre réponse...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              if (_recordedFilePath != null) ...[
                const SizedBox(height: 16),
                _buildRecordPreview(),
              ],
              const SizedBox(height: 16),
              _buildRecordingButtons(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submitReply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                      ),
                      child: _isUploading
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text('Répondre'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: AppColors.primary,
            ),
            onPressed: _playRecordedAudio,
          ),
          const SizedBox(width: 10),
          Text(
            _formatDuration(_recordDuration),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingButtons() {
    return Row(
      children: [
        if (!_isRecording)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.mic),
              label: const Text('Enregistrer une réponse vocale'),
            ),
          )
        else
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _stopRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[900],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.stop),
              label: Text('Arrêter (${_formatDuration(_recordDuration)})'),
            ),
          ),
      ],
    );
  }
}

class AllRepliesScreen extends StatefulWidget {
  final String questionId;
  final Map<String, dynamic> questionData;
  final Function(String, String, String) onReplyToReply;

  const AllRepliesScreen({
    super.key,
    required this.questionId,
    required this.questionData,
    required this.onReplyToReply,
  });

  @override
  State<AllRepliesScreen> createState() => _AllRepliesScreenState();
}

class _AllRepliesScreenState extends State<AllRepliesScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isReplying = false;
  final Map<String, AudioPlayer> _audioPlayers = {};
  Map<String, bool> _showNestedReplies = {};

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  void _playAudio(String audioUrl, String audioId) {
    if (_audioPlayers.containsKey(audioId)) {
      final player = _audioPlayers[audioId]!;
      if (player.state == PlayerState.playing) {
        player.pause();
      } else {
        player.play(UrlSource(audioUrl));
      }
    } else {
      final player = AudioPlayer();
      _audioPlayers[audioId] = player;
      player.play(UrlSource(audioUrl));
    }
  }

  void _toggleNestedReplies(String replyId) {
    setState(() {
      _showNestedReplies[replyId] = !(_showNestedReplies[replyId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Réponses'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: widget.questionData['userPhoto'] != null
                          ? CachedNetworkImageProvider(widget.questionData['userPhoto'])
                          : null,
                      child: widget.questionData['userPhoto'] == null
                          ? Text(
                        widget.questionData['userName']?[0]?.toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.questionData['userName'] ?? 'Utilisateur',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (widget.questionData['isVerified'] == true) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            widget.questionData['category'] ?? 'Général',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.questionData['question'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_questions')
                  .doc(widget.questionId)
                  .collection('replies')
                  .where('parentReplyId', isEqualTo: null)
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final replies = snapshot.data!.docs;

                if (replies.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune réponse pour le moment',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Soyez le premier à répondre!',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: replies.length,
                  itemBuilder: (context, index) {
                    return _buildFullReplyItem(replies[index]);
                  },
                );
              },
            ),
          ),
          _buildReplyInput(),
        ],
      ),
    );
  }

  Widget _buildFullReplyItem(QueryDocumentSnapshot reply) {
    final replyData = reply.data() as Map<String, dynamic>;
    final timestamp = replyData['timestamp'] as Timestamp?;
    final timeAgo = timestamp != null
        ? timeago.format(timestamp.toDate(), locale: 'fr')
        : 'Maintenant';
    final uniqueId = reply.id;
    final showNested = _showNestedReplies[reply.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: replyData['userPhoto'] != null
                    ? CachedNetworkImageProvider(replyData['userPhoto'])
                    : null,
                child: replyData['userPhoto'] == null
                    ? Text(
                  replyData['userName']?[0]?.toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          replyData['userName'] ?? 'Utilisateur',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (replyData['isVerified'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'report':
                      _reportReply(reply.id);
                      break;
                    case 'share':
                      _shareReply(replyData);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 18),
                        SizedBox(width: 8),
                        Text('Partager'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Signaler', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey[600],
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            replyData['reply'] ?? '',
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (replyData['media'] != null && (replyData['media'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildReplyMediaFull(List<Map<String, dynamic>>.from(replyData['media']), uniqueId),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleReplyLike(reply.id, replyData),
                child: Row(
                  children: [
                    Icon(
                      replyData['isLiked'] == true ? Icons.favorite : Icons.favorite_border,
                      color: replyData['isLiked'] == true ? Colors.red : Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${replyData['likesCount'] ?? 0}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => widget.onReplyToReply(
                    widget.questionId,
                    reply.id,
                    replyData['userName'] ?? 'Utilisateur'
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Répondre',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (replyData['nestedRepliesCount'] != null && replyData['nestedRepliesCount'] > 0)
                GestureDetector(
                  onTap: () => _toggleNestedReplies(reply.id),
                  child: Row(
                    children: [
                      Text(
                        '${replyData['nestedRepliesCount']} réponses',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      Icon(
                        showNested ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (showNested) ...[
            const SizedBox(height: 12),
            _buildNestedReplies(reply.id),
          ],
        ],
      ),
    );
  }

  Widget _buildNestedReplies(String parentReplyId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_questions')
          .doc(widget.questionId)
          .collection('replies')
          .where('parentReplyId', isEqualTo: parentReplyId)
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final nestedReplies = snapshot.data!.docs;

        if (nestedReplies.isEmpty) {
          return Container();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: nestedReplies.length,
          itemBuilder: (context, index) {
            return _buildNestedReplyItem(nestedReplies[index]);
          },
        );
      },
    );
  }

  Widget _buildNestedReplyItem(QueryDocumentSnapshot reply) {
    final replyData = reply.data() as Map<String, dynamic>? ?? {};
    final Timestamp? timestamp = replyData['timestamp'] as Timestamp?;
    final String timeAgo = timestamp != null
        ? timeago.format(timestamp.toDate(), locale: 'fr')
        : 'Maintenant';

    final String userName = (replyData['userName'] as String?)?.trim() ?? 'Utilisateur';
    final String initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final String? userPhoto = replyData['userPhoto'] as String?;
    final bool isVerified = replyData['isVerified'] == true;
    final bool isLiked = replyData['isLiked'] == true;
    final int likesCount = replyData['likesCount'] ?? 0;
    final List<dynamic>? mediaList = replyData['media'] as List<dynamic>?;

    return Container(
      margin: const EdgeInsets.only(top: 12, left: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// Entête: avatar + nom + vérifié + temps
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: userPhoto != null
                    ? CachedNetworkImageProvider(userPhoto)
                    : null,
                child: userPhoto == null
                    ? Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// Texte de la réponse
          if ((replyData['reply'] as String?)?.trim().isNotEmpty ?? false)
            Text(
              replyData['reply'],
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
            ),

          /// Media attaché
          if (mediaList != null && mediaList.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildReplyMediaFull(
              List<Map<String, dynamic>>.from(mediaList),
              reply.id,
            ),
          ],

          const SizedBox(height: 8),

          /// Actions: Like et Répondre
          Row(
            children: [
              /// Like
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _toggleReplyLike(reply.id, replyData),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey[600],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$likesCount',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              /// Bouton répondre
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => widget.onReplyToReply(
                  widget.questionId,
                  reply.id,
                  userName,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Répondre',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
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


  Widget _buildReplyMediaFull(List<Map<String, dynamic>> mediaList, String parentId) {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mediaList.length,
        itemBuilder: (context, index) {
          final media = mediaList[index];
          final uniqueId = '${parentId}_$index';
          return Container(
            width: 60,
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildMediaItemFull(media['type'], media['url'], media, uniqueId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaItemFull(String type, String url, Map<String, dynamic> media, String uniqueId) {
    switch (type) {
      case 'image':
        return GestureDetector(
          onTap: () => _showImageFullScreen(url),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.error),
            ),
          ),
        );
      case 'video':
        return GestureDetector(
          onTap: () => _showVideoPlayer(context, url),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                color: Colors.black,
                child: const Icon(
                  Icons.video_library,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 30,
              ),
            ],
          ),
        );
      case 'audio':
        return AudioPlayerWidget(
          audioUrl: url,
          audioId: uniqueId,
          player: _audioPlayers[uniqueId],
          onPlay: () => _playAudio(url, uniqueId),
        );
      default:
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.attachment),
        );
    }
  }

  void _showVideoPlayer(BuildContext context, String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoUrl: videoUrl),
      ),
    );
  }

  void _showImageFullScreen(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: 'Écrivez votre réponse...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                maxLength: 300,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isReplying ? null : _submitReply,
                icon: _isReplying
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(
                  Icons.send,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() {
      _isReplying = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};

      await FirebaseFirestore.instance
          .collection('community_questions')
          .doc(widget.questionId)
          .collection('replies')
          .add({
        'reply': _replyController.text.trim(),
        'userId': user.uid,
        'userName': userData['name'] ?? 'Utilisateur',
        'userPhoto': userData['photoURL'],
        'isVerified': userData['isVerified'] ?? false,
        'timestamp': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'media': [],
        'parentReplyId': null,
      });

      await FirebaseFirestore.instance
          .collection('community_questions')
          .doc(widget.questionId)
          .update({
        'answersCount': FieldValue.increment(1),
      });

      _replyController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi: $e')),
      );
    } finally {
      setState(() {
        _isReplying = false;
      });
    }
  }

  Future<void> _toggleReplyLike(String replyId, Map<String, dynamic> replyData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final isCurrentlyLiked = replyData['isLiked'] == true;
      final currentLikesCount = replyData['likesCount'] ?? 0;

      await FirebaseFirestore.instance
          .collection('community_questions')
          .doc(widget.questionId)
          .collection('replies')
          .doc(replyId)
          .update({
        'isLiked': !isCurrentlyLiked,
        'likesCount': isCurrentlyLiked
            ? currentLikesCount - 1
            : currentLikesCount + 1,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _reportReply(String replyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler cette réponse'),
        content: const Text('Voulez-vous signaler cette réponse comme inappropriée?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Réponse signalée')),
              );
            },
            child: const Text('Signaler', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _shareReply(Map<String, dynamic> replyData) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de partage à venir')),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.error, color: Colors.white, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}