import 'supabase_service.dart';

class ActivityService {
  final _supabase = SupabaseService.client;

  // Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  // Get recent activities (for current user and friends)
  Future<List<Map<String, dynamic>>> getRecentActivities({
    int limit = 20,
    String? type,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      var query = _supabase
          .from('activities')
          .select('''
            *,
            user:user_id (
              id,
              full_name,
              avatar_url
            ),
            task:tasks (
              id,
              title
            )
          ''');

      if (type != null) {
        query = query.eq('type', type);
      }

      final response = await query.order('created_at', ascending: false).limit(limit);

      final activities = List<Map<String, dynamic>>.from(response);

      // Format activities for display
      return activities.map((activity) {
        final user = activity['user'] as Map<String, dynamic>?;
        final task = activity['task'] as Map<String, dynamic>?;

        return {
          'id': activity['id'],
          'type': activity['type'],
          'userName': user?['full_name'] ?? 'User',
          'userAvatar': user?['avatar_url'] ?? '',
          'message': activity['message'],
          'timestamp': DateTime.parse(activity['created_at']),
          'xpGained': activity['xp_gained'],
          'taskTitle': task?['title'],
        };
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Create activity
  Future<Map<String, dynamic>> createActivity({
    required String type,
    required String message,
    String? taskId,
    String? friendId,
    int? xpGained,
    Map<String, dynamic>? metadata,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final activityData = {
        'user_id': _userId!,
        'type': type,
        'message': message,
        'task_id': taskId,
        'friend_id': friendId,
        'xp_gained': xpGained,
        'metadata': metadata,
      };

      final response = await _supabase
          .from('activities')
          .insert(activityData)
          .select()
          .single();

      return response;
    } catch (e) {
      rethrow;
    }
  }
}

