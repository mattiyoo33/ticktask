import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';

/// Light-theme More section colors (Figma-style).
abstract class _MoreSectionColorsLight {
  static const Color background = Color(0xFFFDF7F8);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color headingText = Color(0xFF2D2D2D);
  static const Color subtitleText = Color(0xFF828282);
  static const Color chevron = Color(0xFFADADAD);
  static const Color profileFriendsIcon = Color(0xFFEE8B8B);
  static const Color profileFriendsIconBg = Color(0xFFF8EBEB);
  static const Color achievementsIcon = Color(0xFFEBA954);
  static const Color achievementsIconBg = Color(0xFFF8EFE3);
  static const Color settingsIcon = Color(0xFF828282);
}

/// Theme-aware palette for More section (light = Figma, dark = theme colors).
class _MoreSectionPalette {
  final Color background;
  final Color cardBackground;
  final Color headingText;
  final Color subtitleText;
  final Color chevron;
  final Color profileFriendsIcon;
  final Color profileFriendsIconBg;
  final Color achievementsIcon;
  final Color achievementsIconBg;
  final Color settingsIcon;

  const _MoreSectionPalette({
    required this.background,
    required this.cardBackground,
    required this.headingText,
    required this.subtitleText,
    required this.chevron,
    required this.profileFriendsIcon,
    required this.profileFriendsIconBg,
    required this.achievementsIcon,
    required this.achievementsIconBg,
    required this.settingsIcon,
  });

  factory _MoreSectionPalette.fromContext(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      final c = theme.colorScheme;
      return _MoreSectionPalette(
        background: c.surface,
        cardBackground: c.surfaceContainerHighest,
        headingText: c.onSurface,
        subtitleText: c.onSurfaceVariant,
        chevron: c.onSurfaceVariant,
        profileFriendsIcon: c.secondary,
        profileFriendsIconBg: c.secondaryContainer,
        achievementsIcon: c.tertiary,
        achievementsIconBg: c.tertiaryContainer,
        settingsIcon: c.onSurfaceVariant,
      );
    }
    return const _MoreSectionPalette(
      background: _MoreSectionColorsLight.background,
      cardBackground: _MoreSectionColorsLight.cardBackground,
      headingText: _MoreSectionColorsLight.headingText,
      subtitleText: _MoreSectionColorsLight.subtitleText,
      chevron: _MoreSectionColorsLight.chevron,
      profileFriendsIcon: _MoreSectionColorsLight.profileFriendsIcon,
      profileFriendsIconBg: _MoreSectionColorsLight.profileFriendsIconBg,
      achievementsIcon: _MoreSectionColorsLight.achievementsIcon,
      achievementsIconBg: _MoreSectionColorsLight.achievementsIconBg,
      settingsIcon: _MoreSectionColorsLight.settingsIcon,
    );
  }
}

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
    final palette = _MoreSectionPalette.fromContext(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          // Profile Section
          _buildSectionHeader(
            context,
            palette: palette,
            title: 'Profile',
            icon: Icons.person_outline,
            iconColor: palette.profileFriendsIcon,
          ),
          _buildMenuItem(
            context,
            palette: palette,
            title: 'My Profile',
            subtitle: 'View and edit your profile',
            icon: Icons.person,
            iconColor: palette.profileFriendsIcon,
            iconBackgroundColor: palette.profileFriendsIconBg,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/profile-screen');
            },
          ),
          SizedBox(height: 2.h),
          
          // Achievements Section
          _buildSectionHeader(
            context,
            palette: palette,
            title: 'Achievements',
            icon: Icons.emoji_events_outlined,
            iconColor: palette.achievementsIcon,
          ),
          _buildMenuItem(
            context,
            palette: palette,
            title: 'View Achievements',
            subtitle: 'See your unlocked achievements',
            icon: Icons.emoji_events,
            iconColor: palette.achievementsIcon,
            iconBackgroundColor: palette.achievementsIconBg,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/achievements-screen');
            },
          ),
          SizedBox(height: 2.h),
          
          // Friends Section
          _buildSectionHeader(
            context,
            palette: palette,
            title: 'Friends',
            icon: Icons.people_outline,
            iconColor: palette.profileFriendsIcon,
          ),
          _buildMenuItem(
            context,
            palette: palette,
            title: 'Friends Dashboard',
            subtitle: 'Manage your friends and requests',
            icon: Icons.people,
            iconColor: palette.profileFriendsIcon,
            iconBackgroundColor: palette.profileFriendsIconBg,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/friends-screen');
            },
          ),
          SizedBox(height: 3.h),

          // Settings Section (with header) - compact list style
          _buildSectionHeader(
            context,
            palette: palette,
            title: 'Settings',
            icon: Icons.settings_outlined,
            iconColor: palette.settingsIcon,
          ),
          Container(
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingsItem(
                  context,
                  palette: palette,
                  title: 'Notifications',
                  icon: Icons.notifications,
                  iconColor: palette.settingsIcon,
                  onTap: _handleNotificationSettings,
                ),
                Divider(height: 1, color: palette.subtitleText.withValues(alpha: 0.2)),
                _buildSettingsItem(
                  context,
                  palette: palette,
                  title: 'Privacy',
                  icon: Icons.privacy_tip,
                  iconColor: palette.settingsIcon,
                  onTap: _handlePrivacySettings,
                ),
                Divider(height: 1, color: palette.subtitleText.withValues(alpha: 0.2)),
                _buildSettingsItem(
                  context,
                  palette: palette,
                  title: 'Theme',
                  icon: Icons.palette,
                  iconColor: palette.settingsIcon,
                  onTap: _handleThemeSettings,
                ),
                Divider(height: 1, color: palette.subtitleText.withValues(alpha: 0.2)),
                _buildSettingsItem(
                  context,
                  palette: palette,
                  title: 'Language',
                  icon: Icons.language,
                  iconColor: palette.settingsIcon,
                  onTap: _handleLanguageSettings,
                ),
                Divider(height: 1, color: palette.subtitleText.withValues(alpha: 0.2)),
                _buildSettingsItem(
                  context,
                  palette: palette,
                  title: 'Quiet Hours',
                  icon: Icons.bedtime,
                  iconColor: palette.settingsIcon,
                  onTap: _handleQuietHours,
                ),
                Divider(height: 1, color: palette.subtitleText.withValues(alpha: 0.2)),
                _buildSettingsItem(
                  context,
                  palette: palette,
                  title: 'View Tutorial',
                  icon: Icons.school,
                  iconColor: palette.settingsIcon,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(
                      context,
                      '/tutorial-screen',
                      arguments: false, // isFirstTime = false (returning user)
                    );
                  },
                ),
                Divider(height: 1, color: palette.subtitleText.withValues(alpha: 0.2)),
                _buildSettingsItem(
                  context,
                  palette: palette,
                  title: 'Sign Out',
                  icon: Icons.logout,
                  iconColor: Theme.of(context).colorScheme.error,
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
    BuildContext context, {
    required _MoreSectionPalette palette,
    required String title,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          SizedBox(width: 2.w),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.headingText,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required _MoreSectionPalette palette,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(top: 0.5.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: palette.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
                      color: palette.headingText,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.subtitleText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: palette.chevron,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required _MoreSectionPalette palette,
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isErrorAction = iconColor == theme.colorScheme.error;
    final titleColor = isErrorAction ? iconColor : palette.headingText;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: palette.chevron,
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
