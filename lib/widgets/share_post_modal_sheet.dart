import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/property_post.dart';

void showSharePostModalSheet(BuildContext context, PropertyPost post) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SharePostModalSheet(post: post),
  );
}

class SharePostModalSheet extends StatefulWidget {
  const SharePostModalSheet({super.key, required this.post});
  final PropertyPost post;

  @override
  State<SharePostModalSheet> createState() => _SharePostModalSheetState();
}

class _SharePostModalSheetState extends State<SharePostModalSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _sentContacts = {};

  static const List<(String, String)> _contacts = [
    ('Ravi Kumar', 'RK'),
    ('Prime Plots Kerala', 'PP'),
    ('Calicut Homes', 'CH'),
    ('Green Acre Realty', 'GA'),
    ('Home Tours Calicut', 'HT'),
    ('Anil Kumar', 'AK'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sendToContact(String name) {
    setState(() {
      _sentContacts.add(name);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Listing sent to $name.'),
          ],
        ),
        backgroundColor: const Color(0xFF104B42),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyLink() {
    final post = widget.post;
    final text = '${post.title}\nPrice: ${post.price}\nLocation: ${post.location}';
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.link_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Property link copied to clipboard.'),
          ],
        ),
        backgroundColor: Color(0xFF104B42),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final query = _searchController.text.trim().toLowerCase();
    final filteredContacts = _contacts.where((c) {
      return query.isEmpty || c.$1.toLowerCase().contains(query);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B22) : theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF383E4C) : const Color(0xFFD0D7DE),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),

            // Search Receiver Bar
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search people to send to...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF222630) : const Color(0xFFF6F8FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Horizontal Recent Quick Send Avatars
            SizedBox(
              height: 78,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _contacts.map((c) {
                  final isSent = _sentContacts.contains(c.$1);
                  return GestureDetector(
                    onTap: () => _sendToContact(c.$1),
                    child: Container(
                      margin: const EdgeInsets.only(right: 14),
                      width: 62,
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(
                                  c.$2,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              if (isSent)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF104B42),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            c.$1.split(' ').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Contact List for Direct Send
            Expanded(
              child: ListView.builder(
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = filteredContacts[index];
                  final isSent = _sentContacts.contains(contact.$1);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Text(
                        contact.$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    title: Text(
                      contact.$1,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    trailing: SizedBox(
                      height: 32,
                      width: 72,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: isSent
                              ? isDark
                                  ? const Color(0xFF2E3834)
                                  : const Color(0xFFE0EAE5)
                              : theme.colorScheme.primary,
                          foregroundColor: isSent
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onPrimary,
                        ),
                        onPressed: () => _sendToContact(contact.$1),
                        child: Text(
                          isSent ? 'Sent' : 'Send',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),
            const SizedBox(height: 10),

            // Quick Actions: Copy Link, Share
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyLink,
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: const Text('Copy Link'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      _copyLink();
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share Listing'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
