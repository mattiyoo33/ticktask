import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Watch auth state changes to automatically update current user
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((authState) => authState.session?.user);
});

// Synchronous current user (for immediate access)
final currentUserSyncProvider = Provider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAuthenticated;
});

// Basic profile from auth metadata (synchronous)
final userProfileProvider = Provider<Map<String, dynamic>?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.userProfile;
});

// Full profile from database (async - fetches from profiles table)
// This will automatically invalidate when auth state changes
final userProfileFromDbProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  // Watch auth state to invalidate when user changes
  final authStateAsync = ref.watch(authStateProvider);
  final authState = authStateAsync.value;
  
  // If no user, return null
  if (authState?.session?.user == null) {
    return null;
  }
  
  final authService = ref.watch(authServiceProvider);
  return await authService.fetchUserProfile();
});

