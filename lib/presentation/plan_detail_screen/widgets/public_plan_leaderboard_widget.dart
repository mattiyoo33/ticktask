import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/avatar_utils.dart';

/// Public Plan Leaderboard Widget
/// 
/// Displays a leaderboard of participants ranked by their XP gained from tasks in this plan
class PublicPlanLeaderboardWidget extends ConsumerWidget {
  final String planId;

  const PublicPlanLeaderboardWidget({
    super.key,
    required this.planId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = ref.watch(currentUserProvider).value;

    // Fetch participants using provider
    final participantsFuture = ref.watch(
      publicPlanParticipantsProvider(planId),
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

        // Sort by plan-specific XP (already sorted in service, but ensure consistency)
        participants.sort((a, b) {
          final aPlanXp = a['plan_xp'] as int? ?? 0;
          final bPlanXp = b['plan_xp'] as int? ?? 0;
          if (aPlanXp != bPlanXp) {
            return bPlanXp.compareTo(aPlanXp); // Descending order (highest XP first)
          }
          // If XP is equal, sort by joined_at (earlier join = higher rank)
          final aJoined = a['joined_at'] as String? ?? '';
          final bJoined = b['joined_at'] as String? ?? '';
          return aJoined.compareTo(bJoined);
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
                  final planXp = participant['plan_xp'] as int? ?? 0; // Plan-specific XP
                  final level = profile?['level'] as int? ?? 1;
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
                        // Show plan-specific XP prominently
                        CustomIconWidget(
                          iconName: 'star',
                          color: colorScheme.primary,
                          size: 4.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '$planXp XP',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Level $level',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
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
