/// Public Task Service
/// 
/// Handles all public task operations including creating, joining, leaving,
/// and fetching public tasks with categories and search functionality.
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class PublicTaskService {
  final _supabase = SupabaseService.client;

  // Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  // Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  // Get public tasks with optional filters
  Future<List<Map<String, dynamic>>> getPublicTasks({
    String? categoryId,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      debugPrint('🔍 Fetching public tasks with filters: categoryId=$categoryId, searchQuery=$searchQuery');
      var filterQuery = _supabase
          .from('tasks')
          .select('''
            *,
            categories:category_id(*)
          ''')
          .eq('is_public', true)
          .isFilter('plan_id', null); // Exclude tasks that belong to plans from Discover

      if (categoryId != null) {
        filterQuery = filterQuery.eq('category_id', categoryId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        filterQuery = filterQuery.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      var orderedQuery = filterQuery.order('created_at', ascending: false);

      if (limit != null) {
        orderedQuery = orderedQuery.limit(limit);
      }

      if (offset != null) {
        orderedQuery = orderedQuery.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await orderedQuery;
      final tasks = List<Map<String, dynamic>>.from(response);
      
      // Fetch owner profiles and actual participant counts separately
      final tasksWithProfiles = await Future.wait(tasks.map((task) async {
        final userId = task['user_id'] as String?;
        final taskId = task['id'] as String?;
        
        // Fetch owner profile
        if (userId != null) {
          try {
            final profile = await _supabase
                .from('profiles')
                .select('id, full_name, avatar_url')
                .eq('id', userId)
                .maybeSingle();
            task['profiles'] = profile;
          } catch (e) {
            debugPrint('⚠️ Error fetching profile for user $userId: $e');
            task['profiles'] = null;
          }
        } else {
          task['profiles'] = null;
        }
        
        // Fetch actual participant count
        if (taskId != null) {
          try {
            final participantResponse = await _supabase
                .from('public_task_participants')
                .select('id')
                .eq('task_id', taskId);
            task['public_join_count'] = (participantResponse as List).length;
            debugPrint('📊 Task $taskId: ${task['public_join_count']} participants');
          } catch (e) {
            debugPrint('⚠️ Error fetching participant count for task $taskId: $e');
            task['public_join_count'] = task['public_join_count'] ?? 0;
          }
        }
        
        return task;
      }));
      
      debugPrint('✅ Fetched ${tasksWithProfiles.length} public tasks');
      return tasksWithProfiles;
    } catch (e) {
      debugPrint('❌ Error fetching public tasks: $e');
      throw Exception('Failed to fetch public tasks: $e');
    }
  }

  // Get a single public task by ID
  Future<Map<String, dynamic>?> getPublicTaskById(String taskId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('''
            *,
            categories:category_id(*),
            public_task_participants(*)
          ''')
          .eq('id', taskId)
          .eq('is_public', true)
          .maybeSingle();

      if (response == null) return null;
      
      final task = response;
      
      // Fetch owner profile separately
      final userId = task['user_id'] as String?;
      if (userId != null) {
        try {
          final profile = await _supabase
              .from('profiles')
              .select('id, full_name, avatar_url')
              .eq('id', userId)
              .maybeSingle();
          task['profiles'] = profile;
        } catch (e) {
          debugPrint('⚠️ Error fetching owner profile: $e');
          task['profiles'] = null;
        }
      }
      
      // Fetch participant profiles separately
      final participants = task['public_task_participants'] as List?;
      if (participants != null && participants.isNotEmpty) {
        final participantsWithProfiles = await Future.wait(
          participants.map((participant) async {
            final participantUserId = participant['user_id'] as String?;
            if (participantUserId != null) {
              try {
                final profile = await _supabase
                    .from('profiles')
                    .select('id, full_name, avatar_url')
                    .eq('id', participantUserId)
                    .maybeSingle();
                participant['profiles'] = profile;
              } catch (e) {
                debugPrint('⚠️ Error fetching participant profile: $e');
                participant['profiles'] = null;
              }
            }
            return participant;
          }),
        );
        task['public_task_participants'] = participantsWithProfiles;
      }
      
      return task;
    } catch (e) {
      debugPrint('❌ Error fetching public task by ID: $e');
      return null;
    }
  }

  // Create a public task
  Future<Map<String, dynamic>> createPublicTask({
    required String title,
    required String description,
    required String categoryId,
    DateTime? dueDate,
    String? difficulty,
    bool? isRecurring,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final taskData = {
        'user_id': _userId!,
        'title': title,
        'description': description,
        'category_id': categoryId,
        'is_public': true,
        'is_collaborative': false, // Public tasks are not collaborative
        'status': 'active',
        'due_date': dueDate?.toIso8601String(),
        'difficulty': difficulty ?? 'medium',
        'is_recurring': isRecurring ?? false,
        'public_join_count': 0,
      };

      final response = await _supabase
          .from('tasks')
          .insert(taskData)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to create public task: $e');
    }
  }

  // Join a public task
  Future<void> joinPublicTask(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Check if already joined
      final existing = await _supabase
          .from('public_task_participants')
          .select()
          .eq('task_id', taskId)
          .eq('user_id', _userId!)
          .maybeSingle();

      if (existing != null) {
        throw Exception('You have already joined this task');
      }

      // Check if user is the owner
      final task = await _supabase
          .from('tasks')
          .select('user_id')
          .eq('id', taskId)
          .single();

      if (task['user_id'] == _userId) {
        throw Exception('You cannot join your own task');
      }

      await _supabase
          .from('public_task_participants')
          .insert({
            'task_id': taskId,
            'user_id': _userId!,
            'joined_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  // Leave a public task
  Future<void> leavePublicTask(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final result = await _supabase
          .from('public_task_participants')
          .delete()
          .eq('task_id', taskId)
          .eq('user_id', _userId!)
          .select();

      if (result.isEmpty) {
        throw Exception('You are not a participant of this task');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Check if user has joined a public task
  Future<bool> hasJoinedPublicTask(String taskId) async {
    if (_userId == null) return false;

    try {
      final response = await _supabase
          .from('public_task_participants')
          .select()
          .eq('task_id', taskId)
          .eq('user_id', _userId!)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get public task participants with leaderboard data
  Future<List<Map<String, dynamic>>> getPublicTaskParticipants(String taskId) async {
    try {
      debugPrint('🔍 Fetching participants for task: $taskId');
      
      // Get task info to include owner
      final taskResponse = await _supabase
          .from('tasks')
          .select('user_id, created_at')
          .eq('id', taskId)
          .maybeSingle();
      
      final taskOwnerId = taskResponse?['user_id'] as String?;
      
      final response = await _supabase
          .from('public_task_participants')
          .select('*')
          .eq('task_id', taskId);

      final participants = List<Map<String, dynamic>>.from(response);
      debugPrint('📊 Found ${participants.length} participants in database');
      
      // Add task owner if not already in participants list
      if (taskOwnerId != null) {
        final ownerInList = participants.any((p) => p['user_id'] == taskOwnerId);
        if (!ownerInList) {
          participants.add({
            'user_id': taskOwnerId,
            'task_id': taskId,
            'joined_at': taskResponse?['created_at'] ?? DateTime.now().toIso8601String(),
            'is_owner': true,
          });
        }
      }
      
      // Fetch profiles separately and calculate task-specific XP
      final participantsWithProfiles = await Future.wait(
        participants.map((participant) async {
          final participantUserId = participant['user_id'] as String?;
          if (participantUserId != null) {
            try {
              final profile = await _supabase
                  .from('profiles')
                  .select('id, full_name, avatar_url, total_xp, current_xp, level')
                  .eq('id', participantUserId)
                  .maybeSingle();
              participant['profiles'] = profile;
              
              // Calculate task-specific XP from task_completions
              try {
                final completionsResponse = await _supabase
                    .from('task_completions')
                    .select('xp_gained')
                    .eq('task_id', taskId)
                    .eq('user_id', participantUserId);
                
                final completions = List<Map<String, dynamic>>.from(completionsResponse);
                final taskXp = completions.fold<int>(
                  0,
                  (sum, completion) => sum + (completion['xp_gained'] as int? ?? 0),
                );
                
                // Add task-specific XP to participant data
                participant['task_xp'] = taskXp;
                debugPrint('📊 User $participantUserId: $taskXp XP from task $taskId');
              } catch (e) {
                debugPrint('⚠️ Error calculating task XP for $participantUserId: $e');
                participant['task_xp'] = 0;
              }
            } catch (e) {
              debugPrint('⚠️ Error fetching participant profile for $participantUserId: $e');
              participant['profiles'] = null;
              participant['task_xp'] = 0;
            }
          } else {
            participant['task_xp'] = 0;
          }
          return participant;
        }),
      );
      
      // Sort by task-specific XP (descending) for leaderboard ranking
      participantsWithProfiles.sort((a, b) {
        final aTaskXp = a['task_xp'] as int? ?? 0;
        final bTaskXp = b['task_xp'] as int? ?? 0;
        if (aTaskXp != bTaskXp) {
          return bTaskXp.compareTo(aTaskXp); // Descending order (highest XP first)
        }
        // If XP is equal, sort by completed_count, then contribution
        final aCompleted = a['completed_count'] as int? ?? 0;
        final bCompleted = b['completed_count'] as int? ?? 0;
        if (aCompleted != bCompleted) {
          return bCompleted.compareTo(aCompleted);
        }
        final aContribution = a['contribution'] as int? ?? 0;
        final bContribution = b['contribution'] as int? ?? 0;
        return bContribution.compareTo(aContribution);
      });
      
      debugPrint('✅ Returning ${participantsWithProfiles.length} participants with profiles');
      return participantsWithProfiles;
    } catch (e) {
      debugPrint('❌ Error fetching participants: $e');
      throw Exception('Failed to fetch participants: $e');
    }
  }

  // Delete a public task (owner only)
  Future<void> deletePublicTask(String taskId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Check if user is the owner
      final task = await _supabase
          .from('tasks')
          .select('user_id')
          .eq('id', taskId)
          .single();

      if (task['user_id'] != _userId) {
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
}

