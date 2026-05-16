part of 'chat_screen.dart';

// Lecteur vidéo
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..addListener(_videoListener);
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      setState(() {});
    });
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),

                  if (_showControls)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppBar(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              leading: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: VideoProgressIndicator(
                                _controller,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: Color(0xFF6C56F9),
                                ),
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.skip_previous,
                                    size: 36,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _controller.seekTo(
                                      _controller.value.position -
                                          const Duration(seconds: 10),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    _controller.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_controller.value.isPlaying) {
                                        _controller.pause();
                                      } else {
                                        _controller.play();
                                        _startHideTimer();
                                      }
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.skip_next,
                                    size: 36,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _controller.seekTo(
                                      _controller.value.position +
                                          const Duration(seconds: 10),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }
}
