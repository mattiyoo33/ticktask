import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ParticipantsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> participants;
  final bool isCollaborative;
  final VoidCallback? onSelectFriends;

  const ParticipantsWidget({
    super.key,
    required this.participants,
    this.isCollaborative = false,
    this.onSelectFriends,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show widget if collaborative, has participants, or can select friends
    if (!isCollaborative && participants.isEmpty && onSelectFriends == null) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            offset: Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'group',
                color: colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Participants (${participants.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (onSelectFriends != null)
                TextButton.icon(
                  onPressed: onSelectFriends,
                  icon: CustomIconWidget(
                    iconName: 'add',
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  label: Text(
                    'Select Friends',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          if (participants.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Center(
                child: Column(
                  children: [
                    CustomIconWidget(
                      iconName: 'group',
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      size: 32,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'No participants yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (onSelectFriends != null) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        'Add friends to collaborate',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: participants.length,
              separatorBuilder: (context, index) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
              final participant = participants[index];
              final name = participant['name'] as String? ?? 'Unknown';
              final avatar = participant['avatar'] as String? ?? '';
              final semanticLabel =
                  participant['semanticLabel'] as String? ?? 'User avatar';
              final isCompleted = participant['isCompleted'] as bool? ?? false;
              final contribution = participant['contribution'] as int? ?? 0;

              return Row(
                children: [
                  // Avatar
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted
                            ? Colors.green
                            : colorScheme.outline.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: avatar.isNotEmpty
                          ? CustomImageWidget(
                              imageUrl: avatar,
                              width: 10.w,
                              height: 10.w,
                              fit: BoxFit.cover,
                              semanticLabel: semanticLabel,
                            )
                          : Container(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 3.w),

                  // Name and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.w, vertical: 0.5.h),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : colorScheme.outline
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isCompleted ? 'Completed' : 'Pending',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isCompleted
                                      ? Colors.green
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (contribution > 0) ...[
                              SizedBox(width: 2.w),
                              Text(
                                '${contribution}% contribution',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status icon
                  if (isCompleted)
                    Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: 'check',
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
