import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    this.initialName = 'PlotPost User',
    this.initialAgency = 'Calicut Prime Properties',
    this.initialRole = 'Verified Real Estate Agent',
    this.initialLocation = 'Kozhikode, Kerala',
    this.initialPhone = '+91 98950 00000',
    this.initialEmail = 'agent@plotpost.app',
    this.initialBio = 'Helping buyers find prime residential plots, villas, and apartments across Kozhikode district.',
    this.onSaved,
  });

  final String initialName;
  final String initialAgency;
  final String initialRole;
  final String initialLocation;
  final String initialPhone;
  final String initialEmail;
  final String initialBio;
  final ValueChanged<Map<String, String>>? onSaved;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _agencyController;
  late final TextEditingController _roleController;
  late final TextEditingController _locationController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;

  String? _profileImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _agencyController = TextEditingController(text: widget.initialAgency);
    _roleController = TextEditingController(text: widget.initialRole);
    _locationController = TextEditingController(text: widget.initialLocation);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _emailController = TextEditingController(text: widget.initialEmail);
    _bioController = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _agencyController.dispose();
    _roleController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _profileImagePath = picked.path);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open image picker.')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final updatedData = {
      'name': _nameController.text.trim(),
      'agency': _agencyController.text.trim(),
      'role': _roleController.text.trim(),
      'location': _locationController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'bio': _bioController.text.trim(),
      if (_profileImagePath case final path?) 'imagePath': path,
    };

    widget.onSaved?.call(updatedData);

    Navigator.of(context).pop(updatedData);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Profile updated successfully.'),
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
          'Edit Profile',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Picker Container
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: isDark
                            ? const Color(0xFF174B3A)
                            : theme.colorScheme.primary,
                        backgroundImage: _profileImagePath != null
                            ? FileImage(File(_profileImagePath!))
                            : null,
                        child: _profileImagePath == null
                            ? Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text
                                          .substring(0, 2)
                                          .toUpperCase()
                                    : 'PU',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _pickImage,
                child: Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: plotPostTextAccent(
                      context,
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Form Input Fields
              _buildSectionTitle('Personal Details', theme),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter your full name'
                    : null,
                isDark: isDark,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _agencyController,
                label: 'Agency / Business Name',
                icon: Icons.business_rounded,
                isDark: isDark,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _roleController,
                label: 'Role / Designation',
                icon: Icons.badge_outlined,
                isDark: isDark,
                theme: theme,
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('Contact & Location', theme),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter a contact phone number'
                    : null,
                isDark: isDark,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter email address'
                    : null,
                isDark: isDark,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _locationController,
                label: 'Location / City',
                icon: Icons.location_on_outlined,
                isDark: isDark,
                theme: theme,
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('About & Bio', theme),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _bioController,
                label: 'Bio / Description',
                icon: Icons.notes_rounded,
                maxLines: 3,
                isDark: isDark,
                theme: theme,
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveProfile,
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
                          'Save Profile Changes',
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

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
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
        enabledBorder: OutlineInputBorder(
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
