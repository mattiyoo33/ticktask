/// Achievement Service
/// 
/// This service handles achievement tracking and unlocking. Achievements are milestones
/// that users can unlock by completing certain actions like completing their first task,
/// creating their first plan, adding their first friend, maintaining a streak, etc.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'task_service.dart';
import 'plan_service.dart';
import 'friend_service.dart';

class AchievementService {
  final _supabase = SupabaseService.client;
  final _taskService = TaskService();
  final _planService = PlanService();
  final _friendService = FriendService();

  // Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  // Achievement types
  static const String firstDay = 'first_day';
  static const String sevenDayStreak = 'seven_day_streak';
  static const String firstFriend = 'first_friend';
  static const String firstPlan = 'first_plan';
  static const String firstTask = 'first_task';

  // Get all unlocked achievements for current user
  Future<List<Map<String, dynamic>>> getUnlockedAchievements() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .eq('user_id', _userId!)
          .order('unlocked_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching achievements: $e');
      rethrow;
    }
  }

  // Check if user has unlocked a specific achievement
  Future<bool> hasUnlockedAchievement(String achievementType) async {
    if (_userId == null) return false;

    try {
      final response = await _supabase
          .from('achievements')
          .select('id')
          .eq('user_id', _userId!)
          .eq('achievement_type', achievementType)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error checking achievement: $e');
      return false;
    }
  }

  // Unlock an achievement (if not already unlocked)
  Future<void> unlockAchievement(String achievementType) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Check if already unlocked
      final alreadyUnlocked = await hasUnlockedAchievement(achievementType);
      if (alreadyUnlocked) {
        debugPrint('Achievement $achievementType already unlocked');
        return;
      }

      // Insert achievement
      await _supabase.from('achievements').insert({
        'user_id': _userId!,
        'achievement_type': achievementType,
      });

      debugPrint('✅ Achievement unlocked: $achievementType');
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
      // Don't rethrow - achievements are non-critical
    }
  }

  // Check and unlock achievements based on current user state
  Future<void> checkAndUnlockAchievements() async {
    if (_userId == null) return;

    try {
      // Check First Day achievement
      await _checkFirstDayAchievement();

      // Check First Task achievement
      await _checkFirstTaskAchievement();

      // Check First Plan achievement
      await _checkFirstPlanAchievement();

      // Check First Friend achievement
      await _checkFirstFriendAchievement();

      // Check 7 Day Streak achievement
      await _checkSevenDayStreakAchievement();
    } catch (e) {
      debugPrint('Error checking achievements: $e');
      // Don't rethrow - achievements are non-critical
    }
  }

  // Check First Day achievement (account created today)
  Future<void> _checkFirstDayAchievement() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final accountCreatedAt = user.createdAt;
      if (accountCreatedAt == null) return;

      final today = DateTime.now();
      final accountDate = DateTime(
        accountCreatedAt.year,
        accountCreatedAt.month,
        accountCreatedAt.day,
      );
      final todayDate = DateTime(today.year, today.month, today.day);

      if (accountDate == todayDate) {
        await unlockAchievement(firstDay);
      }
    } catch (e) {
      debugPrint('Error checking first day achievement: $e');
    }
  }

  // Check First Task achievement (completed at least one task)
  Future<void> _checkFirstTaskAchievement() async {
    try {
      final hasUnlocked = await hasUnlockedAchievement(firstTask);
      if (hasUnlocked) return;

      // Check if user has any task completions
      final response = await _supabase
          .from('task_completions')
          .select('id')
          .eq('user_id', _userId!)
          .limit(1);

      if ((response as List).isNotEmpty) {
        await unlockAchievement(firstTask);
      }
    } catch (e) {
      debugPrint('Error checking first task achievement: $e');
    }
  }

  // Check First Plan achievement (created at least one plan)
  Future<void> _checkFirstPlanAchievement() async {
    try {
      final hasUnlocked = await hasUnlockedAchievement(firstPlan);
      if (hasUnlocked) return;

      // Check if user has created any plans
      final plans = await _planService.getPlans();
      if (plans.isNotEmpty) {
        await unlockAchievement(firstPlan);
      }
    } catch (e) {
      debugPrint('Error checking first plan achievement: $e');
    }
  }

  // Check First Friend achievement (has at least one friend)
  Future<void> _checkFirstFriendAchievement() async {
    try {
      final hasUnlocked = await hasUnlockedAchievement(firstFriend);
      if (hasUnlocked) return;

      // Check if user has any friends
      final friends = await _friendService.getFriends();
      if (friends.isNotEmpty) {
        await unlockAchievement(firstFriend);
      }
    } catch (e) {
      debugPrint('Error checking first friend achievement: $e');
    }
  }

  // Check 7 Day Streak achievement (current streak >= 7)
  Future<void> _checkSevenDayStreakAchievement() async {
    try {
      final hasUnlocked = await hasUnlockedAchievement(sevenDayStreak);
      if (hasUnlocked) return;

      // Check if user has a streak of 7 or more days
      final streakData = await _taskService.getOverallUserStreak();
      final currentStreak = streakData['current_streak'] as int? ?? 0;

      if (currentStreak >= 7) {
        await unlockAchievement(sevenDayStreak);
      }
    } catch (e) {
      debugPrint('Error checking seven day streak achievement: $e');
    }
  }

  // Get achievement display info
  static Map<String, Map<String, dynamic>> getAchievementInfo() {
    return {
      firstDay: {
        'title': 'First Day!',
        'description': 'Welcome to TickTask!',
        'icon': Icons.emoji_events, // Cup/medal icon
      },
      firstTask: {
        'title': 'Complete your first Task!',
        'description': 'You completed your first task',
        'icon': Icons.emoji_events, // Cup/medal icon
      },
      firstPlan: {
        'title': 'Create your first plan!',
        'description': 'You created your first plan',
        'icon': Icons.emoji_events, // Cup/medal icon
      },
      firstFriend: {
        'title': 'Add your first friend!',
        'description': 'You added your first friend',
        'icon': Icons.emoji_events, // Cup/medal icon
      },
      sevenDayStreak: {
        'title': '7 day streak!',
        'description': 'You maintained a 7-day streak',
        'icon': Icons.emoji_events, // Cup/medal icon
      },
    };
  }
}

