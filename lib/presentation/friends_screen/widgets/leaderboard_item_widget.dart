import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LeaderboardItemWidget extends StatelessWidget {
  final Map<String, dynamic> user;
  final int rank;
  final bool isCurrentUser;

  const LeaderboardItemWidget({
    super.key,
    required this.user,
    required this.rank,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String name = user['name'] as String? ?? 'Unknown User';
    final String avatar = user['avatar'] as String? ?? '';
    final String semanticLabel =
        user['semanticLabel'] as String? ?? 'User profile picture';
    final int xp = user['xp'] as int? ?? 0;
    final int level = user['level'] as int? ?? 1;
    final List<dynamic> badges = user['badges'] as List<dynamic>? ?? [];

    Color getRankColor() {
      switch (rank) {
        case 1:
          return const Color(0xFFFFD700); // Gold
        case 2:
          return const Color(0xFFC0C0C0); // Silver
        case 3:
          return const Color(0xFFCD7F32); // Bronze
        default:
          return colorScheme.onSurfaceVariant;
      }
    }

    Widget getRankIcon() {
      switch (rank) {
        case 1:
          return CustomIconWidget(
            iconName: 'emoji_events',
            color: getRankColor(),
            size: 24,
          );
        case 2:
          return CustomIconWidget(
            iconName: 'emoji_events',
            color: getRankColor(),
            size: 22,
          );
        case 3:
          return CustomIconWidget(
            iconName: 'emoji_events',
            color: getRankColor(),
            size: 20,
          );
        default:
          return Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          );
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isCurrentUser
              ? Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                )
              : null,
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
            // Rank indicator
            SizedBox(
              width: 10.w,
              child: Center(child: getRankIcon()),
            ),
            SizedBox(width: 3.w),
            // Avatar
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentUser
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.2),
                  width: isCurrentUser ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.w / 2),
                child: CustomImageWidget(
                  imageUrl: avatar,
                  width: 12.w,
                  height: 12.w,
                  fit: BoxFit.cover,
                  semanticLabel: semanticLabel,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCurrentUser
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'You',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'star',
                        color: AppTheme.lightTheme.colorScheme.tertiary,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '$xp XP',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.25.h,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Level $level',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (badges.isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        ...badges.take(3).map((badge) => Padding(
                              padding: EdgeInsets.only(right: 1.w),
                              child: Container(
                                width: 6.w,
                                height: 6.w,
                                decoration: BoxDecoration(
                                  color: AppTheme
                                      .lightTheme.colorScheme.tertiary
                                      .withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: CustomIconWidget(
                                  iconName: badge as String? ?? 'emoji_events',
                                  color:
                                      AppTheme.lightTheme.colorScheme.tertiary,
                                  size: 16,
                                ),
                              ),
                            )),
                        if (badges.length > 3)
                          Text(
                            '+${badges.length - 3}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
