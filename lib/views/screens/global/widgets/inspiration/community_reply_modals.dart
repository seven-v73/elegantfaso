part of 'community_screen.dart';

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
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Répondre',
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
              AppTextField(
                controller: _replyController,
                label: 'Votre réponse',
                hint: 'Avis, conseil, piste...',
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
      _replyController.text.trim(),
      _selectedMedia,
    );
  }
}
