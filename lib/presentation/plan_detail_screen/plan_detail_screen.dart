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
import 'widgets/plan_header_widget.dart';
import 'widgets/plan_task_item_widget.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key});

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshPlan() async {
    setState(() => _isRefreshing = true);
    final planId = ModalRoute.of(context)?.settings.arguments as String?;
    if (planId != null) {
      ref.invalidate(planByIdProvider(planId));
    }
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isRefreshing = false);
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
      final result = await taskService.completeTask(taskId);
      
      final planId = ModalRoute.of(context)?.settings.arguments as String?;
      if (planId != null) {
        ref.invalidate(planByIdProvider(planId));
        ref.invalidate(allTasksProvider);
        ref.invalidate(todaysTasksProvider);
        ref.invalidate(overallUserStreakProvider);
        ref.invalidate(activeStreaksProvider);
      }

      if (mounted) {
        final xpAwarded = result['xp_awarded'] as bool? ?? false;
        final xpGained = result['xp_gained'] as int? ?? 0;
        
        if (xpAwarded && xpGained > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task completed! +$xpGained XP'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task completed (late - no XP)'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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

    return Scaffold(
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
                        ),
                      ],
                    ),
                  )
                else
                  ...taskList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final task = entry.value;
                    return PlanTaskItemWidget(
                      task: task,
                      index: index,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/task-detail-screen',
                          arguments: task['id'] as String,
                        );
                        HapticFeedback.lightImpact();
                      },
                      onComplete: () => _handleTaskComplete(task['id'] as String),
                    );
                  }),
                SizedBox(height: 2.h),
                // Add Task Button
                if (taskList.isNotEmpty)
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
      floatingActionButton: FloatingActionButton.extended(
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
      ),
    );
  }
}

