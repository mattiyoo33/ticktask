import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Task Type Choice Modal
/// 
/// Shows a modal to choose between creating a task or a plan
class TaskTypeChoiceModal extends StatelessWidget {
  final VoidCallback onTaskSelected;
  final VoidCallback onPlanSelected;

  const TaskTypeChoiceModal({
    super.key,
    required this.onTaskSelected,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          Container(
            width: 12.w,
            height: 1.h,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1.h),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Create',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          
          // Task and Plan Options side by side
          Row(
            children: [
              Expanded(
                child: _buildOption(
            context,
                  icon: 'checklist',
                  title: 'Task',
                  description: 'Create a task',
            color: colorScheme.primary,
                  onTap: onTaskSelected,
          ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildOption(
                context,
                icon: 'event',
                  title: 'Plan',
                  description: 'Create a plan',
                  color: colorScheme.secondary,
                  onTap: onPlanSelected,
                ),
              ),
          ],
          ),
          
          SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        // Execute callback first - it will handle closing the modal
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: icon,
                  color: color,
                  size: 8.w,
                ),
              ),
            ),
            SizedBox(height: 2.h),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

