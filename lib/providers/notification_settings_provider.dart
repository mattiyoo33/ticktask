import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _notificationsEnabledKey = 'notifications_enabled';
const String _taskRemindersKey = 'notifications_task_reminders';
const String _dueDateRemindersKey = 'notifications_due_date_reminders';
const String _friendRequestsKey = 'notifications_friend_requests';
const String _achievementsKey = 'notifications_achievements';
const String _planUpdatesKey = 'notifications_plan_updates';

// Notification settings model
class NotificationSettings {
  final bool notificationsEnabled;
  final bool taskReminders;
  final bool dueDateReminders;
  final bool friendRequests;
  final bool achievements;
  final bool planUpdates;

  NotificationSettings({
    this.notificationsEnabled = true,
    this.taskReminders = true,
    this.dueDateReminders = true,
    this.friendRequests = true,
    this.achievements = true,
    this.planUpdates = true,
  });

  NotificationSettings copyWith({
    bool? notificationsEnabled,
    bool? taskReminders,
    bool? dueDateReminders,
    bool? friendRequests,
    bool? achievements,
    bool? planUpdates,
  }) {
    return NotificationSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      taskReminders: taskReminders ?? this.taskReminders,
      dueDateReminders: dueDateReminders ?? this.dueDateReminders,
      friendRequests: friendRequests ?? this.friendRequests,
      achievements: achievements ?? this.achievements,
      planUpdates: planUpdates ?? this.planUpdates,
    );
  }
}

// Notification settings provider
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(NotificationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = NotificationSettings(
        notificationsEnabled: prefs.getBool(_notificationsEnabledKey) ?? true,
        taskReminders: prefs.getBool(_taskRemindersKey) ?? true,
        dueDateReminders: prefs.getBool(_dueDateRemindersKey) ?? true,
        friendRequests: prefs.getBool(_friendRequestsKey) ?? true,
        achievements: prefs.getBool(_achievementsKey) ?? true,
        planUpdates: prefs.getBool(_planUpdatesKey) ?? true,
      );
      state = settings;
    } catch (e) {
      // If there's an error, use default settings
      state = NotificationSettings();
    }
  }

  Future<void> updateSettings(NotificationSettings newSettings) async {
    state = newSettings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, newSettings.notificationsEnabled);
      await prefs.setBool(_taskRemindersKey, newSettings.taskReminders);
      await prefs.setBool(_dueDateRemindersKey, newSettings.dueDateReminders);
      await prefs.setBool(_friendRequestsKey, newSettings.friendRequests);
      await prefs.setBool(_achievementsKey, newSettings.achievements);
      await prefs.setBool(_planUpdatesKey, newSettings.planUpdates);
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final newSettings = state.copyWith(notificationsEnabled: enabled);
    await updateSettings(newSettings);
  }

  Future<void> setTaskReminders(bool enabled) async {
    final newSettings = state.copyWith(taskReminders: enabled);
    await updateSettings(newSettings);
  }

  Future<void> setDueDateReminders(bool enabled) async {
    final newSettings = state.copyWith(dueDateReminders: enabled);
    await updateSettings(newSettings);
  }

  Future<void> setFriendRequests(bool enabled) async {
    final newSettings = state.copyWith(friendRequests: enabled);
    await updateSettings(newSettings);
  }

  Future<void> setAchievements(bool enabled) async {
    final newSettings = state.copyWith(achievements: enabled);
    await updateSettings(newSettings);
  }

  Future<void> setPlanUpdates(bool enabled) async {
    final newSettings = state.copyWith(planUpdates: enabled);
    await updateSettings(newSettings);
  }
}



