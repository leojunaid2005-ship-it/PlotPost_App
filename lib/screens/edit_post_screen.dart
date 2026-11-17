import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/property_post.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../widgets/property_image.dart';

class EditPostScreen extends StatefulWidget {
  const EditPostScreen({
    super.key,
    required this.post,
    required this.onUpdated,
  });

  final PropertyPost post;
  final ValueChanged<PropertyPost> onUpdated;

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _areaController;
  late final TextEditingController _bedroomsController;
  late final TextEditingController _bathroomsController;
  late final TextEditingController _phoneController;

  late String _type;
  late String _deal;
  late String _platform;
  late List<String> _images;
  final List<XFile> _pickedImages = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    _titleController = TextEditingController(text: post.title);
    _priceController = TextEditingController(text: post.price);
    _locationController = TextEditingController(text: post.location);
    _descriptionController = TextEditingController(text: post.description);
    _areaController = TextEditingController(text: post.area);
    _bedroomsController = TextEditingController(text: post.bedrooms);
    _bathroomsController = TextEditingController(text: post.bathrooms);
    _phoneController = TextEditingController(text: post.sellerPhone);

    _type = post.type.isEmpty ? 'Plot' : post.type;
    _deal = post.deal.isEmpty ? 'For sale' : post.deal;
    _platform = post.platform.isEmpty ? 'Instagram' : post.platform;
    _images = List<String>.from(post.imagePaths);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _areaController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
      if (picked.isNotEmpty && mounted) {
        setState(() {
          for (final img in picked) {
            if (_images.length < 8) {
              _images.add(img.path);
              _pickedImages.add(img);
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open image picker.')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final draft = PropertyPost(
        id: widget.post.id,
        ownerId: widget.post.ownerId,
        platform: _platform,
        seller: widget.post.seller,
        age: widget.post.age,
        title: _titleController.text.trim(),
        type: _type,
        deal: _deal,
        price: _priceController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        sellerPhone: _phoneController.text.trim(),
        area: _areaController.text.trim(),
        bedrooms: _bedroomsController.text.trim(),
        bathrooms: _bathroomsController.text.trim(),
        imagePaths: _images,
        color: widget.post.color,
        height: widget.post.height,
        video: widget.post.video,
        socialUrl: widget.post.socialUrl,
        isUserPost: true,
      );
      final updatedPost = widget.post.id.isEmpty
          ? draft
          : await ApiClient.instance.updateListing(
              draft,
              images: List.unmodifiable(_pickedImages),
              existingImages: _images
                  .where(
                    (path) =>
                        path.startsWith('http://') ||
                        path.startsWith('https://'),
                  )
                  .toList(),
            );
      if (!mounted) return;
      widget.onUpdated(updatedPost);
      Navigator.pop(context, updatedPost);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property listing updated successfully.'),
          backgroundColor: Color(0xFF104B42),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } on http.ClientException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not connect to PlotPost. Check the API server URL.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          'Edit Property Listing',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: Text(
              'Save',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos Selector Tray
              Text(
                'Property Photos (${_images.length}/8)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 84,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 84,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF242826)
                              : const Color(0xFFF0F7F4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                fontSize: 10.5,
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
                    ..._images.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final path = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 84,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: PropertyImage(
                                path: path,
                                width: 84,
                                height: 84,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 14,
                            top: 4,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _pickedImages.removeWhere(
                                  (image) => image.path == path,
                                );
                                _images.removeAt(idx);
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
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
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Title & Price
              _buildTextField(
                controller: _titleController,
                label: 'Property Title',
                icon: Icons.title_rounded,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter property title'
                    : null,
                isDark: isDark,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _priceController,
                label: 'Price (e.g. ₹75 lakh / ₹18,000/mo)',
                icon: Icons.sell_outlined,
                keyboardType: TextInputType.text,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter property price'
                    : null,
                isDark: isDark,
                theme: theme,
              ),

              const SizedBox(height: 16),

              // Property & Deal Type Selectors
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: _inputDecoration(
                        'Property Type',
                        Icons.home_work_outlined,
                        isDark,
                        theme,
                      ),
                      items: ['Plot', 'House', 'Villa', 'Flat', 'Commercial']
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _type = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _deal,
                      decoration: _inputDecoration(
                        'Listing Deal',
                        Icons.handshake_outlined,
                        isDark,
                        theme,
                      ),
                      items: ['For sale', 'For rent']
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _deal = val);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Location & Phone
              _buildTextField(
                controller: _locationController,
                label: 'Location (e.g. Nadakkavu, Kozhikode)',
                icon: Icons.location_on_outlined,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter location' : null,
                isDark: isDark,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneController,
                label: 'Contact Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                isDark: isDark,
                theme: theme,
              ),

              const SizedBox(height: 16),

              // Area, Bedrooms, Bathrooms
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _areaController,
                      label: 'Area (sq ft / cents)',
                      icon: Icons.square_foot_rounded,
                      isDark: isDark,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _bedroomsController,
                      label: 'Bedrooms',
                      icon: Icons.bed_outlined,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _bathroomsController,
                      label: 'Bathrooms',
                      icon: Icons.bathtub_outlined,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                      theme: theme,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Property Description',
                icon: Icons.description_outlined,
                maxLines: 4,
                isDark: isDark,
                theme: theme,
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Listing Changes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
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

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
    bool isDark,
    ThemeData theme,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF222630) : const Color(0xFFF6F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF2D3342) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    required bool isDark,
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF222630) : const Color(0xFFF6F8FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2D3342) : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
      ),
    );
  }
}
