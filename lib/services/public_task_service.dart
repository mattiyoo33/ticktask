/// Public Task Service
/// 
/// Handles all public task operations including creating, joining, leaving,
/// and fetching public tasks with categories and search functionality.
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
      var filterQuery = _supabase
          .from('tasks')
          .select('''
            *,
            categories:category_id(*),
            profiles:user_id(id, full_name, email, avatar_url),
            public_task_participants(count)
          ''')
          .eq('is_public', true);

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
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
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
            profiles:user_id(id, full_name, email, avatar_url),
            public_task_participants(
              *,
              profiles:user_id(id, full_name, email, avatar_url)
            )
          ''')
          .eq('id', taskId)
          .eq('is_public', true)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
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

      return response as Map<String, dynamic>;
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
      final response = await _supabase
          .from('public_task_participants')
          .select('''
            *,
            profiles:user_id(id, full_name, email, avatar_url)
          ''')
          .eq('task_id', taskId)
          .order('completed_count', ascending: false)
          .order('contribution', ascending: false)
          .order('joined_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
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

