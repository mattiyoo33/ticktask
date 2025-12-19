import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/register_screen/register_screen.dart';
import '../presentation/task_list_screen/task_list_screen.dart';
import '../presentation/home_dashboard/home_dashboard.dart';
import '../presentation/task_creation_screen/task_creation_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/task_detail_screen/task_detail_screen.dart';
import '../presentation/friends_screen/friends_screen.dart';
import '../presentation/friends_screen/widgets/search_users_screen.dart';
import '../presentation/discover_screen/discover_screen.dart';
import '../presentation/public_task_detail_screen/public_task_detail_screen.dart';
import '../presentation/plans_screen/plans_screen.dart';
import '../presentation/plan_creation_screen/plan_creation_screen.dart';
import '../presentation/plan_detail_screen/plan_detail_screen.dart';
import '../presentation/more_screen/more_screen.dart';
import '../presentation/achievements_screen/achievements_screen.dart';
import '../presentation/tutorial_screen/tutorial_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String taskList = '/task-list-screen';
  static const String homeDashboard = '/home-dashboard';
  static const String taskCreation = '/task-creation-screen';
  static const String profile = '/profile-screen';
  static const String taskDetail = '/task-detail-screen';
  static const String friends = '/friends-screen';
  static const String searchUsers = '/search-users';
  static const String discover = '/discover-screen';
  static const String publicTaskDetail = '/public-task-detail-screen';
  static const String plans = '/plans-screen';
  static const String planCreation = '/plan-creation-screen';
  static const String planDetail = '/plan-detail-screen';
  static const String more = '/more-screen';
  static const String achievements = '/achievements-screen';
  static const String tutorial = '/tutorial-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    taskList: (context) => const TaskListScreen(),
    homeDashboard: (context) => const HomeDashboard(),
    taskCreation: (context) => const TaskCreationScreen(),
    profile: (context) => const ProfileScreen(),
    taskDetail: (context) => const TaskDetailScreen(),
    friends: (context) => const FriendsScreen(),
    searchUsers: (context) => const SearchUsersScreen(),
    discover: (context) => const DiscoverScreen(),
    publicTaskDetail: (context) => const PublicTaskDetailScreen(),
    plans: (context) => const PlansScreen(),
    planCreation: (context) => const PlanCreationScreen(),
    planDetail: (context) => const PlanDetailScreen(),
    '/more-screen': (context) => const MoreScreen(),
    achievements: (context) => const AchievementsScreen(),
    tutorial: (context) {
      // Check if this is first time (from login/register) or returning user (from More)
      final isFirstTime = ModalRoute.of(context)?.settings.arguments as bool? ?? true;
      return TutorialScreen(isFirstTime: isFirstTime);
    },
  };
}
