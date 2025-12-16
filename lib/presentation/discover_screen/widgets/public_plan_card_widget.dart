import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/avatar_utils.dart';

/// Public Plan Card Widget
/// 
/// Displays a public plan in a card format similar to public tasks
class PublicPlanCardWidget extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onTap;

  const PublicPlanCardWidget({
    super.key,
    required this.plan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final title = plan['title'] as String? ?? 'Untitled Plan';
    final description = plan['description'] as String? ?? '';
    final taskCount = plan['task_count'] as int? ?? 0;
    final planDate = plan['plan_date'] as String?;
    final startTime = plan['start_time'] as String?;
    final endTime = plan['end_time'] as String?;
    final category = plan['categories'] as Map<String, dynamic>?;
    final categoryName = category?['name'] as String? ?? 'Uncategorized';
    final categoryIcon = category?['icon'] as String? ?? 'category';
    final owner = plan['profiles'] as Map<String, dynamic>?;
    final ownerName = owner?['full_name'] as String? ?? 'Unknown';
    final ownerAvatar = owner?['avatar_url'] as String? ?? '';

    String dateTimeText = '';
    if (planDate != null) {
      try {
        final date = DateTime.parse(planDate);
        dateTimeText = '${date.day}/${date.month}/${date.year}';
        if (startTime != null && endTime != null) {
          dateTimeText += ' • $startTime - $endTime';
        } else if (startTime != null) {
          dateTimeText += ' • $startTime';
        }
      } catch (e) {
        dateTimeText = planDate;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 3.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category and Task Count
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: categoryIcon,
                        color: colorScheme.primary,
                        size: 4.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        categoryName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'checklist',
                      color: colorScheme.onSurfaceVariant,
                      size: 4.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '$taskCount tasks',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 2.h),
            
            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            if (description.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            SizedBox(height: 2.h),
            
            // Footer: Owner Info
            Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: AvatarUtils.getAvatarIcon(ownerAvatar),
                      color: colorScheme.primary,
                      size: 5.w,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'by $ownerName',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'public',
                        color: colorScheme.secondary,
                        size: 4.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Public',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

