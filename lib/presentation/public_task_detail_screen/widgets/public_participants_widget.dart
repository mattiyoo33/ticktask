import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/avatar_utils.dart';

/// Public Participants Widget
/// 
/// Displays all participants who have joined the public task
class PublicParticipantsWidget extends ConsumerWidget {
  final String taskId;

  const PublicParticipantsWidget({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Fetch participants using shared provider
    final participantsFuture = ref.watch(
      publicTaskParticipantsProvider(taskId),
    );

    return participantsFuture.when(
      data: (participants) {
        if (participants.isEmpty) {
          return Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'group',
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Text(
                  'No participants yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'group',
                    color: colorScheme.primary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Participants (${participants.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 2.h,
                children: participants.map((participant) {
                  final profile = participant['profiles'] as Map<String, dynamic>?;
                  final name = profile?['full_name'] as String? ?? 
                              profile?['email']?.toString().split('@')[0] ?? 
                              'Unknown';
                  final avatar = profile?['avatar_url'] as String? ?? '';
                  
                  return Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                              iconName: AvatarUtils.getAvatarIcon(avatar),
                              color: colorScheme.primary,
                              size: 5.w,
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Container(
        padding: EdgeInsets.all(4.w),
        child: Text(
          'Failed to load participants: $error',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.error,
          ),
        ),
      ),
    );
  }
}

