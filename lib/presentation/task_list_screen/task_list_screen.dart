import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../utils/avatar_utils.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/batch_actions_toolbar_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/search_filter_bar_widget.dart';
import './widgets/task_section_widget.dart';
import '../discover_screen/widgets/task_type_choice_modal.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen>
    with TickerProviderStateMixin {
  String _searchQuery = '';
  TaskFilter _currentFilter = TaskFilter.all;
  TaskSort _currentSort = TaskSort.dueDate;
  bool _isMultiSelectMode = false;
  Set<String> _selectedTaskIds = {};
  bool _isRefreshing = false;
  late AnimationController _confettiController;

  // Get all tasks from database
  // Using ref.watch ensures automatic rebuild when provider changes
  List<Map<String, dynamic>> get _allTasks {
    final tasksAsync = ref.watch(allTasksProvider);
    return tasksAsync.when(
      data: (tasks) {
        debugPrint('📊 _allTasks: Received ${tasks.length} tasks from provider');
        return tasks.map((task) {
        final dueDate = task['due_date'] != null 
            ? DateTime.parse(task['due_date'] as String)
            : null;
        final createdAt = task['created_at'] != null
            ? DateTime.parse(task['created_at'] as String)
            : DateTime.now();
        
        // Determine status
        String status = task['status'] as String? ?? 'active';
        if (status == 'active' && dueDate != null && dueDate.isBefore(DateTime.now())) {
          status = 'overdue';
        }
        
        return {
          'id': task['id'].toString(),
          'title': task['title'] ?? '',
          'description': task['description'] ?? '',
          'dueDate': dueDate,
          'due_date': task['due_date'], // Keep original for compatibility
          'difficulty': task['difficulty'] ?? 'Medium',
          'status': status,
          'isRecurring': task['is_recurring'] ?? false,
          'is_collaborative': task['is_collaborative'] ?? false, // CRITICAL: Include collaborative flag
          'is_public': task['is_public'] ?? false, // Include public flag
          'xpReward': task['xp_reward'] ?? 10,
          'category': task['category'] ?? '',
          'createdAt': createdAt,
        };
        }).toList();
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Refresh pending invitations when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh on first build, not every time dependencies change
    // We'll use a different approach for navigation-based refresh
  }

  void _refreshAllData() {
    debugPrint('🔄 Refreshing all task data...');
    ref.invalidate(allTasksProvider);
    ref.invalidate(todaysTasksProvider);
    ref.invalidate(pendingCollaborationTasksProvider);
    ref.invalidate(recentActivitiesProvider);
    debugPrint('✅ All providers invalidated');
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredTasks {
    List<Map<String, dynamic>> filtered = List.from(_allTasks);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        final title = (task['title'] ?? '').toLowerCase();
        final description = (task['description'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }

    // Apply status/difficulty filter
    switch (_currentFilter) {
      case TaskFilter.active:
        filtered =
            filtered.where((task) => task['status'] == 'active').toList();
        break;
      case TaskFilter.completed:
        filtered =
            filtered.where((task) => task['status'] == 'completed').toList();
        break;
      case TaskFilter.easy:
        filtered =
            filtered.where((task) => task['difficulty'] == 'Easy').toList();
        break;
      case TaskFilter.medium:
        filtered =
            filtered.where((task) => task['difficulty'] == 'Medium').toList();
        break;
      case TaskFilter.hard:
        filtered =
            filtered.where((task) => task['difficulty'] == 'Hard').toList();
        break;
      case TaskFilter.all:
        break;
    }

    // Apply sorting
    switch (_currentSort) {
      case TaskSort.dueDate:
        filtered.sort((a, b) {
          final aDate = a['dueDate'] as DateTime?;
          final bDate = b['dueDate'] as DateTime?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });
        break;
      case TaskSort.difficulty:
        filtered.sort((a, b) {
          const difficultyOrder = {'Easy': 1, 'Medium': 2, 'Hard': 3};
          final aDiff = difficultyOrder[a['difficulty']] ?? 0;
          final bDiff = difficultyOrder[b['difficulty']] ?? 0;
          return bDiff.compareTo(aDiff);
        });
        break;
      case TaskSort.creationDate:
        filtered.sort((a, b) {
          final aDate = a['createdAt'] as DateTime?;
          final bDate = b['createdAt'] as DateTime?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
        break;
      case TaskSort.priority:
        // Sort by combination of due date and difficulty
        filtered.sort((a, b) {
          final aDate = a['dueDate'] as DateTime?;
          final bDate = b['dueDate'] as DateTime?;
          if (aDate != null && bDate != null) {
            final dateComparison = aDate.compareTo(bDate);
            if (dateComparison != 0) return dateComparison;
          }
          const difficultyOrder = {'Easy': 1, 'Medium': 2, 'Hard': 3};
          final aDiff = difficultyOrder[a['difficulty']] ?? 0;
          final bDiff = difficultyOrder[b['difficulty']] ?? 0;
          return bDiff.compareTo(aDiff);
        });
        break;
    }

    return filtered;
  }

  Map<String, List<Map<String, dynamic>>> get _groupedTasks {
    final filtered = _filteredTasks;
    final Map<String, List<Map<String, dynamic>>> grouped = {
      'overdue': [],
      'today': [],
      'tomorrow': [],
      'thisWeek': [],
      'later': [],
      'completed': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    for (final task in filtered) {
      final status = task['status'] as String?;

      if (status == 'completed') {
        grouped['completed']!.add(task);
        continue;
      }

      final dueDate = task['dueDate'] as DateTime?;
      if (dueDate == null) {
        grouped['later']!.add(task);
        continue;
      }

      final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

      if (status == 'overdue' || taskDate.isBefore(today)) {
        grouped['overdue']!.add(task);
      } else if (taskDate.isAtSameMomentAs(today)) {
        grouped['today']!.add(task);
      } else if (taskDate.isAtSameMomentAs(tomorrow)) {
        grouped['tomorrow']!.add(task);
      } else if (taskDate.isBefore(nextWeek)) {
        grouped['thisWeek']!.add(task);
      } else {
        grouped['later']!.add(task);
      }
    }

    return grouped;
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();

    // Refresh all providers including pending invitations
    ref.invalidate(allTasksProvider);
    ref.invalidate(todaysTasksProvider);
    ref.invalidate(pendingCollaborationTasksProvider);
    ref.invalidate(recentActivitiesProvider);
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() => _isRefreshing = false);

    Fluttertoast.showToast(
      msg: "Tasks refreshed successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleTaskComplete(Map<String, dynamic> task) {
    setState(() {
      final index = _allTasks.indexWhere((t) => t['id'] == task['id']);
      if (index != -1) {
        _allTasks[index]['status'] = 'completed';
      }
    });

    // Show confetti animation
    _confettiController.forward().then((_) {
      _confettiController.reset();
    });

    final xpReward = task['xpReward'] ?? 0;
    Fluttertoast.showToast(
      msg: "Task completed! +$xpReward XP earned 🎉",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    HapticFeedback.heavyImpact();
  }

  void _handleTaskEdit(Map<String, dynamic> task) {
    Navigator.pushNamed(context, '/task-creation-screen', arguments: task);
  }

  void _handleTaskDelete(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final taskService = ref.read(taskServiceProvider);
                final taskId = task['id'].toString();
                await taskService.deleteTask(taskId);
                
                // Refresh data
                ref.invalidate(allTasksProvider);
                ref.invalidate(todaysTasksProvider);
                
              Fluttertoast.showToast(
                msg: "Task deleted",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
              HapticFeedback.heavyImpact();
              } catch (e) {
                Fluttertoast.showToast(
                  msg: "Error deleting task: ${e.toString()}",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleTaskShare(Map<String, dynamic> task) {
    Fluttertoast.showToast(
      msg: "Sharing: ${task['title']}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
    HapticFeedback.lightImpact();
  }

  void _handleTaskTap(Map<String, dynamic> task) async {
    // Navigate to task detail and wait for result
    final result = await Navigator.pushNamed(
      context, 
      '/task-detail-screen', 
      arguments: task,
    );
    
    // If task was deleted or left, refresh the list
    if (result == true || result == 'deleted' || result == 'left') {
      debugPrint('🔄 Task was deleted or left, refreshing list...');
      _refreshAllData();
      // Wait for providers to refresh
      try {
        await ref.read(allTasksProvider.future);
        debugPrint('✅ Task list refreshed');
        
        // Show success message on task list screen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result == 'deleted' 
                  ? '✅ Task deleted. Removed from your list.'
                  : '✅ Left task. Removed from your list.',
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('⚠️ Error refreshing task list: $e');
      }
    }
  }

  bool get _hasPendingInvitations {
    final pendingTasksAsync = ref.watch(pendingCollaborationTasksProvider);
    return pendingTasksAsync.when(
      data: (tasks) => tasks.isNotEmpty,
      loading: () => false,
      error: (_, __) => false,
    );
  }

  Widget _buildPendingInvitationsSection(BuildContext context) {
    print('🔍 _buildPendingInvitationsSection: Building invitations section');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pendingTasksAsync = ref.watch(pendingCollaborationTasksProvider);
    print('🔍 _buildPendingInvitationsSection: Watching provider, state: ${pendingTasksAsync.runtimeType}');

    return pendingTasksAsync.when(
      data: (pendingTasks) {
        // Debug: Print pending tasks with more details
        print('📊 UI: Pending tasks count: ${pendingTasks.length}');
        if (pendingTasks.isNotEmpty) {
          print('📋 UI: Pending task titles: ${pendingTasks.map((t) => t['title']).toList()}');
          print('📋 UI: Pending task IDs: ${pendingTasks.map((t) => t['id']).toList()}');
        } else {
          print('⚠️ UI: No pending tasks to display');
          print('💡 Check console logs above for fetch details');
        }
        
        if (pendingTasks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'group',
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Collaboration Invitations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              ...pendingTasks.map((task) => _buildPendingInvitationItem(context, task)),
            ],
          ),
        );
      },
      loading: () {
        print('⏳ UI: Pending invitations loading...');
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 3.w),
              Text(
                'Loading invitations...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
      error: (error, stack) {
        print('❌ Error loading pending invitations: $error');
        print('📚 Stack trace: $stack');
        // Show error state for debugging with more details
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.error.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Error loading invitations',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                'Check console logs for details. Common issues:\n'
                '• RLS policy missing (run FIX_COLLABORATIVE_TASKS_RLS.sql)\n'
                '• Status column missing (run ADD_PARTICIPANT_STATUS.sql)\n'
                '• User not authenticated',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error.withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingInvitationItem(BuildContext context, Map<String, dynamic> task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final taskId = task['id'] as String? ?? '';
    final title = task['title'] as String? ?? 'Untitled Task';
    final description = task['description'] as String? ?? '';
    
    // Handle profiles - could be Map or List
    Map<String, dynamic>? owner;
    if (task['profiles'] != null) {
      if (task['profiles'] is List && (task['profiles'] as List).isNotEmpty) {
        owner = (task['profiles'] as List)[0] as Map<String, dynamic>?;
      } else if (task['profiles'] is Map) {
        owner = task['profiles'] as Map<String, dynamic>?;
      }
    }
    
    final ownerName = owner?['full_name'] as String? ?? 
                      owner?['email']?.toString().split('@')[0] ?? 
                      'Unknown User';
    final ownerAvatar = owner?['avatar_url'] as String? ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: AvatarUtils.getAvatarIcon(ownerAvatar),
                    color: colorScheme.primary,
                    size: 6.w,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              // Accept/Refuse buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'check',
                      color: AppTheme.successLight,
                      size: 5.w,
                    ),
                    onPressed: () => _handleAcceptInvitation(taskId),
                    tooltip: 'Accept',
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.errorLight,
                      size: 5.w,
                    ),
                    onPressed: () => _handleRefuseInvitation(taskId),
                    tooltip: 'Refuse',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAcceptInvitation(String taskId) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.acceptCollaborationInvitation(taskId);
      
      debugPrint('✅ Invitation accepted for task $taskId');
      
      // Invalidate providers to trigger refresh
      ref.invalidate(pendingCollaborationTasksProvider);
      ref.invalidate(allTasksProvider);
      ref.invalidate(todaysTasksProvider);
      
      // Force a full refresh using the refresh handler
      // This ensures all data is reloaded and UI is updated
      await _handleRefresh();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Collaboration invitation accepted! Task added to your list.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint('❌ Error accepting invitation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting invitation: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showTaskTypeChoice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
      ),
      builder: (context) => TaskTypeChoiceModal(
        onPrivateSelected: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/task-creation-screen', arguments: {'isPublic': false});
        },
        onPublicSelected: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/task-creation-screen', arguments: {'isPublic': true});
        },
      ),
    );
  }

  Future<void> _handleRefuseInvitation(String taskId) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.refuseCollaborationInvitation(taskId);
      
      // Refresh providers
      ref.invalidate(pendingCollaborationTasksProvider);
      
      // Force rebuild
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collaboration invitation refused'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refusing invitation: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleTaskSelectionChanged(String taskId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedTaskIds.add(taskId);
        if (!_isMultiSelectMode) {
          _isMultiSelectMode = true;
        }
      } else {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      }
    });
  }

  void _handleSelectAll() {
    setState(() {
      _selectedTaskIds =
          _filteredTasks.map((task) => task['id'].toString()).toSet();
    });
  }

  void _handleDeselectAll() {
    setState(() {
      _selectedTaskIds.clear();
      _isMultiSelectMode = false;
    });
  }

  Future<void> _handleCompleteSelected() async {
    final selectedTasks = _allTasks
        .where((task) => _selectedTaskIds.contains(task['id'].toString()))
        .toList();

    try {
      final taskService = ref.read(taskServiceProvider);
      int totalXpAwarded = 0;
      int tasksCompletedOnTime = 0;
      int tasksCompletedLate = 0;

      for (final task in selectedTasks) {
        final taskId = task['id'].toString();
        final completionResult = await taskService.completeTask(taskId);
        
        final xpAwarded = completionResult['xp_awarded'] as bool? ?? false;
        final xpGained = completionResult['xp_gained'] as int? ?? 0;
        
        totalXpAwarded += xpGained;
        if (xpAwarded) {
          tasksCompletedOnTime++;
        } else {
          tasksCompletedLate++;
        }
      }
      
      // Refresh data
      ref.invalidate(allTasksProvider);
      ref.invalidate(todaysTasksProvider);
      ref.invalidate(recentActivitiesProvider);
      ref.invalidate(userProfileFromDbProvider);
      
      setState(() {
      _selectedTaskIds.clear();
      _isMultiSelectMode = false;
    });

      String message;
      if (tasksCompletedLate > 0 && tasksCompletedOnTime > 0) {
        message = "$tasksCompletedOnTime tasks completed on time (+$totalXpAwarded XP), $tasksCompletedLate completed late (no XP)";
      } else if (tasksCompletedLate > 0) {
        message = "${selectedTasks.length} tasks completed late - no XP awarded";
      } else {
        message = "${selectedTasks.length} tasks completed! +$totalXpAwarded XP earned 🎉";
    _confettiController.forward().then((_) {
      _confettiController.reset();
    });
  }

      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error completing tasks: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _handleDeleteSelected() async {
    try {
      final taskService = ref.read(taskServiceProvider);
      for (final taskId in _selectedTaskIds) {
        await taskService.deleteTask(taskId);
      }
      
      // Refresh data
      ref.invalidate(allTasksProvider);
      ref.invalidate(todaysTasksProvider);
      
    setState(() {
      _selectedTaskIds.clear();
      _isMultiSelectMode = false;
    });

    Fluttertoast.showToast(
      msg: "Selected tasks deleted",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error deleting tasks: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _handleShareSelected() {
    final selectedCount = _selectedTaskIds.length;
    Fluttertoast.showToast(
      msg: "Sharing $selectedCount selected tasks",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    setState(() {
      _selectedTaskIds.clear();
      _isMultiSelectMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groupedTasks = _groupedTasks;
    final hasAnyTasks = _filteredTasks.isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'My Tasks',
        variant: CustomAppBarVariant.standard,
        centerTitle: false,
        actions: [
          if (!_isMultiSelectMode)
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/task-creation-screen');
                HapticFeedback.lightImpact();
              },
              icon: CustomIconWidget(
                iconName: 'add',
                color: colorScheme.onSurface,
                size: 24,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          if (!_isMultiSelectMode)
            SearchFilterBarWidget(
              searchQuery: _searchQuery,
              currentFilter: _currentFilter,
              currentSort: _currentSort,
              onSearchChanged: (query) => setState(() => _searchQuery = query),
              onFilterChanged: (filter) =>
                  setState(() => _currentFilter = filter),
              onSortChanged: (sort) => setState(() => _currentSort = sort),
              onClearSearch: () => setState(() => _searchQuery = ''),
            ),

          // Batch Actions Toolbar
          if (_isMultiSelectMode)
            BatchActionsToolbarWidget(
              selectedCount: _selectedTaskIds.length,
              onSelectAll: _handleSelectAll,
              onDeselectAll: _handleDeselectAll,
              onCompleteSelected: _handleCompleteSelected,
              onDeleteSelected: _handleDeleteSelected,
              onShareSelected: _handleShareSelected,
              onCancel: () => setState(() {
                _selectedTaskIds.clear();
                _isMultiSelectMode = false;
              }),
            ),

          // Task List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Pending Collaboration Invitations (ALWAYS show, even if user has no tasks)
                    _buildPendingInvitationsSection(context),
                    
                    // Divider between invitations and tasks
                    if (_hasPendingInvitations) ...[
                      Divider(
                        height: 4.h,
                        thickness: 2,
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        indent: 4.w,
                        endIndent: 4.w,
                      ),
                    ],
                    
                    // Tasks (only show if user has tasks)
                    if (hasAnyTasks) ...[
                      // Overdue Tasks
                      TaskSectionWidget(
                        title: 'Overdue',
                        tasks: groupedTasks['overdue']!,
                        titleColor: colorScheme.error,
                        isMultiSelectMode: _isMultiSelectMode,
                        selectedTaskIds: _selectedTaskIds,
                        onTaskSelectionChanged: _handleTaskSelectionChanged,
                        onTaskTap: _handleTaskTap,
                        onTaskComplete: _handleTaskComplete,
                        onTaskEdit: _handleTaskEdit,
                        onTaskDelete: _handleTaskDelete,
                        onTaskShare: _handleTaskShare,
                      ),

                          // Today Tasks
                          TaskSectionWidget(
                            title: 'Today',
                            tasks: groupedTasks['today']!,
                            titleColor: colorScheme.primary,
                            isMultiSelectMode: _isMultiSelectMode,
                            selectedTaskIds: _selectedTaskIds,
                            onTaskSelectionChanged: _handleTaskSelectionChanged,
                            onTaskTap: _handleTaskTap,
                            onTaskComplete: _handleTaskComplete,
                            onTaskEdit: _handleTaskEdit,
                            onTaskDelete: _handleTaskDelete,
                            onTaskShare: _handleTaskShare,
                          ),

                          // Tomorrow Tasks
                          TaskSectionWidget(
                            title: 'Tomorrow',
                            tasks: groupedTasks['tomorrow']!,
                            isMultiSelectMode: _isMultiSelectMode,
                            selectedTaskIds: _selectedTaskIds,
                            onTaskSelectionChanged: _handleTaskSelectionChanged,
                            onTaskTap: _handleTaskTap,
                            onTaskComplete: _handleTaskComplete,
                            onTaskEdit: _handleTaskEdit,
                            onTaskDelete: _handleTaskDelete,
                            onTaskShare: _handleTaskShare,
                          ),

                          // This Week Tasks
                          TaskSectionWidget(
                            title: 'This Week',
                            tasks: groupedTasks['thisWeek']!,
                            isMultiSelectMode: _isMultiSelectMode,
                            selectedTaskIds: _selectedTaskIds,
                            onTaskSelectionChanged: _handleTaskSelectionChanged,
                            onTaskTap: _handleTaskTap,
                            onTaskComplete: _handleTaskComplete,
                            onTaskEdit: _handleTaskEdit,
                            onTaskDelete: _handleTaskDelete,
                            onTaskShare: _handleTaskShare,
                          ),

                          // Later Tasks
                          TaskSectionWidget(
                            title: 'Later',
                            tasks: groupedTasks['later']!,
                            isMultiSelectMode: _isMultiSelectMode,
                            selectedTaskIds: _selectedTaskIds,
                            onTaskSelectionChanged: _handleTaskSelectionChanged,
                            onTaskTap: _handleTaskTap,
                            onTaskComplete: _handleTaskComplete,
                            onTaskEdit: _handleTaskEdit,
                            onTaskDelete: _handleTaskDelete,
                            onTaskShare: _handleTaskShare,
                          ),

                          // Completed Tasks
                          if (_currentFilter == TaskFilter.all ||
                              _currentFilter == TaskFilter.completed)
                            TaskSectionWidget(
                              title: 'Completed',
                              tasks: groupedTasks['completed']!,
                              titleColor: colorScheme.secondary,
                              isMultiSelectMode: _isMultiSelectMode,
                              selectedTaskIds: _selectedTaskIds,
                              onTaskSelectionChanged:
                                  _handleTaskSelectionChanged,
                              onTaskTap: _handleTaskTap,
                              onTaskComplete: _handleTaskComplete,
                              onTaskEdit: _handleTaskEdit,
                              onTaskDelete: _handleTaskDelete,
                              onTaskShare: _handleTaskShare,
                            ),

                        SizedBox(height: 10.h),
                      ],
                    // Show empty state only if no tasks and no invitations
                    if (!hasAnyTasks && !_hasPendingInvitations) ...[
                      EmptyStateWidget(
                        title: _searchQuery.isNotEmpty
                            ? 'No tasks found'
                            : 'No tasks yet',
                        subtitle: _searchQuery.isNotEmpty
                            ? 'Try adjusting your search or filters'
                            : 'Create your first task and start your productivity journey!',
                        buttonText: 'Create Your First Task',
                        onButtonPressed: () {
                          Navigator.pushNamed(context, '/task-creation-screen');
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 2),
      floatingActionButton: !_isMultiSelectMode
          ? FloatingActionButton(
              onPressed: () => _showTaskTypeChoice(context),
              child: CustomIconWidget(
                iconName: 'add',
                color: colorScheme.onPrimary,
                size: 24,
              ),
            )
          : null,
    );
  }
}
