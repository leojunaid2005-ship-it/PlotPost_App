import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'chat_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Posting Properties',
    'Buyer Leads',
    'Account & Verification',
    'Privacy & Safety',
  ];

  static const List<(String, String, String)> _faqs = [
    (
      'Posting Properties',
      'How do I post a property listing on PlotPost?',
      'Tap the "+" button in the center of the bottom navigation bar. Fill in your property title, price, deal type (For Sale / For Rent), area, photos, and location, then tap "Publish Property".',
    ),
    (
      'Posting Properties',
      'Can I post property walkthrough videos?',
      'Yes! When creating a listing, you can upload video walkthroughs or link video tours from YouTube and Instagram.',
    ),
    (
      'Buyer Leads',
      'How do buyers contact me about my listings?',
      'Buyers can tap "Show Interest" or "Contact Seller" on your property cards to send direct messages, WhatsApp inquiries, or request phone calls.',
    ),
    (
      'Buyer Leads',
      'Where can I view all buyer inquiries?',
      'Open your Profile and tap "Inquiries" or go to Account Settings > "Auto-Reply & Buyer Inquiries".',
    ),
    (
      'Account & Verification',
      'How do I get a Verified Real Estate Agent badge?',
      'Verified badges are awarded to registered agents who upload a valid RERA or local real estate business ID. Submit your document via Account Settings > Profile.',
    ),
    (
      'Privacy & Safety',
      'How do I report a fake or fraudulent listing?',
      'Tap the options menu ("•••") on any property card or the flag icon on the details page, select "Report Post", choose a reason, and submit.',
    ),
    (
      'Account & Verification',
      'How do I change my contact phone number?',
      'Go to Profile > Edit Profile and update your phone number. Make sure to tap "Save Profile Changes".',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final query = _searchQuery.trim().toLowerCase();
    final filteredFaqs = _faqs.where((faq) {
      final categoryMatches =
          _selectedCategory == 'All' || faq.$1 == _selectedCategory;
      final textMatches =
          query.isEmpty ||
          faq.$2.toLowerCase().contains(query) ||
          faq.$3.toLowerCase().contains(query);
      return categoryMatches && textMatches;
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
          'Help Center & FAQs',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Box Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we help you?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Search guides, questions, or contact PlotPost support',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search help articles...',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF262626)
                                : const Color(0xFFFFFFFF),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category Filter Chips
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _categories.map((cat) {
                        final selected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: selected,
                            selectedColor: theme.colorScheme.primary.withValues(
                              alpha: 0.18,
                            ),
                            backgroundColor: isDark
                                ? const Color(0xFF242826)
                                : const Color(0xFFEFEFEF),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Frequently Asked Questions (${filteredFaqs.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // FAQ Accordion List
          if (filteredFaqs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No matching help articles found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try searching for different keywords or select another category.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final faq = filteredFaqs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ExpansionTile(
                      shape: const Border(),
                      title: Text(
                        faq.$2,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          faq.$1,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: plotPostTextAccent(
                              context,
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Text(
                            faq.$3,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }, childCount: filteredFaqs.length),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181B22) : theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Still need help?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Chat directly with PlotPost Support team',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChatScreen(
                        userName: 'PlotPost Support',
                        userInitials: 'PS',
                        isOnline: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.headset_mic_rounded, size: 18),
                label: const Text('Contact Support'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
