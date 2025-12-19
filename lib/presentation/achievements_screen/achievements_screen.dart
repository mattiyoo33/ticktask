import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: achievementsAsync.when(
        data: (unlockedAchievements) {
          final achievementInfo = AchievementService.getAchievementInfo();
          final allAchievementTypes = achievementInfo.keys.toList();
          
          // Create a map of unlocked achievement types for quick lookup
          final unlockedTypes = unlockedAchievements
              .map((a) => a['achievement_type'] as String)
              .toSet();

          return ListView(
            padding: EdgeInsets.all(4.w),
            children: [
              // Header
              Text(
                'Your Achievements',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                '${unlockedAchievements.length} of ${allAchievementTypes.length} unlocked',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 3.h),

              // Achievement List
              ...allAchievementTypes.map((achievementType) {
                final info = achievementInfo[achievementType]!;
                final isUnlocked = unlockedTypes.contains(achievementType);
                final unlockedAchievement = unlockedAchievements.firstWhere(
                  (a) => a['achievement_type'] == achievementType,
                  orElse: () => {},
                );

                return _buildAchievementCard(
                  context,
                  title: info['title'] as String,
                  description: info['description'] as String,
                  icon: info['icon'] as IconData,
                  isUnlocked: isUnlocked,
                  unlockedAt: unlockedAchievement['unlocked_at'] as String?,
                  colorScheme: colorScheme,
                  theme: theme,
                );
              }).toList(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: colorScheme.error,
              ),
              SizedBox(height: 2.h),
              Text(
                'Error loading achievements',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              SizedBox(height: 1.h),
              TextButton(
                onPressed: () => ref.invalidate(achievementsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 4, // More tab
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isUnlocked,
    String? unlockedAt,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isUnlocked
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.1),
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Medal/Cup Icon
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : colorScheme.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isUnlocked ? Icons.emoji_events : Icons.emoji_events_outlined,
              color: isUnlocked
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 32,
            ),
          ),
          SizedBox(width: 4.w),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isUnlocked
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      Icon(
                        Icons.check_circle,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isUnlocked
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
                if (isUnlocked && unlockedAt != null) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    'Unlocked ${_formatDate(unlockedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'today';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}

