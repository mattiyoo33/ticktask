/// Task Service
/// 
/// This service handles all task-related operations including creating, reading, updating, and deleting
/// tasks. It manages task completion logic with deadline-based XP rewards (XP is only awarded if tasks
/// are completed on or before their due date/time). The service also handles collaborative task features
/// such as adding friends as participants, managing task participants, and handling task comments with
/// real-time updates. It provides methods for fetching task streaks, calculating XP rewards based on
/// difficulty levels, and managing task statuses (active, completed, overdue, etc.).
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
          // The RLS policy "Users can view collaborative tasks" should allow this
          response = await _supabase
              .from('tasks')
              .select('*')
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
    List<String> participantIds = const [],
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
      await _supabase
          .from('task_participants')
          .update({'status': 'accepted'})
          .eq('task_id', taskId)
          .eq('user_id', _userId!)
          .eq('status', 'pending');
    } catch (e) {
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

