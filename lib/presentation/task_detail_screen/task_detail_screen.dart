import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/action_button_widget.dart';
import './widgets/celebration_overlay_widget.dart';
import './widgets/comments_section_widget.dart';
import './widgets/participants_widget.dart';
import './widgets/select_friends_modal_widget.dart';
import './widgets/streak_progress_widget.dart';
import './widgets/task_header_widget.dart';
import './widgets/task_info_widget.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _isLoading = false;
  bool _showCelebration = false;
  int _xpGained = 0;
  bool _isInitialLoading = true;
  
  Map<String, dynamic>? _taskData;
  Map<String, dynamic>? _streakData;
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _comments = [];
  String? _taskId;
  RealtimeChannel? _commentsChannel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialLoading && _taskId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTaskData();
      });
    }
  }

  @override
  void dispose() {
    _commentsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadTaskData() async {
    // Get task from route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task not found')),
        );
      }
      return;
    }

    final taskArg = args as Map<String, dynamic>;
    _taskId = taskArg['id']?.toString();

    if (_taskId == null) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid task ID')),
        );
      }
      return;
    }

    setState(() {
      _isInitialLoading = true;
    });

    try {
      final taskService = ref.read(taskServiceProvider);
      
      // Fetch task data
      final task = await taskService.getTaskById(_taskId!);
      if (task == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task not found')),
          );
        }
        return;
      }

      // Fetch streak data
      final streak = await taskService.getTaskStreak(_taskId!);

      // Fetch participants (only if collaborative)
      List<Map<String, dynamic>> participants = [];
      if (task['is_collaborative'] == true) {
        participants = await taskService.getTaskParticipants(_taskId!);
      }

      // Fetch comments (only if collaborative)
      List<Map<String, dynamic>> comments = [];
      if (task['is_collaborative'] == true) {
        comments = await taskService.getTaskComments(_taskId!);
      }

      setState(() {
        _taskData = task;
        _streakData = streak;
        _participants = _transformParticipants(participants);
        _comments = _transformComments(comments);
        _isInitialLoading = false;
      });

      // Set up real-time comments subscription
      _setupRealtimeComments();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading task: ${e.toString()}')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _transformParticipants(List<Map<String, dynamic>> participants) {
    return participants.map((p) {
      final profile = p['profiles'] as Map<String, dynamic>?;
      return {
        'id': p['user_id'],
        'name': profile?['full_name'] ?? 'Unknown',
        'avatar': profile?['avatar_url'] ?? '',
        'semanticLabel': 'User avatar',
        'isCompleted': false, // TODO: Check if user completed the task
        'contribution': 0, // TODO: Calculate contribution
      };
    }).toList();
  }

  List<Map<String, dynamic>> _transformComments(List<Map<String, dynamic>> comments) {
    return comments.map((c) {
      final profile = c['profiles'] as Map<String, dynamic>?;
      return {
        'id': c['id'],
        'author': profile?['full_name'] ?? 'Unknown',
        'avatar': profile?['avatar_url'] ?? '',
        'semanticLabel': 'User avatar',
        'content': c['content'] ?? '',
        'timestamp': c['created_at'] != null 
            ? DateTime.parse(c['created_at'] as String)
            : DateTime.now(),
      };
    }).toList();
  }

  TaskStatus get _currentTaskStatus {
    if (_taskData == null) return TaskStatus.active;
    switch (_taskData!['status'] as String?) {
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
    if (_taskData == null) return;
    final taskTitle = _taskData!['title'] as String? ?? 'Untitled Task';
    final taskDescription = _taskData!['description'] as String? ?? '';
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

  void _deleteTask() async {
    if (_taskId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text(
            'Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final taskService = ref.read(taskServiceProvider);
                await taskService.deleteTask(_taskId!);
                
                // Refresh task lists
                ref.invalidate(allTasksProvider);
                ref.invalidate(todaysTasksProvider);
                
                if (mounted) {
                  Navigator.pop(context); // Go back to previous screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting task: ${e.toString()}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleMarkComplete() async {
    if (_taskId == null || _taskData == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.completeTask(_taskId!);
      
      final xpReward = _taskData!['xp_reward'] as int? ?? 0;
      final streakBonus = _streakData?['has_streak_bonus'] == true ? 25 : 0;
      
      // Refresh task data
      await _loadTaskData();
      
      // Refresh task lists
      ref.invalidate(allTasksProvider);
      ref.invalidate(todaysTasksProvider);
      
      setState(() {
        _isLoading = false;
        _xpGained = xpReward + streakBonus;
        _showCelebration = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing task: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleMarkIncomplete() async {
    if (_taskId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.updateTask(_taskId!, status: 'active');
      
      // Refresh task data
      await _loadTaskData();
      
      // Refresh task lists
      ref.invalidate(allTasksProvider);
      ref.invalidate(todaysTasksProvider);
      
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task marked as incomplete'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleStartTask() async {
    if (_taskId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.updateTask(_taskId!, status: 'active');
      
      // Refresh task data
      await _loadTaskData();
      
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task started!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting task: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _setupRealtimeComments() {
    if (_taskId == null) return;

    // Unsubscribe from previous channel if exists
    _commentsChannel?.unsubscribe();

    // Subscribe to real-time comments
    _commentsChannel = SupabaseService.client
        .channel('task_comments_$_taskId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'task_comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'task_id',
            value: _taskId,
          ),
          callback: (payload) {
            // Reload comments when a new one is added
            _loadComments();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'task_comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'task_id',
            value: _taskId,
          ),
          callback: (payload) {
            _loadComments();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'task_comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'task_id',
            value: _taskId,
          ),
          callback: (payload) {
            _loadComments();
          },
        )
        .subscribe();
  }

  Future<void> _loadComments() async {
    if (_taskId == null) return;

    try {
      final taskService = ref.read(taskServiceProvider);
      final comments = await taskService.getTaskComments(_taskId!);
      
      if (mounted) {
        setState(() {
          _comments = _transformComments(comments);
        });
      }
    } catch (e) {
      // Silently fail for real-time updates
      debugPrint('Error loading comments: $e');
    }
  }

  void _handleAddComment(String comment) async {
    if (_taskId == null) return;

    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.addComment(_taskId!, comment);
      
      // Real-time subscription will update the UI automatically
      // But we can also manually refresh for immediate feedback
      await _loadComments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding comment: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleSelectFriends() {
    if (_taskId == null) return;

    final currentParticipantIds = _participants
        .map((p) => p['id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectFriendsModalWidget(
        taskId: _taskId!,
        currentParticipantIds: currentParticipantIds,
      ),
    ).then((_) {
      // Reload task data after friend selection
      _loadTaskData();
    });
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

    if (_isInitialLoading || _taskData == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: CustomAppBar(
          variant: CustomAppBarVariant.minimal,
          showBackButton: true,
          onBackPressed: () => Navigator.pop(context),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Parse dates from database
    final dueDate = _taskData!['due_date'] != null
        ? DateTime.parse(_taskData!['due_date'] as String)
        : null;
    final createdDate = _taskData!['created_at'] != null
        ? DateTime.parse(_taskData!['created_at'] as String)
        : DateTime.now();
    final nextOccurrence = _taskData!['next_occurrence'] != null
        ? DateTime.parse(_taskData!['next_occurrence'] as String)
        : null;

    // Get streak data (default to 0 if no streak exists)
    final currentStreak = _streakData?['current_streak'] as int? ?? 0;
    final maxStreak = _streakData?['max_streak'] as int? ?? 0;
    final weekProgress = _streakData?['week_progress'] as List<dynamic>?;
    final weekProgressList = weekProgress != null
        ? weekProgress.cast<bool>()
        : List<bool>.filled(7, false);
    final hasStreakBonus = _streakData?['has_streak_bonus'] == true;

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
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Task Header
                TaskHeaderWidget(
                  title: _taskData!['title'] as String? ?? 'Untitled Task',
                  onEdit: _handleEdit,
                  onMore: _handleMore,
                ),

                SizedBox(height: 2.h),

                // Task Information
                TaskInfoWidget(
                  description: _taskData!['description'] as String? ?? '',
                  dueDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
                  difficulty: _taskData!['difficulty'] as String? ?? 'Medium',
                  xpValue: _taskData!['xp_reward'] as int? ?? 0,
                  createdDate: createdDate,
                  isRecurring: _taskData!['is_recurring'] == true,
                  frequency: _taskData!['recurrence_frequency'] as String?,
                  nextOccurrence: nextOccurrence,
                ),

                // Streak Progress (only show if streak exists)
                if (currentStreak > 0 || maxStreak > 0)
                  StreakProgressWidget(
                    currentStreak: currentStreak,
                    maxStreak: maxStreak,
                    weekProgress: weekProgressList,
                    hasStreakBonus: hasStreakBonus,
                  ),

                // Participants (always show, with option to add friends)
                ParticipantsWidget(
                  participants: _participants,
                  isCollaborative: _taskData!['is_collaborative'] == true,
                  onSelectFriends: _handleSelectFriends,
                ),

                // Comments Section
                CommentsSectionWidget(
                  comments: _comments,
                  onAddComment: _handleAddComment,
                  isCollaborative: _taskData!['is_collaborative'] == true,
                  hasParticipants: _participants.isNotEmpty,
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
