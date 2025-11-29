import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/current_streaks_widget.dart';
import './widgets/greeting_header_widget.dart';
import './widgets/quick_actions_widget.dart';
import './widgets/recent_activity_widget.dart';
import './widgets/tasker_mascot_widget.dart';
import './widgets/todays_tasks_widget.dart';
import './widgets/pixel_art_animation_widget.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;

  Map<String, dynamic> get _userData {
    final userProfileAsync = ref.watch(userProfileFromDbProvider);
    final userProfile = userProfileAsync.value;
    final currentUser = ref.watch(currentUserProvider);
    
    if (userProfile == null && currentUser == null) {
      // Fallback if no user data
      return {
        "id": null,
        "name": "User",
        "avatar": "",
        "level": 1,
        "currentXP": 0,
        "nextLevelXP": 100,
      };
    }

    // Extract name from user profile (from database) or auth metadata
    final fullName = userProfile?['full_name'] as String?;
    final email = userProfile?['email'] as String? ?? currentUser?.email;
    final name = fullName ?? email?.split('@')[0] ?? 'User';
    
    return {
      "id": userProfile?['id'] ?? currentUser?.id,
      "name": name,
      "avatar": userProfile?['avatar_url'] ?? "",
      "level": userProfile?['level'] as int? ?? 1,
      "currentXP": userProfile?['current_xp'] as int? ?? 0,
      "nextLevelXP": _calculateNextLevelXP(userProfile?['level'] as int? ?? 1),
    };
  }

  int _calculateNextLevelXP(int level) {
    // Simple XP calculation: 100 * level^1.5
    return (100 * (level * level * 1.5)).round();
  }

  // Get today's tasks from database
  List<Map<String, dynamic>> get _todaysTasks {
    final tasksAsync = ref.watch(todaysTasksProvider);
    return tasksAsync.when(
      data: (tasks) => tasks.map((task) => {
        'id': task['id'],
        'title': task['title'] ?? '',
        'description': task['description'] ?? '',
        'difficulty': (task['difficulty'] as String?)?.toLowerCase() ?? 'medium',
        'dueTime': task['due_time'] ?? '',
        'isCompleted': task['status'] == 'completed',
        'xpReward': task['xp_reward'] ?? 10,
      }).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  // Get current streaks from database (tasks with recurring streaks)
  List<Map<String, dynamic>> get _currentStreaks {
    final tasksAsync = ref.watch(allTasksProvider);
    return tasksAsync.when(
      data: (tasks) {
        // Filter recurring tasks and get their streak data
        final recurringTasks = tasks.where((task) => 
          task['is_recurring'] == true && task['status'] == 'active'
        ).toList();
        
        // For now, return empty - streaks will be populated when tasks are completed
        // TODO: Fetch actual streak data from task_streaks table
        return [];
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  // Get recent activities from database
  List<Map<String, dynamic>> get _recentActivity {
    final activitiesAsync = ref.watch(recentActivitiesProvider);
    return activitiesAsync.when(
      data: (activities) => activities.map((activity) => {
        'id': activity['id'],
        'type': activity['type'],
        'userName': activity['userName'] ?? 'User',
        'userAvatar': activity['userAvatar'] ?? '',
        'message': activity['message'] ?? '',
        'timestamp': activity['timestamp'] ?? DateTime.now(),
        'xpGained': activity['xpGained'],
      }).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1500));
  }

  void _onTaskComplete(Map<String, dynamic> task) {
    HapticFeedback.mediumImpact();
    _confettiController.forward().then((_) => _confettiController.reset());

    setState(() {
      final taskIndex = _todaysTasks.indexWhere((t) => t['id'] == task['id']);
      if (taskIndex != -1) {
        _todaysTasks[taskIndex]['isCompleted'] = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task completed! +${task['xpReward']} XP earned'),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onTaskEdit(Map<String, dynamic> task) {
    Navigator.pushNamed(context, '/task-detail-screen', arguments: task);
  }

  Future<void> _onTaskDelete(Map<String, dynamic> task) async {
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
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final taskService = ref.read(taskServiceProvider);
                final taskId = task['id'] as String;
                await taskService.deleteTask(taskId);
                
                // Refresh data
                ref.invalidate(todaysTasksProvider);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting task: ${e.toString()}'),
                      backgroundColor: AppTheme.errorLight,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _onStreakTap(Map<String, dynamic> streak) {
    Navigator.pushNamed(context, '/task-detail-screen', arguments: streak);
  }

  void _onActivityTap(Map<String, dynamic> activity) {
    // Handle activity tap - could navigate to user profile or task details
  }

  MascotState _getMascotState() {
    final tasks = _todaysTasks;
    final completedTasks = tasks.where((task) => task['isCompleted'] == true).length;
    final totalTasks = tasks.length;

    if (completedTasks == totalTasks && totalTasks > 0) {
      return MascotState.celebrating;
    } else if (completedTasks > totalTasks / 2 && totalTasks > 0) {
      return MascotState.encouraging;
    } else {
      return MascotState.greeting;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: 2.h),
                    GreetingHeaderWidget(
                      userName: _userData['name'] as String? ?? 'User',
                      userAvatar: _userData['avatar'] as String? ?? '',
                      currentLevel: _userData['level'] as int? ?? 1,
                      currentXP: _userData['currentXP'] as int? ?? 0,
                      nextLevelXP: _userData['nextLevelXP'] as int? ?? 100,
                    ),
                    SizedBox(height: 2.h),
                    TaskerMascotWidget(
                      state: _getMascotState(),
                    ),
                    SizedBox(height: 2.h),
                    // Pixel art animation based on active tasks
                    PixelArtAnimationWidget(
                      activeTasks: _todaysTasks.where((task) => task['isCompleted'] == false).toList(),
                      aiService: AIService(),
                    ),
                    SizedBox(height: 2.h),
                    TodaysTasksWidget(
                      tasks: _todaysTasks,
                      onTaskComplete: _onTaskComplete,
                      onTaskEdit: _onTaskEdit,
                      onTaskDelete: _onTaskDelete,
                    ),
                    SizedBox(height: 2.h),
                    CurrentStreaksWidget(
                      streaks: _currentStreaks,
                      onStreakTap: _onStreakTap,
                    ),
                    SizedBox(height: 2.h),
                    RecentActivityWidget(
                      activities: _recentActivity,
                      onActivityTap: _onActivityTap,
                    ),
                    SizedBox(height: 2.h),
                    QuickActionsWidget(
                      onCreateTask: () =>
                          Navigator.pushNamed(context, '/task-creation-screen'),
                      onViewAllTasks: () =>
                          Navigator.pushNamed(context, '/task-list-screen'),
                      onInviteFriends: () =>
                          Navigator.pushNamed(context, '/friends-screen'),
                      onViewProfile: () =>
                          Navigator.pushNamed(context, '/profile-screen'),
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 0,
        variant: CustomBottomBarVariant.standard,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/task-creation-screen'),
        child: CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
