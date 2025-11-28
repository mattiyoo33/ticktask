import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CurrentStreaksWidget extends StatelessWidget {
  final List<Map<String, dynamic>> streaks;
  final Function(Map<String, dynamic>) onStreakTap;

  const CurrentStreaksWidget({
    super.key,
    required this.streaks,
    required this.onStreakTap,
  });

  Color _getStreakColor(int dayCount, BuildContext context) {
    if (dayCount >= 7) return AppTheme.successLight;
    if (dayCount >= 3) return AppTheme.warningLight;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'local_fire_department',
                  color: AppTheme.warningLight,
                  size: 24,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Current Streaks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          streaks.isEmpty ? _buildEmptyState(context) : _buildStreaksList(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(6.w),
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
        children: [
          CustomIconWidget(
            iconName: 'local_fire_department',
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'No active streaks',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Complete recurring tasks to build streaks!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksList(BuildContext context) {
    return SizedBox(
      height: 20.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        itemCount: streaks.length,
        separatorBuilder: (context, index) => SizedBox(width: 3.w),
        itemBuilder: (context, index) {
          final streak = streaks[index];
          return _buildStreakCard(streak, context);
        },
      ),
    );
  }

  Widget _buildStreakCard(Map<String, dynamic> streak, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dayCount = streak['dayCount'] as int? ?? 0;
    final streakColor = _getStreakColor(dayCount, context);
    final progress = (dayCount % 7) / 7;

    return GestureDetector(
      onTap: () => onStreakTap(streak),
      child: Container(
        width: 35.w,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: streakColor.withValues(alpha: 0.2),
            width: 1,
          ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor: streakColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(streakColor),
                    strokeWidth: 4,
                  ),
                ),
                Column(
                  children: [
                    CustomIconWidget(
                      iconName: 'local_fire_department',
                      color: streakColor,
                      size: 6.w,
                    ),
                    Text(
                      '$dayCount',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: streakColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              streak['title'] as String? ?? 'Untitled Habit',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Day${dayCount != 1 ? 's' : ''}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (dayCount >= 7) ...[
                  SizedBox(width: 1.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 1.5.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: AppTheme.successLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+25 XP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.successLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}