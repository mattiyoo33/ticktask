import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/batch_actions_toolbar_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/search_filter_bar_widget.dart';
import './widgets/task_section_widget.dart';

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
  List<Map<String, dynamic>> get _allTasks {
    final tasksAsync = ref.watch(allTasksProvider);
    return tasksAsync.when(
      data: (tasks) => tasks.map((task) {
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
          'difficulty': task['difficulty'] ?? 'Medium',
          'status': status,
          'isRecurring': task['is_recurring'] ?? false,
          'xpReward': task['xp_reward'] ?? 10,
          'category': task['category'] ?? '',
          'createdAt': createdAt,
        };
      }).toList(),
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
      default:
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

    // Refresh all providers
    ref.invalidate(allTasksProvider);
    ref.invalidate(todaysTasksProvider);
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

  void _handleTaskTap(Map<String, dynamic> task) {
    Navigator.pushNamed(context, '/task-detail-screen', arguments: task);
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
      for (final task in selectedTasks) {
        final taskId = task['id'].toString();
        await taskService.completeTask(taskId);
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

      final totalXP = selectedTasks.fold<int>(
          0, (sum, task) => sum + (task['xpReward'] as int? ?? 0));

      Fluttertoast.showToast(
        msg: "${selectedTasks.length} tasks completed! +$totalXP XP earned 🎉",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      _confettiController.forward().then((_) {
        _confettiController.reset();
      });
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
            child: hasAnyTasks
                ? RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: colorScheme.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
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
                      ),
                    ),
                  )
                : EmptyStateWidget(
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
                    mascotImageUrl:
                        'https://images.pexels.com/photos/1181671/pexels-photo-1181671.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 2),
      floatingActionButton: !_isMultiSelectMode
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/task-creation-screen');
                HapticFeedback.lightImpact();
              },
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
