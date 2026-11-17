import 'package:flutter/material.dart';
import '../models/property_post.dart';

void showCommentsModalSheet(BuildContext context, PropertyPost post) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CommentsModalSheet(post: post),
  );
}

class CommentItem {
  CommentItem({
    required this.userName,
    required this.userAvatarInitials,
    required this.text,
    required this.timeAgo,
    this.likes = 0,
    this.isLiked = false,
  });

  final String userName;
  final String userAvatarInitials;
  final String text;
  final String timeAgo;
  int likes;
  bool isLiked;
}

class CommentsModalSheet extends StatefulWidget {
  const CommentsModalSheet({super.key, required this.post});
  final PropertyPost post;

  @override
  State<CommentsModalSheet> createState() => _CommentsModalSheetState();
}

class _CommentsModalSheetState extends State<CommentsModalSheet> {
  final TextEditingController _commentController = TextEditingController();
  final List<CommentItem> _comments = [
    CommentItem(
      userName: 'Rahul Nair',
      userAvatarInitials: 'RN',
      text: 'Is the price negotiable for immediate settlement?',
      timeAgo: '2h ago',
      likes: 4,
    ),
    CommentItem(
      userName: 'Calicut Properties',
      userAvatarInitials: 'CP',
      text: 'Great location near Nadakkavu. Road access is 20ft wide.',
      timeAgo: '4h ago',
      likes: 9,
    ),
    CommentItem(
      userName: 'Anjali V.',
      userAvatarInitials: 'AV',
      text: 'Are water and electricity connections available on plot?',
      timeAgo: '1d ago',
      likes: 2,
    ),
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _comments.insert(
        0,
        CommentItem(
          userName: 'You',
          userAvatarInitials: 'PU',
          text: text,
          timeAgo: 'Just now',
        ),
      );
    });

    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B22) : theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Drag Handle
            Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF383E4C) : const Color(0xFFD0D7DE),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Comments (${_comments.length})',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Comments List
            Expanded(
              child: _comments.isEmpty
                  ? Center(
                      child: Text(
                        'No comments yet. Be the first to comment!',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 17,
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(
                                  comment.userAvatarInitials,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          comment.userName,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          comment.timeAgo,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      comment.text,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    comment.isLiked = !comment.isLiked;
                                    if (comment.isLiked) {
                                      comment.likes++;
                                    } else {
                                      comment.likes--;
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8, top: 4),
                                  child: Column(
                                    children: [
                                      Icon(
                                        comment.isLiked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 16,
                                        color: comment.isLiked
                                            ? const Color(0xFFED4956)
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                      if (comment.likes > 0) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${comment.likes}',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Comment Input Box
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222630) : const Color(0xFFF6F8FA),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      'PU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _addComment(),
                      decoration: InputDecoration(
                        hintText: 'Add a comment for ${widget.post.seller}...',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _addComment,
                    child: Text(
                      'Post',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
