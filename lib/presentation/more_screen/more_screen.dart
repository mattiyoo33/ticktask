import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  bool _hasRefreshedOnLoad = false;

  @override
  void initState() {
    super.initState();
    // Refresh data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  void _refreshAllData() {
    if (!_hasRefreshedOnLoad) {
      _hasRefreshedOnLoad = true;
      // Refresh user profile data
      ref.invalidate(userProfileFromDbProvider);
    }
  }

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
          
          // Achievements Section
          _buildSectionHeader(
            context,
            'Achievements',
            Icons.emoji_events_outlined,
            colorScheme,
          ),
          _buildMenuItem(
            context,
            title: 'View Achievements',
            subtitle: 'See your unlocked achievements',
            icon: Icons.emoji_events,
            iconColor: const Color(0xFFF26A8D), // Medium pink from new palette
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/achievements-screen');
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

          // Settings Section (with header) - compact list style
          _buildSectionHeader(
            context,
            'Settings',
            Icons.settings_outlined,
            colorScheme,
          ),
          Container(
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                _buildSettingsItem(
                  context,
                  title: 'Notifications',
                  icon: Icons.notifications,
                  iconColor: colorScheme.primary,
                  onTap: _handleNotificationSettings,
                ),
                Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                _buildSettingsItem(
                  context,
                  title: 'Privacy',
                  icon: Icons.privacy_tip,
                  iconColor: colorScheme.primary,
                  onTap: _handlePrivacySettings,
                ),
                Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                _buildSettingsItem(
                  context,
                  title: 'Theme',
                  icon: Icons.palette,
                  iconColor: colorScheme.primary,
                  onTap: _handleThemeSettings,
                ),
                Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                _buildSettingsItem(
                  context,
                  title: 'Language',
                  icon: Icons.language,
                  iconColor: colorScheme.primary,
                  onTap: _handleLanguageSettings,
                ),
                Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                _buildSettingsItem(
                  context,
                  title: 'Quiet Hours',
                  icon: Icons.bedtime,
                  iconColor: colorScheme.primary,
                  onTap: _handleQuietHours,
                ),
                Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                _buildSettingsItem(
                  context,
                  title: 'View Tutorial',
                  icon: Icons.school,
                  iconColor: colorScheme.primary,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(
                      context,
                      '/tutorial-screen',
                      arguments: false, // isFirstTime = false (returning user)
                    );
                  },
                ),
                Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                _buildSettingsItem(
                  context,
                  title: 'Sign Out',
                  icon: Icons.logout,
                  iconColor: AppTheme.errorLight,
                  onTap: _handleLogout,
                ),
              ],
            ),
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

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: iconColor == AppTheme.errorLight 
              ? AppTheme.errorLight 
              : colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _showComingSoonDialog(String title) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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

  void _handleNotificationSettings() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/notification-settings-screen');
  }
  void _handlePrivacySettings() => _showComingSoonDialog('Privacy Settings');
  
  void _handleThemeSettings() {
    HapticFeedback.lightImpact();
    final currentThemeMode = ref.read(themeModeProvider);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(
                context,
                'Light',
                Icons.light_mode,
                ThemeMode.light,
                currentThemeMode,
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context,
                'Dark',
                Icons.dark_mode,
                ThemeMode.dark,
                currentThemeMode,
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context,
                'System Default',
                Icons.brightness_auto,
                ThemeMode.system,
                currentThemeMode,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    ThemeMode mode,
    ThemeMode currentMode,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = mode == currentMode;
    
    return InkWell(
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
        HapticFeedback.lightImpact();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? colorScheme.primary 
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isSelected 
                      ? colorScheme.primary 
                      : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  
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
