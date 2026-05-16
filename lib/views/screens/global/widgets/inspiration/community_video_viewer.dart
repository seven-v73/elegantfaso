part of 'community_screen.dart';

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
        child:
            _controller.value.isInitialized
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
