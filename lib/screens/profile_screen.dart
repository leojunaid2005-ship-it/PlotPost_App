import 'package:flutter/material.dart';

import '../data/sample_posts.dart';
import '../models/property_post.dart';
import '../theme/app_colors.dart';
import '../widgets/property_post_card.dart';
import 'create_post_screen.dart';
import 'edit_profile_screen.dart';
import 'property_details_screen.dart';
import 'account_settings_screen.dart';
import 'my_listings_screen.dart';
import 'inquiries_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userPosts,
    required this.onPublishPost,
  });

  final List<PropertyPost> userPosts;
  final ValueChanged<PropertyPost> onPublishPost;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(onPublish: widget.onPublishPost),
      ),
    );
  }

  void _openPostDetails(PropertyPost post) {
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

    final allUserPosts = <PropertyPost>[
      ...widget.userPosts,
      posts[0],
      posts[4],
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: Icon(
              Icons.settings_outlined,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor:
                                    theme.brightness == Brightness.dark
                                    ? const Color(0xFF174B3A)
                                    : theme.colorScheme.primary,
                                child: Text(
                                  'PU',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'PlotPost User',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.verified_rounded,
                                          size: 16,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Verified Real Estate Agent',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: plotPostTextAccent(
                                          context,
                                          theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Kozhikode, Kerala',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Metric Highlights
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  '${allUserPosts.length}',
                                  'Listed',
                                  Icons.home_work_outlined,
                                  theme,
                                  onTap: () =>
                                      _openListingsScreen(allUserPosts),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildMetricCard(
                                  '18',
                                  'Inquiries',
                                  Icons.chat_outlined,
                                  theme,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const InquiriesScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildMetricCard(
                                  '4.9',
                                  'Rating',
                                  Icons.star_outline_rounded,
                                  theme,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Primary Action: Add New Listing
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _openCreatePost,
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 20,
                        ),
                        label: const Text(
                          'Post a New Property',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Tab Bar: My Listings vs Activity
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorWeight: 2,
                  labelColor: theme.colorScheme.onSurface,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                  tabs: const [
                    Tab(text: 'My Listings'),
                    Tab(text: 'Account Details'),
                  ],
                ),
                theme,
              ),
            ),
          ];
        },

        // Tab Content
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: My Property Listings
            RefreshIndicator(
              color: theme.colorScheme.primary,
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 700));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allUserPosts.length,
                itemBuilder: (context, index) {
                  final post = allUserPosts[index];
                  return PropertyPostCard(
                    key: ValueKey(post.storageKey),
                    post: post,
                    onTap: () => _openPostDetails(post),
                  );
                },
              ),
            ),

            // Tab 2: Account Details & Contact Card
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoTile(
                  'Phone Number',
                  '+91 98950 00000',
                  Icons.phone_outlined,
                  theme,
                ),
                _buildInfoTile(
                  'Email Address',
                  'user@plotpost.app',
                  Icons.email_outlined,
                  theme,
                ),
                _buildInfoTile(
                  'Office Location',
                  'Mavoor Road, Kozhikode, Kerala',
                  Icons.business_outlined,
                  theme,
                ),
                _buildInfoTile(
                  'Bio',
                  'Licensed real estate broker serving Kozhikode and Malabar region with verified residential plots, villas and commercial spaces.',
                  Icons.info_outline_rounded,
                  theme,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Account Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openListingsScreen(List<PropertyPost> allUserPosts) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyListingsScreen(
          userPosts: allUserPosts,
          onPublishPost: widget.onPublishPost,
          onDeletePost: (post) {
            setState(() {
              widget.userPosts.remove(post);
            });
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String value,
    String label,
    IconData icon,
    ThemeData theme, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar, this._theme);

  final TabBar _tabBar;
  final ThemeData _theme;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: _theme.scaffoldBackgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
