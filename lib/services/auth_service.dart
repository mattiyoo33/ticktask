import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  final _supabase = SupabaseService.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      // If signup successful and user is created, update their profile
      if (response.user != null && fullName != null) {
        // Update user metadata
        await _supabase.auth.updateUser(
          UserAttributes(data: {'full_name': fullName}),
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<UserResponse> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (fullName != null) data['full_name'] = fullName;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      return await _supabase.auth.updateUser(
        UserAttributes(data: data),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile data from database (with fallback to auth metadata)
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      // Try to fetch from profiles table first
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        // Return profile from database
        return {
          'id': response['id'] ?? user.id,
          'email': user.email,
          'full_name': response['full_name'] ?? user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
          'avatar_url': response['avatar_url'] ?? user.userMetadata?['avatar_url'],
          'created_at': response['created_at'] ?? user.createdAt,
          'level': response['level'] ?? 1,
          'current_xp': response['current_xp'] ?? 0,
          'total_xp': response['total_xp'] ?? 0,
        };
      }
    } catch (e) {
      // If profiles table doesn't exist or error, fallback to auth metadata
      debugPrint('Error fetching profile from database: $e');
    }

    // Fallback to auth metadata if profiles table doesn't exist or has no data
    return {
      'id': user.id,
      'email': user.email,
      'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
      'avatar_url': user.userMetadata?['avatar_url'],
      'created_at': user.createdAt,
      'level': 1,
      'current_xp': 0,
      'total_xp': 0,
    };
  }

  // Get user profile data (synchronous - uses cached data)
  Map<String, dynamic>? get userProfile {
    final user = currentUser;
    if (user == null) return null;

    // Return basic profile from auth metadata
    // For full profile with XP/level, use fetchUserProfile()
    return {
      'id': user.id,
      'email': user.email,
      'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
      'avatar_url': user.userMetadata?['avatar_url'],
      'created_at': user.createdAt,
    };
  }

  // Update profile in database
  Future<void> updateProfileInDatabase({
    String? fullName,
    String? avatarUrl,
    int? level,
    int? currentXp,
    int? totalXp,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (level != null) updates['level'] = level;
      if (currentXp != null) updates['current_xp'] = currentXp;
      if (totalXp != null) updates['total_xp'] = totalXp;

      await _supabase
          .from('profiles')
          .upsert({
            'id': user.id,
            ...updates,
          });
    } catch (e) {
      rethrow;
    }
  }
}

