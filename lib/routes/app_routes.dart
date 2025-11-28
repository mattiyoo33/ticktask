import 'package:flutter/material.dart';
import '../presentation/task_list_screen/task_list_screen.dart';
import '../presentation/home_dashboard/home_dashboard.dart';
import '../presentation/task_creation_screen/task_creation_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/task_detail_screen/task_detail_screen.dart';
import '../presentation/friends_screen/friends_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String taskList = '/task-list-screen';
  static const String homeDashboard = '/home-dashboard';
  static const String taskCreation = '/task-creation-screen';
  static const String profile = '/profile-screen';
  static const String taskDetail = '/task-detail-screen';
  static const String friends = '/friends-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const HomeDashboard(),
    taskList: (context) => const TaskListScreen(),
    homeDashboard: (context) => const HomeDashboard(),
    taskCreation: (context) => const TaskCreationScreen(),
    profile: (context) => const ProfileScreen(),
    taskDetail: (context) => const TaskDetailScreen(),
    friends: (context) => const FriendsScreen(),
    // TODO: Add your other routes here
  };
}
