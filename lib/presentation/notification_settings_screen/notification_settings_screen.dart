import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Notification Settings',
        showBackButton: true,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.all(4.w),
          children: [
            // Master toggle for all notifications
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable Notifications',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Master switch for all notifications',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settings.notificationsEnabled,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      ref.read(notificationSettingsProvider.notifier).setNotificationsEnabled(value);
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            // Notification categories
            if (settings.notificationsEnabled) ...[
              Text(
                'Notification Types',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 2.h),

              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    _buildNotificationToggle(
                      context,
                      title: 'Task Reminders',
                      subtitle: 'Reminders for your tasks',
                      icon: Icons.task_alt,
                      value: settings.taskReminders,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        ref.read(notificationSettingsProvider.notifier).setTaskReminders(value);
                      },
                    ),
                    Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                    _buildNotificationToggle(
                      context,
                      title: 'Due Date Reminders',
                      subtitle: 'Reminders when tasks are due',
                      icon: Icons.event,
                      value: settings.dueDateReminders,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        ref.read(notificationSettingsProvider.notifier).setDueDateReminders(value);
                      },
                    ),
                    Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                    _buildNotificationToggle(
                      context,
                      title: 'Friend Requests',
                      subtitle: 'Notifications for friend requests',
                      icon: Icons.person_add,
                      value: settings.friendRequests,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        ref.read(notificationSettingsProvider.notifier).setFriendRequests(value);
                      },
                    ),
                    Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                    _buildNotificationToggle(
                      context,
                      title: 'Achievements',
                      subtitle: 'Notifications when you unlock achievements',
                      icon: Icons.emoji_events,
                      value: settings.achievements,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        ref.read(notificationSettingsProvider.notifier).setAchievements(value);
                      },
                    ),
                    Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                    _buildNotificationToggle(
                      context,
                      title: 'Plan Updates',
                      subtitle: 'Updates about your plans',
                      icon: Icons.list_alt,
                      value: settings.planUpdates,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        ref.read(notificationSettingsProvider.notifier).setPlanUpdates(value);
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'Enable notifications above to configure notification types',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      leading: Icon(
        icon,
        color: colorScheme.primary,
        size: 24,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}