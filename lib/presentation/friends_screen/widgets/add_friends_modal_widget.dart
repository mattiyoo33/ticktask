import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AddFriendsModalWidget extends StatefulWidget {
  final VoidCallback? onSearchUsers;
  final VoidCallback? onImportContacts;

  const AddFriendsModalWidget({
    super.key,
    this.onSearchUsers,
    this.onImportContacts,
  });

  @override
  State<AddFriendsModalWidget> createState() => _AddFriendsModalWidgetState();
}

class _AddFriendsModalWidgetState extends State<AddFriendsModalWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _shareInviteLink() {
    HapticFeedback.lightImpact();
    const String inviteMessage =
        "Join me on TickTask! Let's achieve our goals together and compete on the leaderboard. "
        "Download the app and add me as a friend: https://ticktask.app/invite/user123";

    Share.share(
      inviteMessage,
      subject: 'Join me on TickTask!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          // Title
          Text(
            'Add Friends',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Connect with friends to share your progress and compete on the leaderboard!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4.h),
          // Search users option
          _buildOptionTile(
            context: context,
            icon: 'search',
            title: 'Search Users',
            subtitle: 'Find friends by username or email',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              widget.onSearchUsers?.call();
            },
          ),
          SizedBox(height: 2.h),
          // Import contacts option
          _buildOptionTile(
            context: context,
            icon: 'contacts',
            title: 'Import Contacts',
            subtitle: 'Find friends from your contacts',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              widget.onImportContacts?.call();
            },
          ),
          SizedBox(height: 2.h),
          // Share invite link option
          _buildOptionTile(
            context: context,
            icon: 'share',
            title: 'Share Invite Link',
            subtitle: 'Invite friends to join TickTask',
            onTap: _shareInviteLink,
          ),
          SizedBox(height: 4.h),
          // Quick search
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'lightbulb',
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Quick Search',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Enter username or email...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'search',
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: CustomIconWidget(
                              iconName: 'clear',
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      widget.onSearchUsers?.call();
                    }
                  },
                ),
                SizedBox(height: 2.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _searchController.text.trim().isNotEmpty
                        ? () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            widget.onSearchUsers?.call();
                          }
                        : null,
                    child: Text('Search'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required String icon,
    required String title,
    required String subtitle,
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
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
