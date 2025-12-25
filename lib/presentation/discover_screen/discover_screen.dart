import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/public_task_card_widget.dart';
import './widgets/public_plan_card_widget.dart';
import './widgets/category_filter_widget.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  int _selectedTab = 0; // 0 = Tasks, 1 = Plans
  bool _hasRefreshedOnLoad = false;

  @override
  void initState() {
    super.initState();
    // Refresh data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  void _refreshAllData() {
    if (!_hasRefreshedOnLoad) {
      _hasRefreshedOnLoad = true;
      // Note: publicTasksProvider and publicPlansProvider are family providers
      // that require filter parameters. Since the screen uses pushReplacementNamed
      // for navigation, the widget is rebuilt each time, causing providers to be
      // re-watched. Riverpod will fetch fresh data if the cache is stale.
      // Users can also use pull-to-refresh for manual refresh.
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleCategoryFilter(String? categoryId) {
    if (_selectedCategoryId != categoryId) {
      setState(() {
        _selectedCategoryId = categoryId;
      });
    }
  }

  void _handleSearch(String query) {
    // Cancel previous debounce timer
    _searchDebounce?.cancel();
    
    // Set up new debounce timer
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _searchQuery != query) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Create filter objects
    final taskFilters = PublicTaskFilters(
      categoryId: _selectedCategoryId,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      limit: 50,
      offset: 0,
    );
    
    final planFilters = PublicPlanFilters(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      categoryId: _selectedTab == 1 ? _selectedCategoryId : null,
      limit: 50,
      offset: 0,
    );
    
    // Watch public tasks and plans with filters
    final publicTasksAsync = ref.watch(
      publicTasksProvider(taskFilters),
    );
    
    final publicPlansAsync = ref.watch(
      publicPlansProvider(planFilters),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(4.w),
            color: colorScheme.surface,
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              decoration: InputDecoration(
                hintText: _selectedTab == 0 ? 'Search public tasks...' : 'Search public plans...',
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

          // Tab Switcher
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    context,
                    label: 'Tasks',
                    index: 0,
                    icon: 'checklist',
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    context,
                    label: 'Plans',
                    index: 1,
                    icon: 'event',
                  ),
                ),
              ],
            ),
          ),

          // Category Filter (tasks & plans share same selector)
          if (true)
            CategoryFilterWidget(
              selectedCategoryId: _selectedCategoryId,
              onCategorySelected: _handleCategoryFilter,
            ),

          // Content List
          Expanded(
            child: _selectedTab == 0
                ? publicTasksAsync.when(
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
                    ref.invalidate(publicTasksProvider(PublicTaskFilters(
                      categoryId: _selectedCategoryId,
                      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                      limit: 50,
                      offset: 0,
                    )));
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
              error: (error, stack) {
                debugPrint('❌ Discover page error: $error');
                debugPrint('Stack trace: $stack');
                return Center(
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
                      Text(
                        error.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2.h),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(publicTasksProvider(PublicTaskFilters(
                            categoryId: _selectedCategoryId,
                            searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                            limit: 50,
                            offset: 0,
                          )));
                        },
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            )
                : publicPlansAsync.when(
              data: (plans) {
                if (plans.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'event',
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          size: 64,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No public plans found',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Be the first to share a plan!',
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
                    ref.invalidate(publicPlansProvider(PublicPlanFilters(
                      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                      limit: 50,
                      offset: 0,
                    )));
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      return PublicPlanCardWidget(
                        plan: plan,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/plan-detail-screen',
                            arguments: plan['id'] as String,
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
              error: (error, stack) {
                debugPrint('❌ Discover page error: $error');
                debugPrint('Stack trace: $stack');
                return Center(
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
                        'Failed to load plans',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        error.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2.h),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(publicPlansProvider(PublicPlanFilters(
                            searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                            limit: 50,
                            offset: 0,
                          )));
                        },
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 1,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, {required String label, required int index, required String icon}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

