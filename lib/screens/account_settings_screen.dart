import 'package:flutter/material.dart';

import '../data/sample_posts.dart';
import '../theme/app_colors.dart';
import 'auth_form_screen.dart';
import 'edit_profile_screen.dart';
import 'help_center_screen.dart';
import 'inquiries_screen.dart';
import 'my_listings_screen.dart';
import 'terms_privacy_screen.dart';
import 'welcome_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailInquiries = true;
  bool _showPhoneOnListings = true;

  void _logout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of PlotPost?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFED4956),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Log out'),
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
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Account Summary Card
          Container(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isDark
                      ? const Color(0xFF174B3A)
                      : theme.colorScheme.primary,
                  child: Text(
                    'PU',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'PlotPost User',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'user@plotpost.app',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Verified Real Estate Agent',
                        style: TextStyle(
                          fontSize: 11.5,
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
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 1: Appearance & Preferences
          _buildSectionHeader('Appearance & Preferences', theme),
          _themeSelectorTile(theme, isDark),
          _buildSwitchTile(
            'Push Notifications',
            'Receive alerts for buyer inquiries and price drops',
            Icons.notifications_none_rounded,
            _pushNotifications,
            (val) => setState(() => _pushNotifications = val),
            theme,
            isDark,
          ),
          _buildSwitchTile(
            'Email Inquiries',
            'Receive copies of messages in your email inbox',
            Icons.email_outlined,
            _emailInquiries,
            (val) => setState(() => _emailInquiries = val),
            theme,
            isDark,
          ),

          const SizedBox(height: 20),

          // Section 2: Account & Security
          _buildSectionHeader('Account & Security', theme),
          _buildNavigationTile(
            'Edit Profile Details',
            'Name, agency, phone number and location',
            Icons.person_outline_rounded,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
            theme,
            isDark,
          ),
          _buildSwitchTile(
            'Show Phone Number',
            'Display contact number publicly on property listings',
            Icons.phone_outlined,
            _showPhoneOnListings,
            (val) => setState(() => _showPhoneOnListings = val),
            theme,
            isDark,
          ),
          _buildNavigationTile(
            'Change Password',
            'Update account login password',
            Icons.lock_outline_rounded,
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const AuthFormScreen(isSignUp: false, forgotPassword: true),
              ),
            ),
            theme,
            isDark,
          ),

          const SizedBox(height: 20),

          // Section 3: Property & Listings
          _buildSectionHeader('Listings & Leads', theme),
          _buildNavigationTile(
            'Manage My Postings',
            'View, edit or archive your published properties',
            Icons.home_work_outlined,
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MyListingsScreen(
                  userPosts: posts,
                  onPublishPost: (_) {},
                  onDeletePost: (_) {},
                ),
              ),
            ),
            theme,
            isDark,
          ),
          _buildNavigationTile(
            'Auto-Reply Settings',
            'Configure automatic responses for buyer inquiries',
            Icons.reply_rounded,
            () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const InquiriesScreen())),
            theme,
            isDark,
          ),

          const SizedBox(height: 20),

          // Section 4: Support & Legal
          _buildSectionHeader('Support & Legal', theme),
          _buildNavigationTile(
            'Help Center & FAQs',
            'Get support or read guide articles',
            Icons.help_outline_rounded,
            () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
            theme,
            isDark,
          ),
          _buildNavigationTile(
            'Privacy Policy & Terms',
            'Read PlotPost terms of service',
            Icons.privacy_tip_outlined,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsPrivacyScreen()),
            ),
            theme,
            isDark,
          ),

          const SizedBox(height: 24),

          // Log Out Button
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(
                Icons.logout_rounded,
                size: 20,
                color: Color(0xFFED4956),
              ),
              label: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFED4956),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: const Color(0xFFED4956).withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App Version Footer
          Center(
            child: Text(
              'PlotPost v1.0.0 (Build 1) • Created by Digit-us',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
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

  Widget _themeSelectorTile(ThemeData theme, bool isDark) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: plotPostThemeMode,
      builder: (context, currentMode, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'App Theme Mode',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildThemeOption(
                    'Dark',
                    ThemeMode.dark,
                    currentMode,
                    theme,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    'Light',
                    ThemeMode.light,
                    currentMode,
                    theme,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    'System',
                    ThemeMode.system,
                    currentMode,
                    theme,
                    isDark,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    String label,
    ThemeMode mode,
    ThemeMode currentMode,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setPlotPostThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.18)
                : (isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
