import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AccountSettingsWidget extends StatelessWidget {
  final VoidCallback onNotificationSettings;
  final VoidCallback onPrivacySettings;
  final VoidCallback onThemeSettings;
  final VoidCallback onLanguageSettings;
  final VoidCallback onQuietHours;
  final VoidCallback onLogout;

  const AccountSettingsWidget({
    super.key,
    required this.onNotificationSettings,
    required this.onPrivacySettings,
    required this.onThemeSettings,
    required this.onLanguageSettings,
    required this.onQuietHours,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Map<String, dynamic>> settingsGroups = [
      {
        "title": "Preferences",
        "items": [
          {
            "title": "Notifications",
            "subtitle": "Manage your notification preferences",
            "icon": "notifications",
            "onTap": onNotificationSettings,
          },
          {
            "title": "Privacy",
            "subtitle": "Control your privacy settings",
            "icon": "privacy_tip",
            "onTap": onPrivacySettings,
          },
          {
            "title": "Theme",
            "subtitle": "Choose light or dark mode",
            "icon": "palette",
            "onTap": onThemeSettings,
          },
          {
            "title": "Language",
            "subtitle": "Select your preferred language",
            "icon": "language",
            "onTap": onLanguageSettings,
          },
          {
            "title": "Quiet Hours",
            "subtitle": "Set your do not disturb hours",
            "icon": "bedtime",
            "onTap": onQuietHours,
          },
        ],
      },
      {
        "title": "Account",
        "items": [
          {
            "title": "Sign Out",
            "subtitle": "Sign out of your account",
            "icon": "logout",
            "onTap": onLogout,
            "isDestructive": true,
          },
        ],
      },
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          ...settingsGroups.map((group) => _buildSettingsGroup(
                context,
                theme,
                colorScheme,
                group,
              )),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> group,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (group["title"] != null) ...[
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 1.h),
            child: Text(
              group["title"] as String,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(3.w),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: (group["items"] as List<Map<String, dynamic>>)
                .asMap()
                .entries
                .map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == (group["items"] as List).length - 1;

              return _buildSettingsItem(
                context,
                theme,
                colorScheme,
                item,
                isLast,
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 3.h),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> item,
    bool isLast,
  ) {
    final isDestructive = item["isDestructive"] == true;

    return InkWell(
      onTap: item["onTap"] as VoidCallback?,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(3.w),
        bottom: isLast ? Radius.circular(3.w) : Radius.zero,
      ),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          border: !isLast
              ? Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppTheme.errorLight.withValues(alpha: 0.1)
                    : colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: item["icon"] as String,
                  color:
                      isDestructive ? AppTheme.errorLight : colorScheme.primary,
                  size: 5.w,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["title"] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? AppTheme.errorLight
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (item["subtitle"] != null) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      item["subtitle"] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
          ],
        ),
      ),
    );
  }
}
