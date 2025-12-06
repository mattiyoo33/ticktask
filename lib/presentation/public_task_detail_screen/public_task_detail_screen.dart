import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_app_bar.dart';
import '../task_detail_screen/widgets/comments_section_widget.dart';
import './widgets/public_task_leaderboard_widget.dart';
import './widgets/public_participants_widget.dart';

class PublicTaskDetailScreen extends ConsumerStatefulWidget {
  const PublicTaskDetailScreen({super.key});

  @override
  ConsumerState<PublicTaskDetailScreen> createState() => _PublicTaskDetailScreenState();
}

class _PublicTaskDetailScreenState extends ConsumerState<PublicTaskDetailScreen> {
  String? _taskId;
  Map<String, dynamic>? _task;
  bool _hasJoined = false;
  bool _isLoading = true;
  bool _isOwner = false;
  List<Map<String, dynamic>> _comments = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _taskId = args['id'] as String?;
      _task = args;
      _loadTaskDetails();
    }
  }

  Future<void> _loadTaskDetails() async {
    if (_taskId == null) return;

    setState(() => _isLoading = true);

    try {
      final publicTaskService = ref.read(publicTaskServiceProvider);
      final taskService = ref.read(taskServiceProvider);
      final task = await publicTaskService.getPublicTaskById(_taskId!);
      final hasJoined = await publicTaskService.hasJoinedPublicTask(_taskId!);
      
      // Load comments
      List<Map<String, dynamic>> comments = [];
      try {
        comments = await taskService.getTaskComments(_taskId!);
      } catch (e) {
        debugPrint('Error loading comments: $e');
      }
      
      final currentUser = ref.read(currentUserProvider).value;
      final isOwner = task?['user_id'] == currentUser?.id;

      if (mounted) {
        setState(() {
          _task = task;
          _hasJoined = hasJoined;
          _isOwner = isOwner;
          _comments = _transformComments(comments);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load task: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _transformComments(List<Map<String, dynamic>> comments) {
    return comments.map((comment) {
      final profile = comment['profiles'] as Map<String, dynamic>?;
      return {
        'id': comment['id'],
        'content': comment['content'] ?? '',
        'userName': profile?['full_name'] ?? 'Unknown',
        'userAvatar': profile?['avatar_url'] ?? '',
        'timestamp': comment['created_at'] != null
            ? DateTime.parse(comment['created_at'] as String)
            : DateTime.now(),
      };
    }).toList();
  }

  Future<void> _handleAddComment(String content) async {
    if (_taskId == null) return;

    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.addComment(_taskId!, content);
      _loadTaskDetails(); // Reload to get updated comments
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    }
  }

  Future<void> _handleJoinTask() async {
    if (_taskId == null) return;

    try {
      final publicTaskService = ref.read(publicTaskServiceProvider);
      await publicTaskService.joinPublicTask(_taskId!);
      
      if (mounted) {
        setState(() => _hasJoined = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Joined task successfully!')),
        );
        _loadTaskDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join task: $e')),
        );
      }
    }
  }

  Future<void> _handleLeaveTask() async {
    if (_taskId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Task'),
        content: const Text('Are you sure you want to leave this public task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final publicTaskService = ref.read(publicTaskServiceProvider);
        await publicTaskService.leavePublicTask(_taskId!);
        
        if (mounted) {
          setState(() => _hasJoined = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Left task successfully')),
          );
          _loadTaskDetails();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to leave task: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteTask() async {
    if (_taskId == null || !_isOwner) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this public task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final publicTaskService = ref.read(publicTaskServiceProvider);
        await publicTaskService.deletePublicTask(_taskId!);
        
        if (mounted) {
          Navigator.pop(context, 'deleted');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete task: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Task Details'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_task == null) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Task Details'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'error',
                color: colorScheme.error,
                size: 48,
              ),
              SizedBox(height: 2.h),
              Text(
                'Task not found',
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
        ),
      );
    }

    final title = _task!['title'] as String? ?? 'Untitled Task';
    final description = _task!['description'] as String? ?? '';
    final category = _task!['categories'] as Map<String, dynamic>?;
    final categoryName = category?['name'] as String? ?? 'Uncategorized';
    final categoryIcon = category?['icon'] as String? ?? 'category';
    final joinCount = _task!['public_join_count'] as int? ?? 0;
    final owner = _task!['profiles'] as Map<String, dynamic>?;
    final ownerName = owner?['full_name'] as String? ?? 
                     owner?['email']?.toString().split('@')[0] ?? 
                     'Unknown';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Public Task',
        actions: _isOwner
            ? [
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'delete',
                    color: colorScheme.error,
                    size: 24,
                  ),
                  onPressed: _handleDeleteTask,
                  tooltip: 'Delete Task',
                ),
              ]
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTaskDetails,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: categoryIcon,
                      color: colorScheme.primary,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      categoryName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 2.h),

              // Title
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 1.h),

              // Description
              if (description.isNotEmpty)
                Text(
                  description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

              SizedBox(height: 2.h),

              // Owner and Join Count
              Row(
                children: [
                  Text(
                    'by $ownerName',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'group',
                        color: colorScheme.onSurfaceVariant,
                        size: 4.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '$joinCount participants',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 3.h),

              // Join/Leave Button
              if (!_isOwner)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _hasJoined ? _handleLeaveTask : _handleJoinTask,
                    icon: CustomIconWidget(
                      iconName: _hasJoined ? 'exit_to_app' : 'group_add',
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(_hasJoined ? 'Leave Task' : 'Join Task'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      backgroundColor: _hasJoined
                          ? colorScheme.errorContainer
                          : colorScheme.primary,
                      foregroundColor: _hasJoined
                          ? colorScheme.onErrorContainer
                          : colorScheme.onPrimary,
                    ),
                  ),
                ),

              SizedBox(height: 3.h),

              // Participants Section
              PublicParticipantsWidget(taskId: _taskId!),

              SizedBox(height: 3.h),

              // Leaderboard Section
              PublicTaskLeaderboardWidget(taskId: _taskId!),

              SizedBox(height: 3.h),

              // Comments Section
              CommentsSectionWidget(
                comments: _comments,
                onAddComment: _handleAddComment,
                isCollaborative: false,
                hasParticipants: _hasJoined || _isOwner,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 1,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }
}

