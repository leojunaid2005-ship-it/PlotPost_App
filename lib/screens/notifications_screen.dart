import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/property_post.dart';
import '../services/api_client.dart';
import 'property_details_screen.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.userName,
    required this.userAvatarInitials,
    required this.actionText,
    required this.timeAgo,
    required this.section,
    this.post,
    this.hasActionButton = false,
    this.actionButtonLabel = 'View',
    this.isUnread = false,
  });

  final String id;
  final String userName;
  final String userAvatarInitials;
  final String actionText;
  final String timeAgo;
  final String section; // 'Today', 'Yesterday', 'This Week', 'Earlier'
  final PropertyPost? post;
  final bool hasActionButton;
  final String actionButtonLabel;
  final bool isUnread;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationItem> _notifications;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _notifications = [];
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final values = await ApiClient.instance.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = values.map((value) {
          final createdAt = DateTime.tryParse(
            value['createdAt'] as String? ?? '',
          );
          final age = createdAt == null
              ? Duration.zero
              : DateTime.now().difference(createdAt);
          final section = age.inDays == 0
              ? 'Today'
              : age.inDays == 1
              ? 'Yesterday'
              : age.inDays < 7
              ? 'This Week'
              : 'Earlier';
          final name = value['actorName'] as String? ?? 'PlotPost';
          return NotificationItem(
            id: value['id'] as String,
            userName: name,
            userAvatarInitials: _initials(name),
            actionText: value['message'] as String? ?? '',
            timeAgo: _timeAgo(createdAt),
            section: section,
            isUnread: value['isRead'] != true,
          );
        }).toList();
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _isLoading = false;
      });
    } on http.ClientException {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not connect to PlotPost. Check the API server URL.';
        _isLoading = false;
      });
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isEmpty ? 'P' : name[0].toUpperCase();
  }

  static String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  void _openPost(PropertyPost? post) {
    if (post == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PropertyDetailsScreen(
          post: post,
          isSaved: false,
          fallbackLocation: 'Kozhikode',
          onToggleSaved: () {},
          onShowInterest: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sections = ['Today', 'Yesterday', 'This Week', 'Earlier'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: _loadNotifications,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    Text(_loadError!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _loadNotifications,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              )
            else if (_notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Center(
                  child: Text(
                    'You’re all caught up.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...sections.map((sectionName) {
                final items = _notifications
                    .where((item) => item.section == sectionName)
                    .toList();

                if (items.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        sectionName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    ...items.map(
                      (item) => _buildNotificationTile(item, theme, isDark),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    NotificationItem item,
    ThemeData theme,
    bool isDark,
  ) {
    return InkWell(
      onTap: () async {
        if (item.isUnread) {
          try {
            await ApiClient.instance.markNotificationRead(item.id);
          } on ApiException catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(error.message)));
            }
            return;
          } on http.ClientException {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not connect to PlotPost.')),
              );
            }
            return;
          }
          if (!mounted) return;
          setState(() {
            _notifications = _notifications.map((n) {
              return n.id == item.id
                  ? NotificationItem(
                      id: n.id,
                      userName: n.userName,
                      userAvatarInitials: n.userAvatarInitials,
                      actionText: n.actionText,
                      timeAgo: n.timeAgo,
                      section: n.section,
                      post: n.post,
                      hasActionButton: n.hasActionButton,
                      actionButtonLabel: n.actionButtonLabel,
                      isUnread: false,
                    )
                  : n;
            }).toList();
          });
        }
        _openPost(item.post);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            // User Avatar with Story Ring / Initial
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: item.isUnread
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF00E676),
                          Color(0xFF104B42),
                          Color(0xFF000000),
                        ],
                      )
                    : null,
                color: item.isUnread
                    ? null
                    : (isDark
                          ? const Color(0xFF262626)
                          : const Color(0xFFDBDBDB)),
              ),
              child: CircleAvatar(
                radius: 21,
                backgroundColor: isDark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFEFEFEF),
                child: Text(
                  item.userAvatarInitials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text Content
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${item.userName} ',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: item.actionText,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: '  ${item.timeAgo}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            // Right Side Action Button or Thumbnail
            if (item.hasActionButton)
              SizedBox(
                height: 32,
                child: FilledButton(
                  onPressed: () {
                    if (item.actionButtonLabel == 'Reply' ||
                        item.actionButtonLabel == 'Contact') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Contact ${item.userName} connected.'),
                        ),
                      );
                    } else if (item.post != null) {
                      _openPost(item.post);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.brightness == Brightness.dark
                        ? const Color(0xFF174B3A)
                        : theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(item.actionButtonLabel),
                ),
              )
            else if (item.post != null)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: item.post!.color,
                ),
                child: const Icon(
                  Icons.home_work_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
