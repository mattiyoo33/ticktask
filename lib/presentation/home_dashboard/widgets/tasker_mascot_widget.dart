import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

enum MascotState {
  greeting,
  encouraging,
  celebrating,
  waiting,
}

class TaskerMascotWidget extends StatefulWidget {
  final MascotState state;
  final String? message;

  const TaskerMascotWidget({
    super.key,
    this.state = MascotState.greeting,
    this.message,
  });

  @override
  State<TaskerMascotWidget> createState() => _TaskerMascotWidgetState();
}

class _TaskerMascotWidgetState extends State<TaskerMascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getMascotMessage() {
    if (widget.message != null) return widget.message!;

    switch (widget.state) {
      case MascotState.greeting:
        return "Ready to tackle today's tasks?";
      case MascotState.encouraging:
        return "You're doing great! Keep it up!";
      case MascotState.celebrating:
        return "Awesome work! You're on fire! 🔥";
      case MascotState.waiting:
        return "I'm here when you need me!";
    }
  }

  Color _getMascotColor() {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.state) {
      case MascotState.greeting:
        return colorScheme.primary;
      case MascotState.encouraging:
        return colorScheme.secondary;
      case MascotState.celebrating:
        return AppTheme.successLight;
      case MascotState.waiting:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Container(
                    width: 16.w,
                    height: 16.w,
                    decoration: BoxDecoration(
                      color: _getMascotColor().withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: widget.state == MascotState.celebrating
                            ? 'emoji_emotions'
                            : 'smart_toy',
                        color: _getMascotColor(),
                        size: 8.w,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasker',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _getMascotColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _getMascotMessage(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
