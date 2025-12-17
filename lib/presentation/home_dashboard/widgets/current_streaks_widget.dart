import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CurrentStreaksWidget extends StatelessWidget {
  final List<Map<String, dynamic>> streaks;
  final Function(Map<String, dynamic>) onStreakTap;
  final List<Map<String, dynamic>> weeklyCounts;

  const CurrentStreaksWidget({
    super.key,
    required this.streaks,
    required this.onStreakTap,
    this.weeklyCounts = const [],
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
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                  iconName: 'task_alt',
                  color: AppTheme.successLight,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                  'Total Completed',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          _buildWeeklyCompletionCircles(context),
          SizedBox(height: 1.5.h),
          streaks.isEmpty ? _buildEmptyState(context) : _buildStreaksList(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'local_fire_department',
            color: colorScheme.onSurfaceVariant,
            size: 24,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'No streak yet — finish a recurring task to start one.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
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

  Widget _buildWeeklyCompletionCircles(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fallbackLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    List<Map<String, dynamic>> data = weeklyCounts.isNotEmpty
        ? weeklyCounts
        : List.generate(7, (index) => {
              'label': fallbackLabels[index % fallbackLabels.length],
              'count': 0,
            });

    // Rotate so today is first (Sun=0 ... Sat=6)
    if (data.length == 7) {
      // Attempt to align by date if present
      data.sort((a, b) {
        final aDate = a['date'] is DateTime
            ? a['date'] as DateTime
            : DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime.now();
        final bDate = b['date'] is DateTime
            ? b['date'] as DateTime
            : DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime.now();
        return aDate.compareTo(bDate);
      });

      final today = DateTime.now();
      final todayKey = DateTime(today.year, today.month, today.day);
      int todayIndex = data.indexWhere((d) {
        final dt = d['date'] is DateTime
            ? d['date'] as DateTime
            : DateTime.tryParse(d['date']?.toString() ?? '') ?? today;
        final key = DateTime(dt.year, dt.month, dt.day);
        return key == todayKey;
      });
      if (todayIndex == -1) {
        todayIndex = today.weekday % 7; // Sun=0
      }
      if (todayIndex > 0) {
        data = [
          ...data.sublist(todayIndex),
          ...data.sublist(0, todayIndex),
        ];
      }
    }

    return SizedBox(
      height: 12.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: data.map((day) {
          final count = day['count'] as int? ?? 0;
          final label = (day['label'] as String? ?? ' ').substring(0, 1).toUpperCase();
          final isActive = count >= 1;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0),
              Container(
                width: 9.w,
                height: 9.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.surfaceVariant,
                  border: Border.all(
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isActive
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 0),
            ],
          );
        }).toList(),
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