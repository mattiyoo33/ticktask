import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/action_button_widget.dart';
import './widgets/celebration_overlay_widget.dart';
import './widgets/comments_section_widget.dart';
import './widgets/participants_widget.dart';
import './widgets/streak_progress_widget.dart';
import './widgets/task_header_widget.dart';
import './widgets/task_info_widget.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isLoading = false;
  bool _showCelebration = false;
  int _xpGained = 0;

  // Mock task data
  final Map<String, dynamic> _taskData = {
    "id": 1,
    "title": "Complete Flutter Project Documentation",
    "description":
        """Write comprehensive documentation for the TickTask Flutter application including:
    
• User guide with screenshots
• Developer setup instructions
• API documentation
• Testing procedures
• Deployment guidelines
    
This documentation will help new team members understand the project structure and contribute effectively.""",
    "dueDate": DateTime.now().add(Duration(days: 2, hours: 14, minutes: 30)),
    "difficulty": "Hard",
    "xpValue": 30,
    "createdDate": DateTime.now().subtract(Duration(days: 5)),
    "isRecurring": true,
    "frequency": "Weekly",
    "nextOccurrence": DateTime.now().add(Duration(days: 9)),
    "status": "active", // active, completed, scheduled
    "isCollaborative": true,
    "currentStreak": 5,
    "maxStreak": 12,
    "weekProgress": [true, true, false, true, true, false, false],
    "hasStreakBonus": true,
  };

  final List<Map<String, dynamic>> _participants = [
    {
      "id": 1,
      "name": "Sarah Johnson",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_11b715d60-1762273834012.png",
      "semanticLabel":
          "Professional headshot of a woman with shoulder-length brown hair wearing a navy blazer",
      "isCompleted": true,
      "contribution": 45,
    },
    {
      "id": 2,
      "name": "Michael Chen",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_18044ba5a-1762273641333.png",
      "semanticLabel":
          "Professional headshot of an Asian man with short black hair wearing a gray suit",
      "isCompleted": false,
      "contribution": 30,
    },
    {
      "id": 3,
      "name": "Emily Rodriguez",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1beb9fc75-1762273370028.png",
      "semanticLabel":
          "Professional headshot of a Hispanic woman with long dark hair wearing a white blouse",
      "isCompleted": true,
      "contribution": 25,
    },
  ];

  final List<Map<String, dynamic>> _comments = [
    {
      "id": 1,
      "author": "Sarah Johnson",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_11b715d60-1762273834012.png",
      "semanticLabel":
          "Professional headshot of a woman with shoulder-length brown hair wearing a navy blazer",
      "content":
          "I've completed the user guide section with screenshots. The API documentation is next on my list.",
      "timestamp": DateTime.now().subtract(Duration(hours: 2)),
    },
    {
      "id": 2,
      "author": "Michael Chen",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_18044ba5a-1762273641333.png",
      "semanticLabel":
          "Professional headshot of an Asian man with short black hair wearing a gray suit",
      "content":
          "Great work Sarah! I'm working on the developer setup instructions. Should have it ready by tomorrow.",
      "timestamp": DateTime.now().subtract(Duration(hours: 1, minutes: 30)),
    },
    {
      "id": 3,
      "author": "Emily Rodriguez",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1beb9fc75-1762273370028.png",
      "semanticLabel":
          "Professional headshot of a Hispanic woman with long dark hair wearing a white blouse",
      "content":
          "I can handle the testing procedures section. Let me know if you need any specific test cases documented.",
      "timestamp": DateTime.now().subtract(Duration(minutes: 45)),
    },
  ];

  TaskStatus get _currentTaskStatus {
    switch (_taskData['status'] as String) {
      case 'completed':
        return TaskStatus.completed;
      case 'scheduled':
        return TaskStatus.scheduled;
      case 'active':
      default:
        return TaskStatus.active;
    }
  }

  void _handleEdit() {
    // Navigate to edit mode or show edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit functionality would open here'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleMore() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMoreOptionsSheet(),
    );
  }

  Widget _buildMoreOptionsSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.only(top: 2.h),
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            _buildOptionTile(
              icon: 'share',
              title: 'Share Task',
              onTap: () {
                Navigator.pop(context);
                _shareTask();
              },
            ),
            _buildOptionTile(
              icon: 'notifications',
              title: 'Set Reminder',
              onTap: () {
                Navigator.pop(context);
                _setReminder();
              },
            ),
            _buildOptionTile(
              icon: 'copy',
              title: 'Duplicate Task',
              onTap: () {
                Navigator.pop(context);
                _duplicateTask();
              },
            ),
            Divider(
                height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildOptionTile(
              icon: 'delete',
              title: 'Delete Task',
              onTap: () {
                Navigator.pop(context);
                _deleteTask();
              },
              isDestructive: true,
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: CustomIconWidget(
        iconName: icon,
        color: isDestructive ? Colors.red : colorScheme.onSurface,
        size: 24,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isDestructive ? Colors.red : colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
    );
  }

  void _shareTask() {
    final taskTitle = _taskData['title'] as String;
    final taskDescription = _taskData['description'] as String;
    final shareText = 'Check out this task: $taskTitle\n\n$taskDescription';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task shared: $shareText'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setReminder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder settings would open here'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _duplicateTask() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task duplicated successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Task'),
        content: Text(
            'Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Task deleted'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Task restored'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleMarkComplete() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(Duration(milliseconds: 800));

    setState(() {
      _isLoading = false;
      _taskData['status'] = 'completed';
      _xpGained = _taskData['xpValue'] as int;
      if (_taskData['hasStreakBonus'] as bool) {
        _xpGained += 25; // Streak bonus
      }
      _showCelebration = true;
    });
  }

  void _handleMarkIncomplete() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
      _taskData['status'] = 'active';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task marked as incomplete'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleStartTask() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
      _taskData['status'] = 'active';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task started!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleAddComment(String comment) {
    setState(() {
      _comments.insert(0, {
        "id": _comments.length + 1,
        "author": "You",
        "avatar": "",
        "semanticLabel": "Your avatar",
        "content": comment,
        "timestamp": DateTime.now(),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Comment added'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onCelebrationComplete() {
    setState(() {
      _showCelebration = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        variant: CustomAppBarVariant.minimal,
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              children: [
                // Task Header
                TaskHeaderWidget(
                  title: _taskData['title'] as String,
                  onEdit: _handleEdit,
                  onMore: _handleMore,
                ),

                SizedBox(height: 2.h),

                // Task Information
                TaskInfoWidget(
                  description: _taskData['description'] as String,
                  dueDate: _taskData['dueDate'] as DateTime,
                  difficulty: _taskData['difficulty'] as String,
                  xpValue: _taskData['xpValue'] as int,
                  createdDate: _taskData['createdDate'] as DateTime,
                  isRecurring: _taskData['isRecurring'] as bool,
                  frequency: _taskData['frequency'] as String?,
                  nextOccurrence: _taskData['nextOccurrence'] as DateTime?,
                ),

                // Streak Progress
                StreakProgressWidget(
                  currentStreak: _taskData['currentStreak'] as int,
                  maxStreak: _taskData['maxStreak'] as int,
                  weekProgress:
                      (_taskData['weekProgress'] as List).cast<bool>(),
                  hasStreakBonus: _taskData['hasStreakBonus'] as bool,
                ),

                // Participants (for collaborative tasks)
                ParticipantsWidget(
                  participants: _participants,
                  isCollaborative: _taskData['isCollaborative'] as bool,
                ),

                // Comments Section
                CommentsSectionWidget(
                  comments: _comments,
                  onAddComment: _handleAddComment,
                  isCollaborative: _taskData['isCollaborative'] as bool,
                ),

                SizedBox(height: 2.h),

                // Action Button
                ActionButtonWidget(
                  taskStatus: _currentTaskStatus,
                  onMarkComplete: _handleMarkComplete,
                  onMarkIncomplete: _handleMarkIncomplete,
                  onStartTask: _handleStartTask,
                  isLoading: _isLoading,
                ),

                SizedBox(height: 4.h),
              ],
            ),
          ),

          // Celebration Overlay
          CelebrationOverlayWidget(
            isVisible: _showCelebration,
            xpGained: _xpGained,
            onAnimationComplete: _onCelebrationComplete,
          ),
        ],
      ),
    );
  }
}
