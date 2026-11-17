import 'package:flutter/material.dart';
import '../models/property_post.dart';
import '../widgets/property_post_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({
    super.key,
    required this.posts,
    required this.onOpen,
    required this.onRemove,
    this.isLoading = false,
  });

  final List<PropertyPost> posts;
  final ValueChanged<PropertyPost> onOpen;
  final ValueChanged<PropertyPost> onRemove;
  final bool isLoading;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String _activeCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categories = ['All', 'Plot', 'House', 'Villa', 'Flat', 'Commercial'];

    final filteredPosts = widget.posts.where((post) {
      if (_activeCategory == 'All') return true;
      return post.type == _activeCategory;
    }).toList();

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 700));
      },
      child: CustomScrollView(
      slivers: [
        // Instagram Saved Header Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Saved',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF262626)
                            : const Color(0xFFEFEFEF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.posts.length} ${widget.posts.length == 1 ? 'item' : 'items'}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category Filter Chips
                if (widget.posts.isNotEmpty)
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: categories.map((category) {
                        final isSelected = _activeCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            selectedColor: theme.colorScheme.primary.withValues(alpha: 0.18),
                            backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                                  : (isDark ? const Color(0xFF363636) : const Color(0xFFDBDBDB)),
                              width: 0.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onSelected: (_) {
                              setState(() => _activeCategory = category);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // Loading State
        if (widget.isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          )
        // Instagram Saved Empty State
        else if (widget.posts.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.onSurface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.bookmark_border_rounded,
                        size: 38,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Save Posts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save photos and properties that you want to see again. Only you can see what you have saved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        // Filtered Empty State
        else if (filteredPosts.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_remove_outlined,
                    size: 42,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No saved $_activeCategory posts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          )
        // Bookmarked Property Posts List
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = filteredPosts[index];
                  return PropertyPostCard(
                    key: ValueKey(post.storageKey),
                    post: post,
                    isSaved: true,
                    onTap: () => widget.onOpen(post),
                    onToggleSaved: () => widget.onRemove(post),
                  );
                },
                childCount: filteredPosts.length,
              ),
            ),
          ),
      ],
    ),
  );
  }
}
