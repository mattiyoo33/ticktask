import 'package:supabase_flutter/supabase_flutter.dart';
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
        
        // Get friend profile
        final friendProfile = await _supabase
            .from('profiles')
            .select()
            .eq('id', friendId)
            .single();

        friends.add({
          'id': friendId,
          'name': friendProfile['full_name'] ?? 'User',
          'avatar': friendProfile['avatar_url'] ?? '',
          'level': friendProfile['level'] ?? 1,
          'xp': friendProfile['total_xp'] ?? 0,
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
            requester:requested_by (
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
          .or('user_id.eq.${_userId!},friend_id.eq.${_userId!}')
          .or('user_id.eq.$friendId,friend_id.eq.$friendId')
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

