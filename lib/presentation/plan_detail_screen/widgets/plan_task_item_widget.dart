/// Plan Task Item Widget
/// 
/// Displays a single task item within a plan, showing task title, due time, status,
/// and completion checkbox. Tasks can be tapped to view details or marked as complete.
/// Complete button is disabled for 5 minutes after task creation (countdown shown).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class PlanTaskItemWidget extends StatefulWidget {
  final Map<String, dynamic> task;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onRevert;
  final VoidCallback? onLockedTap;
  final bool isLocked;
  final bool isNextUp;

  const PlanTaskItemWidget({
    super.key,
    required this.task,
    required this.index,
    this.onTap,
    this.onComplete,
    this.onRevert,
    this.onLockedTap,
    this.isLocked = false,
    this.isNextUp = false,
  });

  @override
  State<PlanTaskItemWidget> createState() => _PlanTaskItemWidgetState();
}

class _PlanTaskItemWidgetState extends State<PlanTaskItemWidget> {
  int _cooldownRemainingSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _cooldownRemainingSeconds = TaskService.getRemainingCooldownSeconds(
      widget.task['created_at'] as String?,
    );
    if (_cooldownRemainingSeconds > 0) {
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final r = TaskService.getRemainingCooldownSeconds(
          widget.task['created_at'] as String?,
        );
        setState(() => _cooldownRemainingSeconds = r);
        if (r <= 0) _cooldownTimer?.cancel();
      });
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String _formatDueTime(String? dueTime) {
    if (dueTime == null || dueTime.isEmpty) return '';
    return dueTime;
  }

  Color _getStatusColor(String? status, ColorScheme colorScheme) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'overdue':
        return colorScheme.error;
      case 'active':
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = widget.task['title'] as String? ?? 'Untitled Task';
    final status = widget.task['status'] as String? ?? 'active';
    final dueTime = widget.task['due_time'] as String?;
    final isCompleted = status == 'completed';
    final statusColor = _getStatusColor(status, colorScheme);
    final inCooldown = _cooldownRemainingSeconds > 0 && widget.onComplete != null;

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.1),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: widget.isLocked ? widget.onLockedTap : widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              // Task Number Badge
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              // Task Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isCompleted
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    if (dueTime != null && dueTime.isNotEmpty) ...[
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'schedule',
                            color: colorScheme.onSurfaceVariant,
                            size: 14,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            _formatDueTime(dueTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Status Indicator / Action Buttons
              if (widget.isLocked)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: widget.isNextUp ? 'arrow_forward' : 'lock',
                        color: colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        widget.isNextUp ? 'Next up' : 'Locked',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isCompleted && widget.onRevert != null)
                IconButton(
                  onPressed: widget.onRevert,
                  icon: Icon(
                    Icons.undo,
                    color: colorScheme.error,
                    size: 24,
                  ),
                  tooltip: 'Revert completion',
                )
              else if (isCompleted)
                Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'check',
                    color: Colors.white,
                    size: 16,
                  ),
                )
              else if (inCooldown)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.8.h),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(_cooldownRemainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_cooldownRemainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (widget.onComplete != null)
                IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onComplete?.call();
                  },
                  icon: Icon(
                    Icons.check_circle_outline,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  tooltip: 'Mark as complete',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

