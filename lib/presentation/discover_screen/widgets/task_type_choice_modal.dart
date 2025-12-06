import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Task Type Choice Modal
/// 
/// Shows a modal to choose between creating a private or public task
class TaskTypeChoiceModal extends StatelessWidget {
  final VoidCallback onPrivateSelected;
  final VoidCallback onPublicSelected;

  const TaskTypeChoiceModal({
    super.key,
    required this.onPrivateSelected,
    required this.onPublicSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
      ),
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
            'Create Task',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          
          // Private Task Option
          _buildOption(
            context,
            icon: 'lock',
            title: 'Private Task',
            description: 'Create a personal task or invite friends',
            color: colorScheme.primary,
            onTap: onPrivateSelected,
          ),
          
          SizedBox(height: 2.h),
          
          // Public Task Option
          _buildOption(
            context,
            icon: 'public',
            title: 'Public Task',
            description: 'Share with the community and let anyone join',
            color: colorScheme.secondary,
            onTap: onPublicSelected,
          ),
          
          SizedBox(height: 4.h),
        ],
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
        Navigator.pop(context);
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
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: icon,
                  color: color,
                  size: 6.w,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: color,
              size: 5.w,
            ),
          ],
        ),
      ),
    );
  }
}

