import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/property_post.dart';
import '../theme/app_colors.dart';
import '../widgets/report_post_modal.dart';
import '../widgets/property_image.dart';
import 'image_viewer_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({
    super.key,
    required this.post,
    required this.isSaved,
    required this.onToggleSaved,
    required this.onShowInterest,
    this.fallbackLocation = '',
  });

  final PropertyPost post;
  final bool isSaved;
  final VoidCallback onToggleSaved;
  final VoidCallback onShowInterest;
  final String fallbackLocation;

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final PageController _galleryController = PageController();
  int _currentImage = 0;

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  // ---------- data helpers ----------

  String get _location {
    final location = widget.post.location.trim();
    if (location.isNotEmpty) return location;
    if (widget.fallbackLocation.trim().isNotEmpty) {
      return '${widget.fallbackLocation}, Kozhikode, Kerala';
    }
    return 'Location not specified';
  }

  String get _price {
    final price = widget.post.price.trim();
    return price.isEmpty ? 'Price on request' : price;
  }

  bool get _hasPhone => widget.post.sellerPhone.trim().isNotEmpty;
  bool get _hasSocialLink => widget.post.socialUrl.trim().isNotEmpty;

  IconData get _platformIcon => switch (widget.post.platform) {
    'YouTube' => Icons.play_circle_outline_rounded,
    'Instagram' => Icons.photo_camera_outlined,
    'Facebook' => Icons.groups_2_outlined,
    _ => Icons.share_outlined,
  };

  // ---------- actions ----------

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _copy(String text, String confirmation) async {
    await Clipboard.setData(ClipboardData(text: text));
    _message(confirmation);
  }

  Future<void> _openSocialLink() async {
    final uri = Uri.tryParse(widget.post.socialUrl.trim());
    if (uri == null || !uri.hasScheme) {
      _message('This link is not valid.');
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) _message('Could not open the original post.');
    } catch (_) {
      _message('Could not open the original post.');
    }
  }

  Future<void> _callSeller() async {
    final number = widget.post.sellerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) return;
    try {
      final opened = await launchUrl(Uri(scheme: 'tel', path: number));
      if (!opened) _message('Could not open the phone app.');
    } catch (_) {
      _message('Could not open the phone app.');
    }
  }

  void _copyListingSummary() {
    final post = widget.post;
    final lines = <String>[
      post.title,
      '$_price · ${post.type} · ${post.deal}',
      _location,
      if (post.area.trim().isNotEmpty) 'Area: ${post.area.trim()}',
      if (_hasSocialLink) post.socialUrl.trim(),
    ];
    _copy(lines.join('\n'), 'Listing details copied.');
  }

  void _openViewer(int index) {
    final paths = widget.post.imagePaths;
    if (paths.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(paths: paths, initialIndex: index),
      ),
    );
  }

  // ---------- small widgets ----------

  Widget _galleryPlaceholder() {
    return Container(
      color: widget.post.color,
      child: Center(
        child: Icon(
          widget.post.video
              ? Icons.play_circle_outline_rounded
              : Icons.apartment_rounded,
          color: Colors.white,
          size: 76,
        ),
      ),
    );
  }

  Widget _galleryImage(int index) {
    final paths = widget.post.imagePaths;
    if (paths.isEmpty) return _galleryPlaceholder();
    return PropertyImage(
      path: paths[index],
      fit: BoxFit.cover,
      width: double.infinity,
      cacheWidth: 1080,
      errorBuilder: (_, _, _) => _galleryPlaceholder(),
    );
  }

  Widget _circleAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    String? assetPath,
    Color? assetColor,
    Color color = Colors.white,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: .48),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: assetPath == null
            ? Icon(icon, color: color)
            : Image.asset(
                assetPath,
                width: 20,
                height: 20,
                color: assetColor,
                fit: BoxFit.contain,
              ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .3), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }

  Widget _specification(IconData icon, String label, String value) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gallery(int imageCount) {
    final post = widget.post;
    final hasImages = post.imagePaths.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _galleryController,
          itemCount: imageCount,
          onPageChanged: (index) => setState(() => _currentImage = index),
          itemBuilder: (_, index) => GestureDetector(
            onTap: hasImages ? () => _openViewer(index) : null,
            child: _galleryImage(index),
          ),
        ),
        // Soft shade at the bottom so the counter and dots stay readable.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: .45),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          bottom: 18,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .62),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasImages) ...[
                    const Icon(
                      Icons.zoom_out_map_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    hasImages
                        ? '${_currentImage + 1} / $imageCount'
                        : (post.video ? 'Video listing' : 'No photos yet'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (imageCount > 1)
          Positioned(
            right: 18,
            bottom: 24,
            child: IgnorePointer(
              child: Row(
                children: List.generate(
                  imageCount,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(left: 4),
                    width: _currentImage == index ? 17 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: _currentImage == index ? 1 : .55,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sellerCard() {
    final colors = Theme.of(context).colorScheme;
    final post = widget.post;
    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colors.secondaryContainer,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: colors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.seller,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Shared via ${post.platform} · ${post.age}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_hasPhone) ...[
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post.sellerPhone.trim(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _copy(post.sellerPhone.trim(), 'Phone number copied.'),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                ),
              ],
            ),
          ] else
            Text(
              'The seller has not shared a phone number. Use “Show interest” to send an enquiry.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                height: 1.45,
              ),
            ),
        ],
      ),
    );
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final colors = Theme.of(context).colorScheme;
    final imageCount = post.imagePaths.isEmpty ? 1 : post.imagePaths.length;
    final description = post.description.trim().isEmpty
        ? 'The seller has not added a description for this property yet.'
        : post.description.trim();

    final specs = <(IconData, String, String)>[
      (Icons.home_work_outlined, 'Property type', post.type),
      (Icons.sell_outlined, 'Listing', post.deal),
      if (post.area.trim().isNotEmpty)
        (Icons.square_foot_rounded, 'Area', post.area.trim()),
      if (post.bedrooms.trim().isNotEmpty)
        (Icons.bed_outlined, 'Bedrooms', post.bedrooms.trim()),
      if (post.bathrooms.trim().isNotEmpty)
        (Icons.bathtub_outlined, 'Bathrooms', post.bathrooms.trim()),
      (_platformIcon, 'Shared on', post.platform),
      (Icons.schedule_rounded, 'Posted', post.age),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 400,
            backgroundColor: colors.surface,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(7),
              child: _circleAction(
                tooltip: 'Back',
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: _circleAction(
                  tooltip: 'Copy listing details',
                  icon: Icons.ios_share_rounded,
                  assetPath: 'assets/copy.png',
                  assetColor: Colors.white,
                  onPressed: _copyListingSummary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _circleAction(
                  tooltip: 'Report listing',
                  icon: Icons.flag_outlined,
                  assetPath: 'assets/report.png',
                  color: const Color(0xFFFF5252),
                  onPressed: () => showReportPostModal(context, widget.post),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 9, top: 7, bottom: 7),
                child: _circleAction(
                  tooltip: widget.isSaved
                      ? 'Remove saved property'
                      : 'Save property',
                  icon: widget.isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: widget.isSaved
                      ? const Color(0xFFE3C98F)
                      : Colors.white,
                  onPressed: widget.onToggleSaved,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(background: _gallery(imageCount)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _tag(post.type, colors.secondary),
                      _tag(post.deal, colors.primary),
                      if (post.video) _tag('Video listing', colors.primary),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _price,
                    style: TextStyle(
                      color: plotPostTextAccent(context, colors.secondary),
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    post.title,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 21,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.45,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: colors.onSurfaceVariant,
                        size: 19,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _location,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _sectionTitle('Property overview'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 3.2,
                    children: [
                      for (final spec in specs)
                        _specification(spec.$1, spec.$2, spec.$3),
                    ],
                  ),
                  const SizedBox(height: 27),
                  _sectionTitle('About this property'),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 27),
                  _sectionTitle('Seller information'),
                  const SizedBox(height: 12),
                  _sellerCard(),
                  if (_hasSocialLink) ...[
                    const SizedBox(height: 27),
                    _sectionTitle('Original ${post.platform} post'),
                    const SizedBox(height: 6),
                    Text(
                      post.socialUrl.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _openSocialLink,
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 18,
                            ),
                            label: Text('Open on ${post.platform}'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.outlined(
                          tooltip: 'Copy link',
                          onPressed: () => _copy(
                            post.socialUrl.trim(),
                            'Original post link copied.',
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              if (_hasPhone) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _callSeller,
                    icon: const Icon(Icons.call_outlined, size: 19),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: widget.onShowInterest,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
                  label: const Text('Show interest'),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF174B3A)
                        : colors.primary,
                    foregroundColor: colors.onPrimary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
