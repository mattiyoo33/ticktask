import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          // Profile Section
          _buildSectionHeader(
            context,
            'Profile',
            Icons.person_outline,
            colorScheme,
          ),
          _buildMenuItem(
            context,
            title: 'My Profile',
            subtitle: 'View and edit your profile',
            icon: Icons.person,
            iconColor: colorScheme.primary,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/profile-screen');
            },
          ),
          SizedBox(height: 2.h),
          
          // Friends Section
          _buildSectionHeader(
            context,
            'Friends',
            Icons.people_outline,
            colorScheme,
          ),
          _buildMenuItem(
            context,
            title: 'Friends Dashboard',
            subtitle: 'Manage your friends and requests',
            icon: Icons.people,
            iconColor: colorScheme.secondary,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/friends-screen');
            },
          ),
          SizedBox(height: 3.h),

          // Settings Section (with header)
          _buildSectionHeader(
            context,
            'Settings',
            Icons.settings_outlined,
            colorScheme,
          ),
          _buildMenuItem(
            context,
            title: 'Notifications',
            subtitle: 'Manage alerts and reminders',
            icon: Icons.notifications,
            iconColor: colorScheme.primary,
            onTap: _handleNotificationSettings,
          ),
          SizedBox(height: 1.5.h),
          _buildMenuItem(
            context,
            title: 'Privacy',
            subtitle: 'Control visibility and data',
            icon: Icons.privacy_tip,
            iconColor: colorScheme.primary,
            onTap: _handlePrivacySettings,
          ),
          SizedBox(height: 1.5.h),
          _buildMenuItem(
            context,
            title: 'Theme',
            subtitle: 'Light / Dark',
            icon: Icons.palette,
            iconColor: colorScheme.primary,
            onTap: _handleThemeSettings,
          ),
          SizedBox(height: 1.5.h),
          _buildMenuItem(
            context,
            title: 'Language',
            subtitle: 'Choose your language',
            icon: Icons.language,
            iconColor: colorScheme.primary,
            onTap: _handleLanguageSettings,
          ),
          SizedBox(height: 1.5.h),
          _buildMenuItem(
            context,
            title: 'Quiet Hours',
            subtitle: 'Do Not Disturb schedule',
            icon: Icons.bedtime,
            iconColor: colorScheme.primary,
            onTap: _handleQuietHours,
          ),
          SizedBox(height: 1.5.h),
          _buildMenuItem(
            context,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            icon: Icons.logout,
            iconColor: AppTheme.errorLight,
            onTap: _handleLogout,
          ),
          SizedBox(height: 4.h),
        ],
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 4, // More tab
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        SizedBox(width: 2.w),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(String title) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title'),
        content: const Text('This setting will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationSettings() => _showComingSoonDialog('Notification Settings');
  void _handlePrivacySettings() => _showComingSoonDialog('Privacy Settings');
  void _handleThemeSettings() => _showComingSoonDialog('Theme Settings');
  void _handleLanguageSettings() => _showComingSoonDialog('Language Settings');
  void _handleQuietHours() => _showComingSoonDialog('Quiet Hours');

  void _handleLogout() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed out'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
