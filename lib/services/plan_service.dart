/// Plan Service
/// 
/// This service handles all plan-related operations including creating, reading, updating, and deleting
/// plans. A Plan is a container that holds multiple tasks for a specific period (e.g., "Today's Plan",
/// "Weekend Study Plan", "Morning Routine"). Plans allow users to organize a sequence of tasks together
/// instead of creating standalone tasks. Each plan can have a title, description, date/time range, and
/// contains multiple tasks that support all normal task features including completion, due times, and XP rewards.
import 'supabase_service.dart';

class PlanService {
  final _supabase = SupabaseService.client;

  // Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  // Get all plans for current user
  Future<List<Map<String, dynamic>>> getPlans({
    DateTime? planDate,
    String? orderBy = 'plan_date', // 'plan_date' or 'created_at'
    bool ascending = false,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      var query = _supabase
          .from('plans')
          .select()
          .eq('user_id', _userId!);

      if (planDate != null) {
        query = query.eq('plan_date', planDate.toIso8601String().split('T')[0]);
      }

      // Chain order call directly without reassigning
      final response = orderBy == 'plan_date'
          ? await query.order('plan_date', ascending: ascending)
          : await query.order('created_at', ascending: ascending);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get a single plan by ID with its tasks
  Future<Map<String, dynamic>?> getPlanById(String planId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Get plan
      final planResponse = await _supabase
          .from('plans')
          .select()
          .eq('id', planId)
          .eq('user_id', _userId!)
          .maybeSingle();

      if (planResponse == null) return null;

      // Get tasks for this plan, ordered by task_order
      final tasksResponse = await _supabase
          .from('tasks')
          .select()
          .eq('plan_id', planId)
          .eq('user_id', _userId!)
          .order('task_order', ascending: true)
          .order('due_time', ascending: true);

      final plan = Map<String, dynamic>.from(planResponse);
      plan['tasks'] = List<Map<String, dynamic>>.from(tasksResponse);
      
      return plan;
    } catch (e) {
      rethrow;
    }
  }

  // Create a new plan
  Future<Map<String, dynamic>> createPlan({
    required String title,
    String? description,
    DateTime? planDate,
    String? startTime,
    String? endTime,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final planData = {
        'user_id': _userId!,
        'title': title,
        'description': description,
        'plan_date': planDate?.toIso8601String().split('T')[0], // Store only date part
        'start_time': startTime,
        'end_time': endTime,
      };

      final response = await _supabase
          .from('plans')
          .insert(planData)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Update a plan
  Future<Map<String, dynamic>> updatePlan(
    String planId, {
    String? title,
    String? description,
    DateTime? planDate,
    String? startTime,
    String? endTime,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (planDate != null) updateData['plan_date'] = planDate.toIso8601String().split('T')[0];
      if (startTime != null) updateData['start_time'] = startTime;
      if (endTime != null) updateData['end_time'] = endTime;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('plans')
          .update(updateData)
          .eq('id', planId)
          .eq('user_id', _userId!)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a plan (tasks will have plan_id set to NULL due to ON DELETE SET NULL)
  Future<void> deletePlan(String planId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('plans')
          .delete()
          .eq('id', planId)
          .eq('user_id', _userId!);
    } catch (e) {
      rethrow;
    }
  }

  // Reorder tasks within a plan
  Future<void> reorderPlanTasks(String planId, List<String> taskIds) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Verify plan ownership
      final plan = await _supabase
          .from('plans')
          .select('id')
          .eq('id', planId)
          .eq('user_id', _userId!)
          .maybeSingle();

      if (plan == null) {
        throw Exception('Plan not found or access denied');
      }

      // Update task_order for each task
      for (int i = 0; i < taskIds.length; i++) {
        await _supabase
            .from('tasks')
            .update({'task_order': i})
            .eq('id', taskIds[i])
            .eq('plan_id', planId)
            .eq('user_id', _userId!);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get plan statistics
  Future<Map<String, dynamic>> getPlanStats(String planId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final tasks = await _supabase
          .from('tasks')
          .select('status')
          .eq('plan_id', planId)
          .eq('user_id', _userId!);

      final taskList = List<Map<String, dynamic>>.from(tasks);
      final totalTasks = taskList.length;
      final completedTasks = taskList.where((t) => t['status'] == 'completed').length;
      final activeTasks = taskList.where((t) => t['status'] == 'active').length;

      return {
        'total_tasks': totalTasks,
        'completed_tasks': completedTasks,
        'active_tasks': activeTasks,
        'completion_percentage': totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0,
      };
    } catch (e) {
      rethrow;
    }
  }
}

