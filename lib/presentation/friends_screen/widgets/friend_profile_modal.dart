/// Friend Profile Modal Widget
/// 
/// Displays a detailed profile view of a friend when they tap "Profile" from the slide action.
/// Shows avatar, level, XP, daily streak, and account usage duration in a modal dialog.
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../services/friend_service.dart';

class FriendProfileModal extends StatelessWidget {
  final Map<String, dynamic> friend;
  final FriendService friendService;

  const FriendProfileModal({
    super.key,
    required this.friend,
    required this.friendService,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatXp(int xp) {
    if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}K';
    }
    return xp.toString();
  }

  String _formatUsageDuration(DateTime? createdAt) {
    if (createdAt == null) return 'New user';
    
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays < 30) {
      final days = difference.inDays;
      return days == 0 ? 'Today' : '$days ${days == 1 ? 'day' : 'days'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      final years = (difference.inDays / 365).floor();
      final remainingMonths = ((difference.inDays % 365) / 30).floor();
      if (remainingMonths == 0) {
        return '$years ${years == 1 ? 'year' : 'years'}';
      }
      return '$years ${years == 1 ? 'year' : 'years'}, $remainingMonths ${remainingMonths == 1 ? 'month' : 'months'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final String name = friend['name'] as String? ?? 'Unknown User';
    final String avatar = friend['avatar'] as String? ?? '';
    final int level = friend['level'] as int? ?? 1;
    final int xp = friend['xp'] as int? ?? 0;
    final int? currentStreak = friend['current_streak'] as int?;
    final String? accountCreatedAtStr = friend['account_created_at'] as String?;
    final DateTime? accountCreatedAt = accountCreatedAtStr != null
        ? DateTime.tryParse(accountCreatedAtStr)
        : null;

    final initials = _getInitials(name);
    final formattedXp = _formatXp(xp);
    final streakText = currentStreak != null && currentStreak > 0 
        ? '$currentStreak-day streak' 
        : 'No streak';
    final usageText = _formatUsageDuration(accountCreatedAt);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(5.w),
        constraints: BoxConstraints(maxWidth: 90.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 25.w,
              height: 25.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: avatar.isNotEmpty
                  ? ClipOval(
                      child: CustomImageWidget(
                        imageUrl: avatar,
                        width: 25.w,
                        height: 25.w,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          child: Center(
                            child: Text(
                              initials,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 3.h),
            // Name
            Text(
              name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            // Stats Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Level
                _buildStatItem(
                  context,
                  'Level',
                  'Level $level',
                  Icons.star,
                  colorScheme.primary,
                ),
                // XP
                _buildStatItem(
                  context,
                  'XP',
                  formattedXp,
                  Icons.star_border,
                  colorScheme.tertiary,
                ),
              ],
            ),
            SizedBox(height: 3.h),
            // Streak & Usage Duration
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Streak
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Streak',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              streakText,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                  SizedBox(height: 2.h),
                  // Usage Duration
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: colorScheme.secondary,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Using TickTask',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'for $usageText',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),
            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

