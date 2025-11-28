import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './task_card_widget.dart';

class TaskSectionWidget extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> tasks;
  final Color? titleColor;
  final bool isMultiSelectMode;
  final Set<String> selectedTaskIds;
  final Function(String taskId, bool isSelected)? onTaskSelectionChanged;
  final Function(Map<String, dynamic> task)? onTaskTap;
  final Function(Map<String, dynamic> task)? onTaskComplete;
  final Function(Map<String, dynamic> task)? onTaskEdit;
  final Function(Map<String, dynamic> task)? onTaskDelete;
  final Function(Map<String, dynamic> task)? onTaskShare;

  const TaskSectionWidget({
    super.key,
    required this.title,
    required this.tasks,
    this.titleColor,
    this.isMultiSelectMode = false,
    this.selectedTaskIds = const {},
    this.onTaskSelectionChanged,
    this.onTaskTap,
    this.onTaskComplete,
    this.onTaskEdit,
    this.onTaskDelete,
    this.onTaskShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: titleColor ?? colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: (titleColor ?? colorScheme.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: titleColor ?? colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final taskId = task['id']?.toString() ?? index.toString();
            final isSelected = selectedTaskIds.contains(taskId);

            return TaskCardWidget(
              task: task,
              isSelected: isSelected,
              isMultiSelectMode: isMultiSelectMode,
              onTap: () => onTaskTap?.call(task),
              onComplete: () => onTaskComplete?.call(task),
              onEdit: () => onTaskEdit?.call(task),
              onDelete: () => onTaskDelete?.call(task),
              onShare: () => onTaskShare?.call(task),
              onSelectionChanged: (selected) {
                if (onTaskSelectionChanged != null) {
                  onTaskSelectionChanged!(taskId, selected ?? false);
                }
              },
            );
          },
        ),
        SizedBox(height: 2.h),
      ],
    );
  }
}
