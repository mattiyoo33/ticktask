import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StatisticsOverviewWidget extends StatelessWidget {
  final Map<String, dynamic> statisticsData;

  const StatisticsOverviewWidget({
    super.key,
    required this.statisticsData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Map<String, dynamic>> stats = [
      {
        "title": "Total Tasks",
        "value": "${statisticsData["totalTasks"]}",
        "icon": "task_alt",
        "color": colorScheme.primary,
      },
      {
        "title": "Current Streak",
        "value": "${statisticsData["currentStreak"]} days",
        "icon": "local_fire_department",
        "color": colorScheme.secondary,
      },
      {
        "title": "Total XP",
        "value": "${statisticsData["totalXP"]}",
        "icon": "star",
        "color": AppTheme.warningLight,
      },
      {
        "title": "Completion Rate",
        "value": "${statisticsData["completionRate"]}%",
        "icon": "trending_up",
        "color": AppTheme.successLight,
      },
      {
        "title": "Badges Earned",
        "value": "${statisticsData["badgesEarned"]}",
        "icon": "military_tech",
        "color": colorScheme.tertiary,
      },
      {
        "title": "Friends",
        "value": "${statisticsData["friendCount"]}",
        "icon": "people",
        "color": colorScheme.primary,
      },
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 3.w,
              mainAxisSpacing: 1.5.h,
              childAspectRatio: 1.35,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              return Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(4.w),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: (stat["color"] as Color).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: stat["icon"] as String,
                          color: stat["color"] as Color,
                          size: 6.w,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.2.h),
                    Text(
                      stat["value"] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 0.4.h),
                    Text(
                      stat["title"] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
