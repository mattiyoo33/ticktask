/// Onboarding Service
/// 
/// This service handles onboarding/initial setup functionality. It tracks whether
/// a user has completed the onboarding flow and stores their onboarding responses.
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class OnboardingService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _userNameKey = 'onboarding_user_name';
  static const String _genderKey = 'onboarding_gender';
  static const String _ageRangeKey = 'onboarding_age_range';
  static const String _religionKey = 'onboarding_religion';
  static const String _employmentStatusKey = 'onboarding_employment_status';
  static const String _affirmationFamiliarityKey = 'onboarding_affirmation_familiarity';
  static const String _selfReflectionFrequencyKey = 'onboarding_self_reflection_frequency';
  static const String _affirmationHabitsKey = 'onboarding_affirmation_habits';
  static const String _referralSourceKey = 'onboarding_referral_source';
  static const String _affirmationCountKey = 'onboarding_affirmation_count';
  static const String _affirmationStartTimeKey = 'onboarding_affirmation_start_time';
  static const String _affirmationEndTimeKey = 'onboarding_affirmation_end_time';

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (e) {
      debugPrint('Error checking onboarding completion: $e');
      return false;
    }
  }

  // Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
      debugPrint('✅ Onboarding marked as completed');
    } catch (e) {
      debugPrint('Error marking onboarding as completed: $e');
      rethrow;
    }
  }

  // Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, false);
      await prefs.remove(_userNameKey);
      await prefs.remove(_genderKey);
      await prefs.remove(_ageRangeKey);
      await prefs.remove(_religionKey);
      await prefs.remove(_employmentStatusKey);
      await prefs.remove(_affirmationFamiliarityKey);
      await prefs.remove(_selfReflectionFrequencyKey);
      await prefs.remove(_affirmationHabitsKey);
      await prefs.remove(_referralSourceKey);
      await prefs.remove(_affirmationCountKey);
      await prefs.remove(_affirmationStartTimeKey);
      await prefs.remove(_affirmationEndTimeKey);
      debugPrint('✅ Onboarding reset');
    } catch (e) {
      debugPrint('Error resetting onboarding: $e');
      rethrow;
    }
  }

  // Save onboarding data
  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  Future<void> saveGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderKey, gender);
  }

  Future<void> saveAgeRange(String ageRange) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ageRangeKey, ageRange);
  }

  Future<void> saveReligion(String religion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_religionKey, religion);
  }

  Future<void> saveEmploymentStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_employmentStatusKey, status);
  }

  Future<void> saveAffirmationFamiliarity(String familiarity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_affirmationFamiliarityKey, familiarity);
  }

  Future<void> saveSelfReflectionFrequency(String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selfReflectionFrequencyKey, frequency);
  }

  Future<void> saveAffirmationHabits(List<String> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_affirmationHabitsKey, habits);
  }

  Future<void> saveReferralSource(String source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_referralSourceKey, source);
  }

  Future<void> saveAffirmationSettings({
    required int count,
    required String startTime,
    required String endTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_affirmationCountKey, count);
    await prefs.setString(_affirmationStartTimeKey, startTime);
    await prefs.setString(_affirmationEndTimeKey, endTime);
  }

  // Get onboarding data
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<String?> getGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_genderKey);
  }

  Future<String?> getAgeRange() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ageRangeKey);
  }

  Future<String?> getReligion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_religionKey);
  }

  Future<String?> getEmploymentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_employmentStatusKey);
  }

  Future<String?> getAffirmationFamiliarity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_affirmationFamiliarityKey);
  }

  Future<String?> getSelfReflectionFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selfReflectionFrequencyKey);
  }

  Future<List<String>> getAffirmationHabits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_affirmationHabitsKey) ?? [];
  }

  Future<String?> getReferralSource() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_referralSourceKey);
  }

  Future<Map<String, dynamic>?> getAffirmationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_affirmationCountKey);
    final startTime = prefs.getString(_affirmationStartTimeKey);
    final endTime = prefs.getString(_affirmationEndTimeKey);
    
    if (count == null || startTime == null || endTime == null) {
      return null;
    }
    
    return {
      'count': count,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
