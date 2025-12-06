import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Avatar Selection Modal
/// 
/// Displays 6 predefined avatar options for users to choose from.
/// Each avatar is represented by an icon with a unique identifier.
class AvatarSelectionModalWidget extends StatelessWidget {
  final String? currentAvatarId;
  final Function(String avatarId) onAvatarSelected;

  const AvatarSelectionModalWidget({
    super.key,
    this.currentAvatarId,
    required this.onAvatarSelected,
  });

  // Define 6 different avatar options
  static const List<Map<String, String>> availableAvatars = [
    {'id': 'avatar_1', 'icon': 'face', 'name': 'Avatar 1'},
    {'id': 'avatar_2', 'icon': 'person', 'name': 'Avatar 2'},
    {'id': 'avatar_3', 'icon': 'account_circle', 'name': 'Avatar 3'},
    {'id': 'avatar_4', 'icon': 'sentiment_very_satisfied', 'name': 'Avatar 4'},
    {'id': 'avatar_5', 'icon': 'mood', 'name': 'Avatar 5'},
    {'id': 'avatar_6', 'icon': 'person_outline', 'name': 'Avatar 6'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12.w,
            height: 1.h,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1.h),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Choose Your Avatar',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          // Grid of 6 avatars (2 rows, 3 columns)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4.w,
              mainAxisSpacing: 4.w,
              childAspectRatio: 1,
            ),
            itemCount: availableAvatars.length,
            itemBuilder: (context, index) {
              final avatar = availableAvatars[index];
              final isSelected = currentAvatarId == avatar['id'];
              
              return GestureDetector(
                onTap: () {
                  onAvatarSelected(avatar['id']!);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.2),
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: avatar['icon']!,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 12.w,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  /// Get icon name for an avatar ID
  static String getIconName(String? avatarId) {
    if (avatarId == null || avatarId.isEmpty) {
      return 'account_circle'; // Default avatar
    }
    
    final avatar = availableAvatars.firstWhere(
      (a) => a['id'] == avatarId,
      orElse: () => availableAvatars[0], // Fallback to first avatar
    );
    
    return avatar['icon']!;
  }

  /// Check if an avatar ID is valid
  static bool isValidAvatarId(String? avatarId) {
    if (avatarId == null || avatarId.isEmpty) return false;
    return availableAvatars.any((a) => a['id'] == avatarId);
  }
}

