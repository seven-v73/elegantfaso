part of 'community_screen.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

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
            placeholder:
                (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            errorWidget:
                (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 64),
                ),
          ),
        ),
      ),
    );
  }
}
