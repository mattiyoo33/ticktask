/// Plan Card Widget
/// 
/// Displays a single plan card showing plan title, date, description, and completion statistics.
/// Shows the number of tasks in the plan and completion percentage with a progress indicator.
/// Progress bar and percentage color: red (0%) → orange → yellow → greenish → green (100%).
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

/// Returns a color for completion progress: 0% red → orange → yellow → greenish → 100% green.
Color progressColorFromPercentage(int percentage) {
  final t = (percentage.clamp(0, 100) / 100).toDouble();
  const red = Color(0xFFEF4444);
  const orange = Color(0xFFF97316);
  const yellow = Color(0xFFEAB308);
  const greenish = Color(0xFF84CC16);
  const green = Color(0xFF22C55E);
  if (t <= 0.25) {
    return Color.lerp(red, orange, t / 0.25)!;
  }
  if (t <= 0.5) {
    return Color.lerp(orange, yellow, (t - 0.25) / 0.25)!;
  }
  if (t <= 0.75) {
    return Color.lerp(yellow, greenish, (t - 0.5) / 0.25)!;
  }
  return Color.lerp(greenish, green, (t - 0.75) / 0.25)!;
}

class PlanCardWidget extends ConsumerWidget {
  final Map<String, dynamic> plan;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const PlanCardWidget({
    super.key,
    required this.plan,
    this.onTap,
    this.onDelete,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'No date';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final planDate = DateTime(date.year, date.month, date.day);

      if (planDate == today) {
        return 'Today';
      } else if (planDate == today.add(const Duration(days: 1))) {
        return 'Tomorrow';
      } else if (planDate == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTimeRange(String? startTime, String? endTime) {
    if (startTime == null && endTime == null) return '';
    if (startTime != null && endTime != null) {
      return '$startTime - $endTime';
    }
    return startTime ?? endTime ?? '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final planId = plan['id'] as String? ?? '';
    final title = plan['title'] as String? ?? 'Untitled Plan';
    final description = plan['description'] as String?;
    final planDate = plan['plan_date'] as String?;
    final startTime = plan['start_time'] as String?;
    final endTime = plan['end_time'] as String?;

    final planStatsAsync = ref.watch(planStatsProvider(planId));

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                              ),
                            ),
                            Consumer(
                              builder: (context, ref, _) {
                                final stats = ref.watch(planStatsProvider(planId));
                                return stats.maybeWhen(
                                  data: (s) {
                                    final total = s['total_tasks'] as int? ?? 0;
                                    return Container(
                                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CustomIconWidget(
                                            iconName: 'list',
                                            color: colorScheme.primary,
                                            size: 14,
                                          ),
                                          SizedBox(width: 1.w),
                                          Text(
                                            '$total',
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  orElse: () => const SizedBox.shrink(),
                                );
                              },
                            ),
                          ],
                        ),
                        if (description != null && description.isNotEmpty) ...[
                          SizedBox(height: 0.7.h),
                          Text(
                            description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              SizedBox(height: 1.5.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'calendar',
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _formatDate(planDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (startTime != null || endTime != null) ...[
                    SizedBox(width: 3.w),
                    CustomIconWidget(
                      iconName: 'schedule',
                      color: colorScheme.secondary,
                      size: 18,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      _formatTimeRange(startTime, endTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 1.5.h),
              planStatsAsync.when(
                data: (stats) {
                  final totalTasks = stats['total_tasks'] as int? ?? 0;
                  final completedTasks = stats['completed_tasks'] as int? ?? 0;
                  final completionPercentage = stats['completion_percentage'] as int? ?? 0;

                  if (totalTasks == 0) {
                    return Container(
                      padding: EdgeInsets.all(2.5.w),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'info',
                            color: colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'No tasks yet',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final progressColor = progressColorFromPercentage(completionPercentage);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$completedTasks / $totalTasks tasks completed',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$completionPercentage%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: progressColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: completionPercentage / 100,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: progressColor,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => Center(
                  child: SizedBox(
                  height: 2.h,
                    width: 2.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

