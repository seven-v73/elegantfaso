part of 'community_screen.dart';

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
        final path =
            '${tempDir.path}/reply_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: path);

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
        debugPrint('Erreur enregistrement audio réponse: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistrement impossible pour le moment.'),
          ),
        );
      }
    } else {
      if (!mounted) return;
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
    if (_replyController.text.trim().isEmpty && _recordedFilePath == null) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    if (_recordedFilePath != null) {
      _selectedMedia.add(
        MediaAttachment(
          url: _recordedFilePath!,
          type: MediaType.audio,
          filename: 'reponse_vocale.m4a',
        ),
      );
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
                  const Icon(Icons.reply, color: AppColors.primary, size: 24),
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
              AppTextField(
                controller: _replyController,
                label: 'Votre réponse',
                hint: 'Répondre avec un avis utile',
                icon: Icons.reply_rounded,
                maxLines: 5,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
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
                    child: AppButton(
                      label: 'Annuler',
                      onPressed: () => Navigator.pop(context),
                      variant: AppButtonVariant.tertiary,
                      expand: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: _isUploading ? 'Envoi...' : 'Répondre',
                      onPressed: _isUploading ? null : _submitReply,
                      loading: _isUploading,
                      expand: true,
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
            child: AppButton(
              label: 'Réponse vocale',
              onPressed: _startRecording,
              icon: Icons.mic_none_rounded,
              variant: AppButtonVariant.secondary,
              expand: true,
            ),
          )
        else
          Expanded(
            child: AppButton(
              label: 'Arrêter (${_formatDuration(_recordDuration)})',
              onPressed: _stopRecording,
              icon: Icons.stop_rounded,
              variant: AppButtonVariant.danger,
              expand: true,
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
  final Map<String, bool> _showNestedReplies = {};

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
                  color: Colors.grey.withValues(alpha: 0.1),
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
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage:
                          widget.questionData['userPhoto'] != null
                              ? CachedNetworkImageProvider(
                                widget.questionData['userPhoto'],
                              )
                              : null,
                      child:
                          widget.questionData['userPhoto'] == null
                              ? Text(
                                widget.questionData['userName']?[0]
                                        ?.toUpperCase() ??
                                    'U',
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
                                widget.questionData['userName'] ??
                                    'Utilisateur',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (widget.questionData['isVerified'] ==
                                  true) ...[
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
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
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
                          style: TextStyle(color: Colors.grey[500]),
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
    final timeAgo =
        timestamp != null
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
            color: Colors.grey.withValues(alpha: 0.1),
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
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage:
                    replyData['userPhoto'] != null
                        ? CachedNetworkImageProvider(replyData['userPhoto'])
                        : null,
                child:
                    replyData['userPhoto'] == null
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                itemBuilder:
                    (context) => [
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
                            Icon(
                              Icons.flag_outlined,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Signaler',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                child: Icon(Icons.more_vert, color: Colors.grey[600], size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            replyData['reply'] ?? '',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          if (replyData['media'] != null &&
              (replyData['media'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildReplyMediaFull(
              List<Map<String, dynamic>>.from(replyData['media']),
              uniqueId,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleReplyLike(reply.id, replyData),
                child: Row(
                  children: [
                    Icon(
                      replyData['isLiked'] == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                          replyData['isLiked'] == true
                              ? Colors.red
                              : Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${replyData['likesCount'] ?? 0}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap:
                    () => widget.onReplyToReply(
                      widget.questionId,
                      reply.id,
                      replyData['userName'] ?? 'Utilisateur',
                    ),
                child: Row(
                  children: [
                    Icon(Icons.reply, color: Colors.grey[600], size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Répondre',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (replyData['nestedRepliesCount'] != null &&
                  replyData['nestedRepliesCount'] > 0)
                GestureDetector(
                  onTap: () => _toggleNestedReplies(reply.id),
                  child: Row(
                    children: [
                      Text(
                        '${replyData['nestedRepliesCount']} réponses',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
      stream:
          FirebaseFirestore.instance
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
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
              style: const TextStyle(fontSize: 13, height: 1.4),
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              /// Bouton répondre
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap:
                    () => widget.onReplyToReply(
                      widget.questionId,
                      reply.id,
                      userName,
                    ),
                child: Row(
                  children: [
                    Icon(Icons.reply, color: Colors.grey.shade600, size: 16),
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

  Widget _buildReplyMediaFull(
    List<Map<String, dynamic>> mediaList,
    String parentId,
  ) {
    return SizedBox(
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
              child: _buildMediaItemFull(
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

  Widget _buildMediaItemFull(
    String type,
    String url,
    Map<String, dynamic> media,
    String uniqueId,
  ) {
    switch (type) {
      case 'image':
        return GestureDetector(
          onTap: () => _showImageFullScreen(url),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
            errorWidget:
                (context, url, error) => Container(
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
            color: Colors.grey.withValues(alpha: 0.1),
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
              child: AppTextField(
                controller: _replyController,
                label: 'Répondre',
                hint: 'Avis ou conseil',
                icon: Icons.chat_bubble_outline_rounded,
                maxLines: 2,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
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
                icon:
                    _isReplying
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.send, color: Colors.white),
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

      final userDoc =
          await FirebaseFirestore.instance
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
          .update({'answersCount': FieldValue.increment(1)});

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
      debugPrint('Erreur envoi réponse communauté: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Envoi impossible pour le moment.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isReplying = false;
        });
      }
    }
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
      debugPrint('Erreur like réponse communauté: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible pour le moment.')),
      );
    }
  }

  void _reportReply(String replyId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Signaler cette réponse'),
            content: const Text(
              'Voulez-vous signaler cette réponse comme inappropriée?',
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
                    const SnackBar(content: Text('Réponse signalée')),
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

  Future<void> _shareReply(Map<String, dynamic> replyData) async {
    final reply =
        (replyData['reply'] as String?)?.trim() ??
        'Réponse partagée depuis ElegantStyle';
    final author = (replyData['userName'] as String?)?.trim() ?? 'un membre';
    final question =
        (widget.questionData['question'] as String?)?.trim() ??
        'une discussion du Salon';
    final category =
        (widget.questionData['category'] as String?)?.trim() ?? 'Communauté';

    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Réponse ElegantStyle - $category',
          text:
              'Réponse partagée depuis ElegantStyle\n\n'
              '"$reply"\n\n'
              'Par $author, sur la question: $question\n\n'
              'Rejoins le Salon pour continuer l’échange.',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de partager cette réponse.')),
      );
    }
  }
}
