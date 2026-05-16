part of 'community_screen.dart';

class EnhancedQuestionCard extends StatefulWidget {
  final String questionId;
  final Map<String, dynamic> questionData;
  final String? currentUserId;
  final Function(String) onReply;
  final Function(String, String, String) onReplyToReply;
  final Function(String) onEdit;
  final Function(String) onDelete;
  final Future<void> Function(String, String, String) onEditReply;
  final Future<void> Function(String, String) onDeleteReply;
  final Future<void> Function(String, String, bool) onToggleHelpfulReply;
  final bool canReply;
  final bool isAdmin;

  const EnhancedQuestionCard({
    super.key,
    required this.questionId,
    required this.questionData,
    this.currentUserId,
    required this.onReply,
    required this.onReplyToReply,
    required this.onEdit,
    required this.onDelete,
    required this.onEditReply,
    required this.onDeleteReply,
    required this.onToggleHelpfulReply,
    this.canReply = true,
    this.isAdmin = false,
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _likesCount = widget.questionData['likesCount'] ?? 0;
    final likes = List<String>.from(widget.questionData['likes'] ?? []);
    _isLiked =
        widget.currentUserId != null && likes.contains(widget.currentUserId);
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
    final questionRef = firestore
        .collection('community_questions')
        .doc(widget.questionId);

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
    final timeAgo =
        timestamp != null
            ? timeago.format(timestamp.toDate(), locale: 'fr')
            : 'Maintenant';

    final tags = List<String>.from(widget.questionData['tags'] ?? []);
    final mediaList = List<Map<String, dynamic>>.from(
      widget.questionData['media'] ?? [],
    );
    final bool isAuthor = widget.currentUserId == widget.questionData['userId'];

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.line),
              boxShadow: AppColors.softShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Positioned(
                    right: -42,
                    top: -46,
                    child: Icon(
                      Icons.forum_rounded,
                      color: AppColors.primary.withValues(alpha: 0.045),
                      size: 152,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserHeader(timeAgo),
                        if ((widget.questionData['groupName']?.toString() ?? '')
                            .isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildGroupContextPill(
                            widget.questionData['groupName'].toString(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildQuestionContent(),
                        if (mediaList.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildMediaContent(mediaList),
                        ],
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildTags(tags),
                        ],
                        const SizedBox(height: 16),
                        _buildActionBar(isAuthor || widget.isAdmin),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: _buildRepliesSection(),
                          ),
                          crossFadeState:
                              _showReplies
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 220),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserHeader(String timeAgo) {
    final isEdited = widget.questionData['editedAt'] != null;
    final groupName = widget.questionData['groupName']?.toString() ?? '';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.communityGradient,
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surface,
            backgroundImage:
                widget.questionData['userPhoto'] != null
                    ? CachedNetworkImageProvider(
                      widget.questionData['userPhoto'],
                    )
                    : null,
            child:
                widget.questionData['userPhoto'] == null
                    ? Text(
                      widget.questionData['userName']?[0]?.toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
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
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.ink,
                        letterSpacing: 0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.questionData['isVerified'] == true) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                  ],
                ],
              ),
              Text(
                isEdited ? '$timeAgo • modifié' : timeAgo,
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 132),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.label_rounded,
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.questionData['category'] ?? 'Général',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (groupName.isNotEmpty) const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildQuestionContent() {
    return Text(
      widget.questionData['question'] ?? '',
      style: const TextStyle(
        fontSize: 16,
        height: 1.48,
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }

  Widget _buildGroupContextPill(String groupName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.talents, size: 15, color: AppColors.secondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              groupName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(List<Map<String, dynamic>> mediaList) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: mediaList.length,
        itemBuilder: (context, index) {
          final media = mediaList[index];
          final type = media['type'] as String;
          final url = media['url'] as String;
          final uniqueId = '${widget.questionId}_$index';

          return Container(
            width: 164,
            margin: const EdgeInsets.only(right: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildMediaItem(type, url, media, uniqueId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaItem(
    String type,
    String url,
    Map<String, dynamic> media,
    String uniqueId,
  ) {
    switch (type) {
      case 'image':
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => Container(
                color: AppColors.surfaceRaised,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          errorWidget:
              (context, url, error) => Container(
                color: AppColors.surfaceRaised,
                child: const Icon(
                  Icons.broken_image_rounded,
                  color: AppColors.muted,
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
                  color: Colors.white70,
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
          color: AppColors.surfaceRaised,
          child: const Icon(Icons.attachment_rounded, color: AppColors.muted),
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
      children:
          tags
              .map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildActionBar(bool isAuthor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildActionPill(
              icon:
                  _isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
              label: '$_likesCount',
              color: _isLiked ? AppColors.rose : AppColors.inkSoft,
              selected: _isLiked,
              onTap: _toggleLike,
            ),
            const SizedBox(width: 8),
            _buildActionPill(
              icon: Icons.mode_comment_outlined,
              label: 'Répondre',
              color: widget.canReply ? AppColors.primary : AppColors.muted,
              selected: false,
              onTap:
                  widget.canReply
                      ? () => widget.onReply(widget.questionId)
                      : () {},
            ),
            const SizedBox(width: 8),
            _buildActionPill(
              icon:
                  _showReplies
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
              label: '${widget.questionData['answersCount'] ?? 0} réponses',
              color: AppColors.inkSoft,
              selected: _showReplies,
              onTap: () => setState(() => _showReplies = !_showReplies),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: AppColors.inkSoft,
              ),
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
                  case 'edit':
                    widget.onEdit(widget.questionId);
                    break;
                  case 'delete':
                    widget.onDelete(widget.questionId);
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.ios_share_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Partager'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'save',
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_border_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Sauvegarder'),
                        ],
                      ),
                    ),
                    if (isAuthor)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                    if (isAuthor)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.rose,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Supprimer',
                              style: TextStyle(color: AppColors.rose),
                            ),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 18,
                            color: AppColors.rose,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Signaler',
                            style: TextStyle(color: AppColors.rose),
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepliesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('community_questions')
              .doc(widget.questionId)
              .collection('replies')
              .where('parentReplyId', isEqualTo: null)
              .orderBy('timestamp', descending: false)
              .limit(12)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final replies =
            snapshot.data!.docs.where((reply) {
              final data = reply.data() as Map<String, dynamic>? ?? {};
              return data['isDeleted'] != true &&
                  data['status'] != 'deleted' &&
                  data['status'] != 'hidden';
            }).toList();
        replies.sort(_sortRepliesForReading);

        if (replies.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aucune réponse pour le moment. Lance la première piste.',
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 1, color: AppColors.line),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Réponses récentes',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...replies.take(3).map((reply) => _buildReplyItem(reply)),
            if (replies.length > 3) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _showAllReplies,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Voir toutes les réponses'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
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
    final String timeAgo =
        timestamp != null
            ? timeago.format(timestamp.toDate(), locale: 'fr')
            : 'Maintenant';

    final String userName =
        (replyData['userName'] as String?)?.trim() ?? 'Utilisateur';
    final String initial =
        userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final String? userPhoto = replyData['userPhoto'] as String?;
    final bool isVerified = replyData['isVerified'] == true;
    final bool isLiked = replyData['isLiked'] == true;
    final bool isHelpful = replyData['isHelpful'] == true;
    final int likesCount = replyData['likesCount'] ?? 0;
    final List<dynamic>? mediaList = replyData['media'] as List<dynamic>?;
    final bool canManage =
        widget.isAdmin || widget.currentUserId == replyData['userId'];
    final bool canHighlight =
        widget.isAdmin || widget.currentUserId == widget.questionData['userId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isHelpful
                ? AppColors.primary.withValues(alpha: 0.055)
                : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isHelpful
                  ? AppColors.primary.withValues(alpha: 0.28)
                  : Colors.grey[200]!,
        ),
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
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage:
                    userPhoto != null
                        ? CachedNetworkImageProvider(userPhoto)
                        : null,
                child:
                    userPhoto == null
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (isHelpful) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Utile',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (canManage || canHighlight)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    size: 19,
                    color: AppColors.inkSoft,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      widget.onEditReply(
                        widget.questionId,
                        reply.id,
                        replyData['reply']?.toString() ?? '',
                      );
                    }
                    if (value == 'delete') {
                      widget.onDeleteReply(widget.questionId, reply.id);
                    }
                    if (value == 'helpful') {
                      widget.onToggleHelpfulReply(
                        widget.questionId,
                        reply.id,
                        !isHelpful,
                      );
                    }
                  },
                  itemBuilder:
                      (context) => [
                        if (canHighlight)
                          PopupMenuItem(
                            value: 'helpful',
                            child: Row(
                              children: [
                                Icon(
                                  isHelpful
                                      ? Icons.remove_done_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isHelpful ? 'Retirer utile' : 'Marquer utile',
                                ),
                              ],
                            ),
                          ),
                        if (canManage)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                        if (canManage)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppColors.rose,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Supprimer',
                                  style: TextStyle(color: AppColors.rose),
                                ),
                              ],
                            ),
                          ),
                      ],
                ),
            ],
          ),

          const SizedBox(height: 8),

          /// Texte de la réponse
          if ((replyData['reply'] as String?)?.trim().isNotEmpty ?? false)
            Text(
              replyData['reply'],
              style: const TextStyle(fontSize: 14, height: 1.4),
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              /// Bouton répondre
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap:
                    widget.canReply
                        ? () => widget.onReplyToReply(
                          widget.questionId,
                          reply.id,
                          userName,
                        )
                        : null,
                child: Row(
                  children: [
                    Icon(Icons.reply, color: Colors.grey.shade600, size: 18),
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

  int _sortRepliesForReading(QueryDocumentSnapshot a, QueryDocumentSnapshot b) {
    final aData = a.data() as Map<String, dynamic>? ?? {};
    final bData = b.data() as Map<String, dynamic>? ?? {};
    final aHelpful = aData['isHelpful'] == true ? 1 : 0;
    final bHelpful = bData['isHelpful'] == true ? 1 : 0;
    if (aHelpful != bHelpful) return bHelpful.compareTo(aHelpful);

    final aLikes = (aData['likesCount'] as num?)?.toInt() ?? 0;
    final bLikes = (bData['likesCount'] as num?)?.toInt() ?? 0;
    if (aLikes != bLikes) return bLikes.compareTo(aLikes);

    final aTime = aData['timestamp'] as Timestamp?;
    final bTime = bData['timestamp'] as Timestamp?;
    if (aTime == null || bTime == null) return 0;
    return aTime.compareTo(bTime);
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyMedia(
    List<Map<String, dynamic>> mediaList,
    String parentId,
  ) {
    return SizedBox(
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
              child: _buildMediaItem(
                media['type'],
                media['url'],
                media,
                uniqueId,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleReplyLike(
    String replyId,
    Map<String, dynamic> replyData,
  ) async {
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
            'likesCount':
                isCurrentlyLiked
                    ? currentLikesCount - 1
                    : currentLikesCount + 1,
          });
    } catch (e) {
      debugPrint('Erreur like question communauté: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible pour le moment.')),
      );
    }
  }

  Future<void> _shareQuestion() async {
    final question =
        (widget.questionData['question'] as String?)?.trim() ??
        'Discussion ElegantStyle';
    final category =
        (widget.questionData['category'] as String?)?.trim() ?? 'Communauté';
    final author =
        (widget.questionData['userName'] as String?)?.trim() ?? 'la communauté';
    final tags = List<String>.from(widget.questionData['tags'] ?? []);
    final tagLine =
        tags.isEmpty ? '' : '\n${tags.take(4).map((tag) => '#$tag').join(' ')}';

    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Discussion ElegantStyle - $category',
          text:
              'Question partagée depuis ElegantStyle\n\n'
              '$question\n\n'
              'Par $author • $category$tagLine\n\n'
              'Rejoins le Salon pour répondre avec bienveillance.',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de partager cette question.')),
      );
    }
  }

  void _reportQuestion() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Signaler cette question'),
            content: const Text(
              'Voulez-vous vraiment signaler cette question comme inappropriée?',
            ),
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
                child: const Text(
                  'Signaler',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _saveQuestion() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Question sauvegardée')));
  }

  void _showAllReplies() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AllRepliesScreen(
              questionId: widget.questionId,
              questionData: widget.questionData,
              onReplyToReply: widget.onReplyToReply,
            ),
      ),
    );
  }
}
