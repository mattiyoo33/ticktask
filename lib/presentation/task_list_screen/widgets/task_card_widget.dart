import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TaskCardWidget extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final bool isSelected;
  final bool isMultiSelectMode;
  final ValueChanged<bool?>? onSelectionChanged;

  const TaskCardWidget({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onEdit,
    this.onDelete,
    this.onShare,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompleted = task['status'] == 'completed';
    final isOverdue = task['status'] == 'overdue';
    final isCollaborative = task['is_collaborative'] == true;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Slidable(
        key: ValueKey(task['id']),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {
                HapticFeedback.mediumImpact();
                if (onComplete != null) onComplete!();
              },
              backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
              foregroundColor: Colors.white,
              icon: Icons.check,
              label: 'Complete',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {
                HapticFeedback.lightImpact();
                if (onEdit != null) onEdit!();
              },
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (context) {
                HapticFeedback.lightImpact();
                if (onShare != null) onShare!();
              },
              backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
              foregroundColor: Colors.white,
              icon: Icons.share,
              label: 'Share',
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (context) {
                HapticFeedback.heavyImpact();
                if (onDelete != null) onDelete!();
              },
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (isMultiSelectMode && onSelectionChanged != null) {
              onSelectionChanged!(!isSelected);
            } else if (onTap != null) {
              onTap!();
            }
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            if (onSelectionChanged != null) {
              onSelectionChanged!(true);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : isCollaborative
                      ? colorScheme.primaryContainer.withValues(alpha: 0.1)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : isCollaborative
                      ? Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        )
                  : Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: isCollaborative
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : colorScheme.shadow.withValues(alpha: 0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isMultiSelectMode) ...[
                        Checkbox(
                          value: isSelected,
                          onChanged: onSelectionChanged,
                        ),
                        SizedBox(width: 2.w),
                      ],
                      if (isCollaborative) ...[
                        CustomIconWidget(
                          iconName: 'group',
                          color: colorScheme.primary,
                          size: 18,
                        ),
                        SizedBox(width: 1.5.w),
                      ],
                      Expanded(
                        child: Text(
                          task['title'] ?? 'Untitled Task',
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted
                                ? colorScheme.onSurfaceVariant
                                : isCollaborative
                                    ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildDifficultyBadge(context),
                    ],
                  ),
                  if (task['description'] != null &&
                      task['description'].isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    Text(
                      task['description'],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      if (isCollaborative) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomIconWidget(
                                iconName: 'group',
                                color: colorScheme.primary,
                                size: 12,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                'Collaborative',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 2.w),
                      ],
                      CustomIconWidget(
                        iconName: 'schedule',
                        color: isOverdue
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        _formatDueDate(task['dueDate'] ?? task['due_date']),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isOverdue
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                          fontWeight:
                              isOverdue ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      if (task['isRecurring'] == true &&
                          task['streak'] != null) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.secondary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomIconWidget(
                                iconName: 'local_fire_department',
                                color:
                                    AppTheme.lightTheme.colorScheme.secondary,
                                size: 14,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '${task['streak']}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (task['xpReward'] != null) ...[
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomIconWidget(
                                iconName: 'stars',
                                color: colorScheme.primary,
                                size: 14,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '+${task['xpReward']} XP',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(BuildContext context) {
    final theme = Theme.of(context);
    final difficulty = task['difficulty']?.toLowerCase() ?? 'easy';

    Color badgeColor;
    String badgeText;

    switch (difficulty) {
      case 'hard':
        badgeColor = AppTheme.lightTheme.colorScheme.error;
        badgeText = 'Hard';
        break;
      case 'medium':
        badgeColor = AppTheme.warningLight;
        badgeText = 'Medium';
        break;
      default:
        badgeColor = AppTheme.lightTheme.colorScheme.secondary;
        badgeText = 'Easy';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        badgeText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
          fontSize: 10.sp,
        ),
      ),
    );
  }

  String _formatDueDate(dynamic dueDate) {
    if (dueDate == null) return 'No due date';

    DateTime date;
    if (dueDate is String) {
      date = DateTime.tryParse(dueDate) ?? DateTime.now();
    } else if (dueDate is DateTime) {
      date = dueDate;
    } else {
      return 'Invalid date';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    final difference = taskDate.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference < 0) {
      return '${difference.abs()} days overdue';
    } else if (difference <= 7) {
      return 'In $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
