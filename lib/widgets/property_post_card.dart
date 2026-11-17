import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/property_post.dart';
import 'comments_modal_sheet.dart';
import 'report_post_modal.dart';
import 'share_post_modal_sheet.dart';
import 'static_chip.dart';
import 'property_image.dart';

class PropertyPostCard extends StatefulWidget {
  const PropertyPostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.isSaved = false,
    this.onToggleSaved,
  });

  final PropertyPost post;
  final VoidCallback onTap;
  final bool isSaved;
  final VoidCallback? onToggleSaved;

  @override
  State<PropertyPostCard> createState() => _PropertyPostCardState();
}

class _PropertyPostCardState extends State<PropertyPostCard>
    with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  int _likeCount = 42;
  bool _showHeartOverlay = false;

  @override
  void initState() {
    super.initState();
    _likeCount = 40 + (widget.post.title.length * 3) % 150;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount++;
      } else {
        _likeCount--;
      }
    });
  }

  void _onDoubleTapPhoto() {
    if (!_isLiked) {
      setState(() {
        _isLiked = true;
        _likeCount++;
      });
    }

    setState(() => _showHeartOverlay = true);

    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) {
        setState(() => _showHeartOverlay = false);
      }
    });
  }

  void _showPostOptionsMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181B22) : theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.copy_rounded, size: 20),
                title: const Text(
                  'Copy property details',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                onTap: () {
                  Navigator.pop(modalContext);
                  final lines = [
                    widget.post.title,
                    'Price: ${widget.post.price.isEmpty ? 'Price on request' : widget.post.price}',
                    'Type: ${widget.post.type} · ${widget.post.deal}',
                    if (widget.post.location.isNotEmpty)
                      'Location: ${widget.post.location}',
                  ];
                  Clipboard.setData(ClipboardData(text: lines.join('\n')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Listing details copied to clipboard.'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.flag_outlined,
                  color: Color(0xFFED4956),
                  size: 20,
                ),
                title: const Text(
                  'Report this post',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Color(0xFFED4956),
                  ),
                ),
                subtitle: const Text(
                  'Flag fake, spam, or inappropriate content',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(modalContext);
                  showReportPostModal(context, widget.post);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;

    final platformColor = switch (post.platform) {
      'Instagram' => const Color(0xFFE1306C),
      'Facebook' => const Color(0xFF1877F2),
      'YouTube' => const Color(0xFFFF0000),
      _ => theme.colorScheme.primary,
    };

    final shortLoc = post.shortLocation;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                // Story Ring Avatar
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        platformColor,
                        platformColor.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: theme.colorScheme.surface,
                    child: Text(
                      post.initials,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.seller,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${post.platform} • ${post.age}${shortLoc.isNotEmpty ? ' • $shortLoc' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => _showPostOptionsMenu(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Post options',
                ),
              ],
            ),
          ),

          // Image / Video Media Box with Double-Tap to Like Gesture
          GestureDetector(
            onTap: widget.onTap,
            onDoubleTap: _onDoubleTapPhoto,
            child: SizedBox(
              height: 215,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: post.imagePaths.isNotEmpty
                        ? PropertyImage(
                            path: post.imagePaths.first,
                            fit: BoxFit.cover,
                            cacheWidth: 800,
                            errorBuilder: (_, _, _) => Container(
                              color: post.color,
                              child: const Icon(
                                Icons.home_work_outlined,
                                size: 48,
                                color: Colors.white70,
                              ),
                            ),
                          )
                        : Container(
                            color: post.color,
                            child: Center(
                              child: Icon(
                                post.video
                                    ? Icons.play_circle_fill_rounded
                                    : Icons.home_work_outlined,
                                size: 52,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                  ),

                  // Double-Tap Heart Overlay Animation
                  if (_showHeartOverlay)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _showHeartOverlay ? 1.0 : 0.0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFED4956),
                          size: 72,
                        ),
                      ),
                    ),

                  // Price Tag Badge Overlay
                  if (post.price.isNotEmpty)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.price,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action Bar (1. Like, 2. Comment, 3. Share, 4. Bookmark)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                // 1. LIKE ICON
                GestureDetector(
                  onTap: _toggleLike,
                  child: AnimatedScale(
                    scale: _isLiked ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      _isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 25,
                      color: _isLiked
                          ? const Color(0xFFED4956)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // 2. COMMENT ICON
                GestureDetector(
                  onTap: () => showCommentsModalSheet(context, widget.post),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 22,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 16),

                // 3. SHARE ICON
                GestureDetector(
                  onTap: () => showSharePostModalSheet(context, widget.post),
                  child: Icon(
                    Icons.send_rounded,
                    size: 21,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const Spacer(),

                // 4. BOOKMARK / SAVE ICON
                if (widget.onToggleSaved != null)
                  GestureDetector(
                    onTap: widget.onToggleSaved,
                    child: AnimatedScale(
                      scale: widget.isSaved ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        widget.isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 25,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Likes Count & View Comments Link
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_likeCount likes',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${post.seller} ',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: post.title,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () => showCommentsModalSheet(context, widget.post),
                  child: Text(
                    'View all 3 comments',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [StaticChip(post.type), StaticChip(post.deal)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
