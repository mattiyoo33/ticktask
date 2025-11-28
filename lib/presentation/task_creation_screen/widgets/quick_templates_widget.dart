import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickTemplatesWidget extends StatelessWidget {
  final Function(Map<String, dynamic>) onTemplateSelected;

  const QuickTemplatesWidget({
    super.key,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Map<String, dynamic>> templates = [
      {
        'title': 'Morning Workout',
        'description': 'Start your day with 30 minutes of exercise',
        'difficulty': 'Medium',
        'category': 'Health',
        'icon': 'fitness_center',
        'color': AppTheme.lightTheme.colorScheme.secondary,
      },
      {
        'title': 'Read 20 Pages',
        'description': 'Daily reading habit for personal growth',
        'difficulty': 'Easy',
        'category': 'Learning',
        'icon': 'menu_book',
        'color': AppTheme.lightTheme.colorScheme.primary,
      },
      {
        'title': 'Complete Project',
        'description': 'Finish important work assignment',
        'difficulty': 'Hard',
        'category': 'Work',
        'icon': 'work',
        'color': AppTheme.lightTheme.colorScheme.tertiary,
      },
      {
        'title': 'Call Family',
        'description': 'Stay connected with loved ones',
        'difficulty': 'Easy',
        'category': 'Social',
        'icon': 'phone',
        'color': AppTheme.lightTheme.colorScheme.secondary,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Templates',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 20.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (context, index) => SizedBox(width: 3.w),
            itemBuilder: (context, index) {
              final template = templates[index];
              return _buildTemplateCard(context, template);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(
      BuildContext context, Map<String, dynamic> template) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final templateColor = template['color'] as Color;

    return GestureDetector(
      onTap: () => onTemplateSelected(template),
      child: Container(
        width: 40.w,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: templateColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: templateColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: templateColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: template['icon'],
                    color: templateColor,
                    size: 20,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: templateColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    template['difficulty'],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template['title'],
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  Expanded(
                    child: Text(
                      template['description'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
