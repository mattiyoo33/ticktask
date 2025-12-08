import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_tab_bar.dart';
import './widgets/add_friends_modal_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/friend_card_widget.dart';
import './widgets/friends_request_card_widget.dart' show FriendRequestCardWidget;
import './widgets/friend_profile_modal.dart';
import '../../services/friend_service.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  // Get friends from database
  List<Map<String, dynamic>> get _friends {
    final friendsAsync = ref.watch(friendsProvider);
    return friendsAsync.when(
      data: (friends) => friends,
      loading: () => [],
      error: (_, __) => [],
    );
  }

  // Get incoming friend requests from database
  List<Map<String, dynamic>> get _incomingRequests {
    final requestsAsync = ref.watch(incomingFriendRequestsProvider);
    return requestsAsync.when(
      data: (requests) => requests.map((req) {
        final requester = req['requester'] as Map<String, dynamic>?;
        return {
          'id': req['id'],
          'name': requester?['full_name'] ?? 'User',
          'avatar': requester?['avatar_url'] ?? '',
          'timestamp': _formatTimestamp(req['created_at']),
          'friendship_id': req['id'],
        };
      }).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  // Get outgoing friend requests from database
  List<Map<String, dynamic>> get _outgoingRequests {
    final requestsAsync = ref.watch(outgoingFriendRequestsProvider);
    return requestsAsync.when(
      data: (requests) => requests.map((req) {
        final friend = req['friend'] as Map<String, dynamic>?;
        return {
          'id': req['id'],
          'name': friend?['full_name'] ?? 'User',
          'avatar': friend?['avatar_url'] ?? '',
          'timestamp': _formatTimestamp(req['created_at']),
          'friendship_id': req['id'],
        };
      }).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      final date = timestamp is String ? DateTime.parse(timestamp) : timestamp as DateTime;
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshFriends() async {
    HapticFeedback.lightImpact();
    // Refresh providers
    ref.invalidate(friendsProvider);
    ref.invalidate(incomingFriendRequestsProvider);
    ref.invalidate(outgoingFriendRequestsProvider);
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
          Navigator.pushNamed(context, '/search-users');
        },
        onImportContacts: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact import coming soon!'),
            ),
          );
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
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 4,
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
              _showFriendProfile(friend);
            },
            onMessage: () {
              // Open message thread
            },
            onRemove: () async {
              // Show remove friend confirmation
              await _showRemoveFriendDialog(friend);
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


  Future<void> _acceptFriendRequest(Map<String, dynamic> request) async {
    HapticFeedback.lightImpact();
    
    try {
      final friendService = ref.read(friendServiceProvider);
      final friendshipId = request['friendship_id'] as String? ?? request['id'] as String;
      await friendService.acceptFriendRequest(friendshipId);
      
      // Refresh data
      ref.invalidate(friendsProvider);
      ref.invalidate(incomingFriendRequestsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${request['name']} is now your friend!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting request: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _declineFriendRequest(Map<String, dynamic> request) async {
    HapticFeedback.lightImpact();
    
    try {
      final friendService = ref.read(friendServiceProvider);
      final friendshipId = request['friendship_id'] as String? ?? request['id'] as String;
      await friendService.rejectFriendRequest(friendshipId);
      
      // Refresh data
      ref.invalidate(incomingFriendRequestsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request declined'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining request: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showFriendProfile(Map<String, dynamic> friend) {
    final friendService = ref.read(friendServiceProvider);
    showDialog(
      context: context,
      builder: (context) => FriendProfileModal(
        friend: friend,
        friendService: friendService,
      ),
    );
  }

  Future<void> _showRemoveFriendDialog(Map<String, dynamic> friend) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text(
            'Are you sure you want to remove ${friend['name']} from your friends list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final friendService = ref.read(friendServiceProvider);
                final friendshipId = friend['friendship_id'] as String? ?? friend['id'] as String;
                await friendService.removeFriend(friendshipId);
                
                // Refresh data
                ref.invalidate(friendsProvider);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${friend['name']} removed from friends'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error removing friend: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
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
