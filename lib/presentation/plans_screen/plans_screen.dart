/// Plans Screen
/// 
/// This screen displays all user plans in a list format. Plans are containers that hold multiple tasks
/// for a specific period (e.g., "Today's Plan", "Weekend Study Plan", "Morning Routine"). Users can
/// create new plans, view existing plans, and see plan statistics (total tasks, completed tasks, etc.).
/// Each plan card shows the plan title, date, description, and completion progress.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import 'widgets/plan_card_widget.dart';
import 'widgets/empty_state_widget.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshPlans() async {
    setState(() => _isRefreshing = true);
    ref.invalidate(allPlansProvider);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plansAsync = ref.watch(allPlansProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Plans',
        variant: CustomAppBarVariant.standard,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/plan-creation-screen');
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
      body: RefreshIndicator(
        onRefresh: _refreshPlans,
        child: plansAsync.when(
          data: (plans) {
            if (plans.isEmpty) {
              return EmptyStateWidget(
                title: 'No plans yet',
                subtitle: 'Create your first plan to organize multiple tasks together!',
                buttonText: 'Create Your First Plan',
                onButtonPressed: () {
                  Navigator.pushNamed(context, '/plan-creation-screen');
                  HapticFeedback.lightImpact();
                },
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                final isOwner = plan['is_owner'] as bool? ?? true; // Default to true for backward compatibility
                return PlanCardWidget(
                  plan: plan,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/plan-detail-screen',
                      arguments: plan['id'] as String,
                    );
                    HapticFeedback.lightImpact();
                  },
                  // Only show delete button for owned plans
                  onDelete: isOwner ? () async {
                    await _handleDeletePlan(plan['id'] as String);
                  } : null,
                );
              },
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
                  'Error loading plans',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                SizedBox(height: 1.h),
                TextButton(
                  onPressed: _refreshPlans,
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 3),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/plan-creation-screen');
          HapticFeedback.lightImpact();
        },
        child: CustomIconWidget(
          iconName: 'add',
          color: colorScheme.onPrimary,
          size: 24,
        ),
      ),
    );
  }

  Future<void> _handleDeletePlan(String planId) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final planService = ref.read(planServiceProvider);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Plan'),
        content: Text(
          'Are you sure you want to delete this plan? Tasks in this plan will not be deleted, but they will no longer be grouped together.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await planService.deletePlan(planId);
        ref.invalidate(allPlansProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plan deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting plan: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

