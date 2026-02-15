import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Banner shown at the top for 5 seconds after completing a task/plan task.
/// Displays the weekly "Total Completed" streak so the user sees they're on a streak.
class StreakBannerWidget extends StatefulWidget {
  final List<Map<String, dynamic>> weeklyCounts;
  final int currentStreak;
  final VoidCallback? onDismiss;

  const StreakBannerWidget({
    super.key,
    required this.weeklyCounts,
    required this.currentStreak,
    this.onDismiss,
  });

  @override
  State<StreakBannerWidget> createState() => _StreakBannerWidgetState();
}

class _StreakBannerWidgetState extends State<StreakBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value * 120),
            child: Opacity(
              opacity: _slideAnimation.value.clamp(0.0, 1.0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: EdgeInsets.fromLTRB(4.w, MediaQuery.of(context).padding.top + 2.h, 4.w, 0),
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'local_fire_department',
                            color: colorScheme.primary,
                            size: 22,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              widget.currentStreak > 0
                                  ? "You're on a ${widget.currentStreak}-day streak!"
                                  : 'Your week',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.5.h),
                      _buildWeeklyCircles(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyCircles(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fallbackLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    List<Map<String, dynamic>> data = widget.weeklyCounts.isNotEmpty
        ? List.from(widget.weeklyCounts)
        : List.generate(7, (index) => {
              'label': fallbackLabels[index % fallbackLabels.length],
              'count': 0,
            });

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
        todayIndex = today.weekday % 7;
      }
      if (todayIndex > 0) {
        data = [
          ...data.sublist(todayIndex),
          ...data.sublist(0, todayIndex),
        ];
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: data.map((day) {
        final count = day['count'] as int? ?? 0;
        final label = (day['label'] as String? ?? ' ').substring(0, 1).toUpperCase();
        final isActive = count >= 1;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 0.5.h),
            Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: theme.textTheme.labelMedium?.copyWith(
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
    );
  }
}
