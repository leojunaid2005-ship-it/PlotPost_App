import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/sample_posts.dart';
import '../models/property_post.dart';
import 'chat_screen.dart';
import 'property_details_screen.dart';

class InquiryItem {
  const InquiryItem({
    required this.id,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerEmail,
    required this.message,
    required this.preferredContact,
    required this.timeAgo,
    required this.post,
    this.isUnread = false,
  });

  final String id;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final String message;
  final String preferredContact;
  final String timeAgo;
  final PropertyPost post;
  final bool isUnread;
}

class InquiriesScreen extends StatefulWidget {
  const InquiriesScreen({super.key});

  @override
  State<InquiriesScreen> createState() => _InquiriesScreenState();
}

class _InquiriesScreenState extends State<InquiriesScreen> {
  String _activeFilter = 'All';

  late List<InquiryItem> _inquiries;

  @override
  void initState() {
    super.initState();
    _inquiries = [
      InquiryItem(
        id: '1',
        buyerName: 'Ravi Kumar',
        buyerPhone: '+91 98950 12345',
        buyerEmail: 'ravi.k@gmail.com',
        message: 'Hi, I am interested in your 3 BHK villa in Mananchira. Is the price negotiable? Can I visit this Saturday?',
        preferredContact: 'Phone call',
        timeAgo: '15m ago',
        post: posts[0],
        isUnread: true,
      ),
      InquiryItem(
        id: '2',
        buyerName: 'Anil Varma',
        buyerPhone: '+91 98950 67890',
        buyerEmail: 'anil.v@yahoo.com',
        message: 'Is the 10 cent plot in Chevayur clear-titled? Please share the survey map or location pin.',
        preferredContact: 'WhatsApp',
        timeAgo: '2h ago',
        post: posts[1],
        isUnread: true,
      ),
      InquiryItem(
        id: '3',
        buyerName: 'Meera Nair',
        buyerPhone: '+91 98950 54321',
        buyerEmail: 'meera.nair@outlook.com',
        message: 'Looking for a 2 BHK flat for rent near Civil Station. Is car parking covered?',
        preferredContact: 'Email',
        timeAgo: 'Yesterday',
        post: posts[2],
      ),
      InquiryItem(
        id: '4',
        buyerName: 'Suresh Menon',
        buyerPhone: '+91 98950 99887',
        buyerEmail: 'suresh.m@gmail.com',
        message: 'Interested in purchasing the 3 BHK sea view apartment on Beach Road.',
        preferredContact: 'Phone call',
        timeAgo: '2d ago',
        post: posts[3],
      ),
    ];
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _callBuyer(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    try {
      final opened = await launchUrl(Uri(scheme: 'tel', path: digits));
      if (!opened) _message('Could not open phone app.');
    } catch (_) {
      _message('Could not open phone app.');
    }
  }

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    _message('$label copied to clipboard.');
  }

  void _openChat(InquiryItem inquiry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          userName: inquiry.buyerName,
          userInitials: inquiry.buyerName.isNotEmpty
              ? inquiry.buyerName
                    .split(' ')
                    .map((e) => e[0])
                    .take(2)
                    .join('')
                    .toUpperCase()
              : 'B',
          isOnline: true,
          post: inquiry.post,
          initialMessage: inquiry.message,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filters = ['All', 'Unread', 'Phone call', 'WhatsApp'];

    final filtered = _inquiries.where((inq) {
      if (_activeFilter == 'All') return true;
      if (_activeFilter == 'Unread') return inq.isUnread;
      return inq.preferredContact == _activeFilter;
    }).toList();

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
          'Buyer Inquiries',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_inquiries.length} total buyer leads received',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: filters.map((filter) {
                      final isSelected = _activeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary.withValues(
                            alpha: 0.18,
                          ),
                          backgroundColor: isDark
                              ? const Color(0xFF242826)
                              : const Color(0xFFF0F7F4),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.4,
                                  )
                                : (isDark
                                      ? const Color(0xFF2E3834)
                                      : const Color(0xFFE0EAE5)),
                            width: 0.8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onSelected: (_) =>
                              setState(() => _activeFilter = filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Inquiries Feed
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mark_email_unread_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No inquiries found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: theme.colorScheme.primary,
                    onRefresh: () async {
                      await Future<void>.delayed(const Duration(milliseconds: 700));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final inquiry = filtered[index];
                        return _buildInquiryCard(inquiry, theme, isDark);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryCard(InquiryItem inquiry, ThemeData theme, bool isDark) {
    final initials = inquiry.buyerName.isNotEmpty
        ? inquiry.buyerName
              .split(' ')
              .map((e) => e[0])
              .take(2)
              .join('')
              .toUpperCase()
        : 'B';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buyer Info Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark
                    ? const Color(0xFF262626)
                    : const Color(0xFFEFEFEF),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          inquiry.buyerName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (inquiry.isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Prefers: ${inquiry.preferredContact} • ${inquiry.timeAgo}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Inquiry Message
          Container(
            padding: const EdgeInsets.all(12),
            child: Text(
              inquiry.message,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Attached Property Reference Bar
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PropertyDetailsScreen(
                    post: inquiry.post,
                    isSaved: false,
                    fallbackLocation: 'Kozhikode',
                    onToggleSaved: () {},
                    onShowInterest: () {},
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: inquiry.post.color,
                    ),
                    child: const Icon(
                      Icons.home_work_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      inquiry.post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons: Call, Chat, Copy Phone
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: FilledButton.icon(
                    onPressed: () => _callBuyer(inquiry.buyerPhone),
                    icon: const Icon(Icons.phone_rounded, size: 16),
                    label: const Text('Call'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => _openChat(inquiry),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                    ),
                    label: const Text('Reply'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Copy phone number',
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () => _copy(inquiry.buyerPhone, 'Phone number'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
