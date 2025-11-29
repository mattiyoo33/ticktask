import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class TaskHeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;
  final VoidCallback onMore;

  const TaskHeaderWidget({
    super.key,
    required this.title,
    required this.onEdit,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          IconButton(
            onPressed: onEdit,
            icon: CustomIconWidget(
              iconName: 'edit',
              color: colorScheme.onSurfaceVariant,
              size: 24,
            ),
            tooltip: 'Edit task',
          ),
          IconButton(
            onPressed: onMore,
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color: colorScheme.onSurfaceVariant,
              size: 24,
            ),
            tooltip: 'More options',
          ),
        ],
      ),
    );
  }
}
