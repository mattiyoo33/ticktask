/// Plan Service
/// 
/// This service handles all plan-related operations including creating, reading, updating, and deleting
/// plans. A Plan is a container that holds multiple tasks for a specific period (e.g., "Today's Plan",
/// "Weekend Study Plan", "Morning Routine"). Plans allow users to organize a sequence of tasks together
/// instead of creating standalone tasks. Each plan can have a title, description, date/time range, and
/// contains multiple tasks that support all normal task features including completion, due times, and XP rewards.
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class PlanService {
  final _supabase = SupabaseService.client;

  // Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  // Get all plans for current user (owned plans + joined public plans)
  Future<List<Map<String, dynamic>>> getPlans({
    DateTime? planDate,
    String? orderBy = 'plan_date', // 'plan_date' or 'created_at'
    bool ascending = false,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Get plans owned by user (both private and public)
      var ownedPlansQuery = _supabase
          .from('plans')
          .select()
          .eq('user_id', _userId!);

      if (planDate != null) {
        ownedPlansQuery = ownedPlansQuery.eq('plan_date', planDate.toIso8601String().split('T')[0]);
      }

      final ownedPlans = orderBy == 'plan_date'
          ? await ownedPlansQuery.order('plan_date', ascending: ascending)
          : await ownedPlansQuery.order('created_at', ascending: ascending);

      // Get public plans that user has joined
      final participantsQuery = await _supabase
          .from('public_plan_participants')
          .select('plan_id')
          .eq('user_id', _userId!);
      
      final joinedPlanIds = (participantsQuery as List)
          .map((p) => p['plan_id'] as String)
          .toList();
      
      List<Map<String, dynamic>> joinedPlans = [];
      if (joinedPlanIds.isNotEmpty) {
        var joinedPlansQuery = _supabase
            .from('plans')
            .select()
            .inFilter('id', joinedPlanIds)
            .eq('is_public', true);
        
        if (planDate != null) {
          joinedPlansQuery = joinedPlansQuery.eq('plan_date', planDate.toIso8601String().split('T')[0]);
        }
        
        joinedPlans = List<Map<String, dynamic>>.from(
          orderBy == 'plan_date'
              ? await joinedPlansQuery.order('plan_date', ascending: ascending)
              : await joinedPlansQuery.order('created_at', ascending: ascending)
        );
      }
      
      // Combine and deduplicate (in case user owns a public plan they also joined)
      // Mark plans as owned or joined
      final allPlansMap = <String, Map<String, dynamic>>{};
      for (var plan in ownedPlans) {
        final planMap = Map<String, dynamic>.from(plan);
        planMap['is_owner'] = true; // Mark as owned
        allPlansMap[plan['id'] as String] = planMap;
      }
      for (var plan in joinedPlans) {
        final planId = plan['id'] as String;
        if (!allPlansMap.containsKey(planId)) {
          // Only add if not already owned (owned plans take precedence)
          final planMap = Map<String, dynamic>.from(plan);
          planMap['is_owner'] = false; // Mark as joined (not owned)
          allPlansMap[planId] = planMap;
        }
      }
      
      return allPlansMap.values.toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get a single plan by ID with its tasks
  // Can access: own plans (private or public) OR public plans from other users
  Future<Map<String, dynamic>?> getPlanById(String planId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // First try to get plan owned by current user
      var planResponse = await _supabase
          .from('plans')
          .select()
          .eq('id', planId)
          .eq('user_id', _userId!)
          .maybeSingle();

      // If not found, try to get public plan from any user
      if (planResponse == null) {
        planResponse = await _supabase
            .from('plans')
            .select()
            .eq('id', planId)
            .eq('is_public', true)
            .maybeSingle();
      }

      if (planResponse == null) return null;

      final planOwnerId = planResponse['user_id'] as String?;
      final isOwner = planOwnerId == _userId;

      // Get tasks for this plan
      // If owner: get all tasks
      // If viewing public plan: get all tasks (public plans show all tasks)
      // Note: RLS policy should allow viewing tasks in public plans user has joined
      List<Map<String, dynamic>> tasksList = [];
      
      try {
        final tasksResponse = await _supabase
            .from('tasks')
            .select()
            .eq('plan_id', planId)
            .order('task_order', ascending: true)
            .order('due_time', ascending: true);
        
        tasksList = List<Map<String, dynamic>>.from(tasksResponse);
        print('✅ Fetched ${tasksList.length} tasks for plan $planId (isOwner: $isOwner, userId: $_userId, planOwnerId: $planOwnerId)');
      } catch (e) {
        print('⚠️ Error fetching tasks for plan $planId: $e');
        print('⚠️ Plan owner: $planOwnerId, Current user: $_userId, Is owner: $isOwner');
        // If RLS blocks, tasksList will remain empty
        // The RLS policy should handle this, but if not, user will see "No tasks yet"
        // Don't rethrow - allow plan to load even if tasks can't be fetched
      }

      final plan = Map<String, dynamic>.from(planResponse);
      plan['tasks'] = tasksList;
      plan['is_owner'] = isOwner; // Add flag to indicate ownership
      
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
    bool isPublic = false,
    String? categoryId,
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
        'is_public': isPublic,
        if (categoryId != null) 'category_id': categoryId,
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

  // Get public plans with optional filters
  Future<List<Map<String, dynamic>>> getPublicPlans({
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _supabase
          .from('plans')
          .select('''
            *,
            categories:category_id(*)
          ''')
          .eq('is_public', true);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      var orderedQuery = query.order('created_at', ascending: false);

      if (limit != null) {
        orderedQuery = orderedQuery.limit(limit);
      }

      if (offset != null) {
        orderedQuery = orderedQuery.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await orderedQuery;
      final plans = List<Map<String, dynamic>>.from(response);
      
      // Fetch owner profiles and task counts
      final plansWithProfiles = await Future.wait(plans.map((plan) async {
        final userId = plan['user_id'] as String?;
        final planId = plan['id'] as String?;
        
        // Fetch owner profile
        if (userId != null) {
          try {
            final profile = await _supabase
                .from('profiles')
                .select('id, full_name, avatar_url')
                .eq('id', userId)
                .maybeSingle();
            plan['profiles'] = profile;
          } catch (e) {
            plan['profiles'] = null;
          }
        } else {
          plan['profiles'] = null;
        }
        
        // Fetch task count
        if (planId != null) {
          try {
            final tasksResponse = await _supabase
                .from('tasks')
                .select('id')
                .eq('plan_id', planId);
            plan['task_count'] = (tasksResponse as List).length;
          } catch (e) {
            plan['task_count'] = 0;
          }
          
          // Fetch member count (participants who joined the public plan)
          try {
            final participantsResponse = await _supabase
                .from('public_plan_participants')
                .select('id')
                .eq('plan_id', planId);
            plan['member_count'] = (participantsResponse as List).length;
          } catch (e) {
            plan['member_count'] = 0;
          }
        } else {
          plan['member_count'] = 0;
        }
        
        return plan;
      }));
      
      return plansWithProfiles;
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

  // Join a public plan
  Future<void> joinPublicPlan(String planId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Check if plan is public
      final plan = await _supabase
          .from('plans')
          .select('is_public, user_id')
          .eq('id', planId)
          .maybeSingle();

      if (plan == null) {
        throw Exception('Plan not found');
      }

      if (plan['is_public'] != true) {
        throw Exception('This plan is not public');
      }

      if (plan['user_id'] == _userId) {
        throw Exception('You cannot join your own plan');
      }

      // Check if already joined
      final existing = await _supabase
          .from('public_plan_participants')
          .select()
          .eq('plan_id', planId)
          .eq('user_id', _userId!)
          .maybeSingle();

      if (existing != null) {
        throw Exception('You have already joined this plan');
      }

      await _supabase
          .from('public_plan_participants')
          .insert({
            'plan_id': planId,
            'user_id': _userId!,
            'joined_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  // Leave a public plan
  Future<void> leavePublicPlan(String planId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final result = await _supabase
          .from('public_plan_participants')
          .delete()
          .eq('plan_id', planId)
          .eq('user_id', _userId!)
          .select();

      if (result.isEmpty) {
        throw Exception('You are not a participant of this plan');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Check if user has joined a public plan
  Future<bool> hasJoinedPublicPlan(String planId) async {
    if (_userId == null) return false;

    try {
      final response = await _supabase
          .from('public_plan_participants')
          .select()
          .eq('plan_id', planId)
          .eq('user_id', _userId!)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}

