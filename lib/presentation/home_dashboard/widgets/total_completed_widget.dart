import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Weekly completed counts widget (formerly CurrentStreaksWidget)
class TotalCompletedWidget extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyCounts;

  const TotalCompletedWidget({
    super.key,
    required this.weeklyCounts,
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
        ],
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
            ],
          );
        }).toList(),
      ),
    );
  }
}
