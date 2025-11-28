import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TodaysTasksWidget extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;
  final Function(Map<String, dynamic>) onTaskComplete;
  final Function(Map<String, dynamic>) onTaskEdit;
  final Function(Map<String, dynamic>) onTaskDelete;

  const TodaysTasksWidget({
    super.key,
    required this.tasks,
    required this.onTaskComplete,
    required this.onTaskEdit,
    required this.onTaskDelete,
  });

  @override
  State<TodaysTasksWidget> createState() => _TodaysTasksWidgetState();
}

class _TodaysTasksWidgetState extends State<TodaysTasksWidget> {
  bool _isExpanded = true;

  Color _getDifficultyColor(String difficulty) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.successLight;
      case 'medium':
        return AppTheme.warningLight;
      case 'hard':
        return AppTheme.errorLight;
      default:
        return colorScheme.primary;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.circle;
      case 'medium':
        return Icons.change_history;
      case 'hard':
        return Icons.square;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
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
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'today',
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Today\'s Tasks',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.tasks.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: CustomIconWidget(
                      iconName: 'keyboard_arrow_down',
                      color: colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isExpanded ? null : 0,
            child: _isExpanded
                ? widget.tasks.isEmpty
                    ? _buildEmptyState()
                    : _buildTasksList()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'task_alt',
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'No tasks for today',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Create your first task to get started!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: 2.h),
      itemCount: widget.tasks.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
      ),
      itemBuilder: (context, index) {
        final task = widget.tasks[index];
        return _buildTaskItem(task);
      },
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final difficulty = task['difficulty'] as String? ?? 'easy';
    final isCompleted = task['isCompleted'] as bool? ?? false;

    return Slidable(
      key: ValueKey(task['id']),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => widget.onTaskComplete(task),
            backgroundColor: AppTheme.successLight,
            foregroundColor: Colors.white,
            icon: Icons.check,
            label: 'Complete',
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(12)),
          ),
          SlidableAction(
            onPressed: (_) => widget.onTaskEdit(task),
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
        ],
      ),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => widget.onTaskDelete(task),
            backgroundColor: AppTheme.errorLight,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(12)),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: _getDifficultyColor(difficulty).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName:
                      _getDifficultyIcon(difficulty).toString().split('.').last,
                  color: _getDifficultyColor(difficulty),
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] as String? ?? 'Untitled Task',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isCompleted
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task['description'] != null &&
                      (task['description'] as String).isNotEmpty) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      task['description'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(difficulty)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          difficulty.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getDifficultyColor(difficulty),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      CustomIconWidget(
                        iconName: 'schedule',
                        color: colorScheme.onSurfaceVariant,
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        task['dueTime'] as String? ?? 'No time set',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isCompleted)
              Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'check',
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
