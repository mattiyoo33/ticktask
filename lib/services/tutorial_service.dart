/// Tutorial Service
/// 
/// This service handles tutorial/onboarding functionality. It tracks whether
/// a user has completed the tutorial and provides methods to check and mark
/// tutorial completion.
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class TutorialService {
  final _supabase = SupabaseService.client;

  // Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  // Check if user has completed the tutorial
  Future<bool> hasCompletedTutorial() async {
    if (_userId == null) return false;

    try {
      final response = await _supabase
          .from('profiles')
          .select('tutorial_completed')
          .eq('id', _userId!)
          .maybeSingle();

      if (response == null) return false;
      return response['tutorial_completed'] as bool? ?? false;
    } catch (e) {
      debugPrint('Error checking tutorial completion: $e');
      return false; // Default to false if error (show tutorial)
    }
  }

  // Mark tutorial as completed
  Future<void> markTutorialCompleted() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('profiles')
          .update({'tutorial_completed': true})
          .eq('id', _userId!);

      debugPrint('✅ Tutorial marked as completed');
    } catch (e) {
      debugPrint('Error marking tutorial as completed: $e');
      rethrow;
    }
  }

  // Reset tutorial (for testing or if user wants to see it again)
  Future<void> resetTutorial() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('profiles')
          .update({'tutorial_completed': false})
          .eq('id', _userId!);

      debugPrint('✅ Tutorial reset');
    } catch (e) {
      debugPrint('Error resetting tutorial: $e');
      rethrow;
    }
  }
}

