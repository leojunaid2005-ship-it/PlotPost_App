import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/property_post.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import 'property_details_screen.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
  });

  final String text;
  final bool isMe;
  final String time;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.conversationId,
    required this.userName,
    required this.userInitials,
    this.isOnline = false,
    this.post,
    this.initialMessage = '',
  });

  final String? conversationId;
  final String userName;
  final String userInitials;
  final bool isOnline;
  final PropertyPost? post;
  final String initialMessage;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.conversationId != null) {
      _loadMessages();
    } else if (widget.initialMessage.isNotEmpty) {
      _messages.add(
        ChatMessage(text: widget.initialMessage, isMe: false, time: '10:30 AM'),
      );
    }
  }

  Future<void> _loadMessages() async {
    final conversationId = widget.conversationId;
    if (conversationId == null) return;
    setState(() => _isLoading = true);
    try {
      final values = await ApiClient.instance.getMessages(conversationId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(
            values.map((value) {
              final createdAt = DateTime.tryParse(
                value['createdAt'] as String? ?? '',
              );
              return ChatMessage(
                text: value['text'] as String? ?? '',
                isMe: value['senderId'] == ApiClient.instance.userId,
                time: createdAt == null ? '' : _formatTime(createdAt),
              );
            }),
          );
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(error.message);
    } on http.ClientException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Could not connect to PlotPost. Check the API server URL.');
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    final conversationId = widget.conversationId;
    if (conversationId != null) {
      setState(() => _isSending = true);
      try {
        final value = await ApiClient.instance.sendMessage(
          conversationId,
          text,
        );
        if (!mounted) return;
        final createdAt = DateTime.tryParse(
          value['createdAt'] as String? ?? '',
        );
        setState(() {
          _messages.add(
            ChatMessage(
              text: value['text'] as String? ?? text,
              isMe: true,
              time: createdAt == null ? 'Just now' : _formatTime(createdAt),
            ),
          );
          _inputController.clear();
          _isSending = false;
        });
      } on ApiException catch (error) {
        if (!mounted) return;
        setState(() => _isSending = false);
        _showMessage(error.message);
      } on http.ClientException {
        if (!mounted) return;
        setState(() => _isSending = false);
        _showMessage(
          'Could not connect to PlotPost. Check the API server URL.',
        );
      }
      return;
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isMe: true, time: 'Just now'));
      _inputController.clear();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isDark
                  ? const Color(0xFF262626)
                  : const Color(0xFFEFEFEF),
              child: Text(
                widget.userInitials,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  widget.isOnline ? 'Active now' : 'Active 2h ago',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: const [SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          // Property Card Reference Banner if chatting about a post
          if (widget.post != null)
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PropertyDetailsScreen(
                      post: widget.post!,
                      isSaved: false,
                      fallbackLocation: 'Kozhikode',
                      onToggleSaved: () {},
                      onShowInterest: () {},
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: widget.post!.color,
                      ),
                      child: const Icon(
                        Icons.home_work_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_isLoading)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post!.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.post!.price.isNotEmpty
                                  ? widget.post!.price
                                  : 'Tap to view details',
                              style: TextStyle(
                                fontSize: 11,
                                color: plotPostTextAccent(
                                  context,
                                  theme.colorScheme.primary,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isMe
                          ? theme.colorScheme.primary
                          : (isDark
                                ? const Color(0xFF262626)
                                : const Color(0xFFEFEFEF)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(msg.isMe ? 18 : 4),
                        bottomRight: Radius.circular(msg.isMe ? 4 : 18),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.3,
                        color: msg.isMe
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Chat Input Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF262626)
                            : const Color(0xFFEFEFEF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: const InputDecoration(
                                hintText: 'Message...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
