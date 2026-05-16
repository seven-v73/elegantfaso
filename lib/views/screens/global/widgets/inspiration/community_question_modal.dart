part of 'community_screen.dart';

class EnhancedQuestionModal extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onPost;
  final List<String> categories;
  final List<MediaAttachment> selectedMedia;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onPickAudio;
  final Function(int) onRemoveMedia;
  final ValueChanged<String>? onCategoryChanged;
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
    this.onCategoryChanged,
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
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
        final path =
            '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

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
        debugPrint('Erreur enregistrement audio question: $e');
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            _slideAnimation.value * MediaQuery.of(context).size.height,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
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
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: AppColors.communityGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            widget.isEditing
                ? Icons.edit_note_rounded
                : Icons.add_comment_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEditing ? 'Modifier l’échange' : 'Créer un échange',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Demandez un avis ou partagez une idée.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceRaised,
            foregroundColor: AppColors.inkSoft,
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
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.categories.length,
            itemBuilder: (context, index) {
              final category = widget.categories[index];
              final isSelected = category == _selectedCategory;

              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected:
                      (_) => setState(() {
                        _selectedCategory = category;
                        widget.onCategoryChanged?.call(category);
                      }),
                  backgroundColor: AppColors.surfaceRaised,
                  selectedColor: AppColors.primary,
                  showCheckmark: false,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.line,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.inkSoft,
                    fontWeight: FontWeight.w800,
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
    return AppTextField(
      controller: widget.controller,
      focusNode: _focusNode,
      label: 'Votre échange',
      hint: 'Question, avis, inspiration...',
      icon: Icons.chat_bubble_outline_rounded,
      maxLines: 6,
      maxLength: 500,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildRecordPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
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
        SizedBox(
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
          errorBuilder:
              (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image_rounded),
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
              Text(
                'Vidéo',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
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
              Text(
                'Audio',
                style: TextStyle(color: AppColors.primary, fontSize: 10),
              ),
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
            icon: Icons.photo_camera_rounded,
            label: 'Photo',
            onTap: widget.onPickImage,
          ),
        ),
        const SizedBox(width: 8),
        if (!_isRecording)
          Expanded(
            child: _buildMediaButton(
              icon: Icons.mic_none_rounded,
              label: 'Audio',
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
            icon: Icons.more_horiz_rounded,
            label: 'Plus',
            onTap: _showMoreMediaOptions,
          ),
        ),
      ],
    );
  }

  void _showMoreMediaOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SafeArea(
            child: Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.videocam_outlined),
                    title: const Text('Vidéo'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onPickVideo();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_file_rounded),
                    title: const Text('Fichier audio'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onPickAudio();
                    },
                  ),
                ],
              ),
            ),
          ),
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
          color: AppColors.surfaceRaised,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: color ?? AppColors.primary,
                fontWeight: FontWeight.w800,
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
                borderRadius: BorderRadius.circular(14),
              ),
              side: const BorderSide(color: AppColors.line),
              foregroundColor: AppColors.inkSoft,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed:
                widget.isUploading
                    ? null
                    : () {
                      if (_recordedFilePath != null) {
                        widget.selectedMedia.add(
                          MediaAttachment(
                            url: _recordedFilePath!,
                            type: MediaType.audio,
                            filename: 'enregistrement_vocal.m4a',
                          ),
                        );
                      }
                      widget.onPost?.call();
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child:
                widget.isUploading
                    ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
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
