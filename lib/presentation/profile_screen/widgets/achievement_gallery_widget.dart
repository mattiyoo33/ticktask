import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AchievementGalleryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;

  const AchievementGalleryWidget({
    super.key,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievement Gallery',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4.w),
                ),
                child: Text(
                  '${achievements.where((a) => a["isUnlocked"] == true).length}/${achievements.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 3.w,
              mainAxisSpacing: 2.h,
              childAspectRatio: 0.8,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              final isUnlocked = achievement["isUnlocked"] as bool;

              return GestureDetector(
                onTap: () => _showAchievementDetails(context, achievement),
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? colorScheme.surface
                        : colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4.w),
                    border: Border.all(
                      color: isUnlocked
                          ? colorScheme.primary.withValues(alpha: 0.3)
                          : colorScheme.outline.withValues(alpha: 0.1),
                      width: isUnlocked ? 2 : 1,
                    ),
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 15.w,
                            height: 15.w,
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? colorScheme.primary.withValues(alpha: 0.1)
                                  : colorScheme.outline.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: CustomIconWidget(
                                iconName: achievement["icon"] as String,
                                color: isUnlocked
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                size: 7.w,
                              ),
                            ),
                          ),
                          if (!isUnlocked)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surface
                                      .withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: CustomIconWidget(
                                    iconName: 'lock',
                                    color: colorScheme.onSurfaceVariant,
                                    size: 4.w,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        achievement["title"] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isUnlocked
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isUnlocked &&
                          achievement["unlockedDate"] != null) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          achievement["unlockedDate"] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10.sp,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (!isUnlocked && achievement["progress"] != null) ...[
                        SizedBox(height: 1.h),
                        Container(
                          width: double.infinity,
                          height: 0.5.h,
                          decoration: BoxDecoration(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(0.5.h),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (achievement["progress"] as double)
                                .clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(0.5.h),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAchievementDetails(
      BuildContext context, Map<String, dynamic> achievement) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnlocked = achievement["isUnlocked"] as bool;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.w),
        ),
        title: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : colorScheme.outline.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: achievement["icon"] as String,
                  color: isUnlocked
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 6.w,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                achievement["title"] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement["description"] as String,
              style: theme.textTheme.bodyMedium,
            ),
            if (isUnlocked && achievement["unlockedDate"] != null) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'check_circle',
                      color: colorScheme.primary,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Unlocked on ${achievement["unlockedDate"]}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isUnlocked && achievement["progress"] != null) ...[
              SizedBox(height: 2.h),
              Text(
                'Progress: ${((achievement["progress"] as double) * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                width: double.infinity,
                height: 1.h,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(1.h),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor:
                      (achievement["progress"] as double).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(1.h),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
