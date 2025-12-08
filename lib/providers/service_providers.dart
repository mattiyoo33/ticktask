import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/task_service.dart';
import '../services/friend_service.dart';
import '../services/activity_service.dart';
import '../services/public_task_service.dart';
import '../services/plan_service.dart';
import 'auth_provider.dart';

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

// Public Task Service Provider
final publicTaskServiceProvider = Provider<PublicTaskService>((ref) {
  return PublicTaskService();
});

// Plan Service Provider
final planServiceProvider = Provider<PlanService>((ref) {
  return PlanService();
});

// Today's Tasks Provider - watches auth state to auto-invalidate on user change
final todaysTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Watch auth state to invalidate when user changes
  final authState = ref.watch(authStateProvider);
  final authStateValue = authState.value;
  
  // If not authenticated, return empty list
  if (authStateValue?.session == null) {
    return [];
  }
  
  final taskService = ref.watch(taskServiceProvider);
  return await taskService.getTodaysTasks();
});

// All Tasks Provider - watches auth state to auto-invalidate on user change
final allTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Watch auth state to invalidate when user changes
  final authState = ref.watch(authStateProvider);
  final authStateValue = authState.value;
  
  // If not authenticated, return empty list
  if (authStateValue?.session == null) {
    return [];
  }
  
  final taskService = ref.watch(taskServiceProvider);
  return await taskService.getTasks();
});

// Friends Provider - watches auth state to auto-invalidate on user change
final friendsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Watch auth state to invalidate when user changes
  final authState = ref.watch(authStateProvider);
  final authStateValue = authState.value;
  
  // If not authenticated, return empty list
  if (authStateValue?.session == null) {
    return [];
  }
  
  final friendService = ref.watch(friendServiceProvider);
  return await friendService.getFriends();
});

// Incoming Friend Requests Provider - watches auth state to auto-invalidate on user change
final incomingFriendRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Watch auth state to invalidate when user changes
  final authState = ref.watch(authStateProvider);
  final authStateValue = authState.value;
  
  // If not authenticated, return empty list
  if (authStateValue?.session == null) {
    return [];
  }
  
  final friendService = ref.watch(friendServiceProvider);
  return await friendService.getIncomingRequests();
});

// Outgoing Friend Requests Provider - watches auth state to auto-invalidate on user change
final outgoingFriendRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Watch auth state to invalidate when user changes
  final authState = ref.watch(authStateProvider);
  final authStateValue = authState.value;
  
  // If not authenticated, return empty list
  if (authStateValue?.session == null) {
    return [];
  }
  
  final friendService = ref.watch(friendServiceProvider);
  return await friendService.getOutgoingRequests();
});

// Recent Activities Provider - watches auth state to auto-invalidate on user change
final recentActivitiesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Watch auth state to invalidate when user changes
  final authState = ref.watch(authStateProvider);
  final authStateValue = authState.value;
  
  // If not authenticated, return empty list
  if (authStateValue?.session == null) {
    return [];
  }
  
  final activityService = ref.watch(activityServiceProvider);
  return await activityService.getRecentActivities();
});

// Leaderboard Provider - watches auth state to auto-invalidate on user change
final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Watch auth state to invalidate when user changes
  final authState = ref.watch(authStateProvider);
  final authStateValue = authState.value;
  
  // If not authenticated, return empty list
  if (authStateValue?.session == null) {
    return [];
  }
  
  final friendService = ref.watch(friendServiceProvider);
  return await friendService.getLeaderboard();
});

// Pending Collaboration Tasks Provider - watches auth state to auto-invalidate on user change
final pendingCollaborationTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Watch auth state to invalidate when user changes
  final authState = ref.watch(authStateProvider);
  final authStateValue = authState.value;
  
  print('🔍 pendingCollaborationTasksProvider: authState.value = ${authStateValue?.session != null ? "authenticated" : "null"}');
  
  // If not authenticated, return empty list
  if (authStateValue?.session == null) {
    print('⚠️ pendingCollaborationTasksProvider: No session, returning empty list');
    return [];
  }
  
  print('✅ pendingCollaborationTasksProvider: Session exists, fetching pending tasks...');
  final taskService = ref.watch(taskServiceProvider);
  final result = await taskService.getPendingCollaborationTasks();
  print('📊 pendingCollaborationTasksProvider: Fetched ${result.length} pending tasks');
  return result;
});

// Categories Provider
final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final publicTaskService = ref.watch(publicTaskServiceProvider);
  return await publicTaskService.getCategories();
});

// Public Tasks Provider - using a custom filter class for stable equality
class PublicTaskFilters {
  final String? categoryId;
  final String? searchQuery;
  final int limit;
  final int offset;

  const PublicTaskFilters({
    this.categoryId,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicTaskFilters &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          searchQuery == other.searchQuery &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      categoryId.hashCode ^
      searchQuery.hashCode ^
      limit.hashCode ^
      offset.hashCode;
}

final publicTasksProvider = FutureProvider.family<List<Map<String, dynamic>>, PublicTaskFilters>((ref, filters) async {
  final publicTaskService = ref.watch(publicTaskServiceProvider);
  final result = await publicTaskService.getPublicTasks(
    categoryId: filters.categoryId,
    searchQuery: filters.searchQuery,
    limit: filters.limit,
    offset: filters.offset,
  );
  // Keep the provider alive to prevent unnecessary refetches
  ref.keepAlive();
  return result;
});

// Public Task Participants Provider - shared provider for participants
final publicTaskParticipantsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, taskId) async {
  final publicTaskService = ref.watch(publicTaskServiceProvider);
  return await publicTaskService.getPublicTaskParticipants(taskId);
});

// All Plans Provider - watches auth state to auto-invalidate on user change
final allPlansProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Watch auth state to invalidate when user changes
  final authState = ref.watch(authStateProvider);
  final authStateValue = authState.value;
  
  // If not authenticated, return empty list
  if (authStateValue?.session == null) {
    return [];
  }
  
  final planService = ref.watch(planServiceProvider);
  return await planService.getPlans();
});

// Plan by ID Provider
final planByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, planId) async {
  final authState = ref.watch(authStateProvider);
  final authStateValue = authState.value;
  
  if (authStateValue?.session == null) {
    return null;
  }
  
  final planService = ref.watch(planServiceProvider);
  return await planService.getPlanById(planId);
});

