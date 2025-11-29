import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/custom_tab_bar.dart';
import './widgets/add_friends_modal_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/friend_card_widget.dart';
import './widgets/friends_request_card_widget.dart' show FriendRequestCardWidget;
import './widgets/leaderboard_item_widget.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = false;
  String _searchQuery = '';

  // Mock data
  final List<Map<String, dynamic>> _friends = [
    {
      "id": 1,
      "name": "Sarah Johnson",
      "avatar":
          "https://images.unsplash.com/photo-1652391584869-0408bf759537",
      "semanticLabel":
          "Young woman with long brown hair smiling at camera wearing casual white top",
      "level": 12,
      "xp": 2450,
      "recentActivity": "Completed 'Morning Workout' task",
      "isOnline": true,
    },
    {
      "id": 2,
      "name": "Mike Chen",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1ee3f5dd7-1762273615703.png",
      "semanticLabel":
          "Asian man with short black hair and beard wearing dark blue shirt",
      "level": 8,
      "xp": 1680,
      "recentActivity": "Started a 7-day reading streak",
      "isOnline": false,
    },
    {
      "id": 3,
      "name": "Emma Rodriguez",
      "avatar": "https://images.unsplash.com/photo-1669987554988-3e4681612415",
      "semanticLabel":
          "Hispanic woman with curly hair wearing red lipstick and professional attire",
      "level": 15,
      "xp": 3200,
      "recentActivity": "Achieved 'Productivity Master' badge",
      "isOnline": true,
    },
    {
      "id": 4,
      "name": "David Kim",
      "avatar":
          "https://images.unsplash.com/photo-1492140377033-831754a4702f",
      "semanticLabel":
          "Young man with glasses and short dark hair wearing casual gray sweater",
      "level": 6,
      "xp": 980,
      "recentActivity": "Completed daily meditation task",
      "isOnline": false,
    },
  ];

  final List<Map<String, dynamic>> _incomingRequests = [
    {
      "id": 1,
      "name": "Alex Thompson",
      "avatar":
          "https://images.unsplash.com/photo-1713810189168-c4d5340e975b",
      "semanticLabel":
          "Blonde woman with bright smile wearing casual blue top outdoors",
      "timestamp": "2 hours ago",
      "mutualFriends": 3,
    },
    {
      "id": 2,
      "name": "Jordan Lee",
      "avatar": "https://img.rocket.new/generatedImages/rocket_gen_img_1d67f557b-1762249150720.png",
      "semanticLabel":
          "Young man with brown hair wearing white collared shirt smiling",
      "timestamp": "1 day ago",
      "mutualFriends": 1,
    },
  ];

  final List<Map<String, dynamic>> _outgoingRequests = [
    {
      "id": 1,
      "name": "Lisa Park",
      "avatar":
          "https://images.unsplash.com/photo-1725121224951-46860d47987f",
      "semanticLabel":
          "Asian woman with long black hair wearing white top with natural lighting",
      "timestamp": "3 days ago",
      "mutualFriends": 2,
    },
  ];

  final List<Map<String, dynamic>> _leaderboard = [
    {
      "id": 1,
      "name": "Emma Rodriguez",
      "avatar": "https://images.unsplash.com/photo-1669987554988-3e4681612415",
      "semanticLabel":
          "Hispanic woman with curly hair wearing red lipstick and professional attire",
      "xp": 3200,
      "level": 15,
      "badges": ["emoji_events", "star", "local_fire_department"],
      "isCurrentUser": false,
    },
    {
      "id": 2,
      "name": "You",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_152ea5f89-1762274365865.png",
      "semanticLabel":
          "Person with short hair wearing casual clothing in natural lighting",
      "xp": 2850,
      "level": 13,
      "badges": ["star", "local_fire_department"],
      "isCurrentUser": true,
    },
    {
      "id": 3,
      "name": "Sarah Johnson",
      "avatar":
          "https://images.unsplash.com/photo-1652391584869-0408bf759537",
      "semanticLabel":
          "Young woman with long brown hair smiling at camera wearing casual white top",
      "xp": 2450,
      "level": 12,
      "badges": ["star"],
      "isCurrentUser": false,
    },
    {
      "id": 4,
      "name": "Mike Chen",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1ee3f5dd7-1762273615703.png",
      "semanticLabel":
          "Asian man with short black hair and beard wearing dark blue shirt",
      "xp": 1680,
      "level": 8,
      "badges": ["local_fire_department"],
      "isCurrentUser": false,
    },
    {
      "id": 5,
      "name": "David Kim",
      "avatar":
          "https://images.unsplash.com/photo-1492140377033-831754a4702f",
      "semanticLabel":
          "Young man with glasses and short dark hair wearing casual gray sweater",
      "xp": 980,
      "level": 6,
      "badges": [],
      "isCurrentUser": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshFriends() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query.toLowerCase());
  }

  void _showAddFriendsModal() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFriendsModalWidget(
        onSearchUsers: () {
          // Handle search users
        },
        onImportContacts: () {
          // Handle import contacts
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredFriends() {
    if (_searchQuery.isEmpty) return _friends;
    return _friends.where((friend) {
      final name = (friend['name'] as String).toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: _isSearching ? null : 'Friends',
        variant: CustomAppBarVariant.standard,
        leading: _isSearching
            ? IconButton(
                onPressed: _toggleSearch,
                icon: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: colorScheme.onSurface,
                  size: 24,
                ),
              )
            : null,
        actions: [
          if (_isSearching)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search friends...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            )
          else ...[
            IconButton(
              onPressed: _toggleSearch,
              icon: CustomIconWidget(
                iconName: 'search',
                color: colorScheme.onSurface,
                size: 24,
              ),
            ),
            IconButton(
              onPressed: _showAddFriendsModal,
              icon: CustomIconWidget(
                iconName: 'person_add',
                color: colorScheme.primary,
                size: 24,
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          CustomTabBar(
            tabs: const [
              CustomTab(text: 'Friends'),
              CustomTab(text: 'Requests'),
              CustomTab(text: 'Leaderboard'),
            ],
            controller: _tabController,
            variant: CustomTabBarVariant.underline,
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildRequestsTab(),
                _buildLeaderboardTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 3,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  Widget _buildFriendsTab() {
    final filteredFriends = _getFilteredFriends();

    if (filteredFriends.isEmpty && _searchQuery.isEmpty) {
      return EmptyStateWidget(
        title: 'No Friends Yet',
        subtitle: 'Add friends to share your progress and compete together!',
        buttonText: 'Add Friends',
        onButtonPressed: _showAddFriendsModal,
        mascotMessage:
            "Hey there! Friends make everything more fun. Let's find some workout buddies!",
      );
    }

    if (filteredFriends.isEmpty && _searchQuery.isNotEmpty) {
      return EmptyStateWidget(
        title: 'No Results Found',
        subtitle: 'Try searching with a different name or username.',
        buttonText: 'Clear Search',
        onButtonPressed: () {
          _searchController.clear();
          _onSearchChanged('');
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshFriends,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        itemCount: filteredFriends.length,
        itemBuilder: (context, index) {
          final friend = filteredFriends[index];
          return FriendCardWidget(
            friend: friend,
            onTap: () {
              // Navigate to friend profile
            },
            onViewProfile: () {
              // View friend profile
            },
            onMessage: () {
              // Open message thread
            },
            onRemove: () {
              // Show remove friend confirmation
              _showRemoveFriendDialog(friend);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_incomingRequests.isEmpty && _outgoingRequests.isEmpty) {
      return EmptyStateWidget(
        title: 'No Friend Requests',
        subtitle:
            'When someone sends you a friend request, it will appear here.',
        buttonText: 'Find Friends',
        onButtonPressed: _showAddFriendsModal,
        mascotMessage:
            "No requests yet? That's okay! Let's go find some friends to connect with.",
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      children: [
        if (_incomingRequests.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Text(
              'Incoming Requests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          ..._incomingRequests.map((request) => FriendRequestCardWidget(
                request: request,
                onAccept: () => _acceptFriendRequest(request),
                onDecline: () => _declineFriendRequest(request),
              )),
        ],
        if (_outgoingRequests.isNotEmpty) ...[
          if (_incomingRequests.isNotEmpty) SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Text(
              'Sent Requests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          ..._outgoingRequests.map((request) => FriendRequestCardWidget(
                request: request,
                isOutgoing: true,
              )),
        ],
      ],
    );
  }

  Widget _buildLeaderboardTab() {
    return Column(
      children: [
        // Weekly reset info
        Container(
          margin: EdgeInsets.all(4.w),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'emoji_events',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Leaderboard',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Text(
                      'Resets every Monday • 3 days left',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Leaderboard list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 2.h),
            itemCount: _leaderboard.length,
            itemBuilder: (context, index) {
              final user = _leaderboard[index];
              return LeaderboardItemWidget(
                user: user,
                rank: index + 1,
                isCurrentUser: user['isCurrentUser'] as bool? ?? false,
              );
            },
          ),
        ),
      ],
    );
  }

  void _acceptFriendRequest(Map<String, dynamic> request) {
    HapticFeedback.lightImpact();
    setState(() {
      _incomingRequests.remove(request);
      // Add to friends list
      _friends.add({
        ...request,
        "level": 1,
        "xp": 0,
        "recentActivity": "Just joined TickTask!",
        "isOnline": true,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${request['name']} is now your friend!'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _declineFriendRequest(Map<String, dynamic> request) {
    HapticFeedback.lightImpact();
    setState(() {
      _incomingRequests.remove(request);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Friend request declined'),
      ),
    );
  }

  void _showRemoveFriendDialog(Map<String, dynamic> friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Friend'),
        content: Text(
            'Are you sure you want to remove ${friend['name']} from your friends list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _friends.remove(friend);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${friend['name']} removed from friends'),
                ),
              );
            },
            child: Text(
              'Remove',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
