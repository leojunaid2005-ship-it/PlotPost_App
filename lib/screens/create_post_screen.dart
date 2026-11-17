import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/property_post.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key, required this.onPublish});
  final ValueChanged<PropertyPost> onPublish;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _seller = TextEditingController(text: 'You');
  final _price = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _socialUrl = TextEditingController();
  final _phone = TextEditingController();
  final _area = TextEditingController();
  final _bedrooms = TextEditingController();
  final _bathrooms = TextEditingController();
  final List<String> _images = [];
  final List<XFile> _pickedImages = [];
  String _type = 'Plot', _deal = 'For sale', _platform = 'Instagram';
  bool _isPicking = false;
  bool _isPublishing = false;

  @override
  void dispose() {
    _title.dispose();
    _seller.dispose();
    _price.dispose();
    _location.dispose();
    _description.dispose();
    _socialUrl.dispose();
    _phone.dispose();
    _area.dispose();
    _bedrooms.dispose();
    _bathrooms.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
      if (picked.isNotEmpty && mounted) {
        setState(() {
          for (final image in picked) {
            if (_images.length < 8) {
              _images.add(image.path);
              _pickedImages.add(image);
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        _message('Could not open gallery. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _publish() async {
    if (_isPublishing) return;
    if (!_formKey.currentState!.validate()) {
      _message('Please fill in required fields (Title and Location).');
      return;
    }
    if (!ApiClient.instance.isAuthenticated) {
      _message('Sign in before publishing a listing.');
      return;
    }

    setState(() => _isPublishing = true);
    try {
      final draft = PropertyPost(
        platform: _socialUrl.text.trim().isEmpty ? 'PlotPost' : _platform,
        seller: _seller.text.trim().isEmpty ? 'You' : _seller.text.trim(),
        age: 'Just now',
        title: _title.text.trim(),
        type: _type,
        deal: _deal,
        price: _price.text.trim(),
        location: _location.text.trim(),
        description: _description.text.trim(),
        socialUrl: _socialUrl.text.trim(),
        imagePaths: List.unmodifiable(_images),
        isUserPost: true,
        sellerPhone: _phone.text.trim(),
        area: _area.text.trim(),
        bedrooms: _type == 'Plot' ? '' : _bedrooms.text.trim(),
        bathrooms: _type == 'Plot' ? '' : _bathrooms.text.trim(),
      );
      final post = await ApiClient.instance.createListing(
        draft,
        images: List.unmodifiable(_pickedImages),
      );
      widget.onPublish(post);
      if (mounted) Navigator.pop(context, post);
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } on http.ClientException {
      if (mounted) {
        _message('Could not connect to PlotPost. Check the API server URL.');
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));

  Widget _sectionHeading(String title, [String? subtitle]) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
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
            Icons.close_rounded,
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Post',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isPublishing ? null : _publish,
            child: Text(
              _isPublishing ? 'Uploading...' : 'Share',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: plotPostTextAccent(context, theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Photo Upload Section
            _sectionHeading('Photos', 'Up to 8 photos'),
            InkWell(
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                constraints: const BoxConstraints(minHeight: 110),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF262626)
                      : const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                child: _images.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 28,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isPicking
                                ? 'Opening gallery...'
                                : 'Tap to add property photos',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select multiple photos from gallery',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._images.map(
                            (path) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(path),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 3,
                                  right: 3,
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      final index = _images.indexOf(path);
                                      if (index >= 0) {
                                        _images.removeAt(index);
                                        _pickedImages.removeAt(index);
                                      }
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.7,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_images.length < 8)
                            InkWell(
                              onTap: _pickImages,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 28,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),

            // Property Info
            _sectionHeading('Property Details'),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Write a title (e.g. 3 BHK villa near Mananchira)',
                labelText: 'Title',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Enter a property title'
                  : null,
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Property Type',
                    ),
                    items: ['Plot', 'House', 'Villa', 'Flat', 'Commercial']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _deal,
                    decoration: const InputDecoration(
                      labelText: 'Listing Type',
                    ),
                    items: ['For sale', 'For rent']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _deal = v ?? _deal),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              decoration: const InputDecoration(
                labelText: 'Price',
                hintText: 'e.g. ₹1.2 crore or ₹20,000 / month',
                prefixIcon: Icon(Icons.currency_rupee_rounded, size: 20),
              ),
            ),

            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g. Nadakkavu, Kozhikode, Kerala',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Enter property location'
                  : null,
            ),

            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Caption / Description',
                hintText: 'Describe the property, size, nearby places and features...',
              ),
            ),

            // Specifications
            _sectionHeading('Specifications', 'Optional'),
            TextFormField(
              controller: _area,
              decoration: const InputDecoration(
                labelText: 'Area / Size',
                hintText: 'e.g. 10 cents or 1,850 sq ft',
                prefixIcon: Icon(Icons.square_foot_rounded, size: 20),
              ),
            ),

            if (_type != 'Plot') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bedrooms,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bedrooms',
                        prefixIcon: Icon(Icons.bed_outlined, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _bathrooms,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bathrooms',
                        prefixIcon: Icon(Icons.bathtub_outlined, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Social Link
            _sectionHeading('Social Media Link', 'Optional'),
            DropdownButtonFormField<String>(
              initialValue: _platform,
              decoration: const InputDecoration(labelText: 'Platform'),
              items: [
                'Instagram',
                'Facebook',
                'YouTube',
                'Other',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _platform = v ?? _platform),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _socialUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Post URL',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link_rounded, size: 20),
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return null;
                final uri = Uri.tryParse(value);
                if (uri == null ||
                    !uri.hasScheme ||
                    !(uri.scheme == 'https' || uri.scheme == 'http') ||
                    uri.host.isEmpty) {
                  return 'Enter a valid URL starting with https://';
                }
                return null;
              },
            ),

            // Seller Contact Info
            _sectionHeading('Seller Info'),
            TextFormField(
              controller: _seller,
              decoration: const InputDecoration(
                labelText: 'Seller / Agency Name',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'e.g. +91 98950 00000',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return null;
                final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length < 10 || digits.length > 13) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _publish,
                child: const Text('Share Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
