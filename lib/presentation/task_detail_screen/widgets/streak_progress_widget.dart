import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class StreakProgressWidget extends StatelessWidget {
  final int currentStreak;
  final int maxStreak;
  final List<bool> weekProgress;
  final bool hasStreakBonus;

  const StreakProgressWidget({
    super.key,
    required this.currentStreak,
    required this.maxStreak,
    required this.weekProgress,
    this.hasStreakBonus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            offset: Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with flame icon
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'local_fire_department',
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Streak',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '$currentStreak days',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasStreakBonus)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'stars',
                        color: Colors.green,
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '+25 XP',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 3.h),

          // Weekly Progress
          Text(
            'This Week',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final isCompleted =
                  index < weekProgress.length ? weekProgress[index] : false;
              final isToday = index == DateTime.now().weekday - 1;

              return Column(
                children: [
                  Text(
                    days[index],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.orange
                          : isToday
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : colorScheme.outline.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: isToday && !isCompleted
                          ? Border.all(
                              color: colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: isCompleted
                        ? Center(
                            child: CustomIconWidget(
                              iconName: 'check',
                              color: Colors.white,
                              size: 14,
                            ),
                          )
                        : null,
                  ),
                ],
              );
            }),
          ),
          SizedBox(height: 2.h),

          // Best Streak
          Row(
            children: [
              CustomIconWidget(
                iconName: 'emoji_events',
                color: colorScheme.secondary,
                size: 16,
              ),
              SizedBox(width: 2.w),
              Text(
                'Best streak: $maxStreak days',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
