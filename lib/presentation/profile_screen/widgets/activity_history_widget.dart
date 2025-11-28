import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActivityHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> activities;

  const ActivityHistoryWidget({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full activity history
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          activities.isEmpty
              ? _buildEmptyState(context, theme, colorScheme)
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length > 5 ? 5 : activities.length,
                  separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _buildActivityItem(
                        context, theme, colorScheme, activity);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(4.w),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'history',
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 12.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'No Recent Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Complete some tasks to see your activity here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, ThemeData theme,
      ColorScheme colorScheme, Map<String, dynamic> activity) {
    final activityType = activity["type"] as String;
    Color iconColor;
    String iconName;

    switch (activityType) {
      case 'task_completed':
        iconColor = AppTheme.successLight;
        iconName = 'check_circle';
        break;
      case 'streak_achieved':
        iconColor = AppTheme.warningLight;
        iconName = 'local_fire_department';
        break;
      case 'badge_earned':
        iconColor = colorScheme.tertiary;
        iconName = 'military_tech';
        break;
      case 'level_up':
        iconColor = colorScheme.primary;
        iconName = 'star';
        break;
      default:
        iconColor = colorScheme.onSurfaceVariant;
        iconName = 'info';
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: iconColor,
                size: 6.w,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity["title"] as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  activity["description"] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  activity["timestamp"] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.sp,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (activity["xpGained"] != null) ...[
            SizedBox(width: 2.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: AppTheme.warningLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Text(
                '+${activity["xpGained"]} XP',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warningLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
