import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickActionsWidget extends StatelessWidget {
  final VoidCallback onCreateTask;
  final VoidCallback onViewAllTasks;
  final VoidCallback onInviteFriends;
  final VoidCallback onViewProfile;
  final VoidCallback onViewPlans;

  const QuickActionsWidget({
    super.key,
    required this.onCreateTask,
    required this.onViewAllTasks,
    required this.onInviteFriends,
    required this.onViewProfile,
    required this.onViewPlans,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context: context,
                  title: 'Create Task',
                  icon: 'add_task',
                  color: colorScheme.primary,
                  onTap: onCreateTask,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildActionCard(
                  context: context,
                  title: 'View Tasks',
                  icon: 'list_alt',
                  color: colorScheme.secondary,
                  onTap: onViewAllTasks,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.w),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context: context,
                  title: 'Invite Friends',
                  icon: 'person_add',
                  color: AppTheme.accentLight,
                  onTap: onInviteFriends,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildActionCard(
                  context: context,
                  title: 'Profile',
                  icon: 'person',
                  color: AppTheme.warningLight,
                  onTap: onViewProfile,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.w),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context: context,
                  title: 'View Plans',
                  icon: 'calendar_today',
                  color: colorScheme.tertiary,
                  onTap: onViewPlans,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: SizedBox(), // Empty space to maintain grid alignment
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
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
            Container(
              width: 14.w,
              height: 14.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: icon,
                  color: color,
                  size: 7.w,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
