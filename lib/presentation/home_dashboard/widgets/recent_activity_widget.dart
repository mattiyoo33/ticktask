import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/avatar_utils.dart';

class RecentActivityWidget extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final Function(Map<String, dynamic>) onActivityTap;

  const RecentActivityWidget({
    super.key,
    required this.activities,
    required this.onActivityTap,
  });

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'task_completed':
        return Icons.task_alt;
      case 'streak_achieved':
        return Icons.local_fire_department;
      case 'level_up':
        return Icons.star;
      case 'badge_earned':
        return Icons.military_tech;
      case 'friend_added':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(String type, ColorScheme colorScheme) {
    switch (type.toLowerCase()) {
      case 'task_completed':
        return AppTheme.successLight;
      case 'streak_achieved':
        return AppTheme.warningLight;
      case 'level_up':
        return colorScheme.primary;
      case 'badge_earned':
        return AppTheme.accentLight;
      case 'friend_added':
        return colorScheme.secondary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'history',
                  color: colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Recent Activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          activities.isEmpty
              ? _buildEmptyState(theme, colorScheme)
              : _buildActivitiesList(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'history',
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'No recent activity',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Complete tasks and connect with friends to see activity here!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList(ThemeData theme, ColorScheme colorScheme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: 2.h),
      itemCount: activities.length > 5 ? 5 : activities.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: colorScheme.outline.withValues(alpha: 0.1),
      ),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityItem(activity, theme, colorScheme);
      },
    );
  }

  Widget _buildActivityItem(
      Map<String, dynamic> activity, ThemeData theme, ColorScheme colorScheme) {
    final type = activity['type'] as String? ?? 'notification';
    final activityColor = _getActivityColor(type, colorScheme);
    final timestamp = activity['timestamp'] as DateTime? ?? DateTime.now();

    return InkWell(
      onTap: () => onActivityTap(activity),
      child: Container(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: activityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: _getActivityIcon(type).toString().split('.').last,
                  color: activityColor,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (activity['userAvatar'] != null) ...[
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: CustomIconWidget(
                              iconName: AvatarUtils.getAvatarIcon(activity['userAvatar'] as String?),
                              color: colorScheme.primary,
                              size: 4.w,
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                      ],
                      Expanded(
                        child: Text(
                          activity['userName'] as String? ?? 'You',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimeAgo(timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    activity['message'] as String? ?? 'No message',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (activity['xpGained'] != null) ...[
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: AppTheme.successLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${activity['xpGained']} XP',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.successLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
