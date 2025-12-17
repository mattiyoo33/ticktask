/// Task Service
/// 
/// This service handles all task-related operations including creating, reading, updating, and deleting
/// tasks. It manages task completion logic with deadline-based XP rewards (XP is only awarded if tasks
/// are completed on or before their due date/time). The service also handles collaborative task features
/// such as adding friends as participants, managing task participants, and handling task comments with
/// real-time updates. It provides methods for fetching task streaks, calculating XP rewards based on
/// difficulty levels, and managing task statuses (active, completed, overdue, etc.).
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class TaskService {
  final _supabase = SupabaseService.client;

  // Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  // Get all tasks for current user (owned tasks + accepted collaborative tasks)
  Future<List<Map<String, dynamic>>> getTasks({
    String? status,
    String? category,
    DateTime? dueDate,
    bool? isRecurring,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Get tasks owned by user (include plan tasks with plan info)
      var ownedTasksQuery = _supabase
          .from('tasks')
          .select('''
            *,
            plans:plan_id(id, title)
          ''')
          .eq('user_id', _userId!);

      if (status != null) {
        ownedTasksQuery = ownedTasksQuery.eq('status', status);
      }
      if (category != null) {
        ownedTasksQuery = ownedTasksQuery.eq('category', category);
      }
      if (dueDate != null) {
        ownedTasksQuery = ownedTasksQuery.eq('due_date', dueDate.toIso8601String());
      }
      if (isRecurring != null) {
        ownedTasksQuery = ownedTasksQuery.eq('is_recurring', isRecurring);
      }

      final ownedTasks = await ownedTasksQuery.order('due_date', ascending: true).order('created_at', ascending: false);
      
      // Get collaborative tasks where user is an accepted participant
      final participantsQuery = await _supabase
          .from('task_participants')
          .select('task_id')
          .eq('user_id', _userId!)
          .eq('status', 'accepted');
      
      final participantTaskIds = (participantsQuery as List)
          .map((p) => p['task_id'] as String)
          .toList();
      
      List<Map<String, dynamic>> collaborativeTasks = [];
      if (participantTaskIds.isNotEmpty) {
        var collaborativeQuery = _supabase
            .from('tasks')
            .select()
            .inFilter('id', participantTaskIds)
            .eq('is_collaborative', true);
        
        if (status != null) {
          collaborativeQuery = collaborativeQuery.eq('status', status);
        }
        if (category != null) {
          collaborativeQuery = collaborativeQuery.eq('category', category);
        }
        if (dueDate != null) {
          collaborativeQuery = collaborativeQuery.eq('due_date', dueDate.toIso8601String());
        }
        if (isRecurring != null) {
          collaborativeQuery = collaborativeQuery.eq('is_recurring', isRecurring);
        }
        
        collaborativeTasks = List<Map<String, dynamic>>.from(
          await collaborativeQuery.order('due_date', ascending: true).order('created_at', ascending: false)
        );
      }
      
      // Get public tasks where user has joined
      final publicParticipantsQuery = await _supabase
          .from('public_task_participants')
          .select('task_id')
          .eq('user_id', _userId!);
      
      final publicTaskIds = (publicParticipantsQuery as List)
          .map((p) => p['task_id'] as String)
          .toList();
      
      List<Map<String, dynamic>> publicTasks = [];
      if (publicTaskIds.isNotEmpty) {
        var publicQuery = _supabase
            .from('tasks')
            .select('''
              *,
              plans:plan_id(id, title)
            ''')
            .inFilter('id', publicTaskIds)
            .eq('is_public', true);
        
        if (status != null) {
          publicQuery = publicQuery.eq('status', status);
        }
        if (category != null) {
          publicQuery = publicQuery.eq('category', category);
        }
        if (dueDate != null) {
          publicQuery = publicQuery.eq('due_date', dueDate.toIso8601String());
        }
        if (isRecurring != null) {
          publicQuery = publicQuery.eq('is_recurring', isRecurring);
        }
        
        publicTasks = List<Map<String, dynamic>>.from(
          await publicQuery.order('due_date', ascending: true).order('created_at', ascending: false)
        );
      }
      
      // Combine and deduplicate (in case user owns a task they're also a participant in)
      final allTasks = <String, Map<String, dynamic>>{};
      for (var task in ownedTasks) {
        allTasks[task['id'] as String] = task;
      }
      for (var task in collaborativeTasks) {
        allTasks[task['id'] as String] = task;
      }
      for (var task in publicTasks) {
        allTasks[task['id'] as String] = task;
      }
      
      final result = allTasks.values.toList();
      // Sort by due_date and created_at
      result.sort((a, b) {
        final aDate = a['due_date'] as String?;
        final bDate = b['due_date'] as String?;
        if (aDate != null && bDate != null) {
          return aDate.compareTo(bDate);
        } else if (aDate != null) {
          return -1;
        } else if (bDate != null) {
          return 1;
        }
        final aCreated = a['created_at'] as String?;
        final bCreated = b['created_at'] as String?;
        if (aCreated != null && bCreated != null) {
          return bCreated.compareTo(aCreated); // Newest first
        }
        return 0;
      });
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Get today's tasks (owned tasks + accepted collaborative tasks)
  Future<List<Map<String, dynamic>>> getTodaysTasks() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get owned tasks (exclude plan tasks)
      final ownedTasks = await _supabase
          .from('tasks')
          .select()
          .eq('user_id', _userId!)
          .isFilter('plan_id', null) // Exclude tasks that belong to a plan
          .inFilter('status', ['active', 'scheduled'])
          .or('due_date.is.null,and(due_date.gte.${startOfDay.toIso8601String()},due_date.lt.${endOfDay.toIso8601String()})')
          .order('due_time', ascending: true)
          .order('due_date', ascending: true);

      // Get collaborative tasks where user is an accepted participant
      final participantsQuery = await _supabase
          .from('task_participants')
          .select('task_id')
          .eq('user_id', _userId!)
          .eq('status', 'accepted');
      
      final participantTaskIds = (participantsQuery as List)
          .map((p) => p['task_id'] as String)
          .toList();
      
      List<Map<String, dynamic>> collaborativeTasks = [];
      if (participantTaskIds.isNotEmpty) {
        collaborativeTasks = List<Map<String, dynamic>>.from(
          await _supabase
              .from('tasks')
              .select()
              .inFilter('id', participantTaskIds)
              .eq('is_collaborative', true)
              .inFilter('status', ['active', 'scheduled'])
              .or('due_date.is.null,and(due_date.gte.${startOfDay.toIso8601String()},due_date.lt.${endOfDay.toIso8601String()})')
              .order('due_time', ascending: true)
              .order('due_date', ascending: true)
        );
      }
      
      // Combine and deduplicate
      final allTasks = <String, Map<String, dynamic>>{};
      for (var task in ownedTasks) {
        allTasks[task['id'] as String] = task;
      }
      for (var task in collaborativeTasks) {
        allTasks[task['id'] as String] = task;
      }
      
      final result = allTasks.values.toList();
      // Sort by due_time and due_date
      result.sort((a, b) {
        final aTime = a['due_time'] as String?;
        final bTime = b['due_time'] as String?;
        if (aTime != null && bTime != null) {
          return aTime.compareTo(bTime);
        } else if (aTime != null) {
          return -1;
        } else if (bTime != null) {
          return 1;
        }
        final aDate = a['due_date'] as String?;
        final bDate = b['due_date'] as String?;
        if (aDate != null && bDate != null) {
          return aDate.compareTo(bDate);
        }
        return 0;
      });
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Get task by ID (allows access for task owner, participants, or tasks in public plans user has joined)
  Future<Map<String, dynamic>?> getTaskById(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // First try to get as owner
      var response = await _supabase
          .from('tasks')
          .select()
          .eq('id', taskId)
          .eq('user_id', _userId!)
          .maybeSingle();

      // If not found as owner, check if user is a participant in a collaborative task
      if (response == null) {
        final participantCheck = await _supabase
            .from('task_participants')
            .select('task_id')
            .eq('task_id', taskId)
            .eq('user_id', _userId!)
            .maybeSingle();

        if (participantCheck != null) {
          // User is a participant, fetch the task
          // The RLS policy "Users can view collaborative tasks" should allow this
          response = await _supabase
              .from('tasks')
              .select('*')
              .eq('id', taskId)
              .maybeSingle();
        }
      }

      // If still not found, check if task is in a public plan that user has joined
      if (response == null) {
        // First get the task to check if it has a plan_id
        final taskCheck = await _supabase
            .from('tasks')
            .select('plan_id, is_public')
            .eq('id', taskId)
            .maybeSingle();
        
        if (taskCheck != null) {
          final planId = taskCheck['plan_id'] as String?;
          final isPublic = taskCheck['is_public'] as bool? ?? false;
          
          // If task is in a public plan, check if user has joined
          if (planId != null && isPublic) {
            final planParticipantCheck = await _supabase
                .from('public_plan_participants')
                .select('plan_id')
                .eq('plan_id', planId)
                .eq('user_id', _userId!)
                .maybeSingle();
            
            if (planParticipantCheck != null) {
              // User has joined the public plan, fetch the task
              response = await _supabase
                  .from('tasks')
                  .select('*')
                  .eq('id', taskId)
                  .maybeSingle();
            }
          }
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Create a new task
  Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    String? category,
    String? difficulty,
    DateTime? dueDate,
    String? dueTime,
    int? xpReward,
    bool isRecurring = false,
    String? recurrenceFrequency,
    int? recurrenceInterval,
    DateTime? nextOccurrence,
    bool isCollaborative = false,
    List<String> participantIds = const [],
    String? planId,
    int? taskOrder,
    bool? isPublic,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // If planId is provided, check if plan is public to determine is_public
      bool? finalIsPublic = isPublic;
      if (planId != null && finalIsPublic == null) {
        try {
          final planResponse = await _supabase
              .from('plans')
              .select('is_public')
              .eq('id', planId)
              .maybeSingle();
          
          if (planResponse != null) {
            // If plan is public, task must be public; if plan is private, task is private
            finalIsPublic = planResponse['is_public'] as bool? ?? false;
          }
        } catch (e) {
          print('⚠️ Error checking plan public status: $e');
          // Default to false if check fails
          finalIsPublic = false;
        }
      }

      final taskData = {
        'user_id': _userId!,
        'title': title,
        'description': description,
        'category': category,
        'difficulty': difficulty ?? 'Medium',
        'due_date': dueDate?.toIso8601String(),
        'due_time': dueTime,
        'xp_reward': xpReward ?? _calculateXpReward(difficulty ?? 'Medium'),
        'is_recurring': isRecurring,
        'recurrence_frequency': recurrenceFrequency,
        'recurrence_interval': recurrenceInterval ?? 1,
        'next_occurrence': nextOccurrence?.toIso8601String(),
        'is_collaborative': isCollaborative,
        'status': 'active',
        if (planId != null) 'plan_id': planId,
        if (taskOrder != null) 'task_order': taskOrder,
        if (finalIsPublic != null) 'is_public': finalIsPublic,
      };

      final response = await _supabase
          .from('tasks')
          .insert(taskData)
          .select()
          .single();

      // Add participants with pending status if provided
      if (participantIds.isNotEmpty) {
        // CRITICAL: Filter out current user from participants
        // The task owner should never be added as a participant
        final validParticipantIds = participantIds
            .where((userId) => userId != _userId)
            .toList();
        
        if (validParticipantIds.isEmpty) {
          print('No valid participants after filtering out current user');
          return response;
        }
        
        // Ensure task is marked as collaborative (required for RLS policy to work)
        if (!isCollaborative) {
          await _supabase
              .from('tasks')
              .update({'is_collaborative': true})
              .eq('id', response['id']);
          print('Updated task to be collaborative');
        }
        
        // Try to insert with status field first (if migration was run)
        try {
          final participants = validParticipantIds.map((userId) {
            return <String, dynamic>{
              'task_id': response['id'],
              'user_id': userId,
              'role': 'participant',
              'status': 'pending',
            };
          }).toList();

          await _supabase.from('task_participants').insert(participants);
          print('Inserted ${participants.length} participants with pending status');
        } catch (e) {
          // If status column doesn't exist, insert without it
          print('Error inserting with status, trying without: $e');
          final participants = validParticipantIds.map((userId) {
            return <String, dynamic>{
              'task_id': response['id'],
              'user_id': userId,
              'role': 'participant',
            };
          }).toList();

          await _supabase.from('task_participants').insert(participants);
          print('Inserted ${participants.length} participants without status');
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Update a task
  Future<Map<String, dynamic>> updateTask(
    String taskId, {
    String? title,
    String? description,
    String? category,
    String? difficulty,
    DateTime? dueDate,
    String? dueTime,
    int? xpReward,
    String? status,
    bool? isRecurring,
    String? recurrenceFrequency,
    DateTime? nextOccurrence,
    bool? isCollaborative,
    String? planId,
    int? taskOrder,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;
      if (difficulty != null) updates['difficulty'] = difficulty;
      if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();
      if (dueTime != null) updates['due_time'] = dueTime;
      if (xpReward != null) updates['xp_reward'] = xpReward;
      if (status != null) updates['status'] = status;
      if (isRecurring != null) updates['is_recurring'] = isRecurring;
      if (recurrenceFrequency != null) {
        updates['recurrence_frequency'] = recurrenceFrequency;
      }
      if (nextOccurrence != null) {
        updates['next_occurrence'] = nextOccurrence.toIso8601String();
      }
      if (isCollaborative != null) updates['is_collaborative'] = isCollaborative;
      if (planId != null) updates['plan_id'] = planId;
      if (taskOrder != null) updates['task_order'] = taskOrder;

      final response = await _supabase
          .from('tasks')
          .update(updates)
          .eq('id', taskId)
          .eq('user_id', _userId!)
          .select()
          .single();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Delete a task (only allowed for task owner)
  Future<void> deleteTask(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Verify user is the task owner
      final task = await getTaskById(taskId);
      if (task == null) throw Exception('Task not found');
      
      final taskOwnerId = task['user_id'] as String?;
      if (taskOwnerId != _userId) {
        throw Exception('Only the task owner can delete this task');
      }
      
      await _supabase
          .from('tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_id', _userId!);
    } catch (e) {
      rethrow;
    }
  }

  // Leave a collaborative task (for participants only)
  // If all participants leave, the task becomes an individual task
  Future<void> leaveTask(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      print('🔄 Leaving task $taskId, user $_userId');
      
      // Verify user is a participant (not the owner)
      final task = await getTaskById(taskId);
      if (task == null) throw Exception('Task not found');
      
      final taskOwnerId = task['user_id'] as String?;
      if (taskOwnerId == _userId) {
        throw Exception('Task owner cannot leave their own task. Use delete instead.');
      }
      
      // Check if user is a participant
      final participantCheck = await _supabase
          .from('task_participants')
          .select('*')
          .eq('task_id', taskId)
          .eq('user_id', _userId!)
          .maybeSingle();
      
      if (participantCheck == null) {
        throw Exception('You are not a participant in this task');
      }
      
      print('📋 Found participant record, removing...');
      
      // Remove the participant
      await _supabase
          .from('task_participants')
          .delete()
          .eq('task_id', taskId)
          .eq('user_id', _userId!);
      
      print('✅ Participant removed');
      
      // Check if there are any remaining participants
      final remainingParticipants = await _supabase
          .from('task_participants')
          .select('id')
          .eq('task_id', taskId)
          .eq('status', 'accepted');
      
      final remainingCount = (remainingParticipants as List).length;
      print('📊 Remaining participants: $remainingCount');
      
      // If no participants remain, convert task to individual
      if (remainingCount == 0) {
        print('🔄 No participants remaining, converting task to individual...');
        await _supabase
            .from('tasks')
            .update({'is_collaborative': false})
            .eq('id', taskId);
        print('✅ Task converted to individual task');
      }
    } catch (e) {
      print('❌ Error leaving task: $e');
      rethrow;
    }
  }

  // Complete a task
  // Returns completion record with 'xp_awarded' boolean indicating if XP was granted
  Future<Map<String, dynamic>> completeTask(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Get task to get XP reward and deadline info
      final task = await getTaskById(taskId);
      if (task == null) throw Exception('Task not found');

      final taskOwnerId = task['user_id'] as String?;
      final planId = task['plan_id'] as String?;
      final isOwner = taskOwnerId == _userId;
      
      // If task belongs to a plan, enforce step-by-step order: only first incomplete task can be completed
      if (planId != null) {
        try {
          final orderedTasks = await _supabase
              .from('tasks')
              .select('id,status,task_order')
              .eq('plan_id', planId)
              .order('task_order', ascending: true)
              .order('due_time', ascending: true);

          final tasks = List<Map<String, dynamic>>.from(orderedTasks);
          final firstIncomplete = tasks.firstWhere(
            (t) => (t['status'] as String? ?? 'active') != 'completed',
            orElse: () => {},
          );

          final firstIncompleteId = firstIncomplete['id'] as String?;
          if (firstIncompleteId != null && firstIncompleteId != taskId) {
            throw Exception('Complete previous steps in the plan before this task.');
          }
        } catch (e) {
          // If we fail to fetch ordering, proceed to avoid blocking, but log
          print('⚠️ Plan step enforcement skipped: $e');
        }
      }
      
      // Check if this is a task in a public plan (not owned by current user)
      // For public plan tasks, we don't update the global task status
      final isPublicPlanTask = planId != null && !isOwner;

      // Check if user has already completed this task today
      // This check happens before attempting the insert to provide better error messages
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final existingCompletions = await _supabase
          .from('task_completions')
          .select('id, completed_at, xp_gained')
          .eq('task_id', taskId)
          .eq('user_id', _userId!)
          .gte('completed_at', startOfDay.toIso8601String())
          .lt('completed_at', endOfDay.toIso8601String());
      
      if ((existingCompletions as List).isNotEmpty) {
        final existingCompletion = (existingCompletions as List).first;
        final completedAt = existingCompletion['completed_at'] as String?;
        throw Exception('You have already completed this task today${completedAt != null ? ' at ${DateTime.parse(completedAt).toLocal().toString().split('.')[0]}' : ''}. Only one completion per day per task is allowed.');
      }

      final xpReward = task['xp_reward'] as int? ?? 0;
      final dueDateStr = task['due_date'] as String?;
      final dueTimeStr = task['due_time'] as String?;
      
      // Check if task was completed on time
      final now = DateTime.now();
      bool xpAwarded = false;
      int actualXpGained = 0;

      if (dueDateStr != null) {
        // Task has a deadline - check if completed on time
        final deadline = _calculateDeadline(dueDateStr, dueTimeStr);
        
        if (deadline != null && (now.isBefore(deadline) || now.isAtSameMomentAs(deadline))) {
          // Completed on or before deadline - award XP
          xpAwarded = true;
          actualXpGained = xpReward;
        } else if (deadline != null) {
          // Completed after deadline - no XP
          xpAwarded = false;
          actualXpGained = 0;
        } else {
          // Deadline parsing failed - award XP as fallback
          xpAwarded = true;
          actualXpGained = xpReward;
        }
      } else {
        // No deadline set - award XP (tasks without deadlines can be completed anytime)
        xpAwarded = true;
        actualXpGained = xpReward;
      }

      // Create completion record
      // Note: The database trigger will also check for duplicates, but we check here first
      // to provide a better error message
      final completion = await _supabase
          .from('task_completions')
          .insert({
            'task_id': taskId,
            'user_id': _userId!,
            'xp_gained': actualXpGained,
          })
          .select()
          .single();

      // Only update task status if user is the owner
      // For public plan tasks, don't change the global task status
      if (isOwner && !isPublicPlanTask) {
      await updateTask(taskId, status: 'completed');
      }

      // Create activity
      await _supabase.from('activities').insert({
        'user_id': _userId!,
        'type': 'task_completed',
        'task_id': taskId,
        'message': xpAwarded 
            ? "completed '${task['title']}'"
            : "completed '${task['title']}' (late - no XP)",
        'xp_gained': actualXpGained,
      });

      // Add xp_awarded flag to return value
      final result = Map<String, dynamic>.from(completion);
      result['xp_awarded'] = xpAwarded;
      result['xp_should_have_been'] = xpReward;
      
      return result;
    } catch (e) {
      // Re-throw with more context if it's a PostgrestException about duplicate completion
      if (e.toString().contains('already completed today') || 
          e.toString().contains('P0001')) {
        // Check if there's actually a completion record
        try {
          final today = DateTime.now();
          final startOfDay = DateTime(today.year, today.month, today.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));
          
          final checkCompletions = await _supabase
              .from('task_completions')
              .select('id, completed_at')
              .eq('task_id', taskId)
              .eq('user_id', _userId!)
              .gte('completed_at', startOfDay.toIso8601String())
              .lt('completed_at', endOfDay.toIso8601String());
          
          if ((checkCompletions as List).isNotEmpty) {
            final existingCompletion = (checkCompletions as List).first;
            final completedAt = existingCompletion['completed_at'] as String?;
            throw Exception('You have already completed this task today${completedAt != null ? ' at ${DateTime.parse(completedAt).toLocal().toString().split('.')[0]}' : ''}. Only one completion per day per task is allowed.');
          }
        } catch (_) {
          // If check fails, just re-throw original error
        }
      }
      rethrow;
    }
  }

  // Helper: Calculate deadline DateTime from due_date and due_time
  // Returns the exact deadline moment (date + time) for comparison
  DateTime? _calculateDeadline(String? dueDateStr, String? dueTimeStr) {
    if (dueDateStr == null) return null;

    try {
      // Parse the due_date (includes timezone info from database)
      final dueDate = DateTime.parse(dueDateStr);
      
      // Convert to local time for comparison with DateTime.now()
      final localDueDate = dueDate.toLocal();
      
      if (dueTimeStr != null && dueTimeStr.isNotEmpty && dueTimeStr.trim().isNotEmpty) {
        // Parse time string (format: "HH:mm" or "HH:mm:ss")
        final timeParts = dueTimeStr.trim().split(':');
        if (timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]);
          final minute = int.tryParse(timeParts[1]);
          
          if (hour != null && minute != null && hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
            // Combine date and time in local timezone
            return DateTime(
              localDueDate.year,
              localDueDate.month,
              localDueDate.day,
              hour,
              minute,
            );
          }
        }
      }
      
      // If no time specified, deadline is end of day (23:59:59)
      return DateTime(
        localDueDate.year,
        localDueDate.month,
        localDueDate.day,
        23,
        59,
        59,
      );
    } catch (e) {
      // If parsing fails, return null (will fallback to awarding XP)
      return null;
    }
  }

  // Check if the current user has completed a task today
  Future<bool> hasCompletedTaskToday(String taskId) async {
    if (_userId == null) return false;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final completions = await _supabase
          .from('task_completions')
          .select('id')
          .eq('task_id', taskId)
          .eq('user_id', _userId!)
          .gte('completed_at', startOfDay.toIso8601String())
          .lt('completed_at', endOfDay.toIso8601String())
          .limit(1);

      return completions != null && (completions as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error checking task completion: $e');
      return false;
    }
  }

  // Get today's completion record for a task (if exists)
  Future<Map<String, dynamic>?> getTodayCompletion(String taskId) async {
    if (_userId == null) return null;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final completions = await _supabase
          .from('task_completions')
          .select('id, xp_gained, completed_at')
          .eq('task_id', taskId)
          .eq('user_id', _userId!)
          .gte('completed_at', startOfDay.toIso8601String())
          .lt('completed_at', endOfDay.toIso8601String())
          .limit(1)
          .maybeSingle();

      return completions;
    } catch (e) {
      debugPrint('Error getting today completion: $e');
      return null;
    }
  }

  // Revert/undo task completion for today
  // This removes the completion record and reverses the XP gain
  Future<void> revertTaskCompletion(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Get task info
      final task = await getTaskById(taskId);
      if (task == null) throw Exception('Task not found');

      final taskOwnerId = task['user_id'] as String?;
      final planId = task['plan_id'] as String?;
      final isOwner = taskOwnerId == _userId;
      final isPublicPlanTask = planId != null && !isOwner;

      // Get today's completion record
      final completion = await getTodayCompletion(taskId);
      if (completion == null) {
        throw Exception('No completion found for today. Nothing to revert.');
      }

      final completionId = completion['id'] as String;
      final xpGained = completion['xp_gained'] as int? ?? 0;

      // Delete the completion record
      await _supabase
          .from('task_completions')
          .delete()
          .eq('id', completionId)
          .eq('user_id', _userId!);

      // Verify deletion was successful by checking if record still exists
      await Future.delayed(const Duration(milliseconds: 100)); // Small delay for database consistency
      final verifyCompletion = await getTodayCompletion(taskId);
      if (verifyCompletion != null) {
        debugPrint('⚠️ Warning: Completion record still exists after deletion attempt');
        throw Exception('Failed to delete completion record. Please try again.');
      }

      // Revert XP (subtract the XP that was gained)
      // Note: The database trigger should handle this, but we'll also update manually
      // to ensure consistency. The trigger might not fire on delete, so we need to handle XP reversal.
      if (xpGained > 0) {
        // Get current user XP
        final userProfile = await _supabase
            .from('profiles')
            .select('current_xp')
            .eq('id', _userId!)
            .single();

        final currentXp = userProfile['current_xp'] as int? ?? 0;
        final newXp = (currentXp - xpGained).clamp(0, double.infinity).toInt();

        // Update user XP
        await _supabase
            .from('profiles')
            .update({'current_xp': newXp})
            .eq('id', _userId!);
      }

      // Revert task status if user is the owner (only for non-public-plan tasks)
      if (isOwner && !isPublicPlanTask) {
        await updateTask(taskId, status: 'active');
      }

      // Create activity record for the revert
      await _supabase.from('activities').insert({
        'user_id': _userId!,
        'type': 'task_reverted',
        'task_id': taskId,
        'message': "reverted completion of '${task['title']}'",
        'xp_gained': -xpGained, // Negative to show XP was removed
      });

      // Final verification: ensure completion record is gone
      final finalCheck = await getTodayCompletion(taskId);
      if (finalCheck != null) {
        debugPrint('⚠️ Warning: Completion record still exists after deletion attempt');
        throw Exception('Completion record was not fully deleted. Please refresh and try again.');
      }

      debugPrint('✅ Task completion reverted successfully');
    } catch (e) {
      debugPrint('❌ Error reverting task completion: $e');
      rethrow;
    }
  }

  // Get task streak data
  Future<Map<String, dynamic>?> getTaskStreak(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('task_streaks')
          .select()
          .eq('task_id', taskId)
          .eq('user_id', _userId!)
          .maybeSingle();

      if (response == null) return null;

      // Clamp negative or null streak values to zero
      final currentStreak = (response['current_streak'] as int?) ?? 0;
      final maxStreak = (response['max_streak'] as int?) ?? 0;
      final weekProgress = response['week_progress'] as List<dynamic>? ?? [];

      response['current_streak'] = currentStreak < 0 ? 0 : currentStreak;
      response['max_streak'] = maxStreak < 0 ? 0 : maxStreak;
      response['week_progress'] = weekProgress;

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get overall user streak (consecutive days with any task completion)
  Future<Map<String, dynamic>> getOverallUserStreak() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Get all unique completion dates for the user, ordered by date descending
      final completionsResponse = await _supabase
          .from('task_completions')
          .select('completed_at')
          .eq('user_id', _userId!)
          .order('completed_at', ascending: false);

      final completions = List<Map<String, dynamic>>.from(completionsResponse);
      
      if (completions.isEmpty) {
        return {
          'current_streak': 0,
          'longest_streak': 0,
          'last_completed_at': null,
        };
      }

      // Calculate current streak (consecutive days from today backwards)
      int currentStreak = 0;
      DateTime? lastDate;
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      // Get unique dates
      final uniqueDates = <DateTime>{};
      for (final completion in completions) {
        final completedAt = DateTime.parse(completion['completed_at'] as String);
        final completedDate = DateTime(completedAt.year, completedAt.month, completedAt.day);
        uniqueDates.add(completedDate);
      }
      
      final sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));
      
      // Calculate current streak - count consecutive days backwards from today
      DateTime expectedDate = todayDate;
      for (final date in sortedDates) {
        final daysDiff = expectedDate.difference(date).inDays;
        if (daysDiff == 0 || daysDiff == 1) {
          // Today or yesterday - continue streak
          if (daysDiff == 0) {
            currentStreak++;
            expectedDate = date.subtract(const Duration(days: 1));
          } else {
            // Yesterday - continue streak
            currentStreak++;
            expectedDate = date.subtract(const Duration(days: 1));
          }
          lastDate = date;
        } else {
          // Gap found - streak ends
          break;
        }
      }

      // Calculate longest streak
      int longestStreak = 0;
      int tempStreak = 0;
      DateTime? prevDate;
      
      for (final date in sortedDates) {
        if (prevDate == null) {
          tempStreak = 1;
          prevDate = date;
        } else {
          final daysDiff = prevDate.difference(date).inDays;
          if (daysDiff == 1) {
            tempStreak++;
          } else {
            longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
            tempStreak = 1;
          }
          prevDate = date;
        }
      }
      longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

      return {
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_completed_at': sortedDates.isNotEmpty ? sortedDates.first.toIso8601String() : null,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Get all active streaks for the user (tasks with streak data)
  Future<List<Map<String, dynamic>>> getAllActiveStreaks() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Get all streaks with task information
      final streaksResponse = await _supabase
          .from('task_streaks')
          .select('''
            *,
            tasks:tasks!inner(
              id,
              title,
              is_recurring,
              status
            )
          ''')
          .eq('user_id', _userId!)
          .eq('tasks.status', 'active')
          .eq('tasks.is_recurring', true)
          .gt('current_streak', 0)
          .order('current_streak', ascending: false);

      final streaks = List<Map<String, dynamic>>.from(streaksResponse);
      
      // Transform to match the expected format
      return streaks.map((streak) {
        final task = streak['tasks'] as Map<String, dynamic>?;
        return {
          'id': task?['id']?.toString(),
          'title': task?['title'] ?? 'Untitled Task',
          'dayCount': streak['current_streak'] as int? ?? 0,
          'maxStreak': streak['max_streak'] as int? ?? 0,
          'hasStreakBonus': streak['has_streak_bonus'] as bool? ?? false,
          'lastCompletedAt': streak['last_completed_at'],
        };
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get completion counts for the last 7 days (tasks & plan tasks)
  Future<List<Map<String, dynamic>>> getWeeklyCompletionCounts() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

      final response = await _supabase
          .from('task_completions')
          .select('task_id, completed_at')
          .eq('user_id', _userId!)
          .gte('completed_at', start.toIso8601String())
          .order('completed_at', ascending: true);

      final completions = List<Map<String, dynamic>>.from(response);

      // Initialize last 7 days map with zero counts
      final Map<String, int> dailyCounts = {};
      for (int i = 0; i < 7; i++) {
        final date = start.add(Duration(days: i));
        final key = DateTime(date.year, date.month, date.day).toIso8601String();
        dailyCounts[key] = 0;
      }

      // Tally completions per day
      for (final completion in completions) {
        final completedAt = completion['completed_at'];
        if (completedAt == null) continue;
        final date = DateTime.parse(completedAt.toString());
        final normalized = DateTime(date.year, date.month, date.day).toIso8601String();
        if (dailyCounts.containsKey(normalized)) {
          dailyCounts[normalized] = (dailyCounts[normalized] ?? 0) + 1;
        }
      }

      // Build ordered list for UI
      final List<Map<String, dynamic>> result = [];
      dailyCounts.forEach((dateIso, count) {
        final date = DateTime.parse(dateIso);
        result.add({
          'date': date,
          'label': _weekdayLabel(date.weekday),
          'count': count,
        });
      });

      // Ensure chronological order (oldest -> newest)
      result.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      return result;
    } catch (e) {
      rethrow;
    }
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

  // Get task participants (for collaborative tasks)
  Future<List<Map<String, dynamic>>> getTaskParticipants(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // First get the task to find the owner
      final task = await getTaskById(taskId);
      final taskOwnerId = task?['user_id'] as String?;
      
      final response = await _supabase
          .from('task_participants')
          .select('''
            *,
            profiles:user_id (
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('task_id', taskId);

      // CRITICAL: Filter out the task owner from participants list
      // The owner is not a participant, they're the owner
      final participants = List<Map<String, dynamic>>.from(response)
          .where((participant) {
            final participantUserId = participant['user_id'] as String?;
            // Exclude task owner from participants list
            return participantUserId != null && participantUserId != taskOwnerId;
          })
          .toList();

      return participants;
    } catch (e) {
      rethrow;
    }
  }

  // Get task comments
  Future<List<Map<String, dynamic>>> getTaskComments(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('task_comments')
          .select('''
            *,
            profiles:user_id (
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('task_id', taskId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Add comment to task
  Future<Map<String, dynamic>> addComment(String taskId, String content) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('task_comments')
          .insert({
            'task_id': taskId,
            'user_id': _userId!,
            'content': content,
          })
          .select('''
            *,
            profiles:user_id (
              id,
              full_name,
              avatar_url
            )
          ''')
          .single();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Add friend as participant to task
  Future<void> addFriendToTask(String taskId, String friendId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // First, ensure task is collaborative
      final task = await getTaskById(taskId);
      if (task == null) throw Exception('Task not found');

      if (task['is_collaborative'] != true) {
        // Make task collaborative
        await updateTask(taskId, isCollaborative: true);
      }

      // Check if participant already exists
      final existing = await _supabase
          .from('task_participants')
          .select()
          .eq('task_id', taskId)
          .eq('user_id', friendId)
          .maybeSingle();

      if (existing == null) {
        // Add friend as participant
        await _supabase.from('task_participants').insert({
          'task_id': taskId,
          'user_id': friendId,
          'role': 'participant',
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Remove friend from task
  Future<void> removeFriendFromTask(String taskId, String friendId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('task_participants')
          .delete()
          .eq('task_id', taskId)
          .eq('user_id', friendId);
    } catch (e) {
      rethrow;
    }
  }

  // Accept collaboration invitation
  Future<void> acceptCollaborationInvitation(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      print('🔄 Accepting invitation for task $taskId, user $_userId');
      
      // First, verify the participant record exists
      final check = await _supabase
          .from('task_participants')
          .select('*')
          .eq('task_id', taskId)
          .eq('user_id', _userId!)
          .maybeSingle();
      
      if (check == null) {
        throw Exception('Participant record not found for task $taskId');
      }
      
      print('📋 Found participant record: status=${check['status']}, task_id=${check['task_id']}');
      
      // Update the status
      final result = await _supabase
          .from('task_participants')
          .update({'status': 'accepted'})
          .eq('task_id', taskId)
          .eq('user_id', _userId!)
          .select();
      
      print('✅ Update result: $result');
      
      // Verify the update succeeded
      final verify = await _supabase
          .from('task_participants')
          .select('status')
          .eq('task_id', taskId)
          .eq('user_id', _userId!)
          .maybeSingle();
      
      if (verify == null || verify['status'] != 'accepted') {
        throw Exception('Failed to update participant status. Current status: ${verify?['status']}');
      }
      
      print('✅ Verified: Status is now ${verify['status']}');
    } catch (e) {
      print('❌ Error accepting invitation: $e');
      rethrow;
    }
  }

  // Refuse collaboration invitation
  Future<void> refuseCollaborationInvitation(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('task_participants')
          .update({'status': 'refused'})
          .eq('task_id', taskId)
          .eq('user_id', _userId!)
          .eq('status', 'pending');
    } catch (e) {
      rethrow;
    }
  }

  // Get tasks where user has pending collaboration invitations
  Future<List<Map<String, dynamic>>> getPendingCollaborationTasks() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      print('Fetching pending collaboration tasks for user: $_userId');
      
      // First get the task IDs where user has pending invitations
      // CRITICAL: RLS policy "Users can view task participants" must allow this query
      List<Map<String, dynamic>> participantsResponse;
      
      // DIAGNOSTIC: First check ALL participants for this user (without status filter)
      // This helps us see what's actually in the database
      try {
        print('🔍 DIAGNOSTIC: Querying ALL task_participants for user: $_userId (no status filter)');
        final allParticipantsQuery = await _supabase
            .from('task_participants')
            .select('task_id, status, user_id')
            .eq('user_id', _userId!);
        
        final allParticipants = List<Map<String, dynamic>>.from(allParticipantsQuery);
        print('📊 DIAGNOSTIC: Found ${allParticipants.length} total participants for this user');
        
        if (allParticipants.isNotEmpty) {
          print('📋 DIAGNOSTIC: All participants:');
          for (var p in allParticipants) {
            final status = p['status'];
            final statusStr = status == null ? 'NULL' : status.toString();
            print('   - task_id: ${p['task_id']}, status: $statusStr');
          }
          
          // Count by status
          final pendingCount = allParticipants.where((p) => p['status'] == 'pending').length;
          final acceptedCount = allParticipants.where((p) => p['status'] == 'accepted').length;
          final refusedCount = allParticipants.where((p) => p['status'] == 'refused').length;
          final nullCount = allParticipants.where((p) => p['status'] == null).length;
          
          print('📊 DIAGNOSTIC: Status breakdown - pending: $pendingCount, accepted: $acceptedCount, refused: $refusedCount, NULL: $nullCount');
        } else {
          print('⚠️ DIAGNOSTIC: No participants found at all for this user');
          print('💡 This could mean: 1) User was never invited, 2) RLS is blocking, 3) Wrong user_id');
          print('💡 ACTION: Check Supabase dashboard - task_participants table for user_id: $_userId');
        }
      } catch (e) {
        print('❌ DIAGNOSTIC query failed: $e');
        print('💡 This suggests RLS policy issue - run FIX_TASK_PARTICIPANTS_RLS_VIEW.sql');
      }
      
      try {
        // Try querying with status field
        print('🔍 Querying task_participants for user: $_userId with status=pending');
        final queryResponse = await _supabase
            .from('task_participants')
            .select('task_id, status, user_id')
            .eq('user_id', _userId!)
            .eq('status', 'pending');
        
        participantsResponse = List<Map<String, dynamic>>.from(queryResponse);
        print('✅ Query succeeded: Found ${participantsResponse.length} pending participants with status field');
        
        // Debug: Print all participants found
        if (participantsResponse.isNotEmpty) {
          print('📋 Participant details: ${participantsResponse.map((p) => 'task_id: ${p['task_id']}, status: ${p['status']}').toList()}');
        }
      } catch (e) {
        print('❌ Status column query failed: $e');
        print('💡 This might be: 1) RLS policy blocking, 2) Status column missing, 3) Query error');
        
        // Try without status filter to see if RLS is the issue
        try {
          print('🔄 Trying query without status filter to test RLS...');
          final fallbackResponse = await _supabase
              .from('task_participants')
              .select('task_id, user_id, status')
              .eq('user_id', _userId!);
          
          final allParticipants = List<Map<String, dynamic>>.from(fallbackResponse);
          print('📊 Found ${allParticipants.length} total participants for user (without status filter)');
          
          if (allParticipants.isNotEmpty) {
            print('📋 All participants: ${allParticipants.map((p) => 'task_id: ${p['task_id']}, status: ${p['status'] ?? "NULL"}').toList()}');
            // Filter to pending manually
            participantsResponse = allParticipants.where((p) {
              final status = p['status'];
              return status == null || status == 'pending';
            }).toList();
            print('✅ Filtered to ${participantsResponse.length} pending participants');
          } else {
            participantsResponse = [];
            print('⚠️ No participants found at all - RLS might be blocking or user has no participants');
          }
        } catch (e2) {
          print('❌ Fallback query also failed: $e2');
          print('💡 This strongly suggests RLS policy issue - run FIX_TASK_PARTICIPANTS_RLS_VIEW.sql');
          participantsResponse = [];
        }
      }

      if (participantsResponse.isEmpty) {
        print('⚠️ No pending participants found for user: $_userId');
        print('💡 Check: 1) SQL migration ADD_PARTICIPANT_STATUS.sql was run, 2) Participants were created, 3) Status is set to "pending"');
        return [];
      }

      final taskIds = participantsResponse
          .map((p) => p['task_id'] as String)
          .toList();
      
      print('✅ Found ${taskIds.length} pending invitations');
      print('📋 Fetching tasks with IDs: $taskIds');

      // Now fetch the tasks with owner profile information
      // We need to get tasks that the user is invited to (not owned by them)
      // Since RLS might block, we'll use a different approach - get all tasks and filter
      final List<Map<String, dynamic>> tasks = [];
      
      for (final taskId in taskIds) {
        try {
          // Try direct query first (bypasses getTaskById which might have RLS issues)
          // Since we know the user is a participant, RLS should allow this
          print('🔍 Attempting to fetch task $taskId directly...');
          
          Map<String, dynamic>? task;
          
          // Method 1: Try direct query with RLS policy
          try {
            final directResponse = await _supabase
                .from('tasks')
                .select('*')
                .eq('id', taskId)
                .eq('is_collaborative', true)
                .maybeSingle();
            
            if (directResponse != null) {
              task = Map<String, dynamic>.from(directResponse);
              print('✅ Direct query succeeded for task $taskId');
            }
          } catch (e) {
            print('⚠️ Direct query failed: $e');
          }
          
          // Method 2: Fallback to getTaskById if direct query failed
          if (task == null) {
            print('🔄 Trying getTaskById as fallback...');
            task = await getTaskById(taskId);
            if (task != null) {
              print('✅ getTaskById succeeded for task $taskId');
            }
          }
          
          if (task == null) {
            print('❌ Could not fetch task $taskId - RLS might be blocking or task does not exist');
            print('💡 Check: 1) RLS policy "Users can view collaborative tasks" exists, 2) Task is marked as collaborative, 3) User is in task_participants');
            continue;
          }
          
          final taskOwnerId = task['user_id'] as String?;
          final isCollaborative = task['is_collaborative'] as bool? ?? false;
          print('📋 Task details - owner: $taskOwnerId, is_collaborative: $isCollaborative, current user: $_userId');
          
          // Only include tasks not owned by current user (they're invitations)
          if (taskOwnerId != null && taskOwnerId != _userId!) {
            print('✅ Task $taskId is an invitation (owner: $taskOwnerId, current user: $_userId)');
            
            // Fetch owner profile separately
            try {
              final profileResponse = await _supabase
                  .from('profiles')
                  .select('id, full_name, avatar_url')
                  .eq('id', taskOwnerId)
                  .maybeSingle();
              
              if (profileResponse != null) {
                task['profiles'] = profileResponse;
                print('✅ Fetched owner profile: ${profileResponse['full_name']}');
              } else {
                print('⚠️ Owner profile not found for user: $taskOwnerId');
                // Fallback if profile doesn't exist
                task['profiles'] = {
                  'id': taskOwnerId,
                  'full_name': null,
                  'avatar_url': null,
                };
              }
            } catch (e) {
              print('❌ Error fetching profile for user $taskOwnerId: $e');
              // Add empty profile as fallback
              task['profiles'] = {
                'id': taskOwnerId,
                'full_name': null,
                'avatar_url': null,
              };
            }
            
            tasks.add(task);
            print('✅ Added task to invitations list: ${task['title']}');
          } else {
            print('⚠️ Skipping task $taskId: owned by current user (owner: $taskOwnerId, current: $_userId)');
          }
        } catch (e) {
          print('❌ Error fetching task $taskId: $e');
          print('📚 Error details: ${e.toString()}');
          print('📚 Stack trace: ${StackTrace.current}');
          // Continue with next task
        }
      }
      
      print('📊 Final result: Found ${tasks.length} pending collaboration tasks after filtering');
      if (tasks.isNotEmpty) {
        print('📝 Task titles: ${tasks.map((t) => t['title']).toList()}');
      }
      
      return tasks;
    } catch (e) {
      // Log error for debugging
      print('Error fetching pending collaboration tasks: $e');
      print('Stack trace: ${StackTrace.current}');
      // Return empty list instead of throwing to prevent UI errors
      return [];
    }
  }

  // Helper: Calculate XP reward based on difficulty
  int _calculateXpReward(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 10;
      case 'medium':
        return 20;
      case 'hard':
        return 30;
      default:
        return 20;
    }
  }
}

