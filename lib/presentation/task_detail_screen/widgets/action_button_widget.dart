import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

enum TaskStatus { active, completed, scheduled }
//TODO: Commit test

class ActionButtonWidget extends StatelessWidget {
  final TaskStatus taskStatus;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onMarkIncomplete;
  final VoidCallback? onStartTask;
  final bool isLoading;

  const ActionButtonWidget({
    super.key,
    required this.taskStatus,
    this.onMarkComplete,
    this.onMarkIncomplete,
    this.onStartTask,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String buttonText;
    Color buttonColor;
    Color textColor;
    IconData buttonIcon;
    VoidCallback? onPressed;

    switch (taskStatus) {
      case TaskStatus.completed:
        buttonText = 'Mark Incomplete';
        buttonColor = colorScheme.outline.withValues(alpha: 0.2);
        textColor = colorScheme.onSurfaceVariant;
        buttonIcon = Icons.undo;
        onPressed = onMarkIncomplete;
        break;
      case TaskStatus.scheduled:
        buttonText = 'Start Task';
        buttonColor = colorScheme.secondary;
        textColor = Colors.white;
        buttonIcon = Icons.play_arrow;
        onPressed = onStartTask;
        break;
      case TaskStatus.active:
      default:
        buttonText = 'Mark Complete';
        buttonColor = colorScheme.primary;
        textColor = Colors.white;
        buttonIcon = Icons.check_circle;
        onPressed = onMarkComplete;
        break;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: SizedBox(
        width: double.infinity,
        height: 6.h,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onPressed?.call();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: textColor,
            elevation: taskStatus == TaskStatus.active ? 4 : 0,
            shadowColor: buttonColor.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          ),
          child: isLoading
              ? SizedBox(
                  width: 5.w,
                  height: 5.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: buttonIcon.codePoint.toString(),
                      color: textColor,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      buttonText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
