import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/salon/pro_story.dart';
import '../../../../../services/salon/pro_story_service.dart';
import '../../salon_search_screen.dart';

class ProStoryRail extends StatefulWidget {
  const ProStoryRail({super.key});

  @override
  State<ProStoryRail> createState() => _ProStoryRailState();
}

class _ProStoryRailState extends State<ProStoryRail> {
  static final ProStoryService _service = ProStoryService();
  Stream<List<ProStory>>? _storiesStream;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _storiesStream = _service.watchActiveStories();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() => _storiesStream = _service.watchActiveStories());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProStory>>(
      stream: _storiesStream,
      builder: (context, snapshot) {
        final stories = snapshot.data ?? const [];
        if (stories.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            itemCount: stories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == 0) return const _StoryIntroBubble();
              final story = stories[index - 1];
              return _StoryBubble(
                story: story,
                onTap: () {
                  _service.markViewed(story);
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (_, _, _) => _StoryViewer(story: story),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _StoryIntroBubble extends StatelessWidget {
  const _StoryIntroBubble();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: ModernColors.ink,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Stories pro',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({required this.story, required this.onTap});

  final ProStory story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = story.isShop ? ModernColors.shop : ModernColors.creator;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.all(2.4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [color, ModernColors.accent]),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl:
                        story.authorPhotoUrl.isNotEmpty
                            ? story.authorPhotoUrl
                            : story.thumbnailUrl.isNotEmpty
                            ? story.thumbnailUrl
                            : story.mediaUrl,
                    fit: BoxFit.cover,
                    errorWidget:
                        (_, _, _) => Icon(
                          story.isShop ? AppIcons.boutique : AppIcons.creator,
                          color: color,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              story.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ModernColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryViewer extends StatelessWidget {
  const _StoryViewer({required this.story});

  final ProStory story;

  Future<void> _openCta(BuildContext context) async {
    final route = story.ctaRoute.trim();
    if (route.startsWith('http://') || route.startsWith('https://')) {
      final opened = await launchUrl(
        Uri.parse(route),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) _showSnack(context);
      return;
    }
    if (route.startsWith('/')) {
      Navigator.pushNamed(context, route);
      return;
    }
    final query =
        route.isNotEmpty
            ? route
            : '${story.authorName} ${story.caption}'.trim();
    if (query.isEmpty) {
      _showSnack(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SalonSearchScreen(initialQuery: query)),
    );
  }

  void _showSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Action indisponible pour cette story.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = story.isShop ? ModernColors.shop : ModernColors.creator;
    final remaining = story.expiresAt.difference(DateTime.now());
    final hours = remaining.inHours.clamp(0, 24);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.16),
                    backgroundImage:
                        story.authorPhotoUrl.isEmpty
                            ? null
                            : CachedNetworkImageProvider(story.authorPhotoUrl),
                    child:
                        story.authorPhotoUrl.isEmpty
                            ? Icon(Icons.verified_rounded, color: color)
                            : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${story.isShop ? 'Boutique' : 'Créateur'} certifié • encore ${hours}h',
                          style: const TextStyle(
                            color: Color(0xFFD1D5DB),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CachedNetworkImage(
                    imageUrl: story.mediaUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget:
                        (_, _, _) => Container(
                          color: ModernColors.ink,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                  ),
                ),
              ),
              if (story.caption.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  story.caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    fontSize: 15,
                  ),
                ),
              ],
              if (story.ctaLabel.isNotEmpty) ...[
                const SizedBox(height: 12),
                Material(
                  color: color,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () => _openCta(context),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Text(
                        story.ctaLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
