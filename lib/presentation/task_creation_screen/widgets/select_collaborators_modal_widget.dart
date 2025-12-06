import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

/// Modal widget for selecting collaborators during task creation
class SelectCollaboratorsModalWidget extends ConsumerStatefulWidget {
  final List<String> selectedFriendIds;

  const SelectCollaboratorsModalWidget({
    super.key,
    this.selectedFriendIds = const [],
  });

  @override
  ConsumerState<SelectCollaboratorsModalWidget> createState() =>
      _SelectCollaboratorsModalWidgetState();
}

class _SelectCollaboratorsModalWidgetState
    extends ConsumerState<SelectCollaboratorsModalWidget> {
  Set<String> _selectedFriendIds = {};

  @override
  void initState() {
    super.initState();
    _selectedFriendIds = Set.from(widget.selectedFriendIds);
  }

  List<Map<String, dynamic>> get _friends {
    final friendsAsync = ref.watch(friendsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUserId = currentUserAsync.value?.id;
    
    return friendsAsync.when(
      data: (friends) {
        // CRITICAL: Filter out current user to prevent self-collaboration
        if (currentUserId == null) return friends;
        return friends.where((friend) {
          final friendId = friend['id'] as String?;
          return friendId != null && friendId != currentUserId;
        }).toList();
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final friends = _friends;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.only(top: 2.h),
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'group',
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Select Collaborators',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, _selectedFriendIds.toList()),
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),

            // Friends List
            if (friends.isEmpty)
              Padding(
                padding: EdgeInsets.all(8.h),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'group',
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        size: 48,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No friends yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Add friends to collaborate on tasks',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  shrinkWrap: true,
                  itemCount: friends.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    final friendId = friend['id'] as String? ?? '';
                    final name = friend['name'] as String? ?? 'Unknown';
                    final avatar = friend['avatar'] as String? ?? '';
                    final isSelected = _selectedFriendIds.contains(friendId);

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 1.h,
                      ),
                      leading: Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: avatar.isNotEmpty
                            ? ClipOval(
                                child: CustomImageWidget(
                                  imageUrl: avatar,
                                  width: 12.w,
                                  height: 12.w,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(name),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      title: Text(
                        name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedFriendIds.add(friendId);
                            } else {
                              _selectedFriendIds.remove(friendId);
                            }
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedFriendIds.remove(friendId);
                          } else {
                            _selectedFriendIds.add(friendId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

            SizedBox(height: 2.h),

            // Done Button
            Padding(
              padding: EdgeInsets.all(4.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedFriendIds.toList()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

