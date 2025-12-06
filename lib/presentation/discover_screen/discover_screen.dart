import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/public_task_card_widget.dart';
import './widgets/category_filter_widget.dart';
import './widgets/task_type_choice_modal.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleCategoryFilter(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _showTaskTypeChoice() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
      ),
      builder: (context) => TaskTypeChoiceModal(
        onPrivateSelected: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/task-creation-screen', arguments: {'isPublic': false});
        },
        onPublicSelected: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/task-creation-screen', arguments: {'isPublic': true});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Watch public tasks with filters
    final publicTasksAsync = ref.watch(
      publicTasksProvider({
        'categoryId': _selectedCategoryId,
        'searchQuery': _searchQuery.isEmpty ? null : _searchQuery,
        'limit': 50,
        'offset': 0,
      }),
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Discover',
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'add',
              color: colorScheme.primary,
              size: 24,
            ),
            onPressed: _showTaskTypeChoice,
            tooltip: 'Create Task',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(4.w),
            color: colorScheme.surface,
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              decoration: InputDecoration(
                hintText: 'Search public tasks...',
                prefixIcon: CustomIconWidget(
                  iconName: 'search',
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: CustomIconWidget(
                          iconName: 'close',
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category Filter
          CategoryFilterWidget(
            selectedCategoryId: _selectedCategoryId,
            onCategorySelected: _handleCategoryFilter,
          ),

          // Public Tasks List
          Expanded(
            child: publicTasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'explore',
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          size: 64,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No public tasks found',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Be the first to share a task!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(publicTasksProvider({
                      'categoryId': _selectedCategoryId,
                      'searchQuery': _searchQuery.isEmpty ? null : _searchQuery,
                      'limit': 50,
                      'offset': 0,
                    }));
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return PublicTaskCardWidget(
                        task: task,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/public-task-detail-screen',
                            arguments: task,
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
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
                      'Failed to load tasks',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(publicTasksProvider({
                          'categoryId': _selectedCategoryId,
                          'searchQuery': _searchQuery.isEmpty ? null : _searchQuery,
                          'limit': 50,
                          'offset': 0,
                        }));
                      },
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 1,
        variant: CustomBottomBarVariant.standard,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTaskTypeChoice,
        child: CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

