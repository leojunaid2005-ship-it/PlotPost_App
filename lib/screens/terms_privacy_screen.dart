import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TermsPrivacyScreen extends StatefulWidget {
  const TermsPrivacyScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: Text(
          'Privacy & Terms',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.onSurface,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
          tabs: const [
            Tab(text: 'Privacy Policy'),
            Tab(text: 'Terms of Service'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocumentView(
            title: 'PlotPost Privacy Policy',
            lastUpdated: 'Last updated: January 2025',
            sections: const [
              (
                '1. Information We Collect',
                'We collect user information to provide property search, listing publication, and lead communication services. This includes name, phone number, email address, location details, and property photos uploaded by users.',
              ),
              (
                '2. How Your Information Is Used',
                'Property listings, location summaries, and contact details are displayed to prospective buyers to facilitate property inquiries. We do not sell your personal data to third-party ad networks.',
              ),
              (
                '3. Location & Device Data',
                'PlotPost uses approximate location data (such as Kozhikode, Nadakkavu, etc.) to show nearby property listings. You can choose to enable or disable device location access at any time.',
              ),
              (
                '4. Data Security & Storage',
                'All user communications and listing records are protected using standard encryption protocols. User saved preferences are stored locally on your device.',
              ),
              (
                '5. Your Data Rights',
                'You have the right to edit or delete your published property listings and account details at any time through Account Settings.',
              ),
            ],
            theme: theme,
            isDark: isDark,
          ),
          _buildDocumentView(
            title: 'PlotPost Terms of Service',
            lastUpdated: 'Last updated: January 2025',
            sections: const [
              (
                '1. Acceptance of Terms',
                'By downloading, accessing, or using the PlotPost application, you agree to comply with and be bound by these Terms of Service.',
              ),
              (
                '2. Property Listing Rules',
                'Users posting properties must provide accurate pricing, true photos, and clear property descriptions. Fake listings, misleading information, or unauthorized property postings are strictly prohibited.',
              ),
              (
                '3. Buyer & Seller Code of Conduct',
                'Users agree to communicate respectfully. Harassment, spam, fraudulent advance fee requests, or illegal activities will result in immediate account suspension.',
              ),
              (
                '4. Disclaimer of Liability',
                'PlotPost acts as an exploratory platform for real estate listings. Buyers and sellers are strongly advised to perform legal title checks and property verification prior to financial transactions.',
              ),
              (
                '5. Content Moderation',
                'PlotPost reserves the right to review and remove listings reported for policy violations or inaccurate details.',
              ),
            ],
            theme: theme,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentView({
    required String title,
    required String lastUpdated,
    required List<(String, String)> sections,
    required ThemeData theme,
    required bool isDark,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lastUpdated,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: plotPostTextAccent(context, theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...sections.map(
            (sec) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sec.$1,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sec.$2,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
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
