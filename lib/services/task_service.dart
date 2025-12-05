import 'supabase_service.dart';

class TaskService {
  final _supabase = SupabaseService.client;

  // Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  // Get all tasks for current user
  Future<List<Map<String, dynamic>>> getTasks({
    String? status,
    String? category,
    DateTime? dueDate,
    bool? isRecurring,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      var query = _supabase
          .from('tasks')
          .select()
          .eq('user_id', _userId!);

      if (status != null) {
        query = query.eq('status', status);
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      if (dueDate != null) {
        query = query.eq('due_date', dueDate.toIso8601String());
      }
      if (isRecurring != null) {
        query = query.eq('is_recurring', isRecurring);
      }

      final response = await query.order('due_date', ascending: true).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get today's tasks
  Future<List<Map<String, dynamic>>> getTodaysTasks() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('user_id', _userId!)
          .inFilter('status', ['active', 'scheduled'])
          .or('due_date.is.null,and(due_date.gte.${startOfDay.toIso8601String()},due_date.lt.${endOfDay.toIso8601String()})')
          .order('due_time', ascending: true)
          .order('due_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get task by ID (allows access for task owner or participants)
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

      // If not found as owner, check if user is a participant
      if (response == null) {
        final participantCheck = await _supabase
            .from('task_participants')
            .select('task_id')
            .eq('task_id', taskId)
            .eq('user_id', _userId!)
            .maybeSingle();

        if (participantCheck != null) {
          // User is a participant, fetch the task
          response = await _supabase
              .from('tasks')
              .select()
              .eq('id', taskId)
              .maybeSingle();
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
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
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
      };

      final response = await _supabase
          .from('tasks')
          .insert(taskData)
          .select()
          .single();

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

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_id', _userId!);
    } catch (e) {
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
      final completion = await _supabase
          .from('task_completions')
          .insert({
            'task_id': taskId,
            'user_id': _userId!,
            'xp_gained': actualXpGained,
          })
          .select()
          .single();

      // Update task status
      await updateTask(taskId, status: 'completed');

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

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get task participants (for collaborative tasks)
  Future<List<Map<String, dynamic>>> getTaskParticipants(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
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

      return List<Map<String, dynamic>>.from(response);
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

