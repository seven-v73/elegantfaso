part of 'community_screen.dart';

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
                  child: SizedBox(
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
                  child: SizedBox(
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
                SizedBox(
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
                SizedBox(
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
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
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
                              await _player.seek(
                                Duration(seconds: value.toInt()),
                              );
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
                    Icon(Icons.audiotrack, size: 12, color: AppColors.primary),
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
