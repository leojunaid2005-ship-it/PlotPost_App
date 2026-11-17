import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_posts.dart';
import '../models/enquiry.dart';
import '../models/property_post.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../widgets/property_post_card.dart';
import 'saved_screen.dart';
import 'create_post_screen.dart';
import 'filter_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'property_details_screen.dart';
import 'show_interest_screen.dart';
import 'auth_form_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key, this.isGuest = false});
  final bool isGuest;

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  String activePlatform = 'All';
  int selectedNav = 0;
  String _topFeedMode = 'Nearby';
  final Set<String> _followedSellers = {
    'Ravi Kumar',
    'Prime Plots Kerala',
    'Calicut Homes',
  };
  String locality = 'Nadakkavu';
  String searchQuery = '';
  Set<String> selectedTypes = {};
  static const String _savedPostsPreferenceKey = 'plotpost_saved_post_keys';
  final Set<String> _savedPostKeys = {};
  final List<PropertyPost> _userPosts = [];
  final List<PropertyPost> _remotePosts = [];
  final List<Enquiry> _enquiries = [];
  bool _savedPostsLoaded = false;
  String selectedDeal = 'Any';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
    unawaited(_loadRemotePosts(showError: true));
    if (ApiClient.instance.isAuthenticated) {
      unawaited(_loadMyListings(showError: true));
    }
  }

  Future<void> _loadMyListings({bool showError = false}) async {
    try {
      final myListings = await ApiClient.instance.getMyListings();
      if (!mounted) return;
      setState(() {
        _userPosts
          ..clear()
          ..addAll(myListings);
      });
    } on ApiException catch (error) {
      if (mounted && showError) {
        _message('Could not load your listings: ${error.message}');
      }
    }
  }

  Future<bool> _loadRemotePosts({bool showError = false}) async {
    try {
      final remotePosts = await ApiClient.instance.getListings();
      if (!mounted) return false;
      setState(() {
        _remotePosts
          ..clear()
          ..addAll(remotePosts);
      });
      return true;
    } on ApiException catch (error) {
      if (mounted && showError) {
        _message('Could not load online listings: ${error.message}');
      }
    } on http.ClientException {
      if (mounted && showError) {
        _message('Could not connect to PlotPost. Check the API server URL.');
      }
    }
    return false;
  }

  Future<void> _loadSavedPosts() async {
    final preferences = await SharedPreferences.getInstance();
    final savedKeys =
        preferences.getStringList(_savedPostsPreferenceKey) ?? <String>[];
    if (!mounted) return;
    setState(() {
      _savedPostKeys
        ..clear()
        ..addAll(savedKeys);
      _savedPostsLoaded = true;
    });
  }

  Future<void> _persistSavedPosts() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _savedPostsPreferenceKey,
      _savedPostKeys.toList(),
    );
  }

  Future<void> _handleRefresh() async {
    final loaded = await _loadRemotePosts(showError: true);
    if (!loaded || !mounted) return;
    await _loadSavedPosts();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Feed refreshed with latest listings.'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF104B42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();
    final ownedIds = _userPosts.map((post) => post.id).toSet();
    final allPosts = <PropertyPost>[
      ..._userPosts,
      ..._remotePosts.where((post) => !ownedIds.contains(post.id)),
      ...posts,
    ];
    final filtered = allPosts.where((post) {
      final matchesPlatform =
          activePlatform == 'All' || post.platform == activePlatform;
      final matchesSearch =
          query.isEmpty || post.searchableText.contains(query);
      final matchesType =
          selectedTypes.isEmpty || selectedTypes.contains(post.type);
      final matchesDeal = selectedDeal == 'Any' || post.deal == selectedDeal;
      return matchesPlatform && matchesSearch && matchesType && matchesDeal;
    }).toList();

    Widget body;
    if (selectedNav == 1) {
      // Instagram Search View
      body = _searchView(filtered);
    } else if (selectedNav == 3) {
      // Saved Screen
      body = SavedScreen(
        posts: _savedPostsLoaded
            ? allPosts
                  .where((post) => _savedPostKeys.contains(post.storageKey))
                  .toList()
            : const <PropertyPost>[],
        onOpen: _showPost,
        onRemove: _toggleSaved,
        isLoading: !_savedPostsLoaded,
      );
    } else if (selectedNav == 4) {
      // Instagram Profile Screen
      body = ProfileScreen(
        userPosts: _userPosts,
        onPublishPost: (post) {
          setState(() {
            final index = _userPosts.indexWhere(
              (existing) => post.id.isNotEmpty && existing.id == post.id,
            );
            if (index >= 0) {
              _userPosts[index] = post;
            } else {
              _userPosts.insert(0, post);
            }
            selectedNav = 0;
          });
          _message('Your post was published successfully.');
        },
      );
    } else if (_topFeedMode == 'Following') {
      // Following Screen Feed
      body = _followingFeedView(allPosts);
    } else {
      // Nearby Screen Feed
      body = RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Centered Header Row
                    _headerRow(),
                    const SizedBox(height: 8),
                    // Top Sub-Headings: Nearby | Following
                    _feedTabToggle(),
                    const SizedBox(height: 10),
                    // Location Search Bar under headings
                    _locationSearchBar(),
                    const SizedBox(height: 12),
                    // Instagram Stories Tray
                    SizedBox(
                      height: 84,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _locality(
                            '＋',
                            'More',
                            const Color(0xFFF4F4F4),
                            isMore: true,
                          ),
                          _locality(
                            'Na',
                            'Nadakkavu',
                            const Color(0xFFF3E8D7),
                            selected: locality == 'Nadakkavu',
                          ),
                          _locality(
                            'Er',
                            'Eranhipalam',
                            const Color(0xFFEFE4CF),
                            selected: locality == 'Eranhipalam',
                          ),
                          _locality(
                            'WH',
                            'West Hill',
                            const Color(0xFFEADFC8),
                            selected: locality == 'West Hill',
                          ),
                          _locality(
                            'Ch',
                            'Chevayur',
                            const Color(0xFFF1E6D2),
                            selected: locality == 'Chevayur',
                          ),
                          _locality(
                            'Mr',
                            'Mavoor Rd',
                            const Color(0xFFF5E9C9),
                            selected: locality == 'Mavoor Road',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Platform Category Filter Tabs
                    Row(
                      children: ['All', 'Instagram', 'Facebook', 'YouTube'].map(
                        (label) {
                          final selected = activePlatform == label;
                          return Expanded(
                            child: InkWell(
                              onTap: () =>
                                  setState(() => activePlatform = label),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 1,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: selected
                                          ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                          : Theme.of(context)
                                                .colorScheme
                                                .outlineVariant,
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: selected
                                        ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant
                              .withValues(alpha: .65),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No matching posts found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try another keyword or choose a different platform.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              searchQuery = '';
                              activePlatform = 'All';
                            });
                          },
                          child: const Text('Clear search and filters'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final post = filtered[index];
                    return PropertyPostCard(
                      key: ValueKey(post.storageKey),
                      post: post,
                      isSaved: _savedPostKeys.contains(post.storageKey),
                      onTap: () => _showPost(post),
                      onToggleSaved: () => _toggleSaved(post),
                    );
                  }, childCount: filtered.length),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: body),
      bottomNavigationBar: _bottomNavigation(),
    );
  }

  Widget _headerRow() {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'lib/theme/logo.png',
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 5),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'PlotPost',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: '.',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: plotPostTextAccent(
                            context,
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 20),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 7.5,
                      height: 7.5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFED4956),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          Positioned(
            right: 0,
            child: IconButton(
              tooltip: 'Direct Messages',
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MessagesScreen())),
              icon: const Icon(Icons.near_me_outlined, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedTabToggle() {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => setState(() => _topFeedMode = 'Nearby'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nearby',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: _topFeedMode == 'Nearby'
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: _topFeedMode == 'Nearby'
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 28,
                height: 2.5,
                decoration: BoxDecoration(
                  color: _topFeedMode == 'Nearby'
                      ? theme.colorScheme.onSurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        GestureDetector(
          onTap: () => setState(() => _topFeedMode = 'Following'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Following',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: _topFeedMode == 'Following'
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: _topFeedMode == 'Following'
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 32,
                height: 2.5,
                decoration: BoxDecoration(
                  color: _topFeedMode == 'Following'
                      ? theme.colorScheme.onSurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _locationSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: _chooseLocation,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4.5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: theme.colorScheme.primary,
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$locality, Kozhikode',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.onSurface,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _followingFeedView(List<PropertyPost> allPosts) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final followingPosts = allPosts.where((post) {
      return _followedSellers.contains(post.seller) || post.isUserPost;
    }).toList();

    const suggestedSellers = [
      ('Ravi Kumar', 'RK'),
      ('Prime Plots Kerala', 'PP'),
      ('Calicut Homes', 'CH'),
      ('Green Acre Realty', 'GA'),
      ('Home Tours Calicut', 'HT'),
      ('Anil Kumar', 'AK'),
    ];

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerRow(),
                  const SizedBox(height: 8),
                  _feedTabToggle(),
                  const SizedBox(height: 10),
                  _locationSearchBar(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Sellers You Follow',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_followedSellers.length} followed',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 84,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: suggestedSellers.map((seller) {
                        final isFollowing = _followedSellers.contains(
                          seller.$1,
                        );
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isFollowing) {
                                _followedSellers.remove(seller.$1);
                              } else {
                                _followedSellers.add(seller.$1);
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 66,
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isFollowing
                                              ? theme.colorScheme.primary
                                              : (isDark
                                                    ? const Color(0xFF363636)
                                                    : const Color(0xFFDBDBDB)),
                                          width: isFollowing ? 2 : 1,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: isDark
                                            ? const Color(0xFF262626)
                                            : const Color(0xFFEFEFEF),
                                        child: Text(
                                          seller.$2,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: isFollowing
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.surface,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isFollowing
                                              ? Icons.check_rounded
                                              : Icons.add_rounded,
                                          size: 11,
                                          color: isFollowing
                                              ? Colors.white
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  seller.$1,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isFollowing
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          if (followingPosts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add_disabled_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.65,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No posts from followed sellers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap on seller profiles above to follow them and see their latest property posts here.',
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = followingPosts[index];
                  return PropertyPostCard(
                    key: ValueKey(post.storageKey),
                    post: post,
                    isSaved: _savedPostKeys.contains(post.storageKey),
                    onTap: () => _showPost(post),
                    onToggleSaved: () => _toggleSaved(post),
                  );
                }, childCount: followingPosts.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _searchView(List<PropertyPost> filtered) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => searchQuery = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search properties, type or seller...',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13.5,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      suffixIcon: searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: Icon(
                                Icons.close_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => searchQuery = '');
                              },
                            ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF262626)
                          : const Color(0xFFEFEFEF),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Explore (${filtered.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Filters',
                        onPressed: _showFilters,
                        icon: const Icon(Icons.tune_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.65,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No matching properties',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = filtered[index];
                  return PropertyPostCard(
                    key: ValueKey(post.storageKey),
                    post: post,
                    isSaved: _savedPostKeys.contains(post.storageKey),
                    onTap: () => _showPost(post),
                    onToggleSaved: () => _toggleSaved(post),
                  );
                }, childCount: filtered.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _locality(
    String initials,
    String label,
    Color color, {
    bool selected = false,
    bool isMore = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: isMore
          ? _chooseLocation
          : () => setState(() {
              locality = label == 'Mavoor Rd' ? 'Mavoor Road' : label;
            }),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        width: 66,
        child: Column(
          children: [
            // Instagram Story Ring
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF00E676),
                          Color(0xFF104B42),
                          Color(0xFF000000),
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      )
                    : null,
                color: selected
                    ? null
                    : (isDark
                          ? const Color(0xFF262626)
                          : const Color(0xFFDBDBDB)),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.scaffoldBackgroundColor,
                ),
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: isDark
                      ? const Color(0xFF1F1F1F)
                      : const Color(0xFFEFEFEF),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreatePost() {
    if (!ApiClient.instance.isAuthenticated) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AuthFormScreen(isSignUp: false),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          onPublish: (post) {
            setState(() {
              _userPosts.insert(0, post);
              selectedNav = 0;
              activePlatform = 'All';
            });
            _message('Your property listing was published.');
          },
        ),
      ),
    );
  }

  Widget _bottomNavigation() {
    final theme = Theme.of(context);

    final items = [
      (selectedNav == 0 ? Icons.home_rounded : Icons.home_outlined, 'Home'),
      (
        selectedNav == 1 ? Icons.search_rounded : Icons.search_outlined,
        'Search',
      ),
      (Icons.add_rounded, 'Create'),
      (
        selectedNav == 3
            ? Icons.bookmark_rounded
            : Icons.bookmark_border_rounded,
        'Saved',
      ),
      (
        selectedNav == 4 ? Icons.person_rounded : Icons.person_outline_rounded,
        'Profile',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = selectedNav == index;

              // Center Prominent Create Action Button
              if (index == 2) {
                return GestureDetector(
                  onTap: _openCreatePost,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.38,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                );
              }

              return InkWell(
                onTap: () => setState(() => selectedNav = index),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.$1,
                        size: 21,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: plotPostTextAccent(
                              context,
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _chooseLocation() async {
    const locations = [
      'Nadakkavu',
      'Eranhipalam',
      'West Hill',
      'Chevayur',
      'Mavoor Road',
      'Beach Road',
      'Civil Station',
    ];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Select Location',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Kozhikode, Kerala',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // GPS Current Location Tile
              InkWell(
                onTap: () {
                  _message('Location updated via GPS.');
                  Navigator.pop(modalContext, 'Nadakkavu');
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF262626)
                        : const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Use current GPS location',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: plotPostTextAccent(
                            context,
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Divider(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 4),
              ...locations.map((place) {
                final isSelected = place == locality;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  title: Text(
                    '$place, Kozhikode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? plotPostTextAccent(
                              context,
                              theme.colorScheme.primary,
                            )
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () => Navigator.pop(modalContext, place),
                );
              }),
            ],
          ),
        ),
      ),
    );
    if (choice != null && mounted) {
      setState(() => locality = choice);
    }
  }

  Future<void> _showFilters() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => FilterScreen(
          initialPlatform: activePlatform,
          initialDeal: selectedDeal,
          initialTypes: selectedTypes,
          initialLocality: locality,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        activePlatform = result['platform'] as String? ?? 'All';
        selectedDeal = result['deal'] as String? ?? 'Any';
        selectedTypes = Set<String>.from(result['types'] as Set<String>? ?? {});
        final newLocality = result['locality'] as String? ?? locality;
        if (newLocality != 'All Kozhikode') {
          locality = newLocality;
        }
      });
    }
  }

  void _showPost(PropertyPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setDetailsState) => PropertyDetailsScreen(
            post: post,
            isSaved: _savedPostKeys.contains(post.storageKey),
            fallbackLocation: locality,
            onToggleSaved: () {
              _toggleSaved(post);
              setDetailsState(() {});
            },
            onShowInterest: () => _openShowInterest(post),
          ),
        ),
      ),
    );
  }

  void _openShowInterest(PropertyPost post) {
    // Login is not enforced here yet because real authentication comes with
    // the backend. This is where the login check will return.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShowInterestScreen(
          post: post,
          onSubmitted: (enquiry) => _enquiries.insert(0, enquiry),
        ),
      ),
    );
  }

  Future<void> _toggleSaved(PropertyPost post) async {
    // Guest bookmarks are stored locally on this device; no login is required.
    if (!_savedPostsLoaded) {
      await _loadSavedPosts();
    }

    final key = post.storageKey;
    final isNowSaved = !_savedPostKeys.contains(key);
    setState(() {
      if (isNowSaved) {
        _savedPostKeys.add(key);
      } else {
        _savedPostKeys.remove(key);
      }
    });

    try {
      await _persistSavedPosts();
      if (mounted) {
        _message(
          isNowSaved ? 'Property saved.' : 'Property removed from saved posts.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (isNowSaved) {
          _savedPostKeys.remove(key);
        } else {
          _savedPostKeys.add(key);
        }
      });
      _message('Could not update saved posts. Please try again.');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
