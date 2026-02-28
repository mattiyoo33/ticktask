/// Daily Login Service
///
/// Awards XP for opening the app each day. XP increases with consecutive-day streak:
/// Day 1 = 20 XP, Day 2 = 25, Day 3 = 30, Day 4 = 35, Day 5 = 40, Day 6 = 45, Day 7 = 50, Day 8+ = 55 (cap).
/// Milestone achievements at 7, 30, and 100 day streaks.
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import 'auth_service.dart';
import 'achievement_service.dart';

class DailyLoginService {
  final _supabase = SupabaseService.client;
  final _authService = AuthService();

  String? get _userId => _supabase.auth.currentUser?.id;

  /// XP for streak day N: 20 + (min(N, 8) - 1) * 5  => 20, 25, 30, 35, 40, 45, 50, 55
  static const int _baseXp = 20;
  static const int _xpPerDay = 5;
  static const int _maxStreakForXp = 8;
  static const int _maxXp = 50;

  // Use AchievementService milestone types

  /// Call once per app open (e.g. when home dashboard loads). Idempotent per day.
  /// Returns map with 'awarded' (bool), 'xp' (int), 'streak' (int), 'milestone' (int? 7/30/100 if just hit).
  Future<Map<String, dynamic>> recordLoginIfNeeded() async {
    if (_userId == null) return {'awarded': false, 'xp': 0, 'streak': 0};

    try {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Already logged in today?
      final existing = await _supabase
          .from('daily_logins')
          .select('id, xp_awarded')
          .eq('user_id', _userId!)
          .eq('login_date', todayDate.toIso8601String().split('T')[0])
          .maybeSingle();

      if (existing != null) {
        final streak = await _getLoginStreakAfterDate(todayDate);
        return {
          'awarded': false,
          'xp': existing['xp_awarded'] as int? ?? 0,
          'streak': streak
        };
      }

      // Compute streak up to yesterday (consecutive days with a login)
      final yesterday = todayDate.subtract(const Duration(days: 1));
      final streakBeforeToday = await _getLoginStreakEndingAt(yesterday);
      final streakIncludingToday = streakBeforeToday + 1;

      // XP: 20 + (min(streakIncludingToday, 8) - 1) * 5, cap 55
      final effectiveStreak = streakIncludingToday.clamp(1, _maxStreakForXp);
      final xp =
          (_baseXp + (effectiveStreak - 1) * _xpPerDay).clamp(_baseXp, _maxXp);

      // Insert today's login
      await _supabase.from('daily_logins').insert({
        'user_id': _userId!,
        'login_date': todayDate.toIso8601String().split('T')[0],
        'xp_awarded': xp,
      });

      // Add XP to profile (and level up if needed)
      await _addXpToProfile(xp);

      // Milestone achievements at 7, 30, 100
      final achievementService = AchievementService();
      if (streakIncludingToday == 7)
        await achievementService
            .unlockAchievement(AchievementService.loginStreak7);
      if (streakIncludingToday == 30)
        await achievementService
            .unlockAchievement(AchievementService.loginStreak30);
      if (streakIncludingToday == 100)
        await achievementService
            .unlockAchievement(AchievementService.loginStreak100);

      final milestone = streakIncludingToday == 7
          ? 7
          : streakIncludingToday == 30
              ? 30
              : streakIncludingToday == 100
                  ? 100
                  : null;

      return {
        'awarded': true,
        'xp': xp,
        'streak': streakIncludingToday,
        'milestone': milestone,
      };
    } catch (e) {
      debugPrint('DailyLoginService.recordLoginIfNeeded error: $e');
      return {'awarded': false, 'xp': 0, 'streak': 0};
    }
  }

  /// Consecutive days with a login ending on [endDate] (inclusive).
  Future<int> _getLoginStreakEndingAt(DateTime endDate) async {
    if (_userId == null) return 0;
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    int count = 0;
    DateTime d = end;
    while (true) {
      final res = await _supabase
          .from('daily_logins')
          .select('id')
          .eq('user_id', _userId!)
          .eq('login_date', d.toIso8601String().split('T')[0])
          .maybeSingle();
      if (res == null) break;
      count++;
      d = d.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// Current login streak (including today if already logged today).
  Future<int> _getLoginStreakAfterDate(DateTime asOfDate) async {
    final today = DateTime(asOfDate.year, asOfDate.month, asOfDate.day);
    return _getLoginStreakEndingAt(today);
  }

  /// Get current login streak for display (consecutive days including today if logged).
  Future<int> getCurrentLoginStreak() async {
    if (_userId == null) return 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return _getLoginStreakAfterDate(todayDate);
  }

  /// Add XP to current user's profile and handle level-up.
  Future<void> _addXpToProfile(int xpGained) async {
    if (_userId == null || xpGained <= 0) return;

    final profile = await _supabase
        .from('profiles')
        .select('current_xp, total_xp, level')
        .eq('id', _userId!)
        .maybeSingle();

    if (profile == null) return;

    int currentXp = (profile['current_xp'] as int?) ?? 0;
    int totalXp = (profile['total_xp'] as int?) ?? 0;
    int level = (profile['level'] as int?) ?? 1;

    currentXp += xpGained;
    totalXp += xpGained;

    // Level up: next level at 100 * (level^2 * 1.5)
    int nextLevelXp = (100 * (level * level * 1.5)).round();
    while (currentXp >= nextLevelXp) {
      currentXp -= nextLevelXp;
      level++;
      nextLevelXp = (100 * (level * level * 1.5)).round();
    }

    await _authService.updateProfileInDatabase(
      currentXp: currentXp,
      totalXp: totalXp,
      level: level,
    );
  }
}
