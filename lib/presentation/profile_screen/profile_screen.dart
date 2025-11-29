import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  // Mock user data
  final Map<String, dynamic> userData = {
    "id": 1,
    "username": "TaskMaster2024",
    "email": "taskmaster@ticktask.com",
    "avatar":
        "https://img.rocket.new/generatedImages/rocket_gen_img_1274dd504-1762275023732.png",
    "avatarDescription":
        "Professional headshot of a young woman with shoulder-length brown hair wearing a white blazer against a neutral background",
    "level": 12,
    "currentXP": 850,
    "nextLevelXP": 1300,
    "totalXP": 8450,
    "joinDate": "2024-01-15",
  };

  // Mock statistics data
  final Map<String, dynamic> statisticsData = {
    "totalTasks": 247,
    "currentStreak": 15,
    "longestStreak": 28,
    "completionRate": 87,
    "badgesEarned": 12,
    "friendCount": 23,
    "totalXP": 8450,
  };

  // Mock achievements data
  final List<Map<String, dynamic>> achievements = [
    {
      "id": 1,
      "title": "First Steps",
      "description": "Complete your first task",
      "icon": "flag",
      "isUnlocked": true,
      "unlockedDate": "Jan 15, 2024",
      "progress": null,
    },
    {
      "id": 2,
      "title": "Streak Master",
      "description": "Maintain a 7-day streak",
      "icon": "local_fire_department",
      "isUnlocked": true,
      "unlockedDate": "Feb 3, 2024",
      "progress": null,
    },
    {
      "id": 3,
      "title": "Social Butterfly",
      "description": "Add 10 friends",
      "icon": "people",
      "isUnlocked": true,
      "unlockedDate": "Mar 12, 2024",
      "progress": null,
    },
    {
      "id": 4,
      "title": "Century Club",
      "description": "Complete 100 tasks",
      "icon": "military_tech",
      "isUnlocked": true,
      "unlockedDate": "Apr 8, 2024",
      "progress": null,
    },
    {
      "id": 5,
      "title": "Level Up",
      "description": "Reach level 10",
      "icon": "star",
      "isUnlocked": true,
      "unlockedDate": "May 20, 2024",
      "progress": null,
    },
    {
      "id": 6,
      "title": "Perfectionist",
      "description": "Complete 50 hard tasks",
      "icon": "diamond",
      "isUnlocked": false,
      "unlockedDate": null,
      "progress": 0.76,
    },
    {
      "id": 7,
      "title": "Marathon Runner",
      "description": "Maintain a 30-day streak",
      "icon": "directions_run",
      "isUnlocked": false,
      "unlockedDate": null,
      "progress": 0.5,
    },
    {
      "id": 8,
      "title": "Team Player",
      "description": "Complete 25 collaborative tasks",
      "icon": "group_work",
      "isUnlocked": false,
      "unlockedDate": null,
      "progress": 0.32,
    },
    {
      "id": 9,
      "title": "XP Hunter",
      "description": "Earn 10,000 total XP",
      "icon": "trending_up",
      "isUnlocked": false,
      "unlockedDate": null,
      "progress": 0.845,
    },
  ];

  // Mock activity history data
  final List<Map<String, dynamic>> activities = [
    {
      "id": 1,
      "type": "task_completed",
      "title": "Morning Workout",
      "description": "Completed daily exercise routine",
      "timestamp": "2 hours ago",
      "xpGained": 20,
    },
    {
      "id": 2,
      "type": "streak_achieved",
      "title": "15-Day Streak!",
      "description": "Maintained your daily task completion streak",
      "timestamp": "1 day ago",
      "xpGained": 25,
    },
    {
      "id": 3,
      "type": "task_completed",
      "title": "Project Planning",
      "description": "Finished quarterly project roadmap",
      "timestamp": "2 days ago",
      "xpGained": 30,
    },
    {
      "id": 4,
      "type": "badge_earned",
      "title": "Level Up Badge",
      "description": "Reached level 12 milestone",
      "timestamp": "3 days ago",
      "xpGained": null,
    },
    {
      "id": 5,
      "type": "task_completed",
      "title": "Read Chapter 5",
      "description": "Completed reading assignment",
      "timestamp": "4 days ago",
      "xpGained": 10,
    },
    {
      "id": 6,
      "type": "task_completed",
      "title": "Team Meeting",
      "description": "Attended weekly team sync",
      "timestamp": "5 days ago",
      "xpGained": 15,
    },
  ];

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
        // In a real app, you would upload the image to your server
        // For now, we'll just show a success message
        _showSuccessMessage('Profile photo updated successfully!');

        // Update the avatar URL in userData (in real app, this would be the uploaded image URL)
        setState(() {
          userData["avatar"] =
              image.path; // In real app, this would be the server URL
        });
      }
    } catch (e) {
      _showErrorMessage('Failed to update profile photo. Please try again.');
    }
  }

  void _removeAvatar() {
    setState(() {
      userData["avatar"] =
          "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400";
    });
    _showSuccessMessage('Profile photo removed successfully!');
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
