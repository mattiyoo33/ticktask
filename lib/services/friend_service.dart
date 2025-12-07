import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class FriendService {
  final _supabase = SupabaseService.client;

  // Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  // Get all friends (accepted friendships)
  Future<List<Map<String, dynamic>>> getFriends() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('friendships')
          .select('''
            *,
            friend:friend_id (
              id,
              full_name,
              avatar_url,
              level,
              total_xp
            )
          ''')
          .or('user_id.eq.${_userId!},friend_id.eq.${_userId!}')
          .eq('status', 'accepted');

      final friends = <Map<String, dynamic>>[];
      for (var friendship in response) {
        final friendId = friendship['friend_id'] == _userId
            ? friendship['user_id']
            : friendship['friend_id'];
        
        // CRITICAL: Skip if friendId is the current user (shouldn't happen, but safety check)
        if (friendId == _userId) {
          print('Warning: Found self as friend, skipping. Friendship ID: ${friendship['id']}');
          continue;
        }
        
        // Get friend profile with all needed data
        final friendProfile = await _supabase
            .from('profiles')
            .select('id, full_name, avatar_url, level, total_xp, created_at')
            .eq('id', friendId)
            .single();

        // Calculate daily streak (consecutive days with any task completion)
        int dailyStreak = 0;
        try {
          dailyStreak = await _calculateDailyStreak(friendId.toString());
        } catch (e) {
          debugPrint('Error calculating streak for user $friendId: $e');
        }

        // Handle created_at - it might be DateTime or String, and might be null
        String? accountCreatedAtStr;
        final createdAtValue = friendProfile['created_at'];
        if (createdAtValue != null) {
          if (createdAtValue is DateTime) {
            accountCreatedAtStr = createdAtValue.toIso8601String();
          } else if (createdAtValue is String) {
            accountCreatedAtStr = createdAtValue;
          }
        }

        friends.add({
          'id': friendId,
          'name': friendProfile['full_name'] ?? 'User',
          'avatar': friendProfile['avatar_url'] ?? '',
          'level': friendProfile['level'] ?? 1,
          'xp': friendProfile['total_xp'] ?? 0,
          'current_streak': dailyStreak,
          'account_created_at': accountCreatedAtStr,
          'friendship_id': friendship['id'],
        });
      }

      return friends;
    } catch (e) {
      rethrow;
    }
  }

  // Get incoming friend requests
  Future<List<Map<String, dynamic>>> getIncomingRequests() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('friendships')
          .select('''
            *,
            requester:user_id (
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('friend_id', _userId!)
          .eq('status', 'pending');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get outgoing friend requests
  Future<List<Map<String, dynamic>>> getOutgoingRequests() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('friendships')
          .select('''
            *,
            friend:friend_id (
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('user_id', _userId!)
          .eq('status', 'pending');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Send friend request
  Future<Map<String, dynamic>> sendFriendRequest(String friendId) async {
    if (_userId == null) throw Exception('User not authenticated');
    if (_userId == friendId) throw Exception('Cannot add yourself as friend');

    try {
      // Check if friendship already exists
      final existing = await _supabase
          .from('friendships')
          .select()
          .or('and(user_id.eq.${_userId!},friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.${_userId!})')
          .maybeSingle();

      if (existing != null) {
        throw Exception('Friendship already exists');
      }

      final response = await _supabase
          .from('friendships')
          .insert({
            'user_id': _userId!,
            'friend_id': friendId,
            'status': 'pending',
            'requested_by': _userId!,
          })
          .select()
          .single();

      // Create activity
      await _supabase.from('activities').insert({
        'user_id': _userId!,
        'type': 'friend_added',
        'friend_id': friendId,
        'message': 'sent a friend request',
      });

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String friendshipId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('friendships')
          .update({
            'status': 'accepted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId)
          .eq('friend_id', _userId!)
          .eq('status', 'pending');

      // Get friendship to create activity
      final friendship = await _supabase
          .from('friendships')
          .select()
          .eq('id', friendshipId)
          .single();

      // Create activity
      await _supabase.from('activities').insert({
        'user_id': _userId!,
        'type': 'friend_added',
        'friend_id': friendship['user_id'],
        'message': 'accepted a friend request',
      });
    } catch (e) {
      rethrow;
    }
  }

  // Reject friend request
  Future<void> rejectFriendRequest(String friendshipId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('friendships')
          .delete()
          .eq('id', friendshipId)
          .eq('friend_id', _userId!)
          .eq('status', 'pending');
    } catch (e) {
      rethrow;
    }
  }

  // Remove friend
  Future<void> removeFriend(String friendshipId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('friendships')
          .delete()
          .eq('id', friendshipId)
          .or('user_id.eq.${_userId!},friend_id.eq.${_userId!}');
    } catch (e) {
      rethrow;
    }
  }

  // Search users by name or email
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (_userId == null) throw Exception('User not authenticated');
    if (query.trim().isEmpty) return [];

    try {
      // Search in profiles table by full_name
      // Note: We can't search by email directly from profiles, but we can search by name
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, avatar_url, level, total_xp')
          .ilike('full_name', '%$query%')
          .neq('id', _userId!) // Exclude current user
          .limit(20);

      // Get list of existing friendships to exclude
      final friendships = await _supabase
          .from('friendships')
          .select('user_id, friend_id')
          .or('user_id.eq.${_userId!},friend_id.eq.${_userId!}');

      final friendIds = <String>{};
      for (var friendship in friendships) {
        if (friendship['user_id'] == _userId) {
          friendIds.add(friendship['friend_id'] as String);
        } else {
          friendIds.add(friendship['user_id'] as String);
        }
      }

      return List<Map<String, dynamic>>.from(response)
          .where((profile) => !friendIds.contains(profile['id']))
          .map((profile) {
            return {
              'id': profile['id'],
              'name': profile['full_name'] ?? 'User',
              'avatar': profile['avatar_url'] ?? '',
              'level': profile['level'] ?? 1,
              'xp': profile['total_xp'] ?? 0,
            };
          })
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Calculate daily streak for a user (consecutive days with any task completion)
  Future<int> _calculateDailyStreak(String userId) async {
    try {
      // Get all unique completion dates for this user
      final completions = await _supabase
          .from('task_completions')
          .select('completed_at')
          .eq('user_id', userId);

      if (completions.isEmpty) return 0;

      // Get unique dates (normalize to local date strings)
      final completionDates = <String>{};
      for (var completion in completions) {
        final completedAt = completion['completed_at'] as String?;
        if (completedAt != null) {
          final date = DateTime.parse(completedAt).toLocal();
          final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          completionDates.add(dateStr);
        }
      }

      if (completionDates.isEmpty) return 0;

      // Sort dates descending
      final sortedDates = completionDates.toList()..sort((a, b) => b.compareTo(a));

      // Calculate consecutive days starting from today or yesterday
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      int streak = 0;
      DateTime checkDate = today;
      
      // Check if today has a completion
      if (sortedDates.contains(todayStr)) {
        streak = 1;
        checkDate = today.subtract(const Duration(days: 1));
      } else {
        // Start from yesterday (today doesn't count if no completion)
        checkDate = today.subtract(const Duration(days: 1));
      }

      // Count consecutive days backwards
      int daysChecked = 0;
      while (daysChecked < 365) {
        final dateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        
        if (sortedDates.contains(dateStr)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
          daysChecked++;
        } else {
          // Streak broken
          break;
        }
      }

      return streak;
    } catch (e) {
      // Return 0 if calculation fails
      debugPrint('Error calculating streak: $e');
      return 0;
    }
  }

  // Get leaderboard (top users by XP)
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, avatar_url, level, total_xp')
          .order('total_xp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response).map((profile) {
        return {
          'id': profile['id'],
          'name': profile['full_name'] ?? 'User',
          'avatar': profile['avatar_url'] ?? '',
          'xp': profile['total_xp'] ?? 0,
          'level': profile['level'] ?? 1,
          'isCurrentUser': profile['id'] == _userId,
        };
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}

