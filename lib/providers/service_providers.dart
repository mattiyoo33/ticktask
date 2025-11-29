import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/task_service.dart';
import '../services/friend_service.dart';
import '../services/activity_service.dart';

// Task Service Provider
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

// Friend Service Provider
final friendServiceProvider = Provider<FriendService>((ref) {
  return FriendService();
});

// Activity Service Provider
final activityServiceProvider = Provider<ActivityService>((ref) {
  return ActivityService();
});

// Today's Tasks Provider
final todaysTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final taskService = ref.watch(taskServiceProvider);
  return await taskService.getTodaysTasks();
});

// All Tasks Provider
final allTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final taskService = ref.watch(taskServiceProvider);
  return await taskService.getTasks();
});

// Friends Provider
final friendsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final friendService = ref.watch(friendServiceProvider);
  return await friendService.getFriends();
});

// Incoming Friend Requests Provider
final incomingFriendRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final friendService = ref.watch(friendServiceProvider);
  return await friendService.getIncomingRequests();
});

// Outgoing Friend Requests Provider
final outgoingFriendRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final friendService = ref.watch(friendServiceProvider);
  return await friendService.getOutgoingRequests();
});

// Recent Activities Provider
final recentActivitiesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final activityService = ref.watch(activityServiceProvider);
  return await activityService.getRecentActivities();
});

// Leaderboard Provider
final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final friendService = ref.watch(friendServiceProvider);
  return await friendService.getLeaderboard();
});

