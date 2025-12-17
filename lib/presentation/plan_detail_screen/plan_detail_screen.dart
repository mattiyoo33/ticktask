/// Plan Detail Screen
/// 
/// Displays a plan with all its tasks. Users can view task details, add new tasks to the plan,
/// mark tasks as completed, and reorder tasks. Tasks within a plan support all normal task features
/// including completion, due times, XP rewards, and collaborative features. Tasks can be viewed
/// both within the plan and in the global task list.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../task_detail_screen/widgets/celebration_overlay_widget.dart';
import 'widgets/plan_header_widget.dart';
import 'widgets/plan_task_item_widget.dart';
import 'widgets/public_plan_leaderboard_widget.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key});

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  bool _isRefreshing = false;
  bool _showCelebration = false;
  int _xpGained = 0;
  bool _hasJoined = false;
  bool _isOwner = false;
  bool _isLoadingJoinStatus = true;

  Future<void> _refreshPlan() async {
    setState(() => _isRefreshing = true);
    final planId = ModalRoute.of(context)?.settings.arguments as String?;
    if (planId != null) {
      ref.invalidate(planByIdProvider(planId));
      await _checkJoinStatus(planId);
    }
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isRefreshing = false);
  }

  Future<void> _checkJoinStatus(String planId) async {
    try {
      final planService = ref.read(planServiceProvider);
      final planAsync = await ref.read(planByIdProvider(planId).future);
      
      if (planAsync != null) {
        final currentUser = ref.read(currentUserProvider).value;
        final planOwnerId = planAsync['user_id'] as String?;
        final isOwner = planOwnerId == currentUser?.id;
        final isPublic = planAsync['is_public'] as bool? ?? false;
        
        bool hasJoined = false;
        if (!isOwner && isPublic) {
          hasJoined = await planService.hasJoinedPublicPlan(planId);
        }
        
        if (mounted) {
          setState(() {
            _isOwner = isOwner;
            _hasJoined = hasJoined;
            _isLoadingJoinStatus = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking join status: $e');
      if (mounted) {
        setState(() => _isLoadingJoinStatus = false);
      }
    }
  }

  Future<void> _handleJoinPlan(String planId) async {
    try {
      final planService = ref.read(planServiceProvider);
      await planService.joinPublicPlan(planId);
      
      // Invalidate providers to refresh plans list
      ref.invalidate(allPlansProvider);
      
      if (mounted) {
        setState(() => _hasJoined = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Joined plan successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshPlan();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join plan: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleLeavePlan(String planId) async {
    try {
      final planService = ref.read(planServiceProvider);
      await planService.leavePublicPlan(planId);
      
      // Invalidate providers to refresh plans list
      ref.invalidate(allPlansProvider);
      
      if (mounted) {
        setState(() => _hasJoined = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left plan successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshPlan();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave plan: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleAddTask(String planId) async {
    final result = await Navigator.pushNamed(
      context,
      '/task-creation-screen',
      arguments: {'planId': planId},
    );

    if (result == true) {
      _refreshPlan();
    }
  }

  Future<void> _handleTaskComplete(String taskId) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      
      // Get streak data for potential bonus
      final streakData = await taskService.getTaskStreak(taskId);
      final result = await taskService.completeTask(taskId);
      
      final planId = ModalRoute.of(context)?.settings.arguments as String?;
      if (planId != null) {
        ref.invalidate(planByIdProvider(planId));
        ref.invalidate(allTasksProvider);
        ref.invalidate(todaysTasksProvider);
        ref.invalidate(overallUserStreakProvider);
        ref.invalidate(activeStreaksProvider);
        ref.invalidate(userProfileFromDbProvider);
        ref.invalidate(recentActivitiesProvider);
      }

      if (mounted) {
        final xpAwarded = result['xp_awarded'] as bool? ?? false;
        final xpGained = result['xp_gained'] as int? ?? 0;
        final streakBonus = streakData?['has_streak_bonus'] == true && xpAwarded ? 25 : 0;
        
        setState(() {
          _xpGained = xpGained + streakBonus;
          _showCelebration = true; // Show celebration for all completions
        });
      }
    } catch (e) {
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

  Future<void> _handleTaskRevert(String taskId) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.revertTaskCompletion(taskId);
      
      // Small delay to ensure database has processed the deletion
      await Future.delayed(const Duration(milliseconds: 300));
      
      final planId = ModalRoute.of(context)?.settings.arguments as String?;
      if (planId != null) {
        ref.invalidate(planByIdProvider(planId));
        ref.invalidate(allTasksProvider);
        ref.invalidate(todaysTasksProvider);
        ref.invalidate(overallUserStreakProvider);
        ref.invalidate(activeStreaksProvider);
        
        // Wait for plan to refresh
        try {
          await ref.read(planByIdProvider(planId).future);
        } catch (e) {
          debugPrint('⚠️ Error refreshing plan after revert: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Task completion reverted'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        _refreshPlan();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reverting task: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
    final planId = ModalRoute.of(context)?.settings.arguments as String?;

    if (planId == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Plan',
          variant: CustomAppBarVariant.standard,
        ),
        body: Center(
          child: Text(
            'Plan not found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ),
      );
    }

    final planAsync = ref.watch(planByIdProvider(planId));

    // Check join status when plan loads
    if (_isLoadingJoinStatus && planId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkJoinStatus(planId);
      });
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: CustomAppBar(
            title: 'Plan Details',
            variant: CustomAppBarVariant.standard,
            centerTitle: false,
            actions: [
              IconButton(
                onPressed: _refreshPlan,
                icon: Icon(
                  Icons.refresh,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshPlan,
            child: planAsync.when(
              data: (plan) {
            if (plan == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'error',
                      color: colorScheme.error,
                      size: 48,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Plan not found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              );
            }

            final tasks = plan['tasks'] as List<dynamic>? ?? [];
            final taskList = tasks.cast<Map<String, dynamic>>();
            final isPublic = plan['is_public'] as bool? ?? false;

            return ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                // Plan Header
                PlanHeaderWidget(
                  plan: plan,
                  onEdit: () {
                    // TODO: Implement edit plan
                  },
                ),
                SizedBox(height: 3.h),
                
                // Join/Leave Button for non-owners viewing public plans
                if (!_isOwner && isPublic) ...[
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    child: _hasJoined
                        ? OutlinedButton.icon(
                            onPressed: () => _handleLeavePlan(planId),
                            icon: CustomIconWidget(
                              iconName: 'close',
                              color: colorScheme.error,
                              size: 20,
                            ),
                            label: Text('Leave Plan'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              side: BorderSide(color: colorScheme.error),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _handleJoinPlan(planId),
                            icon: CustomIconWidget(
                              iconName: 'check',
                              color: colorScheme.onPrimary,
                              size: 20,
                            ),
                            label: Text('Join Plan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                            ),
                          ),
                  ),
                  SizedBox(height: 3.h),
                ],
                
                // Leaderboard Section (only for public plans)
                if (isPublic) ...[
                  PublicPlanLeaderboardWidget(planId: planId),
                  SizedBox(height: 3.h),
                ],
                
                // Tasks Section
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'list',
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Tasks (${taskList.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                if (taskList.isEmpty)
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        CustomIconWidget(
                          iconName: 'task',
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          size: 48,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No tasks yet',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Add tasks to organize your plan',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        // Only show add task button if owner
                        if (_isOwner)
                          ElevatedButton.icon(
                            onPressed: () => _handleAddTask(planId),
                            icon: CustomIconWidget(
                              iconName: 'add',
                              color: colorScheme.onPrimary,
                              size: 18,
                            ),
                            label: Text('Add Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                          )
                        else
                          Text(
                            'Only the plan owner can add tasks',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  )
                else
                  ...taskList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final task = entry.value;
                    final taskId = task['id'] as String;
                    final taskOwnerId = task['user_id'] as String?;
                    final currentUser = ref.read(currentUserProvider).value;
                    final isTaskOwner = taskOwnerId == currentUser?.id;
                    
                    // For public plan tasks, check user-specific completion status
                    // Use FutureBuilder to check if user has completed this task today
                    return FutureBuilder<bool>(
                      future: isPublic && !_isOwner && !isTaskOwner
                          ? ref.read(taskServiceProvider).hasCompletedTaskToday(taskId)
                          : Future.value(false),
                      builder: (context, snapshot) {
                        final userCompletedToday = snapshot.data ?? false;
                        // Create a modified task map with user-specific completion status
                        final taskWithUserStatus = Map<String, dynamic>.from(task);
                        if (userCompletedToday) {
                          taskWithUserStatus['status'] = 'completed';
                        }
                        final isUnlocked = taskWithUserStatus['is_unlocked'] == true;
                        final isNextUp = taskWithUserStatus['is_next_up'] == true;
                        
                        return PlanTaskItemWidget(
                          task: taskWithUserStatus,
                          index: index,
                          isLocked: !isUnlocked,
                          isNextUp: isNextUp,
                          onLockedTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isNextUp
                                    ? 'Complete this task to unlock the next one'
                                    : 'Complete earlier steps to unlock this task'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/task-detail-screen',
                              arguments: taskWithUserStatus, // Pass the full task object, not just the ID
                            );
                            HapticFeedback.lightImpact();
                          },
                          // Show completion button if not completed, revert button if completed
                          onComplete: userCompletedToday || !isUnlocked
                              ? null 
                              : () => _handleTaskComplete(taskId),
                          onRevert: userCompletedToday
                              ? () => _handleTaskRevert(taskId)
                              : null,
                        );
                      },
                    );
                  }),
                SizedBox(height: 2.h),
                // Add Task Button (only for owners)
                if (taskList.isNotEmpty && _isOwner)
                  OutlinedButton.icon(
                    onPressed: () => _handleAddTask(planId),
                    icon: CustomIconWidget(
                      iconName: 'add',
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    label: Text('Add Task to Plan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      side: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                SizedBox(height: 4.h),
              ],
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'error',
                  color: colorScheme.error,
                  size: 48,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Error loading plan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                SizedBox(height: 1.h),
                TextButton(
                  onPressed: _refreshPlan,
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        ),
          floatingActionButton: _isOwner
              ? FloatingActionButton.extended(
                  onPressed: () {
                    final planId = ModalRoute.of(context)?.settings.arguments as String?;
                    if (planId != null) {
                      _handleAddTask(planId);
                    }
                  },
                  icon: CustomIconWidget(
                    iconName: 'add',
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                  label: Text('Add Task'),
                )
              : null,
        ),
      // Celebration Overlay
      CelebrationOverlayWidget(
        isVisible: _showCelebration,
        xpGained: _xpGained,
        onAnimationComplete: _onCelebrationComplete,
      ),
    ],
    );
  }
}
