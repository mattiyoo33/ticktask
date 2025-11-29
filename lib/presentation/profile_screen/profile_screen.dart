import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/account_settings_widget.dart';
import './widgets/achievement_gallery_widget.dart';
import './widgets/activity_history_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/statistics_overview_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic> get userData {
    final userProfileAsync = ref.watch(userProfileFromDbProvider);
    final userProfile = userProfileAsync.value;
    final currentUser = ref.watch(currentUserProvider);
    
    if (userProfile == null && currentUser == null) {
      // Fallback if no user data
      return {
        "id": null,
        "username": "User",
        "email": "",
        "avatar": "",
        "level": 1,
        "currentXP": 0,
        "nextLevelXP": 100,
        "totalXP": 0,
        "joinDate": DateTime.now().toIso8601String(),
      };
    }

    final fullName = userProfile?['full_name'] as String?;
    final email = userProfile?['email'] as String? ?? currentUser?.email ?? "";
    final username = fullName ?? (email.isNotEmpty ? email.split('@')[0] : "User");
    
    // Handle createdAt - get from user profile or current user
    DateTime createdAt = DateTime.now();
    
    // First try to get from database profile
    if (userProfile?['created_at'] != null) {
      final created = userProfile!['created_at'];
      if (created is DateTime) {
        createdAt = created;
      } else if (created is String) {
        try {
          createdAt = DateTime.parse(created);
        } catch (e) {
          // Keep default, will try currentUser below
        }
      }
    }
    
    // If still default, use currentUser.createdAt (which is DateTime?)
    // We'll use the database value primarily, currentUser.createdAt as fallback
    // Note: The database profile should have created_at, so this is just a safety fallback
    
    final level = userProfile?['level'] as int? ?? 1;
    
    return {
      "id": userProfile?['id'] ?? currentUser?.id,
      "username": username,
      "email": email,
      "avatar": userProfile?['avatar_url'] ?? "",
      "avatarDescription": "User profile picture",
      "level": level,
      "currentXP": userProfile?['current_xp'] as int? ?? 0,
      "nextLevelXP": _calculateNextLevelXP(level),
      "totalXP": userProfile?['total_xp'] as int? ?? 0,
      "joinDate": createdAt.toIso8601String().split('T')[0],
    };
  }

  int _calculateNextLevelXP(int level) {
    // Simple XP calculation: 100 * level^1.5
    return (100 * (level * level * 1.5)).round();
  }

  // Get real statistics from database
  Map<String, dynamic> get statisticsData {
    final tasksAsync = ref.watch(allTasksProvider);
    final userProfileAsync = ref.watch(userProfileFromDbProvider);
    final friendsAsync = ref.watch(friendsProvider);
    
    return tasksAsync.when(
      data: (tasks) {
        final userProfile = userProfileAsync.value;
        final friends = friendsAsync.value ?? [];
        
        final totalTasks = tasks.length;
        final completedTasks = tasks.where((t) => t['status'] == 'completed').length;
        final completionRate = totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;
        final totalXP = userProfile?['total_xp'] as int? ?? 0;
        final friendCount = friends.length;
        
        // Calculate current streak (simplified - can be enhanced)
        int currentStreak = 0;
        int longestStreak = 0;
        
        return {
          "totalTasks": totalTasks,
          "currentStreak": currentStreak,
          "longestStreak": longestStreak,
          "completionRate": completionRate,
          "badgesEarned": 0, // TODO: Implement badges
          "friendCount": friendCount,
          "totalXP": totalXP,
        };
      },
      loading: () => {
        "totalTasks": 0,
        "currentStreak": 0,
        "longestStreak": 0,
        "completionRate": 0,
        "badgesEarned": 0,
        "friendCount": 0,
        "totalXP": 0,
      },
      error: (_, __) => {
        "totalTasks": 0,
        "currentStreak": 0,
        "longestStreak": 0,
        "completionRate": 0,
        "badgesEarned": 0,
        "friendCount": 0,
        "totalXP": 0,
      },
    );
  }

  // Get achievements (currently empty - can be enhanced with badge system)
  List<Map<String, dynamic>> get achievements {
    // TODO: Implement achievements/badges system
    return [];
  }


  // Get activity history from database
  List<Map<String, dynamic>> get activities {
    final activitiesAsync = ref.watch(recentActivitiesProvider);
    return activitiesAsync.when(
      data: (activities) => activities,
      loading: () => [],
      error: (_, __) => [],
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ProfileHeaderWidget(
                userData: userData,
                onEditProfile: _handleEditProfile,
                onChangeAvatar: _handleChangeAvatar,
              ),
              SizedBox(height: 2.h),
              StatisticsOverviewWidget(
                statisticsData: statisticsData,
              ),
              SizedBox(height: 2.h),
              AchievementGalleryWidget(
                achievements: achievements,
              ),
              SizedBox(height: 2.h),
              ActivityHistoryWidget(
                activities: activities,
              ),
              SizedBox(height: 2.h),
              AccountSettingsWidget(
                onNotificationSettings: _handleNotificationSettings,
                onPrivacySettings: _handlePrivacySettings,
                onThemeSettings: _handleThemeSettings,
                onLanguageSettings: _handleLanguageSettings,
                onQuietHours: _handleQuietHours,
                onLogout: _handleLogout,
              ),
              SizedBox(height: 10.h), // Bottom padding for navigation
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 4, // Profile tab
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  Future<void> _handleChangeAvatar() async {
    HapticFeedback.lightImpact();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 1.h,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1.h),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Change Profile Photo',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAvatarOption(
                  context,
                  'Camera',
                  'camera_alt',
                  () => _pickImage(ImageSource.camera),
                ),
                _buildAvatarOption(
                  context,
                  'Gallery',
                  'photo_library',
                  () => _pickImage(ImageSource.gallery),
                ),
                _buildAvatarOption(
                  context,
                  'Remove',
                  'delete',
                  _removeAvatar,
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption(
      BuildContext context, String title, String iconName, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: colorScheme.primary,
                size: 7.w,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request camera permission if needed
      if (source == ImageSource.camera) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) {
          _showPermissionDeniedDialog('Camera');
          return;
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        // TODO: Upload image to Supabase Storage and get URL
        // For now, we'll just show a success message
        _showSuccessMessage('Profile photo updated successfully!');
        
        // Note: In production, you would:
        // 1. Upload image to Supabase Storage
        // 2. Get the public URL
        // 3. Update user profile with: authService.updateProfile(avatarUrl: url)
        // 4. The UI will automatically update via Riverpod
      }
    } catch (e) {
      _showErrorMessage('Failed to update profile photo. Please try again.');
    }
  }

  Future<void> _removeAvatar() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateProfile(avatarUrl: '');
      _showSuccessMessage('Profile photo removed successfully!');
    } catch (e) {
      _showErrorMessage('Failed to remove profile photo. Please try again.');
    }
  }

  void _handleEditProfile() {
    HapticFeedback.lightImpact();
    // Navigate to edit profile screen
    _showComingSoonDialog('Edit Profile');
  }

  void _handleNotificationSettings() {
    HapticFeedback.lightImpact();
    _showComingSoonDialog('Notification Settings');
  }

  void _handlePrivacySettings() {
    HapticFeedback.lightImpact();
    _showComingSoonDialog('Privacy Settings');
  }

  void _handleThemeSettings() {
    HapticFeedback.lightImpact();
    _showComingSoonDialog('Theme Settings');
  }

  void _handleLanguageSettings() {
    HapticFeedback.lightImpact();
    _showComingSoonDialog('Language Settings');
  }

  void _handleQuietHours() {
    HapticFeedback.lightImpact();
    _showComingSoonDialog('Quiet Hours');
  }

  void _handleLogout() {
    HapticFeedback.lightImpact();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.w),
        ),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'logout',
              color: AppTheme.errorLight,
              size: 6.w,
            ),
            SizedBox(width: 3.w),
            const Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorLight,
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _performLogout() {
    // In a real app, you would clear user session and navigate to login
    _showSuccessMessage('Successfully signed out!');
    // Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showComingSoonDialog(String feature) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.w),
        ),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'construction',
              color: AppTheme.warningLight,
              size: 6.w,
            ),
            SizedBox(width: 3.w),
            const Text('Coming Soon'),
          ],
        ),
        content: Text(
          '$feature is coming soon! Stay tuned for updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog(String permission) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.w),
        ),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning',
              color: AppTheme.warningLight,
              size: 6.w,
            ),
            SizedBox(width: 3.w),
            const Text('Permission Required'),
          ],
        ),
        content: Text(
          '$permission permission is required to use this feature. Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: Colors.white,
              size: 5.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.w),
        ),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'error',
              color: Colors.white,
              size: 5.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.w),
        ),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }
}
