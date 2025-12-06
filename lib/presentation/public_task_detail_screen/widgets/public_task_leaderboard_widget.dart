import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/avatar_utils.dart';

/// Public Task Leaderboard Widget
/// 
/// Displays a leaderboard of participants ranked by their contribution and completion count
class PublicTaskLeaderboardWidget extends ConsumerWidget {
  final String taskId;

  const PublicTaskLeaderboardWidget({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = ref.watch(currentUserProvider).value;

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
                  iconName: 'emoji_events',
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'No participants yet - leaderboard will appear when people join',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Sort by completed_count and contribution
        participants.sort((a, b) {
          final aCompleted = a['completed_count'] as int? ?? 0;
          final bCompleted = b['completed_count'] as int? ?? 0;
          if (aCompleted != bCompleted) {
            return bCompleted.compareTo(aCompleted);
          }
          final aContribution = a['contribution'] as int? ?? 0;
          final bContribution = b['contribution'] as int? ?? 0;
          return bContribution.compareTo(aContribution);
        });

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
                    iconName: 'emoji_events',
                    color: colorScheme.primary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Leaderboard',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: participants.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  final profile = participant['profiles'] as Map<String, dynamic>?;
                  final userId = profile?['id'] as String?;
                  final name = profile?['full_name'] as String? ?? 
                              profile?['email']?.toString().split('@')[0] ?? 
                              'Unknown';
                  final avatar = profile?['avatar_url'] as String? ?? '';
                  final completedCount = participant['completed_count'] as int? ?? 0;
                  final contribution = participant['contribution'] as int? ?? 0;
                  final isCurrentUser = userId == currentUser?.id;
                  final rank = index + 1;

                  return ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.w,
                          child: Text(
                            '#$rank',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: rank <= 3
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrentUser
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            border: Border.all(
                              color: isCurrentUser
                                  ? colorScheme.primary
                                  : colorScheme.outline.withValues(alpha: 0.2),
                              width: isCurrentUser ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: CustomIconWidget(
                              iconName: AvatarUtils.getAvatarIcon(avatar),
                              color: isCurrentUser
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              size: 6.w,
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'You',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        if (completedCount > 0) ...[
                          CustomIconWidget(
                            iconName: 'check_circle',
                            color: colorScheme.primary,
                            size: 4.w,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '$completedCount completed',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (contribution > 0) ...[
                          if (completedCount > 0) ...[
                            SizedBox(width: 3.w),
                            Text('•', style: theme.textTheme.bodySmall),
                            SizedBox(width: 3.w),
                          ],
                          Text(
                            '$contribution% contribution',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => SizedBox.shrink(),
    );
  }
}

