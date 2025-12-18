import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class TaskInfoWidget extends StatelessWidget {
  final String description;
  final DateTime? dueDate;
  final String difficulty;
  final int xpValue;
  final DateTime createdDate;
  final bool isRecurring;
  final String? frequency;
  final List<String>? recurrenceDays;
  final DateTime? nextOccurrence;

  const TaskInfoWidget({
    super.key,
    required this.description,
    this.dueDate,
    required this.difficulty,
    required this.xpValue,
    required this.createdDate,
    this.isRecurring = false,
    this.frequency,
    this.recurrenceDays,
    this.nextOccurrence,
  });

  Color _getDifficultyColor(BuildContext context, String difficulty) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return colorScheme.primary;
    }
  }

  String _formatTimeRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} days left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes left';
    } else {
      return 'Due now';
    }
  }

  String _formatFrequency(String frequency) {
    // Capitalize first letter
    if (frequency.isEmpty) return frequency;
    final formatted = frequency[0].toUpperCase() + frequency.substring(1).toLowerCase();
    
    // For Custom frequency, show selected days as "Every Mon, Wed, Fri" format
    if (formatted.toLowerCase() == 'custom') {
      if (recurrenceDays != null && recurrenceDays!.isNotEmpty) {
        return 'Every ${recurrenceDays!.join(", ")}';
      }
      return 'Custom schedule';
    }
    
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
          // Description
          Text(
            'Description',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          SizedBox(height: 3.h),

          if (dueDate != null) ...[
            // Due Date with Countdown
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'schedule',
                  color: colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Date',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${dueDate!.day}/${dueDate!.month}/${dueDate!.year} at ${dueDate!.hour.toString().padLeft(2, '0')}:${dueDate!.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatTimeRemaining(dueDate!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: dueDate!.isBefore(DateTime.now())
                              ? Colors.red
                              : colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],

          // Difficulty and XP
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(context, difficulty)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getDifficultyColor(context, difficulty),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        difficulty.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getDifficultyColor(context, difficulty),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'stars',
                      color: colorScheme.primary,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '$xpValue XP',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Created Date
          Row(
            children: [
              CustomIconWidget(
                iconName: 'calendar_today',
                color: colorScheme.onSurfaceVariant,
                size: 16,
              ),
              SizedBox(width: 2.w),
              Text(
                'Created on ${createdDate.day}/${createdDate.month}/${createdDate.year}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          // Recurring Task Info
          if (isRecurring) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.secondary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'repeat',
                        color: colorScheme.secondary,
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Recurring Task',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (frequency != null) ...[
                    SizedBox(height: 1.h),
                    Text(
                      'Frequency: ${_formatFrequency(frequency!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (nextOccurrence != null) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      'Next: ${nextOccurrence!.day}/${nextOccurrence!.month}/${nextOccurrence!.year}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
