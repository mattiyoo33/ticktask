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

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;

  // Mock user data
  final Map<String, dynamic> _userData = {
    "id": 1,
    "name": "Sarah Johnson",
    "avatar":
        "https://img.rocket.new/generatedImages/rocket_gen_img_1274dd504-1762275023732.png",
    "semanticLabel":
        "Professional headshot of a young woman with brown hair wearing a white blazer",
    "level": 12,
    "currentXP": 850,
    "nextLevelXP": 1200,
  };

  // Mock today's tasks data
  final List<Map<String, dynamic>> _todaysTasks = [
    {
      "id": 1,
      "title": "Morning Workout",
      "description": "30-minute cardio session at the gym",
      "difficulty": "medium",
      "dueTime": "8:00 AM",
      "isCompleted": false,
      "xpReward": 20,
    },
    {
      "id": 2,
      "title": "Read 20 Pages",
      "description": "Continue reading 'Atomic Habits' book",
      "difficulty": "easy",
      "dueTime": "7:00 PM",
      "isCompleted": false,
      "xpReward": 10,
    },
    {
      "id": 3,
      "title": "Complete Project Report",
      "description": "Finish quarterly analysis report for client presentation",
      "difficulty": "hard",
      "dueTime": "5:00 PM",
      "isCompleted": true,
      "xpReward": 30,
    },
    {
      "id": 4,
      "title": "Meditate",
      "description": "10-minute mindfulness meditation",
      "difficulty": "easy",
      "dueTime": "9:00 PM",
      "isCompleted": false,
      "xpReward": 10,
    },
  ];

  // Mock current streaks data
  final List<Map<String, dynamic>> _currentStreaks = [
    {
      "id": 1,
      "title": "Daily Exercise",
      "dayCount": 12,
      "category": "fitness",
      "lastCompleted": DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      "id": 2,
      "title": "Reading",
      "dayCount": 8,
      "category": "learning",
      "lastCompleted": DateTime.now().subtract(const Duration(hours: 18)),
    },
    {
      "id": 3,
      "title": "Meditation",
      "dayCount": 5,
      "category": "wellness",
      "lastCompleted": DateTime.now().subtract(const Duration(hours: 12)),
    },
    {
      "id": 4,
      "title": "Water Intake",
      "dayCount": 15,
      "category": "health",
      "lastCompleted": DateTime.now().subtract(const Duration(hours: 1)),
    },
  ];

  // Mock recent activity data
  final List<Map<String, dynamic>> _recentActivity = [
    {
      "id": 1,
      "type": "task_completed",
      "userName": "You",
      "userAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1274dd504-1762275023732.png",
      "semanticLabel":
          "Professional headshot of a young woman with brown hair wearing a white blazer",
      "message": "completed 'Complete Project Report'",
      "timestamp": DateTime.now().subtract(const Duration(hours: 1)),
      "xpGained": 30,
    },
    {
      "id": 2,
      "type": "streak_achieved",
      "userName": "Mike Chen",
      "userAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1f3d1cbe1-1762274610155.png",
      "semanticLabel":
          "Portrait of an Asian man with short black hair wearing a casual blue shirt",
      "message": "achieved a 7-day streak in Daily Workout!",
      "timestamp": DateTime.now().subtract(const Duration(hours: 3)),
      "xpGained": 25,
    },
    {
      "id": 3,
      "type": "level_up",
      "userName": "Emma Wilson",
      "userAvatar":
          "https://images.unsplash.com/photo-1545946463-c7abd8b3ff5d",
      "semanticLabel":
          "Smiling blonde woman in a red sweater outdoors with autumn leaves in background",
      "message": "leveled up to Level 15!",
      "timestamp": DateTime.now().subtract(const Duration(hours: 5)),
      "xpGained": null,
    },
    {
      "id": 4,
      "type": "friend_added",
      "userName": "You",
      "userAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1274dd504-1762275023732.png",
      "semanticLabel":
          "Professional headshot of a young woman with brown hair wearing a white blazer",
      "message": "added Alex Rodriguez as a friend",
      "timestamp": DateTime.now().subtract(const Duration(hours: 8)),
      "xpGained": null,
    },
    {
      "id": 5,
      "type": "badge_earned",
      "userName": "David Kim",
      "userAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_14d5cbd5d-1762275037552.png",
      "semanticLabel":
          "Professional headshot of a man with dark hair wearing a navy suit and tie",
      "message": "earned the 'Consistency Champion' badge",
      "timestamp": DateTime.now().subtract(const Duration(hours: 12)),
      "xpGained": null,
    },
  ];

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

  void _onTaskDelete(Map<String, dynamic> task) {
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
            onPressed: () {
              setState(() {
                _todaysTasks.removeWhere((t) => t['id'] == task['id']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task deleted')),
              );
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
    final completedTasks =
        _todaysTasks.where((task) => task['isCompleted'] == true).length;
    final totalTasks = _todaysTasks.length;

    if (completedTasks == totalTasks && totalTasks > 0) {
      return MascotState.celebrating;
    } else if (completedTasks > totalTasks / 2) {
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
                      userName: _userData['name'] as String,
                      userAvatar: _userData['avatar'] as String,
                      currentLevel: _userData['level'] as int,
                      currentXP: _userData['currentXP'] as int,
                      nextLevelXP: _userData['nextLevelXP'] as int,
                    ),
                    SizedBox(height: 2.h),
                    TaskerMascotWidget(
                      state: _getMascotState(),
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
